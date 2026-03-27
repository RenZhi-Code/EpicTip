local addonName, ET = ...

ET.Tooltip = ET.Tooltip or {}
local Tooltip = ET.Tooltip
local L = ET.L or {}

-- PATCH 12.0.0+ COMPATIBILITY: Secret Values System
-- This module has been updated to handle Blizzard's new Secret Values system
-- introduced in Patch 12.0.0 (Midnight). The system restricts operations on
-- combat-related data returned by certain APIs to prevent tainted code from
-- performing complex combat logic. Key protections added:
-- - Error handling with pcall to catch secret value errors gracefully
-- See: https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes
--
-- PATCH 12.0.1 TOOLTIP LINE TYPE CHANGES:
-- All Restricted<X> line types replaced with single UsageRequirement type:
-- - RaceClass, Faction, Skill, PvPMedal, Reputation, Level, NotInArena,
--   NotInRatedBg, NotAlreadyKnown converted to UsageRequirement
-- New line types added:
-- - UsageRequirement (replaces all Restricted* types)
-- - ItemSpellTriggerLearn (spellID), LearnTransmogSet (setID),
--   LearnTransmogIllusion (spellID), TradeTimeRemaining (secondsLeft),
--   ItemQuality (colorblind mode), ErrorLine, DisabledLine
-- ItemName now has quality arg, QuestObjective has numRequired/numFulfilled/progressBarPercent

-- PERFORMANCE-CRITICAL: Cache expensive Blizzard API results
-- These APIs involve network requests and C++↔Lua transitions
-- Caching prevents: 1) Server spam 2) UI freezes 3) Memory churn
Tooltip.inspectedGUID = nil  -- Track which player we've cached
Tooltip.specName = ""        -- Cache spec to avoid repeated API calls
Tooltip.cachedIlvl = "?"     -- Cache item level (expensive inspect data)
Tooltip.cachedRole = ""      -- Cache role to avoid repeated calculations

-- TAINT-SAFE STATE TRACKING
-- CRITICAL: Never write custom properties directly to GameTooltip or any Blizzard frame.
-- Writing tooltip.epicTipProcessed = true taints the frame, causing Blizzard's secure
-- SetWatch() to fail with "Lua Taint: EpicTip". Instead, use this external table.
-- All modules should use ET.TooltipState:Get/Set/Clear instead of tooltip.epicTipXxx.
local tooltipStateData = {}
ET.TooltipState = {}

function ET.TooltipState:Get(tooltip, key)
    local id = tostring(tooltip)
    return tooltipStateData[id] and tooltipStateData[id][key]
end

function ET.TooltipState:Set(tooltip, key, value)
    local id = tostring(tooltip)
    if not tooltipStateData[id] then
        tooltipStateData[id] = {}
    end
    tooltipStateData[id][key] = value
end

function ET.TooltipState:Clear(tooltip)
    local id = tostring(tooltip)
    tooltipStateData[id] = nil
end

local function GetUtils()
    return ET.Utils
end

local function IsSecretValue(value)
    if not issecretvalue then return false end
    local ok, res = pcall(issecretvalue, value)
    return ok and res or false
end

local function SafeGetUnit(tooltip)
    if not tooltip or not tooltip.GetUnit then return nil end
    local ok, _, unit = pcall(tooltip.GetUnit, tooltip)
    if not ok or not unit or IsSecretValue(unit) then return nil end
    return unit
end

local function TooltipHasSpell(tooltip)
    if not tooltip or not tooltip.GetSpell then return false end

    local ok, spellName, _, spellId = pcall(tooltip.GetSpell, tooltip)
    if not ok then return false end

    if spellId and not IsSecretValue(spellId) then return true end
    if spellName and not IsSecretValue(spellName) then return true end
    return false
end

-- Detect World Quest tooltips to prevent interference with World Quest display
-- World Quests use special tooltip frames that should not be modified
-- Walk a frame's parent chain looking for WorldMapFrame (up to 10 levels)
local function IsDescendantOfWorldMap(frame)
    if not frame then return false end
    local worldMap = _G.WorldMapFrame
    if not worldMap then return false end
    local current = frame
    for _ = 1, 10 do
        if current == worldMap then return true end
        local ok, parent = pcall(function() return current:GetParent() end)
        if not ok or not parent then break end
        current = parent
    end
    return false
end

local function IsWorldQuestTooltip(tooltip)
    if not tooltip then return false end

    -- Match dedicated WQ tooltip frames by name or global reference
    local okName, tooltipName = pcall(tooltip.GetName, tooltip)
    if okName and tooltipName and not IsSecretValue(tooltipName) then
        if tooltipName:find("WorldQuest") or tooltipName:find("World_Quest") then
            return true
        end
    end

    if tooltip == _G.WorldQuestTooltip or tooltip == _G.WorldQuestDataProviderTooltip then
        return true
    end

    -- Detect GameTooltip shown in a WQ/map context by walking the owner's parent chain.
    -- WQ pins are children of WorldMapFrame — if the owner is a descendant, skip processing.
    local owner = nil
    if tooltip.GetOwner then
        local ok, o = pcall(tooltip.GetOwner, tooltip)
        if ok then owner = o end
    end
    if not owner and tooltip.GetOwnerRegion then
        local ok, o = pcall(tooltip.GetOwnerRegion, tooltip)
        if ok then owner = o end
    end
    if owner and IsDescendantOfWorldMap(owner) then
        return true
    end

    return false
end

-- Expose IsWorldQuestTooltip for use in other modules
function Tooltip.IsWorldQuestTooltip(tooltip)
    return IsWorldQuestTooltip(tooltip)
end

-- Ensure we only install GameTooltip hooks once per session
Tooltip.hooksInstalled = Tooltip.hooksInstalled or false
Tooltip.statusBarHooksInstalled = Tooltip.statusBarHooksInstalled or false

-- TAINT-SAFE: Restricted instance detection (modeled after MidnightTooltip).
-- In dungeons, raids, and scenarios, calling tooltip:GetUnit() inside a
-- TooltipDataProcessor callback taints the tooltip's processing chain, causing
-- Blizzard's SetWatch() on GameTooltipStatusBar to fail. The fix: skip all
-- tooltip processing in restricted instances so we never touch the chain.
local isInRestrictedInstance = false
local wasInRestrictedInstance = false

local instanceTypeLabels = {
    party = "Dungeon",
    raid = "Raid",
    scenario = "Scenario",
    pvp = "Battleground",
    arena = "Arena",
}

local function UpdateRestrictedState()
    local inInstance, instanceType = IsInInstance()
    local wasRestricted = isInRestrictedInstance

    if not inInstance then
        isInRestrictedInstance = false
    else
        isInRestrictedInstance = (instanceType == "party" or instanceType == "raid" or instanceType == "scenario")
    end

    -- Notify the player when restriction state changes
    if isInRestrictedInstance and not wasRestricted then
        local label = instanceTypeLabels[instanceType] or instanceType or "Instance"
        print("|cff00ccffEpicTip|r |cffaaaaaa-|r Tooltip enhancements paused |cffffffff(" .. label .. ")|r |cffaaaaaa- Blizzard Midnight API restrictions|r")
    elseif wasRestricted and not isInRestrictedInstance then
        print("|cff00ccffEpicTip|r |cffaaaaaa-|r Tooltip enhancements |cff00ff00resumed|r")
    end
end

local function IsRestrictedInstanceForHealthBarVisibility()
    return isInRestrictedInstance
end

local function ApplyRestrictedInstanceCosmetics(tooltip)
    if not tooltip then return end
    if not EpicTipDB or not EpicTipDB.enabled then return end

    -- Always apply background/border styling in instances to prevent the translucent
    -- tooltip bug — this is safe and does not touch any unit data or taint-prone APIs.
    pcall(function()
        if ET.TooltipStyling then
            ET.TooltipStyling:ApplyAdvancedStyling(tooltip, nil)
        end
    end)

    -- Scale, width wrapping, and fonts are opt-in via allowRestrictedCosmetics
    if not EpicTipDB.allowRestrictedCosmetics then return end

    local scale = EpicTipDB.scale or 1.0
    pcall(function()
        tooltip:SetScale(scale)
        if ET.Tooltip and ET.Tooltip.ApplyMaxWidthAndWrap then ET.Tooltip:ApplyMaxWidthAndWrap(tooltip) end
        if ET.FontManager and ET.FontManager.ApplyFonts then
            ET.FontManager:ApplyFonts(tooltip)
        end
    end)
end

local function GetRestrictedTooltipUnitToken()
    if UnitExists("mouseover") then
        return "mouseover"
    elseif UnitExists("target") then
        return "target"
    elseif UnitExists("focus") then
        return "focus"
    end
    return nil
end

-- Restricted-instance safe unit enhancements:
-- - No tooltip:GetUnit() inside TooltipDataProcessor callbacks (causes taint)
-- - GetUnit() IS safe inside C_Timer.After callbacks (different execution context)
-- - No health math / UnitHealth* (may be secret values)
-- - No auras / UnitAura (can be restricted/taint-prone in some contexts)
-- This is intended to keep all cosmetic info (class/reaction/faction colors, guild rank,
-- target, M+ rating, text filtering) working inside instances.
local function ApplyRestrictedInstanceUnitEnhancements(tooltip)
    if not tooltip then return end
    if not EpicTipDB or not EpicTipDB.enabled then return end

    -- SafeGetUnit is safe here because this function is only ever called from
    -- C_Timer.After callbacks, never from inside TooltipDataProcessor.
    local unit = SafeGetUnit(tooltip)
    if not unit or not UnitExists(unit) then
        -- Fallback to unit tokens if GetUnit() didn't work
        unit = GetRestrictedTooltipUnitToken()
    end
    if not unit or not UnitExists(unit) then return end

    pcall(function()
        if Tooltip and Tooltip.InsertCustomInfo then
            Tooltip.InsertCustomInfo(tooltip, unit)
        end
    end)

    pcall(function()
        if ET.TextFiltering and ET.TextFiltering.FilterTooltipLines then
            ET.TextFiltering.FilterTooltipLines(tooltip)
        end
    end)

    pcall(function()
        if ET.TextFiltering and ET.TextFiltering.ApplyTooltipColoring then
            ET.TextFiltering.ApplyTooltipColoring(tooltip, unit)
        end
    end)

    -- Force tooltip to auto-fit after lines were added
    pcall(tooltip.SetHeight, tooltip, 0)
    pcall(tooltip.Show, tooltip)
end

-- In restricted instances (Patch 12.0.0+), EpicTip avoids all unit tooltip processing to prevent taint.
-- Health bar hiding can still be applied safely without touching tooltip:GetUnit() by using non-secret unit tokens.
local function ApplyRestrictedInstanceHealthBarVisibility()
    if not EpicTipDB or not EpicTipDB.enabled then return end
    if not (EpicTipDB.hideHealthBar or EpicTipDB.hideNPCHealthBar) then return end
    if not GameTooltipStatusBar then return end

    local unit = nil
    if UnitExists("mouseover") then
        unit = "mouseover"
    elseif UnitExists("target") then
        unit = "target"
    elseif UnitExists("focus") then
        unit = "focus"
    end

    local shouldHide = false
    if unit then
        if UnitIsPlayer(unit) and EpicTipDB.hideHealthBar then
            shouldHide = true
        elseif (not UnitIsPlayer(unit)) and EpicTipDB.hideNPCHealthBar then
            shouldHide = true
        end
    else
        -- If we can't reliably determine which unit the tooltip is showing, only hide when both toggles are enabled.
        shouldHide = EpicTipDB.hideHealthBar and EpicTipDB.hideNPCHealthBar
    end

    if shouldHide then
        pcall(GameTooltipStatusBar.Hide, GameTooltipStatusBar)
    end
end

-- Expose for other modules if needed
function Tooltip.IsInRestrictedInstance()
    return isInRestrictedInstance
end

-- Clear cached player data
function Tooltip.ClearCache()
    Tooltip.specName = ""
    Tooltip.cachedIlvl = "?"
    Tooltip.cachedRole = ""
end

-- Update player specialization and item level
function Tooltip.UpdateSpecAndIlvl(unit)
    local guid = UnitGUID(unit)
    if not guid then return end

    if Tooltip.inspectedGUID and Tooltip.inspectedGUID ~= guid then
        Tooltip.ClearCache()
    end

    local Utils = GetUtils()
    if not Utils or not Utils:CanInspectThrottled(unit) then
        return
    end

    -- Check if unit is in inspection range before calling NotifyInspect
    -- Classic/Era requires proximity check to avoid "too far away" errors
    -- CheckInteractDistance(unit, 1) = ~28 yards (inspect range)
    if not CheckInteractDistance(unit, 1) then
        if EpicTipDB and EpicTipDB.debugMode then
            print("EpicTip: Unit out of inspection range:", UnitName(unit) or "Unknown")
        end
        return
    end

    -- Use enhanced tracking system
    Utils:TrackInspectRequest(guid)
    Tooltip.inspectedGUID = guid
    NotifyInspect(unit)
    -- RequestInspectHonorData is Retail-only and can fail in some contexts
    if EpicTipDB.showPvPRating and RequestInspectHonorData then
        pcall(RequestInspectHonorData)
    end

    if EpicTipDB and EpicTipDB.debugMode then
        print("EpicTip: Inspection requested for", UnitName(unit) or "Unknown")
    end
end

-- Format numbers using Blizzard's native API (more memory efficient)
-- Patch 12.0.0+: num may be a secret value in instances/combat.
-- Arithmetic on secrets throws errors, so guard everything with pcall.
function Tooltip.FormatNumber(num)
    if not num then return "0" end
    if IsSecretValue(num) then return "?" end

    -- pcall the comparison in case num is a secret that slipped through
    local ok, isZero = pcall(function() return num == 0 end)
    if not ok or isZero then return "0" end

    -- Use Blizzard's native number formatting when available
    if BreakUpLargeNumbers then
        local ok2, result = pcall(BreakUpLargeNumbers, num)
        if ok2 and result then return result end
    end

    -- Fallback for older clients (all arithmetic wrapped)
    local ok3, formatted = pcall(function()
        local absNum = math.abs(num)
        local sign = num < 0 and "-" or ""

        if absNum >= 1000000 then
            return string.format("%s%.1fM", sign, absNum / 1000000)
        elseif absNum >= 1000 then
            return string.format("%s%.1fK", sign, absNum / 1000)
        else
            return tostring(num)
        end
    end)

    return (ok3 and formatted) or "?"
end

-- Add custom player information to tooltip
function Tooltip.InsertCustomInfo(tooltip, unit)
    if not unit or not UnitIsPlayer(unit) then return end
    if not EpicTipDB or not EpicTipDB.enabled then return end
    
    -- Prevent duplicate processing for the *same unit*.
    -- GameTooltip can update in-place without hiding, so a simple per-tooltip flag can
    -- get "stuck" and block future units (including after instance transitions).
    local guid = UnitGUID(unit)
    if guid and not IsSecretValue(guid) then
        if ET.TooltipState:Get(tooltip, "processedGuid") == guid then
            return
        end
        ET.TooltipState:Set(tooltip, "processedGuid", guid)
    end

    local className, classFileName = UnitClass(unit)
    
    -- Use Blizzard's native guild API with enhanced validation
    if EpicTipDB.showGuildRank then
        local guildName, guildRankName = GetGuildInfo(unit)
        if guildName and guildRankName and guildName ~= "" and guildRankName ~= "" then
            local guildRankLabel = L["Guild Rank:"] or "Guild Rank:"
            local alreadyAdded = false
            local tooltipName2 = tooltip:GetName() or "GameTooltip"
            for i = 1, tooltip:NumLines() do
                local left = _G[tooltipName2 .. "TextLeft" .. i]
                if left then
                    local ok, text = pcall(left.GetText, left)
                    if ok and text and text:find("Guild Rank") then
                        alreadyAdded = true
                        break
                    end
                end
            end
            if not alreadyAdded then
                tooltip:AddDoubleLine(guildRankLabel, guildRankName, 1, 1, 0, 0.8, 0.8, 0.8)
            end
        end
    end
    
    -- Enhanced coloring using Blizzard's native class color system
    local classColor = classFileName and RAID_CLASS_COLORS[classFileName]
    local r, g, b = 1, 1, 1
    if classColor then
        r, g, b = classColor:GetRGB()
    end
    
    local tooltipName = tooltip:GetName() or "GameTooltip"
    local nameLine = _G[tooltipName .. "TextLeft1"]
    if nameLine then
        local ok, nameText = pcall(nameLine.GetText, nameLine)
        if ok and nameText and not IsSecretValue(nameText) then
            if EpicTipDB.showClassIcon then
                local classIcon = ET.Utils and ET.Utils.GetClassIcon and ET.Utils:GetClassIcon(classFileName) or ""
                if classIcon ~= "" then
                    if not nameText:find("ClassIcon_") and not nameText:find("Interface\\Icons\\ClassIcon_") then
                        nameLine:SetText(classIcon .. " " .. nameText)
                    end
                end
            end
            nameLine:SetTextColor(r, g, b)
        end
    end

    -- Process existing tooltip lines for coloring
    local numLines = tooltip:NumLines()
    for lineIndex = 1, numLines do
        local left = _G[tooltipName .. "TextLeft" .. lineIndex]
        if left then
            local ok, text = pcall(left.GetText, left)
            if ok and text and not IsSecretValue(text) then
                if lineIndex == 2 and not text:find("Level") and not text:find("Alliance") and not text:find("Horde") and text ~= className then
                    left:SetText("<" .. text .. ">")
                    left:SetTextColor(0.25, 1, 0.25)
                elseif text:find("Level") or text:find("%(Player%)") then
                    -- Use Blizzard's native text processing when available
                    if strtrim then
                        text = strtrim(text:gsub("%s*%(Player%)", ""))
                        text = strtrim(text:gsub("%s*%(Item Level %d+%)", ""))
                        text = strtrim(text:gsub("%s*Item Level: %d+", ""))
                    else
                        text = text:gsub("%s*%(Player%)", "")
                        text = text:gsub("%s*%(Item Level %d+%)", "")
                        text = text:gsub("%s*Item Level: %d+", "")
                    end
                    left:SetText(text)
                elseif text == className or (className and text:find(className)) then
                    left:SetTextColor(r, g, b)
                elseif text == "Alliance" then
                    left:SetTextColor(0, 0.5, 1)
                elseif text == "Horde" then
                    left:SetTextColor(1, 0, 0)
                end
            end
        end
    end
    
    -- Add target information using Blizzard's native unit token system
    if EpicTipDB.showTarget then
        local targetUnit = unit .. "target"
        if UnitExists(targetUnit) then
            local targetName = UnitName(targetUnit)
            if targetName and targetName ~= "" and targetName ~= UNKNOWN then
                -- Check if target info already exists
                local targetExists = false
                for i = 1, tooltip:NumLines() do
                    local leftLine = _G[tooltip:GetName() .. "TextLeft" .. i]
                    if leftLine then
                        local ok, text = pcall(leftLine.GetText, leftLine)
                        if ok and text and not IsSecretValue(text) and text:find("Target:") then
                            targetExists = true
                            break
                        end
                    end
                end
                
                if not targetExists then
                    tooltip:AddDoubleLine(L["Target:"] or "Target:", targetName, 1, 1, 0, 1, 0, 0)
                end
            end
        end
    end
    
    -- Add module information (Mythic+, PvP, Mount info) with error protection
    if ET.MythicPlusInfo and ET.MythicPlusInfo.AddToTooltip then
        local success, err = pcall(ET.MythicPlusInfo.AddToTooltip, tooltip, unit)
        if not success and EpicTipDB.debugMode then
            print("EpicTip: Error in MythicPlusInfo:", err)
        end
    end
    
    if ET.PvPInfo and ET.PvPInfo.AddToTooltip then
        local success, err = pcall(ET.PvPInfo.AddToTooltip, tooltip, unit)
        if not success and EpicTipDB.debugMode then
            print("EpicTip: Error in PvPInfo:", err)
        end
    end
    
    if ET.MountInfo and ET.MountInfo.AddToTooltip then
        local success, err = pcall(ET.MountInfo.AddToTooltip, tooltip, unit)
        if not success and EpicTipDB.debugMode then
            print("EpicTip: Error in MountInfo:", err)
        end
    end

    -- Add UnitAuras info (buffs/debuffs, targeting, status, raid icons)
    if ET.UnitAuras and ET.UnitAuras.ProcessUnitTooltip then
        local success, err = pcall(ET.UnitAuras.ProcessUnitTooltip, tooltip, unit)
        if not success and EpicTipDB.debugMode then
            print("EpicTip: Error in UnitAuras:", err)
        end
    end
    
    -- Add role information
    if EpicTipDB.showRoleIcon and Tooltip.cachedRole and Tooltip.cachedRole ~= "" then
        local Utils = GetUtils()
        local roleIcon = Utils and Utils.GetRoleIcon and Utils:GetRoleIcon(Tooltip.cachedRole) or ""
        local roleText = Tooltip.cachedRole
        if roleIcon ~= "" then
            roleText = roleIcon .. " " .. roleText
        end
        tooltip:AddDoubleLine(L["Role:"] or "Role:", roleText, 1, 1, 0, 1, 1, 1)
    end
    
    -- Add specialization information
    if EpicTipDB.showSpec and Tooltip.specName and Tooltip.specName ~= "" then
        tooltip:AddDoubleLine(L["Specialization:"] or "Specialization:", Tooltip.specName, 1, 1, 0, 1, 1, 1)
    end
    
    -- Add item level information
    if EpicTipDB.showIlvl and Tooltip.cachedIlvl and Tooltip.cachedIlvl ~= "?" and Tooltip.cachedIlvl ~= "" then
        tooltip:AddDoubleLine(L["Item Level:"] or "Item Level:", Tooltip.cachedIlvl, 1, 1, 0, 1, 1, 1)
    end
end

-- Hide health bars based on settings.
-- This code only runs outside restricted instances (all callers are gated by
-- isInRestrictedInstance). Inside instances all tooltip processing is skipped,
-- so GameTooltipStatusBar is never touched in a context where taint matters.
function Tooltip.ProcessHealthBarVisibility(tooltip, unit)
    if not tooltip or not unit or not UnitExists(unit) then return end
    if not EpicTipDB or not EpicTipDB.enabled then return end
    if not GameTooltipStatusBar then return end

    local shouldHide = false
    if UnitIsPlayer(unit) and EpicTipDB.hideHealthBar then
        shouldHide = true
    elseif not UnitIsPlayer(unit) and EpicTipDB.hideNPCHealthBar then
        shouldHide = true
    end

    if shouldHide then
        GameTooltipStatusBar:Hide()
    end
    -- When not hiding, Blizzard's own code already shows the bar during
    -- the secure processing chain (before our deferred callback runs).
end








-- Process player unit
function Tooltip:ApplyMaxWidthAndWrap(tooltip)
    if not tooltip or not EpicTipDB then return end

    -- Never constrain WQ tooltip width — Blizzard's reward item layout needs
    -- its natural width and breaks (item icon overlaps text) if we cap it.
    if IsWorldQuestTooltip(tooltip) then return end

    local maxW = EpicTipDB.maxTooltipWidth
    if maxW and maxW > 0 and tooltip.GetScale and tooltip.GetWidth then
        -- Secret Values (12.0.0+): guard scale and width before any arithmetic.
        local okScale, scale = pcall(tooltip.GetScale, tooltip)
        if okScale and type(scale) == "number" and scale ~= 0 and not IsSecretValue(scale) then
            local targetWidth = maxW / scale

            local okWidth, currentWidth = pcall(tooltip.GetWidth, tooltip)
            if okWidth and type(currentWidth) == "number" and not IsSecretValue(currentWidth) then
                if currentWidth > targetWidth then
                    pcall(tooltip.SetWidth, tooltip, targetWidth)
                end
            end
        end
    end

    local name = tooltip:GetName()
    if name then
        local i = 1
        while i <= 30 do
            local left = _G[name .. "TextLeft" .. i]
            if left then
                if left.SetWordWrap then left:SetWordWrap(true) end
                if left.SetNonSpaceWrap then left:SetNonSpaceWrap(true) end
                left:SetJustifyH("LEFT")
            end
            local right = _G[name .. "TextRight" .. i]
            if right then
                if right.SetWordWrap then right:SetWordWrap(true) end
                if right.SetNonSpaceWrap then right:SetNonSpaceWrap(true) end
            end
            i = i + 1
        end
    end
end

-- Process player unit
function Tooltip.ProcessPlayerUnit(tooltip, unit)
    local guid = UnitGUID(unit)
    if guid and Tooltip.inspectedGUID ~= guid then
        Tooltip.ClearCache()
    end
    
    if UnitInParty(unit) or UnitInRaid(unit) then
        local Utils = GetUtils()
        if Utils then
            Tooltip.cachedRole = Utils.GetRole and Utils:GetRole(unit) or ""
        end
    elseif UnitIsUnit(unit, "player") then
        -- For self-tooltips, get role, spec, and item level info directly without inspection
        local Utils = GetUtils()
        if Utils then
            Tooltip.cachedRole = Utils.GetRole and Utils:GetRole(unit) or ""
            Tooltip.specName = Utils.GetSpec and Utils:GetSpec(unit) or ""
        end
        
        -- Get own item level — GetAverageItemLevel() is always available for self
        local ilvl = nil
        if GetAverageItemLevel then
            local ok, equipped, _ = pcall(GetAverageItemLevel)
            if ok and equipped and equipped > 0 then
                ilvl = math.floor(equipped + 0.5)
            end
        end
        if not ilvl and C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel then
            local ok, val = pcall(C_PaperDollInfo.GetInspectItemLevel, "player")
            if ok and val and val > 0 then ilvl = math.floor(val + 0.5) end
        end
        Tooltip.cachedIlvl = ilvl or "?"
        
        -- Set inspected GUID for self to allow modules to work properly
        Tooltip.inspectedGUID = UnitGUID("player")
    else
        if not InCombatLockdown() then
            Tooltip.UpdateSpecAndIlvl(unit)
        end
    end
    
    Tooltip.InsertCustomInfo(tooltip, unit)

    Tooltip.ProcessHealthBarVisibility(tooltip, unit)
end

-- Main tooltip processing function
function Tooltip.ProcessUnitTooltip(tooltip, unit)
    if not tooltip or not unit or not UnitExists(unit) then return end
    if not EpicTipDB or not EpicTipDB.enabled then return end
    
    -- Skip World Quest tooltips to prevent interference
    if IsWorldQuestTooltip(tooltip) then return end

    -- Reset per-tooltip state when the unit changes (prevents duplicate lines without causing self-tooltip flicker)
    local okGuid, guid = pcall(UnitGUID, unit)
    if okGuid and guid and not IsSecretValue(guid) then
        local lastGuid = ET.TooltipState:Get(tooltip, "unitGuid")
        if lastGuid ~= guid then
            ET.TooltipState:Clear(tooltip)
            ET.TooltipState:Set(tooltip, "unitGuid", guid)
        end
    end

    -- Throttle duplicate re-processing bursts (common on self-tooltips and rapid refreshes)
    local okTime, now = pcall(GetTime)
    if okTime and type(now) == "number" and okGuid and guid and not IsSecretValue(guid) then
        local lastTime = ET.TooltipState:Get(tooltip, "lastProcessedTime")
        local lastGuid = ET.TooltipState:Get(tooltip, "unitGuid")
        if lastGuid == guid and type(lastTime) == "number" and (now - lastTime) < 0.05 then
            -- Still resize the tooltip in case other addons (e.g. Raider.IO) appended
            -- lines after our synchronous TooltipDataProcessor pass ran.
            pcall(tooltip.SetHeight, tooltip, 0)
            pcall(tooltip.Show, tooltip)
            return
        end
        ET.TooltipState:Set(tooltip, "lastProcessedTime", now)
    end
    
    -- Combat check is handled in OnShow before any processing runs
    if EpicTipDB.hideInCombat and InCombatLockdown() then return end
    
    -- Wrap entire function in pcall for safety
    local success, err = pcall(function()
        -- Apply basic styling to all units
        local scale = EpicTipDB.scale or 1.0
        tooltip:SetScale(scale)
        if ET.Tooltip and ET.Tooltip.ApplyMaxWidthAndWrap then ET.Tooltip:ApplyMaxWidthAndWrap(tooltip) end
        
        -- Process player-specific information
        if UnitIsPlayer(unit) then
            Tooltip.ProcessPlayerUnit(tooltip, unit)
        else
            Tooltip.ProcessHealthBarVisibility(tooltip, unit)
        end
        
        -- Apply styling and fonts
        if ET.TooltipStyling then
            ET.TooltipStyling:ApplyAdvancedStyling(tooltip, unit)
        end
        
         -- Apply fonts using FontManager
         if ET.FontManager and ET.FontManager.ApplyFonts then
             ET.FontManager:ApplyFonts(tooltip)
         end

         -- TAINT-SAFE: Filter/hide unwanted Blizzard lines post-population (no method overrides)
         if ET.TextFiltering and ET.TextFiltering.FilterTooltipLines then
             ET.TextFiltering.FilterTooltipLines(tooltip)
         end

         -- Apply optional text coloring (reaction/class colors) after all other updates
         if ET.TextFiltering and ET.TextFiltering.ApplyTooltipColoring then
             ET.TextFiltering.ApplyTooltipColoring(tooltip, unit)
         end

         -- Force the tooltip to recalculate its dimensions after we added lines.
         -- Since our processing is deferred (C_Timer.After), the tooltip was already
         -- sized before our content was added. SetHeight(0) resets the height constraint
         -- so Show() triggers a full auto-fit re-layout.
         pcall(tooltip.SetHeight, tooltip, 0)
         tooltip:Show()
     end)

     if not success then
         if EpicTipDB.debugMode then
             print("EpicTip: Error in ProcessUnitTooltip:", err)
        end
        -- Still try to apply basic styling even if main processing fails
        local scale = EpicTipDB.scale or 1.0
        tooltip:SetScale(scale)
        if ET.Tooltip and ET.Tooltip.ApplyMaxWidthAndWrap then ET.Tooltip:ApplyMaxWidthAndWrap(tooltip) end
    end
end

-- Simple tooltip processor setup - CORE FUNCTION 1: Hook tooltip events
--
-- CRITICAL: All tooltip modifications (AddLine, SetText, SetTextColor, SetScale, etc.)
-- MUST be deferred out of Blizzard's secure tooltip processing chain using C_Timer.After(0).
-- If we modify the tooltip inside TooltipDataProcessor callbacks or OnShow hooks that fire
-- during the secure chain, we taint the tooltip frame. Blizzard's own SetWatch() on the
-- health bar then fails with "Lua Taint: EpicTip" because it's running in a tainted context.
-- Deferring to the next frame ensures our modifications happen AFTER the secure chain completes.
--
function Tooltip.SetupUnifiedTooltipProcessor()
    if not TooltipDataProcessor or not TooltipDataProcessor.AddTooltipPostCall or not Enum.TooltipDataType then
        print("|cffff0000EpicTip:|r TooltipDataProcessor not available - falling back to backup hooks")
        if ET.SetupBackupTooltipHooks then
            ET:SetupBackupTooltipHooks()
        end
        return
    end
    print("|cff00ff00EpicTip:|r SetupUnifiedTooltipProcessor running OK")

    -- Deferred processing helper: schedules tooltip work for next frame
    -- to avoid tainting Blizzard's secure tooltip processing chain
    local function DeferTooltipWork(tooltip, workFunc)
        if not C_Timer or not C_Timer.After then
            local ok, err = pcall(workFunc)
            if not ok and EpicTipDB and EpicTipDB.debugMode then
                print("|cffff0000EpicTip Error:|r " .. tostring(err))
            end
            return
        end
        C_Timer.After(0, function()
            if not tooltip then return end
            local ok, err = pcall(workFunc)
            if not ok and EpicTipDB and EpicTipDB.debugMode then
                print("|cffff0000EpicTip Error:|r " .. tostring(err))
            end
        end)
    end

    -- Unit Tooltip Processor
    -- TAINT-SAFE: In restricted instances (dungeons/raids/scenarios), bail out immediately.
    -- Calling tooltip:GetUnit() inside a TooltipDataProcessor callback taints the entire
    -- processing chain. Blizzard's SetWatch() then fails with "Lua Taint: EpicTip".
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        if isInRestrictedInstance then return end
        if not tooltip or not tooltip.GetUnit then return end
        if not EpicTipDB or not EpicTipDB.enabled then return end
        
        -- Skip World Quest tooltips to prevent interference
        if IsWorldQuestTooltip(tooltip) then return end

        local unit = SafeGetUnit(tooltip)
        if not unit or not UnitExists(unit) then return end

        pcall(Tooltip.ProcessUnitTooltip, tooltip, unit)
    end)

    -- Quest Tooltip Processor — set a flag so Item processor knows to leave this tooltip alone.
    -- WQ reward items fire BOTH a Quest and an Item post-call on the same GameTooltip frame.
    -- Tracking the Quest call lets us reliably skip EpicTip styling without any frame-name guessing.
    local questTooltipFrames = {}  -- tostring(tooltip) -> expiry time
    if Enum.TooltipDataType.Quest then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Quest, function(tooltip)
            if not tooltip then return end
            questTooltipFrames[tostring(tooltip)] = GetTime() + 2
            -- Restore NineSlice since we suppressed it in OnShow before knowing this was a quest tooltip
            if tooltip.NineSlice then
                pcall(function()
                    tooltip.NineSlice:SetAlpha(1)
                    tooltip.NineSlice:Show()
                end)
            end
            -- Hide our custom background frames if they were already applied
            if ET.TooltipStyling and ET.TooltipStyling.CleanupTooltipStyling then
                ET.TooltipStyling:CleanupTooltipStyling(tooltip)
            end
        end)
    end

    local function IsQuestFlaggedTooltip(tooltip)
        local expiry = questTooltipFrames[tostring(tooltip)]
        return expiry and GetTime() < expiry
    end

    -- Item Tooltip Processor
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
        if not EpicTipDB or not EpicTipDB.enabled then return end

        -- Skip entirely if this tooltip was recently used to show quest/WQ content,
        -- or if the world map is open (WQ/quest pins use GameTooltip on the map).
        local wqSkip = IsWorldQuestTooltip(tooltip) or IsQuestFlaggedTooltip(tooltip)
        local mapSkip = _G.WorldMapFrame and _G.WorldMapFrame:IsShown()
        if EpicTipDB.debugMode then
            print("|cff00ff00EpicTip:|r Item processor. tooltip=" .. tostring(tooltip and tooltip:GetName()) .. " wqSkip=" .. tostring(wqSkip) .. " mapSkip=" .. tostring(mapSkip) .. " isRestricted=" .. tostring(isInRestrictedInstance))
        end
        if wqSkip or mapSkip then return end

        -- In restricted instances apply background-only styling (safe, no unit data touched)
        if isInRestrictedInstance then
            DeferTooltipWork(tooltip, function()
                if ET.TooltipStyling then
                    ET.TooltipStyling:ApplyAdvancedStyling(tooltip, nil)
                end
            end)
            return
        end

        -- Apply background styling to ALL item tooltips, including comparison tooltips.
        -- Suppressing NineSlice without applying our own background leaves them transparent.
        DeferTooltipWork(tooltip, function()
            if ET.TooltipStyling then
                ET.TooltipStyling:ApplyAdvancedStyling(tooltip, nil)
            end
        end)

        -- Only continue with full EpicTip processing for primary tooltips.
        if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then
            return
        end

        -- Apply background/scale/fonts immediately (no unit data, no taint risk).
        -- This eliminates the 1-frame flicker on AH item hovers where the tooltip
        -- briefly appears unstyled before DeferTooltipWork fires.
        local scale = EpicTipDB.scale or 1.0
        pcall(function()
            tooltip:SetScale(scale)
            if ET.Tooltip and ET.Tooltip.ApplyMaxWidthAndWrap then ET.Tooltip:ApplyMaxWidthAndWrap(tooltip) end
            if ET.TooltipStyling then
                ET.TooltipStyling:ApplyAdvancedStyling(tooltip, nil)
            end
            if ET.FontManager and ET.FontManager.ApplyFonts then
                ET.FontManager:ApplyFonts(tooltip)
            end
        end)

        -- Add enrichment lines synchronously (same frame as tooltip build)
        -- Deferred approach caused lines to be discarded when tooltip moved to next item
        pcall(function()
            if EpicTipDB.debugMode then
                print("|cff00ff00EpicTip:|r Item enrichment firing. showItemInfo=" .. tostring(EpicTipDB.showItemInfo) .. " showStatValues=" .. tostring(EpicTipDB.showStatValues))
            end
            if tooltip == GameTooltip or tooltip == ItemRefTooltip then
                if EpicTipDB.showItemInfo and ET.ItemInfo and ET.ItemInfo.ProcessItemTooltip then
                    ET.ItemInfo:ProcessItemTooltip(tooltip)
                end
                if EpicTipDB.showStatValues and ET.ItemInfo and ET.ItemInfo.ShowUpgradeScore then
                    local ok, _, link = pcall(tooltip.GetItem, tooltip)
                    local itemEquipLoc = ok and link and select(9, GetItemInfo(GetItemInfoFromHyperlink(link) or 0))
                    if itemEquipLoc and itemEquipLoc ~= "" then
                        ET.ItemInfo:ShowUpgradeScore(tooltip, link, itemEquipLoc)
                    end
                end
                if EpicTipDB.showStatValues and ET.StatValues and ET.StatValues.ProcessStatTooltip then
                    ET.StatValues:ProcessStatTooltip(tooltip)
                end
            end
        end)
    end)

    -- Spell Tooltip Processor
    -- TAINT-SAFE: Skip in restricted instances to prevent taint propagation
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip)
        if isInRestrictedInstance then return end
        if not EpicTipDB or not EpicTipDB.enabled then return end
        
        -- Skip World Quest tooltips to prevent interference
        if IsWorldQuestTooltip(tooltip) then return end

        DeferTooltipWork(tooltip, function()
            if ET.Tooltip and ET.Tooltip.ApplyMaxWidthAndWrap then ET.Tooltip:ApplyMaxWidthAndWrap(tooltip) end
            if not EpicTipDB.showStatValues or tooltip ~= GameTooltip then return end

            -- Process StatValues for spells
            if ET.StatValues and ET.StatValues.ProcessStatTooltip then
                ET.StatValues:ProcessStatTooltip(tooltip)
            end
        end)
    end)
end

-- Event handlers for inspect data
function Tooltip.OnInspectReady(guid)
    if guid == Tooltip.inspectedGUID then
        local unit = "mouseover"
        if not UnitExists(unit) or UnitGUID(unit) ~= guid then
            for _, unitId in ipairs({"target", "focus", "player"}) do
                if UnitExists(unitId) and UnitGUID(unitId) == guid then
                    unit = unitId
                    break
                end
            end
        end
        
        local Utils = GetUtils()
        if Utils then
            Tooltip.specName = Utils:GetSpec(unit)
            Tooltip.cachedRole = Utils:GetRole(unit)
        end
        
        -- Get inspected player's item level
        local ilvl = nil
        if C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel then
            local ok, val = pcall(C_PaperDollInfo.GetInspectItemLevel, unit)
            if ok and val and val > 0 then ilvl = math.floor(val + 0.5) end
        end
        -- Fallback: sum equipped slot item levels manually
        if not ilvl then
            local total, count = 0, 0
            for slot = 1, 17 do
                if slot ~= 4 then -- skip shirt
                    local slotLink = GetInventoryItemLink(unit, slot)
                    if slotLink then
                        local ok, slotIlvl = pcall(C_Item.GetDetailedItemLevelInfo, slotLink)
                        if ok and slotIlvl and slotIlvl > 0 then
                            total = total + slotIlvl
                            count = count + 1
                        end
                    end
                end
            end
            if count > 0 then ilvl = math.floor(total / count + 0.5) end
        end
        Tooltip.cachedIlvl = ilvl or "?"

        if GameTooltip:IsShown() and UnitExists(unit) then
            local currentUnit = SafeGetUnit(GameTooltip)
            if currentUnit == unit then
                GameTooltip:SetUnit(unit)
            end
        end
    end
end

function Tooltip.OnInspectHonorUpdate()
    if GameTooltip:IsShown() then
        local unit = SafeGetUnit(GameTooltip)
        if unit and UnitExists(unit) then
            pcall(GameTooltip.SetUnit, GameTooltip, unit)
        end
    end
end

function Tooltip.OnTargetChanged()
    Tooltip.specName = ""
    Tooltip.cachedIlvl = "?"
    Tooltip.cachedRole = ""
end







-- Apply unified styling to tooltip (CRITICAL FUNCTION - called from Events.lua)
function Tooltip.ApplyUnifiedStyling(tooltip, unit)
    if not tooltip then return end
    
    -- Apply styling and fonts
    if ET.TooltipStyling then
        ET.TooltipStyling:ApplyAdvancedStyling(tooltip, unit)
    end
    
    -- Apply fonts using FontManager
    if ET.FontManager and ET.FontManager.ApplyFonts then
        ET.FontManager:ApplyFonts(tooltip)
    end
    
    -- Apply anchoring if needed
    if ET.TooltipAnchoring then
        ET.TooltipAnchoring:HandleTooltipAnchoring(tooltip)
    end
end

-- Patch 12.0.1: New tooltip line type enum mappings
-- These are used by C_TooltipInfo for data line processing
Tooltip.LineTypeEnums = {
    -- New in 12.0.1 - replaces all Restricted* types
    UsageRequirement = "UsageRequirement",
    -- New line types
    ItemSpellTriggerLearn = "ItemSpellTriggerLearn",
    LearnTransmogSet = "LearnTransmogSet",
    LearnTransmogIllusion = "LearnTransmogIllusion",
    TradeTimeRemaining = "TradeTimeRemaining",
    ItemQuality = "ItemQuality",  -- Colorblind mode quality name
    ErrorLine = "ErrorLine",      -- Red text lines (FF2020)
    DisabledLine = "DisabledLine", -- Gray text lines (808080)
}

-- Patch 12.0.1: UsageRequirement type mappings
Tooltip.UsageRequirementTypes = {
    -- Converted from old Restricted* types
    RaceClass = 1,      -- RACE_CLASS_ONLY, ITEM_RACES_ALLOWED, ITEM_CLASSES_ALLOWED
    Faction = 2,        -- ITEM_REQ_HORDE, ITEM_REQ_ALLIANCE
    Skill = 3,          -- ITEM_MIN_SKILL, ITEM_REQ_SKILL
    PvPMedal = 4,       -- ITEM_REQ_SKILL (with medal arg)
    Reputation = 5,     -- ITEM_REQ_REPUTATION (with factionID, reactionLevel)
    Level = 6,          -- ITEM_MIN_LEVEL, ITEM_LEVEL_RANGE_CURRENT (with level, maxLevel)
    NotInArena = 7,     -- ARENA_NOT_USABLE (was RestrictedArena)
    NotInRatedBg = 8,   -- RATEDBG_NOT_USABLE (was RestrictedBg)
    NotAlreadyKnown = 9, -- ITEM_SPELL_KNOWN, ERR_COSMETIC_KNOWN (was RestrictedSpellKnown)
    -- New requirement types
    Guild = 10,         -- ITEM_REQ_PURCHASE_GUILD
    Achievement = 11,   -- ITEM_REQ_PURCHASE_ACHIEVEMENT (with achievementID)
    PvPRank = 12,       -- ITEM_REQ_SKILL (with rank)
    EquippedItem = 13,  -- SPELL_EQUIPPED_ITEM_NOSPACE, SPELL_EQUIPPED_ITEM
    ShapeshiftForm = 14, -- SPELL_REQUIRED_FORM_NOSPACE, SPELL_REQUIRED_FORM
    ArenaRating = 15,   -- ITEM_REQ_ARENA_RATING_* (with bracket, rating)
    EarnCurrency = 16,  -- ITEM_REQ_AMOUNT_EARNED (with currencyID, amount)
    Specialization = 17, -- ITEM_REQ_SPECIALIZATION (with specID)
}

-- Helper function to check if new line types are available
function Tooltip.HasNewLineTypes()
    return ET.APICompatibility and ET.APICompatibility:DetectFeature("TooltipLineTypes")
end

-- Initialize tooltip system
function Tooltip.Initialize()
    if not EpicTipDB then
        return
    end

    Tooltip.inspectedGUID = nil
    Tooltip.specName = ""
    Tooltip.cachedIlvl = "?"
    Tooltip.cachedRole = ""

    -- TAINT-SAFE: Initialize restricted instance detection and register zone change events
    -- so isInRestrictedInstance is always current when tooltip callbacks fire.
    UpdateRestrictedState()
    if not Tooltip.restrictedStateFrame then
        Tooltip.restrictedStateFrame = CreateFrame("Frame")
        Tooltip.restrictedStateFrame:SetScript("OnEvent", function()
            UpdateRestrictedState()
        end)
        Tooltip.restrictedStateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        Tooltip.restrictedStateFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
        Tooltip.restrictedStateFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        Tooltip.restrictedStateFrame:RegisterEvent("ZONE_CHANGED")
        Tooltip.restrictedStateFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
        Tooltip.restrictedStateFrame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
    end

    -- Initialize text filtering system
    if ET.TextFiltering and ET.TextFiltering.Initialize then
        ET.TextFiltering.Initialize()
    end
    
    -- Migrate legacy anchorToMouse setting to new anchoring system
    if EpicTipDB.anchorToMouse and EpicTipDB.anchoring == "default" then
        EpicTipDB.anchoring = "mouse"
        EpicTipDB.anchorToMouse = false
    end
    
    -- Setup anchor hook system for tooltip positioning using TooltipAnchoring module
    if ET.TooltipAnchoring then
        ET.TooltipAnchoring:SetupAnchorHook()
    end
    
     -- Setup tooltip cleanup on hide using TooltipStyling module
     if GameTooltip then
         -- TAINT-SAFE: In restricted instances, Blizzard may re-show the status bar after our tooltip hooks run.
         -- Hook the status bar's OnShow so we can immediately re-hide it if the user has enabled the option.
         if not Tooltip.statusBarHooksInstalled and GameTooltipStatusBar and GameTooltipStatusBar.HookScript then
             Tooltip.statusBarHooksInstalled = true
             pcall(GameTooltipStatusBar.HookScript, GameTooltipStatusBar, "OnShow", function()
                 if not EpicTipDB or not EpicTipDB.enabled then return end
                 -- Handle restricted instances via safe unit tokens
                 if IsRestrictedInstanceForHealthBarVisibility() then
                     pcall(ApplyRestrictedInstanceHealthBarVisibility)
                     return
                 end
                 -- Handle open world: re-hide immediately if the setting is on
                 -- This catches the flash where Blizzard re-shows the bar after our hook ran
                 local unit = UnitExists("mouseover") and "mouseover" or (UnitExists("target") and "target" or nil)
                 if not unit then return end
                 local shouldHide = (UnitIsPlayer(unit) and EpicTipDB.hideHealthBar)
                     or (not UnitIsPlayer(unit) and EpicTipDB.hideNPCHealthBar)
                 if shouldHide then
                     GameTooltipStatusBar:Hide()
                 end
             end)
         end

         GameTooltip:HookScript("OnHide", function(self)
             -- TAINT-SAFE: Clear all state via external table, never write to the frame
             ET.TooltipState:Clear(self)
             -- Clear quest flag so next show starts fresh
             if questTooltipFrames then questTooltipFrames[tostring(self)] = nil end

            -- Cleanup UnitAuras flags (also uses ET.TooltipState now)
            if ET.UnitAuras and ET.UnitAuras.CleanupTooltip then
                ET.UnitAuras.CleanupTooltip(self)
            end

            if ET.TooltipStyling then
                ET.TooltipStyling:CleanupTooltipStyling(self)
            end
        end)
        
         -- Hook OnShow as a reliable fallback to apply EpicTip styling.
         -- CRITICAL: Defer to next frame to avoid tainting Blizzard's secure tooltip chain.
         -- TAINT-SAFE: In restricted instances, only apply health bar visibility (no tooltip:GetUnit()).
         GameTooltip:HookScript("OnShow", function(self)
             -- Keep restricted-instance state in sync even if zone events are missed.
             UpdateRestrictedState()

             -- Hide immediately during combat if enabled — covers all tooltip types
             if EpicTipDB and EpicTipDB.enabled and EpicTipDB.hideInCombat and InCombatLockdown() then
                 self:Hide()
                 return
             end
             -- Skip World Quest tooltips to prevent interference
             if IsWorldQuestTooltip(self) then return end
             
             -- Immediately suppress Blizzard's NineSlice backdrop before deferred styling runs,
             -- but ONLY when EpicTip is actually going to draw its own background.
             --
             -- In restricted instances (dungeons/raids/scenarios) with
             -- allowRestrictedCosmetics == false, we leave Blizzard's
             -- NineSlice alone so the default background remains visible.
             local canRestyleBackground = EpicTipDB
                 and EpicTipDB.enabled
                 and (not IsRestrictedInstanceForHealthBarVisibility() or EpicTipDB.allowRestrictedCosmetics)
                 and not (_G.WorldMapFrame and _G.WorldMapFrame:IsShown())

             if canRestyleBackground and self.NineSlice then
                 pcall(function()
                     self.NineSlice:SetAlpha(0)
                     self.NineSlice:Hide()
                 end)
             end
             if IsRestrictedInstanceForHealthBarVisibility() then
                 if C_Timer and C_Timer.After then
                     C_Timer.After(0, function()
                         if not IsRestrictedInstanceForHealthBarVisibility() then return end
                         if not self:IsShown() then return end
                         pcall(ApplyRestrictedInstanceHealthBarVisibility)
                         ApplyRestrictedInstanceCosmetics(self)
                         ApplyRestrictedInstanceUnitEnhancements(self)
                     end)
                 else
                     pcall(ApplyRestrictedInstanceHealthBarVisibility)
                     ApplyRestrictedInstanceCosmetics(self)
                     ApplyRestrictedInstanceUnitEnhancements(self)
                 end
                 return
             end
             if isInRestrictedInstance then return end
             -- Skip all processing when the world map is open — tooltips shown over map pins
             -- (world quests, quests, bonus objectives) should render natively via Blizzard.
             if _G.WorldMapFrame and _G.WorldMapFrame:IsShown() then return end
             if C_Timer and C_Timer.After then
                 C_Timer.After(0, function()
                     if isInRestrictedInstance then return end
                     if _G.WorldMapFrame and _G.WorldMapFrame:IsShown() then return end
                     if not self:IsShown() then return end
                    pcall(function()
                        local isSpellTooltip = TooltipHasSpell(self)
                        local unit = (not isSpellTooltip) and SafeGetUnit(self) or nil

                        if unit and UnitExists(unit) then
                            Tooltip.ProcessUnitTooltip(self, unit)
                            return
                        end

                        if not EpicTipDB or not EpicTipDB.enabled then return end

                        local scale = EpicTipDB.scale or 1.0
                        self:SetScale(scale)
                        if ET.Tooltip and ET.Tooltip.ApplyMaxWidthAndWrap then ET.Tooltip:ApplyMaxWidthAndWrap(self) end
                        if ET.TooltipStyling then
                            ET.TooltipStyling:ApplyAdvancedStyling(self, nil)
                        end
                        if ET.FontManager and ET.FontManager.ApplyFonts then
                            ET.FontManager:ApplyFonts(self)
                        end
                    end)
                end)
            end
        end)

        -- Extra safety: Some builds/contexts do not reliably trigger TooltipDataProcessor post-calls
        -- or the backup OnShow hooks. Hook OnTooltipSet* and defer work to avoid taint.
        if not Tooltip.hooksInstalled then
            Tooltip.hooksInstalled = true

            local function SafeHookScript(frame, scriptName, handler)
                if not frame or not frame.HookScript then return false end
                if frame.HasScript and not frame:HasScript(scriptName) then
                    return false
                end
                local ok = pcall(frame.HookScript, frame, scriptName, handler)
                return ok
            end

             SafeHookScript(GameTooltip, "OnTooltipSetUnit", function(self)
                 -- Skip World Quest tooltips to prevent interference
                 if IsWorldQuestTooltip(self) then return end
                 
                 if IsRestrictedInstanceForHealthBarVisibility() then
                     if not EpicTipDB or not EpicTipDB.enabled then return end
                     if C_Timer and C_Timer.After then
                         C_Timer.After(0, function()
                             if not IsRestrictedInstanceForHealthBarVisibility() then return end
                             if not self:IsShown() then return end
                             pcall(ApplyRestrictedInstanceHealthBarVisibility)
                             ApplyRestrictedInstanceCosmetics(self)
                             ApplyRestrictedInstanceUnitEnhancements(self)
                         end)
                     else
                         pcall(ApplyRestrictedInstanceHealthBarVisibility)
                         ApplyRestrictedInstanceCosmetics(self)
                         ApplyRestrictedInstanceUnitEnhancements(self)
                     end
                     return
                 end
                 if isInRestrictedInstance then return end
                 if not EpicTipDB or not EpicTipDB.enabled then return end
                 if not C_Timer or not C_Timer.After then return end
                 if TooltipHasSpell(self) then return end

                local unit = SafeGetUnit(self)
                if not unit or not UnitExists(unit) then return end

                C_Timer.After(0, function()
                    if isInRestrictedInstance then return end
                    if not self:IsShown() then return end
                    if TooltipHasSpell(self) then return end
                    local currentUnit = SafeGetUnit(self)
                    if currentUnit == unit and UnitExists(unit) then
                        Tooltip.ProcessUnitTooltip(self, unit)
                    end
                end)
            end)

             SafeHookScript(GameTooltip, "OnTooltipSetItem", function(self)
                 -- Skip World Quest tooltips to prevent interference
                 if IsWorldQuestTooltip(self) then return end
                 
                 if IsRestrictedInstanceForHealthBarVisibility() then
                     if not EpicTipDB or not EpicTipDB.enabled then return end
                     if not EpicTipDB.allowRestrictedCosmetics then return end
                     if not C_Timer or not C_Timer.After then
                         ApplyRestrictedInstanceCosmetics(self)
                         return
                     end
                     C_Timer.After(0, function()
                         if not self:IsShown() then return end
                         if not IsRestrictedInstanceForHealthBarVisibility() then return end
                         ApplyRestrictedInstanceCosmetics(self)
                     end)
                     return
                 end
                 if isInRestrictedInstance then return end
                 if not EpicTipDB or not EpicTipDB.enabled then return end
                 if not C_Timer or not C_Timer.After then return end

                 pcall(function()
                    local scale = EpicTipDB.scale or 1.0
                    self:SetScale(scale)
                    if ET.Tooltip and ET.Tooltip.ApplyMaxWidthAndWrap then ET.Tooltip:ApplyMaxWidthAndWrap(self) end
                    if ET.TooltipStyling then ET.TooltipStyling:ApplyAdvancedStyling(self, nil) end
                    if ET.FontManager and ET.FontManager.ApplyFonts then ET.FontManager:ApplyFonts(self) end

                    if self == GameTooltip or self == ItemRefTooltip then
                        if EpicTipDB.showItemInfo and ET.ItemInfo and ET.ItemInfo.ProcessItemTooltip then
                            ET.ItemInfo:ProcessItemTooltip(self)
                        end
                        if EpicTipDB.showStatValues and ET.ItemInfo and ET.ItemInfo.ShowUpgradeScore then
                            local ok, _, link = pcall(self.GetItem, self)
                            local itemEquipLoc = ok and link and select(9, GetItemInfo(GetItemInfoFromHyperlink(link) or 0))
                            if itemEquipLoc and itemEquipLoc ~= "" then
                                ET.ItemInfo:ShowUpgradeScore(self, link, itemEquipLoc)
                            end
                        end
                        if EpicTipDB.showStatValues and ET.StatValues and ET.StatValues.ProcessStatTooltip then
                            ET.StatValues:ProcessStatTooltip(self)
                        end
                    end
                end)
            end)

             SafeHookScript(GameTooltip, "OnTooltipSetSpell", function(self)
                 -- Skip World Quest tooltips to prevent interference
                 if IsWorldQuestTooltip(self) then return end
                 
                 if IsRestrictedInstanceForHealthBarVisibility() then
                     if not EpicTipDB or not EpicTipDB.enabled then return end
                     if not EpicTipDB.allowRestrictedCosmetics then return end
                     if not C_Timer or not C_Timer.After then
                         ApplyRestrictedInstanceCosmetics(self)
                         return
                     end
                     C_Timer.After(0, function()
                         if not self:IsShown() then return end
                         if not IsRestrictedInstanceForHealthBarVisibility() then return end
                         ApplyRestrictedInstanceCosmetics(self)
                     end)
                     return
                 end
                 if isInRestrictedInstance then return end
                 if not EpicTipDB or not EpicTipDB.enabled then return end
                 if not C_Timer or not C_Timer.After then return end

                 C_Timer.After(0, function()
                    if not self:IsShown() then return end
                    if ET.Tooltip and ET.Tooltip.ApplyMaxWidthAndWrap then ET.Tooltip:ApplyMaxWidthAndWrap(self) end
                    if not EpicTipDB.showStatValues then return end
                    if ET.StatValues and ET.StatValues.ProcessStatTooltip then
                        ET.StatValues:ProcessStatTooltip(self)
                    end

                    -- Affix description from StaticData
                    if ET.StaticData and EpicTipDB.showMythicRating then
                        local ok, spellName = pcall(function()
                            local n = select(1, self:GetSpell())
                            return n
                        end)
                        if ok and spellName and type(spellName) == "string" then
                            local data = ET.StaticData.GetMythicPlusData()
                            if data and data.seasonalAffixes and data.seasonalAffixes[spellName] then
                                self:AddLine(" ")
                                self:AddLine("|cFFFFD700Mythic+ Affix|r", 1, 1, 1)
                                self:AddLine(data.seasonalAffixes[spellName], 0.8, 0.8, 0.8, true)
                                pcall(self.SetHeight, self, 0)
                                self:Show()
                            end
                        end
                    end
                end)
            end)
        end
    end

end

local addonName, ET = ...

ET.Tooltip = ET.Tooltip or {}
local Tooltip = ET.Tooltip
local L = ET.L or {}

-- PERFORMANCE-CRITICAL: Cache expensive Blizzard API results
-- These APIs involve network requests and C++↔Lua transitions
-- Caching prevents: 1) Server spam 2) UI freezes 3) Memory churn
Tooltip.inspectedGUID = nil  -- Track which player we've cached
Tooltip.specName = ""        -- Cache spec to avoid repeated API calls  
Tooltip.cachedIlvl = "?"     -- Cache item level (expensive inspect data)
Tooltip.cachedRole = ""      -- Cache role to avoid repeated calculations

local function GetUtils()
    return ET.Utils
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
    
    -- Use enhanced tracking system
    Utils:TrackInspectRequest(guid)
    Tooltip.inspectedGUID = guid
    NotifyInspect(unit)
    if EpicTipDB.showPvPRating and RequestInspectHonorData then
        RequestInspectHonorData()
    end
    
    if EpicTipDB and EpicTipDB.debugMode then
        print("EpicTip: Inspection requested for", UnitName(unit) or "Unknown")
    end
end

-- Format numbers using Blizzard's native API (more memory efficient)
function Tooltip.FormatNumber(num)
    if not num or num == 0 then return "0" end
    
    -- Use Blizzard's native number formatting when available
    if BreakUpLargeNumbers then
        return BreakUpLargeNumbers(num)
    end
    
    -- Fallback for older clients
    local absNum = math.abs(num)
    local sign = num < 0 and "-" or ""
    
    if absNum >= 1000000 then
        return string.format("%s%.1fM", sign, absNum / 1000000)
    elseif absNum >= 1000 then
        return string.format("%s%.1fK", sign, absNum / 1000)
    else
        return tostring(num)
    end
end

-- Add custom player information to tooltip
function Tooltip.InsertCustomInfo(tooltip, unit)
    if not unit or not UnitIsPlayer(unit) then return end
    if not EpicTipDB or not EpicTipDB.enabled then return end
    
    -- Prevent duplicate processing
    if tooltip.epicTipProcessed then
        return
    end
    tooltip.epicTipProcessed = true

    local className, classFileName = UnitClass(unit)
    
    -- Use Blizzard's native guild API with enhanced validation
    if EpicTipDB.showGuildRank then
        local guildName, guildRankName = GetGuildInfo(unit)
        if guildName and guildRankName and guildName ~= "" and guildRankName ~= "" then
            tooltip:AddDoubleLine(L["Guild Rank:"] or "Guild Rank:", guildRankName, 1, 1, 0, 0.8, 0.8, 0.8)
        end
    end
    
    -- Enhanced coloring using Blizzard's native class color system
    local classColor = classFileName and RAID_CLASS_COLORS[classFileName]
    local r, g, b = 1, 1, 1
    if classColor then
        r, g, b = classColor:GetRGB()
    end
    
    local nameLine = _G["GameTooltipTextLeft1"]
    if nameLine then
        local nameText = nameLine:GetText()
        if nameText then
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
        local left = _G["GameTooltipTextLeft" .. lineIndex]
        if left then
            local text = left:GetText()
            if text then
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
                        local text = leftLine:GetText()
                        if text and text:find("Target:") then
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

-- Hide health bars based on settings
function Tooltip.ProcessHealthBarVisibility(tooltip, unit)
    if not tooltip or not unit or not UnitExists(unit) then return end
    if not EpicTipDB or not EpicTipDB.enabled then return end
    
    -- Check if we should hide health bars
    local shouldHide = false
    if UnitIsPlayer(unit) and EpicTipDB.hideHealthBar then
        shouldHide = true
    elseif not UnitIsPlayer(unit) and EpicTipDB.hideNPCHealthBar then
        shouldHide = true
    end
    
    -- Hide or show the GameTooltip status bar
    if GameTooltipStatusBar then
        if shouldHide then
            GameTooltipStatusBar:Hide()
        else
            GameTooltipStatusBar:Show()
        end
    end
end

-- Add health numbers to tooltip
function Tooltip.ProcessHealthNumbers(tooltip, unit)
    if not EpicTipDB.showHealthNumbers then return end
    
    -- Check if health information was already added
    if tooltip.epicTipHealthAdded then
        return
    end
    
    local currentHealth = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    
    if not currentHealth or not maxHealth or maxHealth <= 0 or not UnitExists(unit) then
        return
    end
    
    -- Check if health info already exists in tooltip
    local tooltipName = tooltip:GetName()
    for i = 1, tooltip:NumLines() do
        local leftLine = _G[tooltipName .. "TextLeft" .. i]
        if leftLine then
            local text = leftLine:GetText()
            if text and (text:find("Health:") or text:find("HP")) then
                tooltip.epicTipHealthAdded = true
                return
            end
        end
    end
    
    -- Calculate health with formatting
    local healthText
    if currentHealth == maxHealth then
        healthText = Tooltip.FormatNumber(maxHealth) .. " HP"
    else
        healthText = Tooltip.FormatNumber(currentHealth) .. " / " .. Tooltip.FormatNumber(maxHealth) .. " HP"
    end
    
    -- Calculate health percentage using Blizzard's native calculation
    local healthPct = UnitHealth(unit) / UnitHealthMax(unit)
    local displayPct = math.floor(healthPct * 100 + 0.5)
    
    local r, g, b
    if ET.ColorUtils then
        r, g, b = ET.ColorUtils:GetHealthColor(healthPct)
    else
        -- Fallback color logic
        if healthPct > 0.75 then
            r, g, b = 0.2, 1, 0.2 -- Green
        elseif healthPct > 0.5 then
            r, g, b = 1, 0.9, 0.1 -- Yellow
        elseif healthPct > 0.25 then
            r, g, b = 1, 0.6, 0.1 -- Orange
        else
            r, g, b = 1, 0.15, 0.15 -- Red
        end
    end
    
    -- Add percentage if not at full health
    if currentHealth < maxHealth then
        healthText = healthText .. string.format(" (%d%%)", displayPct)
    end
    
    tooltip:AddDoubleLine(L["Health:"] or "Health:", healthText, 1, 1, 0, r, g, b)
    tooltip.epicTipHealthAdded = true
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
        
        -- Get player's item level directly
        local itemLevel = C_PaperDollInfo.GetInspectItemLevel("player")
        if itemLevel and itemLevel > 0 then
            Tooltip.cachedIlvl = math.floor(itemLevel + 0.5)
        else
            Tooltip.cachedIlvl = "?"
        end
        
        -- Set inspected GUID for self to allow modules to work properly
        Tooltip.inspectedGUID = UnitGUID("player")
    else
        if not InCombatLockdown() then
            Tooltip.UpdateSpecAndIlvl(unit)
        end
    end
    
    Tooltip.InsertCustomInfo(tooltip, unit)
    Tooltip.ProcessHealthNumbers(tooltip, unit)
    Tooltip.ProcessHealthBarVisibility(tooltip, unit)
end

-- Main tooltip processing function
function Tooltip.ProcessUnitTooltip(tooltip, unit)
    if not tooltip or not unit or not UnitExists(unit) then return end
    if not EpicTipDB or not EpicTipDB.enabled then return end
    
    -- Clear processing flags only for player's own character to prevent duplication on others
    if UnitIsUnit(unit, "player") then
        tooltip.epicTipProcessed = nil
        tooltip.epicTipHealthAdded = nil
    end
    
    -- Skip processing during combat if hideInCombat is enabled
    if EpicTipDB.hideInCombat and InCombatLockdown() then
        if EpicTipDB.debugMode then
            print("EpicTip: Skipping - in combat")
        end
        return
    end
    
    -- Wrap entire function in pcall for safety
    local success, err = pcall(function()
        -- Apply basic styling to all units
        local scale = EpicTipDB.scale or 1.0
        tooltip:SetScale(scale)
        
        -- Process player-specific information
        if UnitIsPlayer(unit) then
            Tooltip.ProcessPlayerUnit(tooltip, unit)
        else
            -- Process health numbers for NPCs
            Tooltip.ProcessHealthNumbers(tooltip, unit)
            -- Process health bar visibility for NPCs
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
    end)
    
    if not success then
        if EpicTipDB.debugMode then
            print("EpicTip: Error in ProcessUnitTooltip:", err)
        end
        -- Still try to apply basic styling even if main processing fails
        local scale = EpicTipDB.scale or 1.0
        tooltip:SetScale(scale)
    end
end

-- Simple tooltip processor setup - CORE FUNCTION 1: Hook tooltip events
function Tooltip.SetupUnifiedTooltipProcessor()
    if not TooltipDataProcessor or not TooltipDataProcessor.AddTooltipPostCall or not Enum.TooltipDataType then
        -- Modern tooltip API not available, activate backup system
        if ET.SetupBackupTooltipHooks then
            ET:SetupBackupTooltipHooks()
        end
        return
    end
    
    -- Simple OnShow hook for immediate processing
    if GameTooltip then
        GameTooltip:HookScript("OnShow", function(tooltip)
            local _, unit = tooltip:GetUnit()
            if unit and UnitExists(unit) then
                Tooltip.ProcessUnitTooltip(tooltip, unit)
            end
        end)
    end
    
    -- Unit Tooltip Processor
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        if not tooltip or not tooltip.GetUnit then return end
        if not EpicTipDB or not EpicTipDB.enabled then return end
        
        local _, unit = tooltip:GetUnit()
        if unit and UnitExists(unit) then
            Tooltip.ProcessUnitTooltip(tooltip, unit)
        end
    end)
    
    -- Item Tooltip Processor  
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
        if not EpicTipDB or not EpicTipDB.enabled then return end
        
        -- Apply scaling and basic styling to all item tooltips
        local scale = EpicTipDB.scale or 1.0
        tooltip:SetScale(scale)
        if ET.TooltipStyling then
            ET.TooltipStyling:ApplyAdvancedStyling(tooltip, nil)
        end
        
        -- Apply fonts
        if ET.FontManager and ET.FontManager.ApplyFonts then
            ET.FontManager:ApplyFonts(tooltip)
        end
        
        -- Process ItemInfo module if enabled
        if EpicTipDB.showItemInfo and (tooltip == GameTooltip or tooltip == ItemRefTooltip) then
            if ET.ItemInfo and ET.ItemInfo.ProcessItemTooltip then
                ET.ItemInfo:ProcessItemTooltip(tooltip)
            end
        end
        
        -- Process StatValues for items if enabled
        if EpicTipDB.showStatValues and tooltip == GameTooltip then
            if ET.StatValues and ET.StatValues.ProcessStatTooltip then
                ET.StatValues:ProcessStatTooltip(tooltip)
            end
        end
    end)
    
    -- Spell Tooltip Processor
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip)
        if not EpicTipDB or not EpicTipDB.enabled then return end
        if not EpicTipDB.showStatValues or tooltip ~= GameTooltip then return end
        
        -- Process StatValues for spells
        if ET.StatValues and ET.StatValues.ProcessStatTooltip then
            ET.StatValues:ProcessStatTooltip(tooltip)
        end
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
        
        -- Use Blizzard's native item level API directly
        local itemLevel = C_PaperDollInfo.GetInspectItemLevel(unit)
        if itemLevel and itemLevel > 0 then
            Tooltip.cachedIlvl = math.floor(itemLevel + 0.5)
        else
            Tooltip.cachedIlvl = "?"
        end

        if GameTooltip:IsShown() and UnitExists(unit) then
            local currentUnit = select(2, GameTooltip:GetUnit())
            if currentUnit == unit then
                GameTooltip:SetUnit(unit)
            end
        end
    end
end

function Tooltip.OnInspectHonorUpdate()
    if GameTooltip:IsShown() then
        local _, unit = GameTooltip:GetUnit()
        if unit and UnitExists(unit) then
            GameTooltip:SetUnit(unit)
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

-- Initialize tooltip system
function Tooltip.Initialize()
    if not EpicTipDB then
        return
    end
    
    Tooltip.inspectedGUID = nil
    Tooltip.specName = ""
    Tooltip.cachedIlvl = "?"
    Tooltip.cachedRole = ""
    
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
        GameTooltip:HookScript("OnHide", function(self)
            -- Reset processing flags to prevent stale data
            self.epicTipProcessed = nil
            self.epicTipHealthAdded = nil
            
            if ET.TooltipStyling then
                ET.TooltipStyling:CleanupTooltipStyling(self)
            end
        end)
        
        -- Hook OnShow to ensure health bar visibility is always processed
        GameTooltip:HookScript("OnShow", function(self)
            local _, unit = self:GetUnit()
            if unit and UnitExists(unit) then
                Tooltip.ProcessHealthBarVisibility(self, unit)
            end
        end)
    end
end
local addonName, ET = ...

-- EPICTIP UNIT AURAS MODULE
-- Provides buff/debuff display, targeting info, AFK/DND status, and raid icons
-- Compatible with Patch 12.0.x Secret Values system
--
-- API COMPATIBILITY:
-- Retail (11.0.2+): Uses C_UnitAuras.GetAuraDataByIndex() - UnitAura was removed
-- Classic/Era/Wrath/MoP: Uses UnitAura() / UnitBuff() / UnitDebuff()
-- All versions: UnitIsAFK, UnitIsDND, GetRaidTargetIndex are available

ET.UnitAuras = ET.UnitAuras or {}
local UnitAuras = ET.UnitAuras
local L = ET.L or {}

-- Version detection
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local hasModernAuraAPI = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex ~= nil

local function IsSecretValue(value)
    if not issecretvalue then return false end
    local ok, res = pcall(issecretvalue, value)
    return ok and res or false
end

-- Configuration defaults
local MAX_AURAS_DISPLAY = 8  -- Max buffs/debuffs to show per row
local AURA_ICON_SIZE = 20    -- Default icon size
local AURA_SPACING = 2       -- Space between icons

-- Classic debuff limits (Retail is unlimited)
local MAX_AURA_SCAN = isRetail and 40 or (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and 16 or 40)

-- Cache for performance
local auraFramePool = {}
local activeAuraFrames = {}

-- Initialize module
function UnitAuras.Initialize()
    if EpicTipDB and EpicTipDB.debugMode then
        print("EpicTip: UnitAuras module initialized")
    end
end

--------------------------------------------------------------------------------
-- BUFF/DEBUFF DISPLAY
--------------------------------------------------------------------------------

-- Safely read a field from a table that may be fully secret (Patch 12.0.0+)
-- When C_TooltipInfo.GetUnitAura is invoked with secret values, the entire
-- returned table (including sub-tables like "lines") becomes a secret vector.
-- Indexing a secret vector makes ALL reads produce secrets. We must pcall
-- every field access and check each result with issecretvalue().
local function SafeField(tbl, key, fallback)
    if not tbl then return fallback end
    local ok, val = pcall(function() return tbl[key] end)
    if not ok then return fallback end
    if IsSecretValue(val) then return fallback end
    return val
end

-- Check if a table itself is fully secret (all indexing produces secrets)
local function IsSecretTable(tbl)
    if not tbl then return false end
    -- Try reading a known-safe key; if even that produces a secret, the table is secret
    local ok, val = pcall(function() return tbl["name"] end)
    if not ok then return true end  -- pcall failed = table is inaccessible
    return IsSecretValue(val)
end

-- Get unit's auras (buffs or debuffs)
function UnitAuras.GetUnitAuras(unit, filter)
    if not unit or not UnitExists(unit) then return {} end

    local auras = {}
    local auraIndex = 1

    -- Use C_UnitAuras for modern API (Retail 11.0.2+)
    if hasModernAuraAPI then
        while auraIndex <= MAX_AURA_SCAN do  -- Safety limit
            -- Patch 12.0.0+: The entire GetAuraDataByIndex call can fail or return
            -- a fully secret table when in instances/combat. Wrap in pcall.
            local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unit, auraIndex, filter)
            if not ok or not auraData then break end

            -- If the aura table itself is fully secret, skip it entirely
            if not IsSecretTable(auraData) then
                -- Use SafeField for every access - individual fields may still be secret
                local name = SafeField(auraData, "name", nil)
                local icon = SafeField(auraData, "icon", nil)
                local applications = SafeField(auraData, "applications", 0)
                local duration = SafeField(auraData, "duration", 0)
                local expirationTime = SafeField(auraData, "expirationTime", 0)
                local sourceUnit = SafeField(auraData, "sourceUnit", nil)
                local spellId = SafeField(auraData, "spellId", nil)
                local isBossDebuff = SafeField(auraData, "isBossDebuff", false)
                local isFromPlayerOrPlayerPet = SafeField(auraData, "isFromPlayerOrPlayerPet", false)
                local canApplyAura = SafeField(auraData, "canApplyAura", false)

                if name then
                    table.insert(auras, {
                        name = name,
                        icon = icon,
                        count = applications,
                        duration = duration,
                        expirationTime = expirationTime,
                        sourceUnit = sourceUnit,
                        spellId = spellId,
                        isHarmful = (filter == "HARMFUL"),
                        canApplyAura = canApplyAura,
                        isBossAura = isBossDebuff,
                        isFromPlayerOrPlayerPet = isFromPlayerOrPlayerPet,
                    })
                end
            end

            auraIndex = auraIndex + 1
        end
    else
        -- Classic/Era/Wrath/MoP: Use UnitAura (or UnitBuff/UnitDebuff)
        -- UnitAura returns: name, icon, count, dispelType, duration, expirationTime, source,
        --                   isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff,
        --                   castByPlayer, nameplateShowAll, timeMod, ...
        while auraIndex <= MAX_AURA_SCAN do
            local name, icon, count, debuffType, duration, expirationTime, source,
                  isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer

            -- Use UnitAura which exists in all Classic versions
            if UnitAura then
                name, icon, count, debuffType, duration, expirationTime, source,
                isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer =
                    UnitAura(unit, auraIndex, filter)
            end

            if not name then break end

            -- Determine if it's from the player (for "show only my auras" feature)
            local isFromPlayer = (source == "player") or (source == "pet") or (source == "vehicle") or castByPlayer

            table.insert(auras, {
                name = name,
                icon = icon,
                count = count or 0,
                duration = duration or 0,
                expirationTime = expirationTime or 0,
                sourceUnit = source,
                spellId = spellId,
                isHarmful = (filter == "HARMFUL"),
                debuffType = debuffType,
                canApplyAura = canApplyAura,
                isBossAura = isBossDebuff,
                isFromPlayerOrPlayerPet = isFromPlayer,
            })

            auraIndex = auraIndex + 1
        end
    end

    return auras
end

-- Format remaining time for aura
local function FormatAuraTime(timeLeft)
    if timeLeft <= 0 then return "" end

    if timeLeft < 60 then
        return string.format("%ds", math.floor(timeLeft))
    elseif timeLeft < 3600 then
        return string.format("%dm", math.floor(timeLeft / 60))
    else
        return string.format("%dh", math.floor(timeLeft / 3600))
    end
end

-- Add aura icons to tooltip
function UnitAuras.AddAurasToTooltip(tooltip, unit)
    if not tooltip or not unit or not UnitExists(unit) then return end
    if not EpicTipDB or not EpicTipDB.showAuras then return end

    -- TAINT-SAFE: Use external state table instead of writing to tooltip frame
    if ET.TooltipState:Get(tooltip, "aurasAdded") then return end
    ET.TooltipState:Set(tooltip, "aurasAdded", true)

    local currentTime = GetTime()
    local showOnlyMine = EpicTipDB.showOnlyMyAuras
    local maxAuras = EpicTipDB.maxAurasDisplay or MAX_AURAS_DISPLAY

    -- Get buffs
    local buffs = UnitAuras.GetUnitAuras(unit, "HELPFUL")
    local debuffs = UnitAuras.GetUnitAuras(unit, "HARMFUL")

    -- Filter for only player's auras if setting enabled
    if showOnlyMine then
        local myBuffs = {}
        for _, aura in ipairs(buffs) do
            if aura.isFromPlayerOrPlayerPet or aura.sourceUnit == "player" then
                table.insert(myBuffs, aura)
            end
        end
        buffs = myBuffs

        local myDebuffs = {}
        for _, aura in ipairs(debuffs) do
            if aura.isFromPlayerOrPlayerPet or aura.sourceUnit == "player" then
                table.insert(myDebuffs, aura)
            end
        end
        debuffs = myDebuffs
    end

    -- Helper: safely build icon string (icon may be number or string path)
    local iconSize = EpicTipDB.auraIconSize or AURA_ICON_SIZE
    local function BuildIconStr(aura)
        local iconPath = aura.icon
        if not iconPath or iconPath == "" then
            iconPath = "Interface\\Icons\\INV_Misc_QuestionMark"
        end
        -- Icon can be a number (fileDataID) or string path - both work in |T|t
        local ok, str = pcall(string.format, "|T%s:%d:%d|t", tostring(iconPath), iconSize, iconSize)
        if ok then return str end
        return "|TInterface\\Icons\\INV_Misc_QuestionMark:" .. iconSize .. ":" .. iconSize .. "|t"
    end

    -- Add buffs section
    if #buffs > 0 and EpicTipDB.showBuffs ~= false then
        tooltip:AddLine(" ")

        local buffText = ""
        local count = 0
        for i, aura in ipairs(buffs) do
            if count >= maxAuras then break end
            buffText = buffText .. BuildIconStr(aura) .. " "
            count = count + 1
        end

        if buffText ~= "" then
            tooltip:AddLine("|cFF00FF00Buffs:|r " .. buffText, 1, 1, 1)
        end
    end

    -- Add debuffs section
    if #debuffs > 0 and EpicTipDB.showDebuffs ~= false then
        local debuffText = ""
        local count = 0
        for i, aura in ipairs(debuffs) do
            if count >= maxAuras then break end
            debuffText = debuffText .. BuildIconStr(aura) .. " "
            count = count + 1
        end

        if debuffText ~= "" then
            tooltip:AddLine("|cFFFF0000Debuffs:|r " .. debuffText, 1, 1, 1)
        end
    end
end

--------------------------------------------------------------------------------
-- WHO IS TARGETING (Party/Raid)
--------------------------------------------------------------------------------

function UnitAuras.GetUnitsTargeting(unit)
    if not unit or not UnitExists(unit) then return {} end

    local targetingUnits = {}
    local unitGUID = UnitGUID(unit)

    if not unitGUID then return {} end

    -- Check party members
    if IsInGroup() then
        local groupType = IsInRaid() and "raid" or "party"
        local maxMembers = IsInRaid() and 40 or 4

        for i = 1, maxMembers do
            local memberUnit = groupType .. i
            if UnitExists(memberUnit) and not UnitIsUnit(memberUnit, "player") then
                local targetUnit = memberUnit .. "target"
                if UnitExists(targetUnit) and UnitGUID(targetUnit) == unitGUID then
                    local name = UnitName(memberUnit)
                    local _, classFileName = UnitClass(memberUnit)
                    local classColor = classFileName and RAID_CLASS_COLORS[classFileName]

                    if classColor then
                        name = string.format("|c%s%s|r", classColor.colorStr, name)
                    end

                    table.insert(targetingUnits, name)
                end
            end
        end
    end

    -- Also check player's target
    if not UnitIsUnit(unit, "player") then
        local playerTarget = "target"
        if UnitExists(playerTarget) and UnitGUID(playerTarget) == unitGUID then
            -- Player is targeting this unit, don't add to list (obvious)
        end
    end

    return targetingUnits
end

function UnitAuras.AddTargetingInfoToTooltip(tooltip, unit)
    if not tooltip or not unit or not UnitExists(unit) then return end
    if not EpicTipDB or not EpicTipDB.showTargetedBy then return end
    if not IsInGroup() then return end

    -- TAINT-SAFE: Use external state table instead of writing to tooltip frame
    if ET.TooltipState:Get(tooltip, "targetingAdded") then return end
    ET.TooltipState:Set(tooltip, "targetingAdded", true)

    local targetingUnits = UnitAuras.GetUnitsTargeting(unit)

    if #targetingUnits > 0 then
        tooltip:AddLine(" ")
        local targetedByText = table.concat(targetingUnits, ", ")
        tooltip:AddDoubleLine(
            L["Targeted By:"] or "Targeted By:",
            targetedByText,
            1, 0.82, 0,  -- Gold color for label
            1, 1, 1      -- White for names
        )
    end
end

--------------------------------------------------------------------------------
-- AFK/DND STATUS
--------------------------------------------------------------------------------

function UnitAuras.GetPlayerStatus(unit)
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then
        return nil
    end

    -- All these APIs exist in both Retail and Classic (vanilla, wrath, mop, etc.)
    -- Using safety checks anyway for robustness
    if UnitIsAFK and UnitIsAFK(unit) then
        return "AFK", 1, 0.5, 0  -- Orange
    elseif UnitIsDND and UnitIsDND(unit) then
        return "DND", 1, 0, 0    -- Red
    elseif UnitIsConnected and not UnitIsConnected(unit) then
        return "Offline", 0.5, 0.5, 0.5  -- Gray
    elseif UnitIsDead and UnitIsDead(unit) then
        return "Dead", 0.5, 0.5, 0.5     -- Gray
    elseif UnitIsGhost and UnitIsGhost(unit) then
        return "Ghost", 0.5, 0.5, 0.5    -- Gray
    end

    return nil
end

function UnitAuras.AddStatusToTooltip(tooltip, unit)
    if not tooltip or not unit or not UnitExists(unit) then return end
    if not EpicTipDB or not EpicTipDB.showPlayerStatus then return end

    -- TAINT-SAFE: Use external state table instead of writing to tooltip frame
    if ET.TooltipState:Get(tooltip, "statusAdded") then return end
    ET.TooltipState:Set(tooltip, "statusAdded", true)

    local status, r, g, b = UnitAuras.GetPlayerStatus(unit)

    if status then
        tooltip:AddDoubleLine(
            L["Status:"] or "Status:",
            string.format("|cff%02x%02x%02x<%s>|r", r*255, g*255, b*255, status),
            1, 1, 0,  -- Yellow for label
            r, g, b
        )
    end
end

--------------------------------------------------------------------------------
-- RAID TARGET ICON
--------------------------------------------------------------------------------

local RAID_TARGET_ICONS = {
    [1] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t", -- Star
    [2] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t", -- Circle
    [3] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t", -- Diamond
    [4] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t", -- Triangle
    [5] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t", -- Moon
    [6] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t", -- Square
    [7] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t", -- Cross
    [8] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t", -- Skull
}

local RAID_TARGET_NAMES = {
    [1] = "Star",
    [2] = "Circle",
    [3] = "Diamond",
    [4] = "Triangle",
    [5] = "Moon",
    [6] = "Square",
    [7] = "Cross",
    [8] = "Skull",
}

function UnitAuras.GetRaidTargetIcon(unit)
    if not unit or not UnitExists(unit) then return nil, nil end

    -- GetRaidTargetIndex exists in all versions (Retail and Classic)
    if not GetRaidTargetIndex then return nil, nil end

    local raidTargetIndex = GetRaidTargetIndex(unit)
    if raidTargetIndex and raidTargetIndex > 0 and raidTargetIndex <= 8 then
        return RAID_TARGET_ICONS[raidTargetIndex], RAID_TARGET_NAMES[raidTargetIndex]
    end

    return nil, nil
end

function UnitAuras.AddRaidIconToTooltip(tooltip, unit)
    if not tooltip or not unit or not UnitExists(unit) then return end
    if not EpicTipDB or not EpicTipDB.showRaidIcon then return end

    -- TAINT-SAFE: Use external state table instead of writing to tooltip frame
    if ET.TooltipState:Get(tooltip, "raidIconAdded") then return end
    ET.TooltipState:Set(tooltip, "raidIconAdded", true)

    local icon, name = UnitAuras.GetRaidTargetIcon(unit)

    if icon and name then
        tooltip:AddDoubleLine(
            L["Raid Icon:"] or "Raid Icon:",
            icon .. " " .. name,
            1, 1, 0,  -- Yellow for label
            1, 1, 1   -- White for icon+name
        )
    end
end

--------------------------------------------------------------------------------
-- MAIN PROCESSING FUNCTION
--------------------------------------------------------------------------------

function UnitAuras.ProcessUnitTooltip(tooltip, unit)
    if not tooltip or not unit or not UnitExists(unit) then return end
    if not EpicTipDB then return end

    -- Wrap in pcall for safety
    local success, err = pcall(function()
        -- Add raid icon first (appears near top)
        UnitAuras.AddRaidIconToTooltip(tooltip, unit)

        -- Add player status (AFK/DND/Offline)
        if UnitIsPlayer(unit) then
            UnitAuras.AddStatusToTooltip(tooltip, unit)
        end

        -- Add targeting information
        UnitAuras.AddTargetingInfoToTooltip(tooltip, unit)

        -- Add buffs/debuffs last (can be long)
        UnitAuras.AddAurasToTooltip(tooltip, unit)
    end)

    if not success and EpicTipDB.debugMode then
        print("EpicTip UnitAuras: Error processing tooltip:", err)
    end
end

-- Cleanup flags on tooltip hide
-- TAINT-SAFE: No-op now since all state is in ET.TooltipState and gets cleared
-- by ET.TooltipState:Clear() in the OnHide hook. Kept for API compatibility.
function UnitAuras.CleanupTooltip(tooltip)
    -- State is managed by ET.TooltipState:Clear() in the OnHide hook
end

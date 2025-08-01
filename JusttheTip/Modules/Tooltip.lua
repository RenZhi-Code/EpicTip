local addonName, JTT = ...

local C_Timer = _G.C_Timer

JTT.Tooltip = JTT.Tooltip or {}
local Tooltip = JTT.Tooltip
local L = JTT.L or {}

local function GetUtils()
    return JTT.Utils
end

Tooltip.inspectedGUID = nil
Tooltip.specName = ""
Tooltip.cachedIlvl = "?"
Tooltip.cachedRole = ""

function Tooltip.ClearCache()
    Tooltip.specName = ""
    Tooltip.cachedIlvl = "?"
    Tooltip.cachedRole = ""
end

function Tooltip.UpdateSpecAndIlvl(unit)
    local guid = UnitGUID(unit)
    if not guid then return end
    
    if Tooltip.inspectedGUID and Tooltip.inspectedGUID ~= guid then
        Tooltip.ClearCache()
    end
    
    local Utils = GetUtils()
    if not Utils or not Utils.CanInspectThrottled(unit) then
        return
    end
    
    local currentTime = GetTime()
    Utils.pendingInspects[guid] = currentTime
    Tooltip.inspectedGUID = guid
    NotifyInspect(unit)
end

function Tooltip.InsertCustomInfo(tooltip, unit)
    if not unit or not UnitIsPlayer(unit) then return end
    if not JustTheTipDB or not JustTheTipDB.enabled then return end

    local className, classFileName = UnitClass(unit)
    
    local r, g, b = 1, 1, 1
    if classFileName and RAID_CLASS_COLORS[classFileName] then
        r, g, b = RAID_CLASS_COLORS[classFileName]:GetRGB()
    end
    local nameLine = _G["GameTooltipTextLeft1"]
    if nameLine then
        local nameText = nameLine:GetText()
        if nameText then
            if JustTheTipDB.showClassIcon then
                local Utils = GetUtils()
                local classIcon = Utils and Utils.GetClassIcon and Utils.GetClassIcon(classFileName) or ""
                if classIcon ~= "" then
                    if not nameText:find("ClassIcon_") and not nameText:find("Interface\\\\Icons\\\\ClassIcon_") then
                        nameLine:SetText(classIcon .. " " .. nameText)
                    end
                end
            end
            nameLine:SetTextColor(r, g, b)
        end
    end
    
    for i = 1, tooltip:NumLines() do
        local left = _G["GameTooltipTextLeft" .. i]
        if left then
            local text = left:GetText()
            if text then
                if i == 2 and not text:find("Level") and not text:find("Alliance") and not text:find("Horde") and text ~= className then
                    left:SetText("<" .. text .. ">")
                    left:SetTextColor(0.25, 1, 0.25)
                    
                elseif text:find("Level") or text:find("%(Player%)") then
                    text = text:gsub("%s*%(Player%)", "")
                    text = text:gsub("%s*%(Item Level %d+%)", "")
                    text = text:gsub("%s*Item Level: %d+", "")
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
    
    if JustTheTipDB.showTarget then
        local targetName = UnitName(unit .. "target")
        if targetName and targetName ~= "" and targetName ~= UNKNOWN then
            tooltip:AddDoubleLine(L["Target:"] or "Target:", targetName, 1, 1, 0, 1, 0, 0)
        end
    end
    
    if JustTheTipDB.showMythicRating then
        local Utils = GetUtils()
        local mythicRating = Utils and Utils.GetMythicPlusRating and Utils.GetMythicPlusRating(unit)
        if mythicRating and mythicRating > 0 then
            tooltip:AddDoubleLine(L["Mythic+ Rating:"] or "Mythic+ Rating:", tostring(mythicRating), 1, 0.5, 0, 1, 1, 1)
        end
    end
    
    if JustTheTipDB.showPvPRating then
        local Utils = GetUtils()
        local pvpRating = Utils and Utils.GetPvPRating and Utils.GetPvPRating(unit)
        if pvpRating and pvpRating > 0 then
            tooltip:AddDoubleLine(L["PvP Rating:"] or "PvP Rating:", tostring(pvpRating), 0.5, 1, 0.5, 1, 1, 1)
        end
    end
    
    if JustTheTipDB.showRoleIcon and Tooltip.cachedRole and Tooltip.cachedRole ~= "" then
        local Utils = GetUtils()
        local roleIcon = Utils and Utils.GetRoleIcon and Utils.GetRoleIcon(Tooltip.cachedRole) or ""
        local roleText = Tooltip.cachedRole
        if roleIcon ~= "" then
            roleText = roleIcon .. " " .. roleText
        end
        tooltip:AddDoubleLine(L["Role:"] or "Role:", roleText, 1, 1, 0, 1, 1, 1)
    end
    
    if JustTheTipDB.showIlvl and Tooltip.cachedIlvl ~= "?" then
        tooltip:AddDoubleLine(L["Item Level:"] or "Item Level:", Tooltip.cachedIlvl, 1, 1, 0, 1, 1, 1)
    end
    
    if JustTheTipDB and JustTheTipDB.debugMode == true then
        local guid = UnitGUID(unit)
        local unitID = unit
        local classID = classFileName
        local specID = GetInspectSpecialization(unit)
        
        if guid then
            tooltip:AddDoubleLine(L["GUID:"], guid:sub(1, 8) .. "...", 0.5, 0.5, 0.5, 0.8, 0.8, 0.8)
        end
        if unitID then
            tooltip:AddDoubleLine(L["Unit ID:"], unitID, 0.5, 0.5, 0.5, 0.8, 0.8, 0.8)
        end
        if classID then
            tooltip:AddDoubleLine(L["Class ID:"], classID, 0.5, 0.5, 0.5, 0.8, 0.8, 0.8)
        end
        if specID and specID > 0 then
            tooltip:AddDoubleLine(L["Spec ID:"], tostring(specID), 0.5, 0.5, 0.5, 0.8, 0.8, 0.8)
        end
    end
end

local function ApplyBackgroundColor(tooltip)
    if not JustTheTipDB or not JustTheTipDB.backgroundColor then return end
    
    local color = JustTheTipDB.backgroundColor
    local opacity = (JustTheTipDB and JustTheTipDB.backgroundOpacity) or color.a or 0.8
    
    if tooltip then
        if tooltip.NineSlice then
            if tooltip.NineSlice.SetCenterColor then
                tooltip.NineSlice:SetCenterColor(color.r, color.g, color.b, opacity)
            end
            if tooltip.NineSlice.SetBorderColor then
                tooltip.NineSlice:SetBorderColor(color.r * 0.8, color.g * 0.8, color.b * 0.8, opacity)
            end
        end
        
        if tooltip.SetBackdropColor then
            tooltip:SetBackdropColor(color.r, color.g, color.b, opacity)
        end
        
        if tooltip.SetBackdropBorderColor then
            tooltip:SetBackdropBorderColor(color.r * 0.8, color.g * 0.8, color.b * 0.8, opacity)
        end
        
        if tooltip == GameTooltip and GameTooltip.SetBackdrop then
            local backdrop = GameTooltip:GetBackdrop()
            if backdrop then
                GameTooltip:SetBackdropColor(color.r, color.g, color.b, opacity)
                GameTooltip:SetBackdropBorderColor(color.r * 0.8, color.g * 0.8, color.b * 0.8, opacity)
            end
        end
    end
end

function Tooltip.SetupTooltipProcessor()
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
            if not tooltip or not tooltip.GetUnit then return end
            if not JustTheTipDB or not JustTheTipDB.enabled then return end
            
            local _, unit = tooltip:GetUnit()
            if not unit or not UnitIsPlayer(unit) then return end
            
            if JustTheTipDB.hideInCombat and InCombatLockdown() then
                tooltip:Hide()
                return
            end
            
            local guid = UnitGUID(unit)
            if guid and Tooltip.inspectedGUID ~= guid then
                Tooltip.ClearCache()
            end
            
            if UnitInParty(unit) or UnitInRaid(unit) or UnitIsUnit(unit, "player") then
                local Utils = GetUtils()
                if Utils then
                    Tooltip.cachedRole = Utils.GetRole and Utils.GetRole(unit) or ""
                    Tooltip.specName = Utils.GetSpec and Utils.GetSpec(unit) or ""
                end
            end
            
            if not InCombatLockdown() then
                Tooltip.UpdateSpecAndIlvl(unit)
            end
            
            local scale = JustTheTipDB and JustTheTipDB.scale or 1.0
            tooltip:SetScale(scale)
            
            if GameTooltipStatusBar then
                if JustTheTipDB and JustTheTipDB.hideHealthBar then
                    GameTooltipStatusBar:Hide()
                else
                    GameTooltipStatusBar:Show()
                end
            end
            
            Tooltip.InsertCustomInfo(tooltip, unit)
            ApplyBackgroundColor(tooltip)
        end)
    end
    
    if JustTheTipDB and JustTheTipDB.anchorToMouse then
        hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
            if JustTheTipDB and JustTheTipDB.enabled and JustTheTipDB.anchorToMouse then
                tooltip:SetOwner(parent, "ANCHOR_CURSOR")
            end
        end)
    end
end

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
            Tooltip.specName = Utils.GetSpec(unit)
            Tooltip.cachedRole = Utils.GetRole(unit)
        end
        
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

function Tooltip.OnTargetChanged()
    Tooltip.specName = ""
    Tooltip.cachedIlvl = "?"
    Tooltip.cachedRole = ""
end

function Tooltip.SetupAnchorHook()
end

function Tooltip.Initialize()
    if not JustTheTipDB then
        return
    end
    
    Tooltip.inspectedGUID = nil
    Tooltip.specName = ""
    Tooltip.cachedIlvl = "?"
    Tooltip.cachedRole = ""
end
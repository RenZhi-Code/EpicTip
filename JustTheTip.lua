local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("INSPECT_READY")
f:RegisterEvent("ADDON_LOADED")

local inspectedGUID
local specName = ""
local cachedIlvl = "?"

local function GetSpec(unit)
    local specID = GetInspectSpecialization(unit)
    if specID and specID ~= 0 then
        local id, name = GetSpecializationInfoByID(specID)
        return name or ""
    end
    return ""
end

local function UpdateSpecAndIlvl(unit)
    if UnitIsPlayer(unit) and CanInspect(unit) then
        inspectedGUID = UnitGUID(unit)
        NotifyInspect(unit)
    end
end

local function InsertCustomInfo(tooltip, unit)
    if not unit or not UnitIsPlayer(unit) then return end
    if not JustTheTipDB or not JustTheTipDB.enabled then return end

    local className, classFileName = UnitClass(unit)
    local r, g, b = RAID_CLASS_COLORS[classFileName]:GetRGB()

    -- Name color (Line 1)
    local nameLine = _G["GameTooltipTextLeft1"]
    if nameLine then
        nameLine:SetTextColor(r, g, b)
    end

    -- Guild color and < > (Line 2)
    local guildLine = _G["GameTooltipTextLeft2"]
    if guildLine then
        local guildText = guildLine:GetText()
        if guildText and guildText ~= "" then
            guildLine:SetText("<" .. guildText .. ">")
            guildLine:SetTextColor(0.25, 1, 0.25)
        end
    end

    -- Process all lines to clean up unwanted info and add iLvl
    local levelLineFound = false
    for i = 1, tooltip:NumLines() do
        local left = _G["GameTooltipTextLeft" .. i]
        if left then
            local text = left:GetText()
            if text then
                -- Remove (Player) from any line
                if text:find("%(Player%)") then
                    text = text:gsub("%s*%b()", "") -- Remove (Player)
                    if not levelLineFound and JustTheTipDB.showIlvl and cachedIlvl ~= "?" then
                        text = text .. " - iLvl " .. cachedIlvl
                        levelLineFound = true
                    end
                    left:SetText(text)
                end

                -- Remove unwanted info (e.g., titles, PvP ranks)
                if text:find("PvP") or text:match("^<.*>$") and i ~= 2 then -- Skip guild line
                    left:SetText("")
                end

                -- Recolor faction line
                if text == "Alliance" then
                    left:SetTextColor(0, 0.5, 1)
                elseif text == "Horde" then
                    left:SetTextColor(1, 0, 0)
                end
            end
        end
    end

    -- Add Target (yellow "Target:", red name)
    if JustTheTipDB.showTarget then
        local targetName = UnitName(unit .. "target")
        if targetName and targetName ~= "" and targetName ~= UNKNOWN then
            tooltip:AddDoubleLine("Target:", targetName, 1, 1, 0, 1, 0, 0)
        end
    end
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
    if not tooltip or not tooltip.GetUnit then return end
    local _, unit = tooltip:GetUnit()
    if not unit then return end

    -- Hide tooltip in combat if option enabled
    if JustTheTipDB and JustTheTipDB.hideInCombat and InCombatLockdown() then
        tooltip:Hide()
        return
    end

    if UnitIsPlayer(unit) and CanInspect(unit) then
        UpdateSpecAndIlvl(unit)
    end

    tooltip:SetScale(JustTheTipDB and JustTheTipDB.scale or 1.0)

    -- Always hide the health bar
    if GameTooltipStatusBar then
        GameTooltipStatusBar:Hide()
    end

    InsertCustomInfo(tooltip, unit)
end)

hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
    if JustTheTipDB and JustTheTipDB.enabled and JustTheTipDB.anchorToMouse then
        tooltip:SetOwner(parent, "ANCHOR_CURSOR")
    end
end)

f:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == "JustTheTip" then
        -- Initialize settings if not already set by the menu
        if not JustTheTipDB then
            JustTheTipDB = {}
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        specName = ""
        cachedIlvl = "?"
    elseif event == "INSPECT_READY" then
        local guid = ...
        if guid == inspectedGUID then
            local unit = "mouseover"
            specName = GetSpec(unit)
            local itemLevel = C_PaperDollInfo.GetInspectItemLevel(unit)
            if itemLevel and itemLevel > 0 then
                cachedIlvl = math.floor(itemLevel + 0.5)
            else
                cachedIlvl = "?"
            end
        end
    end
end)
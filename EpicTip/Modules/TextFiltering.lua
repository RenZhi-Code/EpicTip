local addonName, ET = ...

ET.TextFiltering = ET.TextFiltering or {}
local TextFiltering = ET.TextFiltering
local L = ET.L or {}

local function IsSecretValue(value)
    if not issecretvalue then return false end
    local ok, res = pcall(issecretvalue, value)
    return ok and res or false
end

TextFiltering.HidePatterns = {
    PVP = "^" .. (PVP_ENABLED or "PvP Enabled") .. "$",
    RIGHT_CLICK = (UNIT_POPUP_RIGHT_CLICK or "Right click for more options"),
    SPECIALIZATION_CLASS = {
        "^%w+ %w+$",
    }
}

TextFiltering.ReactionColors = {
    [1] = {r = 0.8, g = 0.1, b = 0.1},
    [2] = {r = 0.8, g = 0.4, b = 0.1},
    [3] = {r = 0.8, g = 0.8, b = 0.1},
    [4] = {r = 0.1, g = 0.8, b = 0.1},
    [5] = {r = 0.1, g = 0.8, b = 0.1},
    [6] = {r = 0.1, g = 0.8, b = 0.1},
    [7] = {r = 0.0, g = 0.6, b = 0.9},
    [8] = {r = 0.0, g = 0.4, b = 1.0},
    [9] = {r = 0.6, g = 0.2, b = 1.0},
}

TextFiltering.CustomClassColors = {
    ["WARRIOR"] = {r = 0.78, g = 0.61, b = 0.43},
    ["PALADIN"] = {r = 0.96, g = 0.55, b = 0.73},
    ["HUNTER"] = {r = 0.67, g = 0.83, b = 0.45},
    ["ROGUE"] = {r = 1.00, g = 0.96, b = 0.41},
    ["PRIEST"] = {r = 1.00, g = 1.00, b = 1.00},
    ["DEATHKNIGHT"] = {r = 0.77, g = 0.12, b = 0.23},
    ["SHAMAN"] = {r = 0.00, g = 0.44, b = 0.87},
    ["MAGE"] = {r = 0.25, g = 0.78, b = 0.92},
    ["WARLOCK"] = {r = 0.53, g = 0.53, b = 0.93},
    ["MONK"] = {r = 0.00, g = 1.00, b = 0.59},
    ["DRUID"] = {r = 1.00, g = 0.49, b = 0.04},
    ["DEMONHUNTER"] = {r = 0.64, g = 0.19, b = 0.79},
    ["EVOKER"] = {r = 0.20, g = 0.58, b = 0.50},
}

function TextFiltering.ShouldHideText(text)
    -- PATCH 12.0.0: Check for secret values before string operations
    if issecretvalue and issecretvalue(text) then return false end
    if not text or type(text) ~= "string" or text == "" then return false end
    
    if EpicTipDB.hidePvpText and text:match(TextFiltering.HidePatterns.PVP) then
        return true
    end
    
    if EpicTipDB.hideRightClickText and text:find(TextFiltering.HidePatterns.RIGHT_CLICK) then
        return true
    end
    
    if EpicTipDB.hideSpecializationAndClassText then
        for _, pattern in ipairs(TextFiltering.HidePatterns.SPECIALIZATION_CLASS) do
            if text:match(pattern) then
                local words = {}
                for word in text:gmatch("%w+") do
                    table.insert(words, word)
                end
                if #words == 2 then
                    -- Check if this matches a class specialization format
                    for className, _ in pairs(LOCALIZED_CLASS_NAMES_MALE) do
                        if text:find(className) then
                            return true
                        end
                    end
                end
            end
        end
    end
    
    return false
end

function TextFiltering.GetClassColor(classFileName, unit)
    if not classFileName then return nil end
    
    if EpicTipDB.enableCustomClassColors and TextFiltering.CustomClassColors[classFileName] then
        local color = TextFiltering.CustomClassColors[classFileName]
        return CreateColor(color.r, color.g, color.b, 1)
    end
    
    local classColor = C_ClassColor.GetClassColor(classFileName)
    return classColor
end

function TextFiltering.GetReactionColor(unit)
    if not EpicTipDB.useReactionColoring then return nil end
    if not unit then return nil end
    
    local reaction = UnitReaction("player", unit)
    if not reaction then return nil end
    
    local colorData = TextFiltering.ReactionColors[reaction]
    if colorData then
        return CreateColor(colorData.r, colorData.g, colorData.b, 1)
    end
    
    return nil
end

function TextFiltering.FilterTooltipLines(tooltip)
    if not tooltip or not EpicTipDB then return end
    if not EpicTipDB.hidePvpText and not EpicTipDB.hideRightClickText and not EpicTipDB.hideSpecializationAndClassText then
        return
    end
    
    -- Skip World Quest tooltips to prevent interference
    if ET.Tooltip and ET.Tooltip.IsWorldQuestTooltip and ET.Tooltip.IsWorldQuestTooltip(tooltip) then return end

    local okName, tooltipName = pcall(tooltip.GetName, tooltip)
    if not okName or not tooltipName or IsSecretValue(tooltipName) then return end

    local numLines = 30
    if tooltip.NumLines then
        local okNum, n = pcall(tooltip.NumLines, tooltip)
        if okNum and type(n) == "number" and n > 0 then
            numLines = n
        end
    end

    local changed = false
    for i = 1, numLines do
        local leftLine = _G[tooltipName .. "TextLeft" .. i]
        local rightLine = _G[tooltipName .. "TextRight" .. i]

        local leftText, rightText = nil, nil
        if leftLine and leftLine.GetText then
            local ok, text = pcall(leftLine.GetText, leftLine)
            if ok and text and not IsSecretValue(text) then
                leftText = text
            end
        end
        if rightLine and rightLine.GetText then
            local ok, text = pcall(rightLine.GetText, rightLine)
            if ok and text and not IsSecretValue(text) then
                rightText = text
            end
        end

        local hideLeft = leftText and TextFiltering.ShouldHideText(leftText)
        local hideRight = rightText and TextFiltering.ShouldHideText(rightText)

        if hideLeft and hideRight then
            if leftLine then
                leftLine:SetText("")
                leftLine:Hide()
            end
            if rightLine then
                rightLine:SetText("")
                rightLine:Hide()
            end
            changed = true
        elseif hideLeft then
            if rightText and rightText ~= "" and leftLine and rightLine then
                leftLine:SetText(rightText)
                leftLine:Show()
                rightLine:SetText("")
                rightLine:Hide()
            elseif leftLine then
                leftLine:SetText("")
                leftLine:Hide()
            end
            changed = true
        elseif hideRight then
            if rightLine then
                rightLine:SetText("")
                rightLine:Hide()
            end
            changed = true
        end
    end

    if changed and tooltip.Show then
        pcall(tooltip.Show, tooltip)
    end
end

-- Apply text coloring to all visible tooltip lines
function TextFiltering.ApplyTooltipColoring(tooltip, unit)
    if not tooltip or not unit then return end
    if not EpicTipDB.useReactionColoring and not EpicTipDB.enableCustomClassColors then return end
    
    -- Apply coloring to the main tooltip lines
    for i = 1, 30 do
        local leftLine = _G[tooltip:GetName() .. "TextLeft" .. i]
        local rightLine = _G[tooltip:GetName() .. "TextRight" .. i]
        
        if leftLine and leftLine:IsShown() then
            local ok, text = pcall(leftLine.GetText, leftLine)
            if ok and text and not IsSecretValue(text) and text ~= "" then
                -- First line is usually the name - apply name coloring
                if i == 1 then
                    local coloredText = TextFiltering.ApplyColoringToText(text, unit, true)
                    if coloredText ~= text then
                        leftLine:SetText(coloredText)
                    end
                else
                    -- Other lines get general reaction coloring for NPCs
                    if not UnitIsPlayer(unit) then
                        local reactionColor = TextFiltering.GetReactionColor(unit)
                        if reactionColor then
                            local r, g, b = reactionColor:GetRGB()
                            leftLine:SetTextColor(r, g, b)
                        end
                    end
                end
            end
        end
        
        if rightLine and rightLine:IsShown() then
            local ok, text = pcall(rightLine.GetText, rightLine)
            if ok and text and not IsSecretValue(text) and text ~= "" then
                -- Right lines get reaction coloring for NPCs
                if not UnitIsPlayer(unit) then
                    local reactionColor = TextFiltering.GetReactionColor(unit)
                    if reactionColor then
                        local r, g, b = reactionColor:GetRGB()
                        rightLine:SetTextColor(r, g, b)
                    end
                end
            end
        end
    end
end

function TextFiltering.ApplyColoringToText(text, unit, isPlayerName)
    if not text or text == "" or IsSecretValue(text) then return text end
    if not unit then return text end
    
    -- For player names, use class colors
    if isPlayerName and UnitIsPlayer(unit) then
        local _, classFileName = UnitClass(unit)
        local classColor = TextFiltering.GetClassColor(classFileName, unit)
        if classColor then
            return classColor:WrapTextInColorCode(text)
        end
    end
    
    -- For NPCs or general text, use reaction colors  
    if not UnitIsPlayer(unit) then
        local reactionColor = TextFiltering.GetReactionColor(unit)
        if reactionColor then
            return reactionColor:WrapTextInColorCode(text)
        end
    end
    
    return text
end

function TextFiltering.Initialize()
    -- TAINT FIX: Never override Blizzard tooltip methods (e.g., GameTooltip:AddLine).
    -- Overriding methods taints protected frames and can break Blizzard's SetWatch()
    -- on GameTooltipStatusBar, resulting in "Lua Taint: EpicTip" errors.
    -- Filtering is now done post-population via TextFiltering.FilterTooltipLines().
    return true
end

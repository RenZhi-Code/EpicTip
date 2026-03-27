local addonName, ET = ...

-- Color Utilities Module - Extracted from bloated Tooltip.lua
-- Handles reaction colors, class colors, and color calculations following WoW 11.2 standards

ET.ColorUtils = ET.ColorUtils or {}
local ColorUtils = ET.ColorUtils

-- Get reaction colors using Blizzard's native reaction system
function ColorUtils:GetReactionColor(unit)
    if not unit or not UnitExists(unit) then
        return nil, nil
    end
    
    local reaction = UnitReaction(unit, "player")
    if not reaction then return nil, nil end
    
    -- Use Blizzard's native reaction colors when available
    if FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction] then
        local color = FACTION_BAR_COLORS[reaction]
        local bgColor = { r = color.r * 0.3, g = color.g * 0.3, b = color.b * 0.3, a = 0.8 }
        local borderColor = { r = color.r, g = color.g, b = color.b, a = 1.0 }
        return bgColor, borderColor
    end
    
    -- Background colors based on reaction
    local bgColors = {
        [1] = { r = 0.3, g = 0, b = 0, a = 0.8 },      -- Hostile
        [2] = { r = 0.3, g = 0, b = 0, a = 0.8 },      -- Hostile
        [3] = { r = 0.3, g = 0.15, b = 0, a = 0.8 },   -- Unfriendly
        [4] = { r = 0.3, g = 0.3, b = 0, a = 0.8 },    -- Neutral
        [5] = { r = 0, g = 0.2, b = 0, a = 0.8 },      -- Friendly
        [6] = { r = 0, g = 0.25, b = 0.15, a = 0.8 },  -- Honored
        [7] = { r = 0, g = 0.3, b = 0.25, a = 0.8 },   -- Revered
        [8] = { r = 0, g = 0.3, b = 0.3, a = 0.8 },    -- Exalted
    }
    
    -- Border colors (slightly brighter than background)
    local borderColors = {
        [1] = { r = 1, g = 0, b = 0, a = 1 },          -- Hostile
        [2] = { r = 1, g = 0, b = 0, a = 1 },          -- Hostile
        [3] = { r = 1, g = 0.5, b = 0, a = 1 },        -- Unfriendly
        [4] = { r = 1, g = 1, b = 0, a = 1 },          -- Neutral
        [5] = { r = 0, g = 1, b = 0, a = 1 },          -- Friendly
        [6] = { r = 0, g = 1, b = 0.5, a = 1 },        -- Honored
        [7] = { r = 0, g = 1, b = 0.75, a = 1 },       -- Revered
        [8] = { r = 0, g = 1, b = 1, a = 1 },          -- Exalted
    }
    
    return bgColors[reaction], borderColors[reaction]
end

-- Get health color based on health percentage
function ColorUtils:GetHealthColor(healthPct)
    local r, g, b
    if healthPct > 0.75 then
        r, g, b = 0.2, 1, 0.2 -- Green
    elseif healthPct > 0.5 then
        r, g, b = 1, 0.9, 0.1 -- Yellow
    elseif healthPct > 0.25 then
        r, g, b = 1, 0.6, 0.1 -- Orange
    else
        r, g, b = 1, 0.15, 0.15 -- Red
    end
    return r, g, b
end

-- Get class color from class filename
function ColorUtils:GetClassColor(classFileName)
    if classFileName and RAID_CLASS_COLORS[classFileName] then
        local classColor = RAID_CLASS_COLORS[classFileName]
        return classColor.r, classColor.g, classColor.b
    end
    return 1, 1, 1 -- Default white
end

-- Get faction colors
function ColorUtils:GetFactionColors()
    return {
        Alliance = { r = 0, g = 0.5, b = 1 },
        Horde = { r = 1, g = 0, b = 0 }
    }
end
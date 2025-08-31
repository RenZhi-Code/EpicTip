local addonName, ET = ...

-- Tooltip Styling Module - Extracted from bloated Tooltip.lua
-- Handles background, border, and visual styling following WoW 11.2 standards

ET.TooltipStyling = ET.TooltipStyling or {}
local TooltipStyling = ET.TooltipStyling

-- Simple styling system for tooltips using modern WoW frame creation
function TooltipStyling:ApplyModernStyling(tooltip, bgColor, borderColor, opacity)
    if not tooltip then return end
    
    -- Ensure we have valid color parameters with fallbacks
    bgColor = bgColor or { r = 0, g = 0, b = 0, a = 0.8 }
    borderColor = borderColor or { r = 0.3, g = 0.3, b = 0.4, a = 1.0 }
    opacity = opacity or 0.8
    
    -- Validate color table structure
    if type(bgColor) ~= "table" or not bgColor.r then
        bgColor = { r = 0, g = 0, b = 0, a = 0.8 }
    end
    if type(borderColor) ~= "table" or not borderColor.r then
        borderColor = { r = 0.3, g = 0.3, b = 0.4, a = 1.0 }
    end
    
    -- Simple background and border styling with frame pooling
    if not tooltip.epicTipStyling then
        local bgFrame, borderFrame
        
        -- Use frame pooling if available
        if ET.MemoryPool and ET.MemoryPool.GetFrame then
            bgFrame = ET.MemoryPool.GetFrame("background", nil, tooltip)
            borderFrame = ET.MemoryPool.GetFrame("border", nil, tooltip)
        else
            -- Fallback to direct creation
            bgFrame = CreateFrame("Frame", nil, tooltip)
            borderFrame = CreateFrame("Frame", nil, tooltip)
        end
        
        tooltip.epicTipStyling = {
            bgFrame = bgFrame,
            borderFrame = borderFrame,
            isPooled = ET.MemoryPool and ET.MemoryPool.GetFrame and true or false
        }
        
        -- Create background texture
        tooltip.epicTipStyling.bgTexture = tooltip.epicTipStyling.bgFrame:CreateTexture(nil, "BACKGROUND")
        tooltip.epicTipStyling.bgTexture:SetAllPoints()
        
        -- Create border textures
        tooltip.epicTipStyling.borders = {}
        for _, side in ipairs({"top", "bottom", "left", "right"}) do
            tooltip.epicTipStyling.borders[side] = tooltip.epicTipStyling.borderFrame:CreateTexture(nil, "OVERLAY")
        end
    end
    
    local styling = tooltip.epicTipStyling
    
    -- Position frames
    styling.bgFrame:SetAllPoints(tooltip)
    styling.bgFrame:SetFrameLevel(math.max(0, tooltip:GetFrameLevel() - 1))
    styling.borderFrame:SetAllPoints(tooltip)
    styling.borderFrame:SetFrameLevel(math.min(65535, tooltip:GetFrameLevel() + 1))
    
    -- Apply background color
    styling.bgTexture:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, opacity)
    
    -- Position and color borders
    local thickness = EpicTipDB.borderWidth or 2
    local borders = styling.borders
    
    borders.top:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 0, 0)
    borders.top:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", 0, 0)
    borders.top:SetHeight(thickness)
    
    borders.bottom:SetPoint("BOTTOMLEFT", tooltip, "BOTTOMLEFT", 0, 0)
    borders.bottom:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", 0, 0)
    borders.bottom:SetHeight(thickness)
    
    borders.left:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 0, 0)
    borders.left:SetPoint("BOTTOMLEFT", tooltip, "BOTTOMLEFT", 0, 0)
    borders.left:SetWidth(thickness)
    
    borders.right:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", 0, 0)
    borders.right:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", 0, 0)
    borders.right:SetWidth(thickness)
    
    for _, border in pairs(borders) do
        border:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    end
    
    -- Show frames
    styling.bgFrame:Show()
    styling.borderFrame:Show()
end

-- Apply advanced styling with color logic to tooltips
function TooltipStyling:ApplyAdvancedStyling(tooltip, unit)
    if not EpicTipDB or not tooltip then return end
    
    -- Provide fallback default values if database values are nil
    local bgColor = EpicTipDB.backgroundColor or { r = 0, g = 0, b = 0, a = 0.8 }
    local borderColor = EpicTipDB.borderColor or { r = 0.3, g = 0.3, b = 0.4, a = 1.0 }
    local opacity = EpicTipDB.backgroundOpacity or 0.8
    
    -- Check for reaction-based coloring
    if unit and EpicTipDB.reactionColoredBackground then
        local reactionBg, reactionBorder = ET.ColorUtils:GetReactionColor(unit)
        if reactionBg then
            bgColor = reactionBg
        end
        if reactionBorder then
            borderColor = reactionBorder
        end
    end
    
    -- Check for class-colored background
    if unit and UnitIsPlayer(unit) and EpicTipDB.classColoredBackground then
        local _, classFileName = UnitClass(unit)
        if classFileName and RAID_CLASS_COLORS[classFileName] then
            local classColor = RAID_CLASS_COLORS[classFileName]
            bgColor = { r = classColor.r, g = classColor.g, b = classColor.b, a = bgColor.a or 0.8 }
        end
    end
    
    -- Check for class-colored border
    if unit and UnitIsPlayer(unit) and EpicTipDB.classColoredBorder then
        local _, classFileName = UnitClass(unit)
        if classFileName and RAID_CLASS_COLORS[classFileName] then
            local classColor = RAID_CLASS_COLORS[classFileName]
            borderColor = { r = classColor.r, g = classColor.g, b = classColor.b, a = 1 }
        end
    end
    
    -- Ensure we have valid color tables before applying styling
    if not bgColor or type(bgColor) ~= "table" then
        bgColor = { r = 0, g = 0, b = 0, a = 0.8 }
    end
    if not borderColor or type(borderColor) ~= "table" then
        borderColor = { r = 0.3, g = 0.3, b = 0.4, a = 1.0 }
    end
    
    -- Apply styling
    self:ApplyModernStyling(tooltip, bgColor, borderColor, opacity)
end

-- Clean up tooltip styling on hide
function TooltipStyling:CleanupTooltipStyling(tooltip)
    if tooltip.epicTipStyling then
        local styling = tooltip.epicTipStyling
        
        -- Return pooled frames if they were obtained from the pool
        if styling.isPooled and ET.MemoryPool and ET.MemoryPool.ReturnFrame then
            if styling.bgFrame then
                ET.MemoryPool.ReturnFrame(styling.bgFrame, "background")
            end
            if styling.borderFrame then
                ET.MemoryPool.ReturnFrame(styling.borderFrame, "border")
            end
        else
            -- Standard cleanup for non-pooled frames
            if styling.bgFrame then 
                styling.bgFrame:Hide()
                styling.bgFrame:ClearAllPoints()
            end
            if styling.borderFrame then 
                styling.borderFrame:Hide()
                styling.borderFrame:ClearAllPoints()
            end
        end
        if styling.borders then
            for _, border in pairs(styling.borders) do
                if border then border:ClearAllPoints() end
            end
        end
        
        tooltip.epicTipStyling = nil
    end
    
    -- Reset duplicate tracking flags
    tooltip.epicTipHealthAdded = nil
    tooltip.epicTipProcessed = nil
end
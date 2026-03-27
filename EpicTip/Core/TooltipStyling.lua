local addonName, ET = ...

-- Tooltip Styling Module - Extracted from bloated Tooltip.lua
-- Handles background, border, and visual styling following WoW 11.2 standards
--
-- TAINT-SAFE: This module NEVER writes custom properties to Blizzard tooltip frames.
-- All styling frame references are stored in private module-level lookup tables
-- keyed by tostring(tooltip). This prevents tainting GameTooltip which would cause
-- Blizzard's SetWatch() on GameTooltipStatusBar to fail with "Lua Taint: EpicTip".

ET.TooltipStyling = ET.TooltipStyling or {}
local TooltipStyling = ET.TooltipStyling

-- TAINT-SAFE: Private lookup tables for styling state.
-- These persist across tooltip hide/show cycles (the child frames we create are
-- parented to the tooltip and survive hide/show). Using external tables instead of
-- writing tooltip.epicTipStyling / tooltip.epicTipStylingHooked to the frame.
local stylingFrames = {}  -- tostring(tooltip) -> { bgFrame, borderFrame, bgTexture, borders, isPooled }
local stylingHooked = {}  -- tostring(tooltip) -> true (OnSizeChanged hook installed)

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

    -- TAINT-SAFE: Look up styling frames from private table, not tooltip frame
    local id = tostring(tooltip)
    local styling = stylingFrames[id]

    if not styling then
        local bgFrame, borderFrame

        -- Use frame pooling if available
        if ET.MemoryPool and ET.MemoryPool.GetFrame then
            bgFrame = ET.MemoryPool.GetFrame("background", nil, tooltip)
            borderFrame = ET.MemoryPool.GetFrame("border", nil, tooltip)
        else
            -- Fallback to direct creation with proper strata
            bgFrame = CreateFrame("Frame", nil, tooltip, "BackdropTemplate")
            borderFrame = CreateFrame("Frame", nil, tooltip)
        end

        if not bgFrame or not borderFrame then
            return
        end

        styling = {
            bgFrame = bgFrame,
            borderFrame = borderFrame,
            isPooled = ET.MemoryPool and ET.MemoryPool.GetFrame and true or false
        }

        -- Create background texture with explicit draw layer
        styling.bgTexture = styling.bgFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
        styling.bgTexture:SetAllPoints(styling.bgFrame)

        -- Create border textures
        styling.borders = {}
        for _, side in ipairs({"top", "bottom", "left", "right"}) do
            styling.borders[side] = styling.borderFrame:CreateTexture(nil, "OVERLAY")
        end

        -- Store in private table (NEVER on the tooltip frame)
        stylingFrames[id] = styling

        -- Hook OnSizeChanged ONLY once to ensure background always covers the tooltip
        if not stylingHooked[id] then
            tooltip:HookScript("OnSizeChanged", function(self)
                if not EpicTipDB or not EpicTipDB.enabled then return end
                local s = stylingFrames[tostring(self)]
                if s and s.bgFrame then
                    s.bgFrame:SetAllPoints(self)
                    s.borderFrame:SetAllPoints(self)
                    -- Force visibility when size changes
                    s.bgFrame:Show()
                    s.borderFrame:Show()
                    -- Re-hide Blizzard's NineSlice - it can re-appear after resize/content refresh
                    if self.NineSlice then
                        pcall(function()
                            self.NineSlice:SetAlpha(0)
                            self.NineSlice:Hide()
                        end)
                    end
                end
            end)
            stylingHooked[id] = true
        end
    end

    -- Position frames with proper stacking order
    styling.bgFrame:SetAllPoints(tooltip)
    styling.borderFrame:SetAllPoints(tooltip)

    -- CRITICAL FIX: Set frame strata and levels to ensure visibility
    -- Background must be visible but behind text
    styling.bgFrame:SetFrameStrata("TOOLTIP")
    styling.borderFrame:SetFrameStrata("TOOLTIP")

    local tooltipLevel = 0
    if tooltip.GetFrameLevel then
        local ok, lvl = pcall(tooltip.GetFrameLevel, tooltip)
        if ok and type(lvl) == "number" then
            tooltipLevel = lvl
        end
    end
    styling.bgFrame:SetFrameLevel(tooltipLevel)
    styling.borderFrame:SetFrameLevel(tooltipLevel + 1)

    -- Ensure background texture is on the proper layer
    if styling.bgTexture then
        styling.bgTexture:SetDrawLayer("BACKGROUND", -8)
    end

    -- Apply background color with proper opacity handling
    local finalAlpha = (bgColor.a or 0.8) * (opacity or 0.8)
    if finalAlpha < 0 then finalAlpha = 0 end
    if finalAlpha > 1 then finalAlpha = 1 end
    if styling.bgTexture then
        styling.bgTexture:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, finalAlpha)
    end

    -- Position and color borders
    local thickness = (EpicTipDB and EpicTipDB.borderWidth) or 2
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

    -- Force frames to show and be visible
    styling.bgFrame:Show()
    styling.borderFrame:Show()
    styling.bgFrame:SetAlpha(1)
    styling.borderFrame:SetAlpha(1)

    -- Ensure textures are visible
    if styling.bgTexture then
        styling.bgTexture:Show()
    end
    for _, border in pairs(borders) do
        if border then
            border:Show()
        end
    end

    -- Only after our frames are ready, hide Blizzard's defaults (so failures don't leave a blank tooltip).
    if tooltip.NineSlice then
        pcall(function()
            tooltip.NineSlice:SetAlpha(0)
            tooltip.NineSlice:Hide()
        end)
    end
    if tooltip.SetBackdrop then
        pcall(tooltip.SetBackdrop, tooltip, nil)
    end
end

-- Apply advanced styling with color logic to tooltips
function TooltipStyling:ApplyAdvancedStyling(tooltip, unit)
    if not EpicTipDB or not tooltip then return end

    -- Skip WQ tooltips entirely — let Blizzard render them natively
    if ET.Tooltip and ET.Tooltip.IsWorldQuestTooltip and ET.Tooltip.IsWorldQuestTooltip(tooltip) then
        return
    end

    -- Provide fallback default values if database values are nil
    local bgColor = EpicTipDB.backgroundColor or { r = 0, g = 0, b = 0, a = 0.8 }
    local borderColor = EpicTipDB.borderColor or { r = 0.3, g = 0.3, b = 0.4, a = 1.0 }
    local opacity = EpicTipDB.backgroundOpacity or 0.8

    -- Check for reaction-based coloring
    if unit and EpicTipDB.reactionColoredBackground and ET.ColorUtils and ET.ColorUtils.GetReactionColor then
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
-- TAINT-SAFE: Reads from private table, never from tooltip frame properties
function TooltipStyling:CleanupTooltipStyling(tooltip)
    local id = tostring(tooltip)
    local styling = stylingFrames[id]

    if styling then
        -- Just hide frames, don't destroy them (they persist for reuse)
        if styling.bgFrame then
            styling.bgFrame:Hide()
        end
        if styling.borderFrame then
            styling.borderFrame:Hide()
        end
    end

    -- Restore Blizzard's NineSlice on hide so the next show cycle starts clean
    if tooltip.NineSlice then
        pcall(function()
            tooltip.NineSlice:SetAlpha(1)
            tooltip.NineSlice:Show()
        end)
    end

    -- Processing flags (healthAdded, processed) are now managed by
    -- ET.TooltipState:Clear() in the OnHide hook - no need to touch them here
end

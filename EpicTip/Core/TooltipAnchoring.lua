local addonName, ET = ...

-- Tooltip Anchoring Module - Extracted from bloated Tooltip.lua  
-- Handles smart positioning and anchor logic following WoW 11.2 standards

ET.TooltipAnchoring = ET.TooltipAnchoring or {}
local TooltipAnchoring = ET.TooltipAnchoring

-- Smart anchor positioning based on cursor location
function TooltipAnchoring:SmartAnchor(tooltip, parent)
    if not tooltip or not parent then return end
    
    local screenWidth = GetScreenWidth() * UIParent:GetEffectiveScale()
    local screenHeight = GetScreenHeight() * UIParent:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    
    local anchor = "ANCHOR_BOTTOMRIGHT"
    local xOffset, yOffset = 0, 0
    
    -- Determine best position based on cursor location
    if cursorX > screenWidth / 2 then
        anchor = "ANCHOR_BOTTOMLEFT"
        xOffset = -10
    else
        anchor = "ANCHOR_BOTTOMRIGHT"
        xOffset = 10
    end
    
    if cursorY < screenHeight / 2 then
        -- Use Blizzard's native anchor constants when available
        if anchor == "ANCHOR_BOTTOMRIGHT" then
            anchor = "ANCHOR_TOPRIGHT"
        elseif anchor == "ANCHOR_BOTTOMLEFT" then
            anchor = "ANCHOR_TOPLEFT"
        end
        yOffset = 10
    else
        yOffset = -10
    end
    
    tooltip:SetOwner(parent, anchor, xOffset, yOffset)
end

-- Setup anchor hook system - part of tooltip event handling
function TooltipAnchoring:SetupAnchorHook()
    if not _G.GameTooltip_SetDefaultAnchor then
        return
    end
    
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        if not EpicTipDB or not EpicTipDB.enabled then return end
        
        local anchoring = EpicTipDB.anchoring or "default"
        
        if anchoring == "mouse" then
            tooltip:SetOwner(parent, "ANCHOR_CURSOR")
        elseif anchoring == "smart" then
            self:SmartAnchor(tooltip, parent)
        end
    end)
end
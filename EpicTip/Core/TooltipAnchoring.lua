local addonName, ET = ...

-- Tooltip Anchoring Module - Extracted from bloated Tooltip.lua
-- Handles smart positioning, fixed positioning, and anchor logic following WoW 11.2 standards

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

-- Fixed anchor positioning at a user-chosen screen location
function TooltipAnchoring:FixedAnchor(tooltip, parent)
    if not tooltip or not parent then return end

    local anchorPoint = EpicTipDB.fixedAnchorPoint or "BOTTOMRIGHT"
    local x = EpicTipDB.fixedAnchorX or -50
    local y = EpicTipDB.fixedAnchorY or 100

    tooltip:SetOwner(parent, "ANCHOR_NONE")
    tooltip:ClearAllPoints()
    tooltip:SetPoint(anchorPoint, UIParent, anchorPoint, x, y)
end

-- Create draggable anchor frame for visual positioning
function TooltipAnchoring:CreateAnchorFrame()
    if self.anchorFrame then return self.anchorFrame end

    local frame = CreateFrame("Frame", "EpicTipAnchorFrame", UIParent, "BackdropTemplate")
    frame:SetSize(40, 40)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")

    -- Backdrop styling
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetBackdropBorderColor(1, 0.82, 0, 1)

    -- Crosshair texture
    local crosshair = frame:CreateTexture(nil, "ARTWORK")
    crosshair:SetTexture("Interface\\Cursor\\CrossHairs")
    crosshair:SetSize(24, 24)
    crosshair:SetPoint("CENTER")
    crosshair:SetVertexColor(1, 0.82, 0)

    -- Label
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", frame, "BOTTOM", 0, -4)
    label:SetText("|cFFFFD700EpicTip Anchor|r")

    -- Drag hint
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOP", label, "BOTTOM", 0, -2)
    hint:SetText("|cFF999999Drag to position|r")

    -- Position from saved settings
    local anchorPoint = EpicTipDB and EpicTipDB.fixedAnchorPoint or "BOTTOMRIGHT"
    local x = EpicTipDB and EpicTipDB.fixedAnchorX or -50
    local y = EpicTipDB and EpicTipDB.fixedAnchorY or 100
    frame:ClearAllPoints()
    frame:SetPoint(anchorPoint, UIParent, anchorPoint, x, y)

    -- Drag handlers
    frame:SetScript("OnDragStart", function(f)
        f:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        self:SaveAnchorPosition(f)
    end)

    -- Right-click to hide
    frame:SetScript("OnMouseUp", function(f, button)
        if button == "RightButton" then
            f:Hide()
        end
    end)

    -- Auto-hide timer
    frame.autoHideTimer = nil
    frame:SetScript("OnShow", function(f)
        if f.autoHideTimer then
            f.autoHideTimer:Cancel()
        end
        f.autoHideTimer = C_Timer.NewTimer(15, function()
            f:Hide()
        end)
    end)

    frame:SetScript("OnHide", function(f)
        if f.autoHideTimer then
            f.autoHideTimer:Cancel()
            f.autoHideTimer = nil
        end
    end)

    frame:Hide()
    self.anchorFrame = frame
    return frame
end

-- Determine nearest anchor point from frame position
function TooltipAnchoring:SaveAnchorPosition(frame)
    if not frame or not EpicTipDB then return end

    local scale = UIParent:GetEffectiveScale()
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()

    -- Get frame center in UI coordinates
    local centerX, centerY = frame:GetCenter()
    if not centerX or not centerY then return end

    -- Determine which third of the screen we're in (horizontal and vertical)
    local xZone = centerX < screenWidth / 3 and "LEFT" or centerX > screenWidth * 2 / 3 and "RIGHT" or ""
    local yZone = centerY < screenHeight / 3 and "BOTTOM" or centerY > screenHeight * 2 / 3 and "TOP" or ""

    local anchorPoint
    if yZone == "" and xZone == "" then
        anchorPoint = "CENTER"
    elseif yZone == "" then
        anchorPoint = xZone
    elseif xZone == "" then
        anchorPoint = yZone
    else
        anchorPoint = yZone .. xZone
    end

    -- Calculate offset relative to the chosen anchor point on UIParent
    local refX, refY = self:GetAnchorCoordinates(anchorPoint, screenWidth, screenHeight)
    local offsetX = centerX - refX
    local offsetY = centerY - refY

    -- Save to DB
    EpicTipDB.fixedAnchorPoint = anchorPoint
    EpicTipDB.fixedAnchorX = math.floor(offsetX + 0.5)
    EpicTipDB.fixedAnchorY = math.floor(offsetY + 0.5)

    if ET and ET.SaveConfig then ET:SaveConfig() end

    -- Reposition frame cleanly to the computed anchor
    frame:ClearAllPoints()
    frame:SetPoint(anchorPoint, UIParent, anchorPoint, EpicTipDB.fixedAnchorX, EpicTipDB.fixedAnchorY)
end

-- Get the screen coordinates of a named anchor point
function TooltipAnchoring:GetAnchorCoordinates(point, screenWidth, screenHeight)
    local coords = {
        TOPLEFT     = { 0, screenHeight },
        TOP         = { screenWidth / 2, screenHeight },
        TOPRIGHT    = { screenWidth, screenHeight },
        LEFT        = { 0, screenHeight / 2 },
        CENTER      = { screenWidth / 2, screenHeight / 2 },
        RIGHT       = { screenWidth, screenHeight / 2 },
        BOTTOMLEFT  = { 0, 0 },
        BOTTOM      = { screenWidth / 2, 0 },
        BOTTOMRIGHT = { screenWidth, 0 },
    }
    local c = coords[point] or coords["BOTTOMRIGHT"]
    return c[1], c[2]
end

-- Show the draggable anchor frame
function TooltipAnchoring:ShowAnchorFrame()
    local frame = self:CreateAnchorFrame()

    -- Refresh position from DB
    local anchorPoint = EpicTipDB and EpicTipDB.fixedAnchorPoint or "BOTTOMRIGHT"
    local x = EpicTipDB and EpicTipDB.fixedAnchorX or -50
    local y = EpicTipDB and EpicTipDB.fixedAnchorY or 100
    frame:ClearAllPoints()
    frame:SetPoint(anchorPoint, UIParent, anchorPoint, x, y)

    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

-- Setup anchor hook system - part of tooltip event handling
function TooltipAnchoring:SetupAnchorHook()
    if not _G.GameTooltip_SetDefaultAnchor then
        return
    end

    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        if not EpicTipDB or not EpicTipDB.enabled then return end
        
        -- Skip World Quest tooltips to prevent interference with World Quest display
        if ET.Tooltip and ET.Tooltip.IsWorldQuestTooltip and ET.Tooltip.IsWorldQuestTooltip(tooltip) then return end

        local anchoring = EpicTipDB.anchoring or "default"

        if anchoring == "mouse" then
            tooltip:SetOwner(parent, "ANCHOR_CURSOR")
        elseif anchoring == "smart" then
            self:SmartAnchor(tooltip, parent)
        elseif anchoring == "fixed" then
            self:FixedAnchor(tooltip, parent)
        end
    end)
end

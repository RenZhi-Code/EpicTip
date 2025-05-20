-- Ensure the global JustTheTip table exists
JustTheTip = JustTheTip or {}

-- Default settings structure
local DEFAULTS = {
    enabled = true,
    showIlvl = true,
    showTarget = true,
    anchorToMouse = true,
    scale = 1.0,
    hideInCombat = false,
}

-- Create a section box with a consistent look
local function CreateSectionBox(parent, title, description, height)
    local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    section:SetSize(560, height)
    section:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    section:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    section:SetBackdropBorderColor(0.4, 0.4, 0.4)

    local header = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetText(title)
    header:SetTextColor(0.5, 0.8, 1)

    local desc = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    desc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
    desc:SetWidth(540)
    desc:SetJustifyH("LEFT")
    desc:SetText(description)
    desc:SetTextColor(0.8, 0.8, 0.8)

    return section
end

-- Create the main config panel
local function CreateConfigPanel()
    local panel = CreateFrame("Frame", "JustTheTipConfigPanel", UIParent, "BackdropTemplate")
    panel.name = "JustTheTip"
    panel:SetSize(620, 600)
    panel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    panel:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    panel:SetBackdropBorderColor(0.4, 0.4, 0.4)

    -- Header
    local header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOP", 0, -15)
    header:SetText("JustTheTip Settings")
    header:SetTextColor(0.5, 0.8, 1)

    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -45)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 15)

    -- Content Frame
    local content = CreateFrame("Frame")
    content:SetSize(590, 950)
    scrollFrame:SetScrollChild(content)

    -- Track the y-offset for stacking sections
    local yOffset = -15

    -- Function to add a settings section
    local function AddSettingsSection(title, description, height, setupFunction)
        local section = CreateSectionBox(content, title, description, height)
        section:SetPoint("TOPLEFT", 15, yOffset)
        yOffset = yOffset - height - 25 -- Add spacing between sections
        if setupFunction then
            setupFunction(section)
        end
        return section
    end

    -- Initialize settings if not already set
    if not JustTheTipDB then
        JustTheTipDB = CopyTable(DEFAULTS)
    else
        for k, v in pairs(DEFAULTS) do
            if JustTheTipDB[k] == nil then
                JustTheTipDB[k] = v
            end
        end
    end

    -- Enable Tooltip Section
    AddSettingsSection("Enable Tooltip", "Toggle the tooltip functionality", 100, function(section)
        local checkbox = CreateFrame("CheckButton", nil, section, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", section, "TOPLEFT", 20, -50)
        checkbox.Text:SetText("Enable Tooltip")
        checkbox:SetChecked(JustTheTipDB.enabled)
        checkbox:SetScript("OnClick", function(self)
            JustTheTipDB.enabled = self:GetChecked()
        end)
    end)

    -- Show Item Level Section
    AddSettingsSection("Show Item Level", "Display the item level in the tooltip", 100, function(section)
        local checkbox = CreateFrame("CheckButton", nil, section, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", section, "TOPLEFT", 20, -50)
        checkbox.Text:SetText("Show Item Level")
        checkbox:SetChecked(JustTheTipDB.showIlvl)
        checkbox:SetScript("OnClick", function(self)
            JustTheTipDB.showIlvl = self:GetChecked()
        end)
    end)

    -- Show Target Section
    AddSettingsSection("Show Target", "Display the target's name in the tooltip", 100, function(section)
        local checkbox = CreateFrame("CheckButton", nil, section, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", section, "TOPLEFT", 20, -50)
        checkbox.Text:SetText("Show Target")
        checkbox:SetChecked(JustTheTipDB.showTarget)
        checkbox:SetScript("OnClick", function(self)
            JustTheTipDB.showTarget = self:GetChecked()
        end)
    end)

    -- Anchor Tooltip to Mouse Cursor Section
    AddSettingsSection("Anchor Tooltip to Mouse Cursor", "Anchor the tooltip to the mouse cursor", 100, function(section)
        local checkbox = CreateFrame("CheckButton", nil, section, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", section, "TOPLEFT", 20, -50)
        checkbox.Text:SetText("Anchor Tooltip to Mouse Cursor")
        checkbox:SetChecked(JustTheTipDB.anchorToMouse)
        checkbox:SetScript("OnClick", function(self)
            JustTheTipDB.anchorToMouse = self:GetChecked()
        end)
    end)

    -- Hide Tooltip in Combat Section
    AddSettingsSection("Hide Tooltip in Combat", "Hide the tooltip when in combat", 100, function(section)
        local checkbox = CreateFrame("CheckButton", nil, section, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", section, "TOPLEFT", 20, -50)
        checkbox.Text:SetText("Hide Tooltip in Combat")
        checkbox:SetChecked(JustTheTipDB.hideInCombat)
        checkbox:SetScript("OnClick", function(self)
            JustTheTipDB.hideInCombat = self:GetChecked()
        end)
    end)

    -- Tooltip Scale Section
    AddSettingsSection("Tooltip Scale", "Adjust the size of the tooltip", 150, function(section)
        local scaleSlider = CreateFrame("Slider", "JustTheTipScaleSlider", section, "OptionsSliderTemplate")
        scaleSlider:SetWidth(220)
        scaleSlider:SetHeight(20)
        scaleSlider:SetOrientation('HORIZONTAL')
        scaleSlider:SetMinMaxValues(0.5, 2.0)
        scaleSlider:SetValueStep(0.05)
        scaleSlider:SetObeyStepOnDrag(true)
        scaleSlider:SetPoint("TOPLEFT", section, "TOPLEFT", 20, -50)
        scaleSlider:SetValue(JustTheTipDB.scale)
        _G[scaleSlider:GetName().."Low"]:SetText("0.5")
        _G[scaleSlider:GetName().."High"]:SetText("2.0")
        _G[scaleSlider:GetName().."Text"]:SetText("Tooltip Scale")

        scaleSlider:SetScript("OnValueChanged", function(self, value)
            JustTheTipDB.scale = value
        end)
    end)

    -- Register with modern Settings API
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "JustTheTip")
        Settings.RegisterAddOnCategory(category)
    end

    return panel, AddSettingsSection
end

-- Initialize and store the panel and section adder in the global JustTheTip table
JustTheTip.panel, JustTheTip.AddSettingsSection = CreateConfigPanel()
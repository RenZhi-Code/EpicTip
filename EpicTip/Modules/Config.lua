local addonName, ET = ...

ET.Config = ET.Config or {}
local Config = ET.Config
local L = ET.L

-- Default settings with descriptions
Config.defaults = {
    -- CORE FUNCTIONALITY
    enabled = true,              -- Master switch for entire addon
    enableInspect = true,        -- Allow inspecting other players for detailed info
    
    -- TOOLTIP BEHAVIOR  
    anchorToMouse = true,        -- Tooltips follow mouse cursor vs fixed position
    scale = 1.0,                 -- Tooltip size multiplier (0.5-2.0)
    hideHealthBar = false,       -- Remove health bars from player tooltips
    hideNPCHealthBar = false,    -- Remove health bars from NPC tooltips
    hideInCombat = false,        -- Hide enhanced tooltips during combat
    
    -- PLAYER INFORMATION
    showSpec = true,             -- Show player specialization (e.g., "Protection Warrior")
    showTarget = true,           -- Show what the unit is currently targeting
    showClassIcon = true,        -- Display class icons next to player names
    showRoleIcon = true,         -- Show role icons (tank/healer/dps)
    showMythicRating = true,     -- Display Mythic+ rating/score
    showPvPRating = true,        -- Show PvP rating/ranking
    
    -- ITEM INFORMATION
    showIlvl = true,             -- Display item level on equipment
    showItemInfo = true,         -- Enhanced item details and comparisons
    showStatValues = true,       -- Calculated stat weights and upgrade indicators
    
    -- FONT CONFIGURATION
    fontFamily = "Fonts\\FRIZQT__.TTF",  -- Default WoW font
    titleFontSize = 14,          -- Font size for tooltip titles
    infoFontSize = 12,           -- Font size for general information
    headerFontSize = 13,         -- Font size for section headers
    descriptionFontSize = 11,    -- Font size for descriptions

    -- Production optimized - debug features removed
        
    }

function Config.InitializeDatabase()
    if not EpicTipDB then
        EpicTipDB = CopyTable(Config.defaults)
    else
        -- Use efficient iteration instead of pairs() for better performance
        for key in next, Config.defaults do
            if EpicTipDB[key] == nil then
                EpicTipDB[key] = Config.defaults[key]
            end
        end
        
        -- Minimap settings removed - not used in current version
    end
end

function Config.CreateOptionsPanel()
    -- Use frame pool for config panel creation
    local panel
    if ET.Tooltip and ET.Tooltip.FrameFactory then
        panel = ET.Tooltip.FrameFactory:GetFrame("config", nil, UIParent)
        -- Note: Pooled frames cannot be renamed after creation
    else
        -- Fallback for initialization order - create with name
        panel = CreateFrame("Frame", "EpicTipOptions", UIParent)
    end
    
    panel.name = L["EpicTip"]

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L["EpicTip"] .. " - " .. L["Options"])

    local function CreateCheckbox(label, anchor, dbKey, description)
        local checkbox
        if ET.Tooltip and ET.Tooltip.FrameFactory then
            checkbox = ET.Tooltip.FrameFactory:GetFrame("config", "InterfaceOptionsCheckButtonTemplate", panel)
            -- Manual setup for pooled checkbox
            checkbox:SetSize(26, 26)
            if not checkbox.Text then
                checkbox.Text = checkbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                checkbox.Text:SetPoint("LEFT", checkbox, "RIGHT", 2, 1)
            end
        else
            -- Fallback creation
            checkbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
        end
        
        checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
        checkbox.Text:SetText(label)
        checkbox:SetChecked(EpicTipDB[dbKey])
        checkbox:SetScript("OnClick", function(self)
            EpicTipDB[dbKey] = self:GetChecked()
            if ET.SaveConfig then
                ET:SaveConfig()
            end
        end)
        
        -- Add description text if provided
        if description then
            local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            desc:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 20, -2)
            desc:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -20, 0)
            desc:SetJustifyH("LEFT")
            desc:SetTextColor(0.8, 0.8, 0.8)
            desc:SetText(description)
            desc:SetWordWrap(true)
            checkbox.description = desc
        end
        
        return checkbox
    end

    local enableCheckbox = CreateCheckbox(L["Enable Tooltip"], title, "enabled", 
        "Master switch for the entire addon. When disabled, all tooltip enhancements are turned off.")
    
    local ilvlCheckbox = CreateCheckbox(L["Show Item Level"], enableCheckbox.description or enableCheckbox, "showIlvl",
        "Displays the item level of equipment in tooltips. Useful for quickly comparing gear upgrades.")
    
    local specCheckbox = CreateCheckbox(L["Show Specialization"], ilvlCheckbox.description or ilvlCheckbox, "showSpec",
        "Shows player specialization (e.g., 'Protection Warrior') in unit tooltips when inspecting other players.")
    
    local targetCheckbox = CreateCheckbox(L["Show Target"], specCheckbox.description or specCheckbox, "showTarget",
        "Displays what the unit you're hovering over is currently targeting. Helpful in PvP and group content.")
    
    local anchorCheckbox = CreateCheckbox(L["Anchor Tooltip to Mouse Cursor"], targetCheckbox.description or targetCheckbox, "anchorToMouse",
        "Makes tooltips follow your mouse cursor instead of appearing in fixed positions. More convenient for scanning multiple items.")
    
    local healthBarCheckbox = CreateCheckbox(L["Hide Tooltip Health Bar"], anchorCheckbox.description or anchorCheckbox, "hideHealthBar",
        "Removes the health bar from player tooltips for a cleaner appearance. Health percentage will still be shown as text.")
    
    local npcHealthBarCheckbox = CreateCheckbox(L["Hide NPC Health Bar"], healthBarCheckbox.description or healthBarCheckbox, "hideNPCHealthBar",
        "Removes the health bar from NPC tooltips for a cleaner appearance. Health percentage will still be shown as text.")
    
    local hideCombatCheckbox = CreateCheckbox(L["Hide Tooltip In Combat"], npcHealthBarCheckbox.description or npcHealthBarCheckbox, "hideInCombat",
        "Automatically hides enhanced tooltips during combat to reduce screen clutter and improve performance.")
    
    local classIconCheckbox = CreateCheckbox(L["Show Class Icon"], hideCombatCheckbox.description or hideCombatCheckbox, "showClassIcon",
        "Displays class icons next to player names in tooltips. Makes it easier to identify classes at a glance.")
    
    local roleIconCheckbox = CreateCheckbox(L["Show Role Icon"], classIconCheckbox.description or classIconCheckbox, "showRoleIcon",
        "Shows role icons (tank, healer, DPS) for players in tooltips. Useful for group composition awareness.")
    
    local mythicCheckbox = CreateCheckbox(L["Show Mythic+ Rating"], roleIconCheckbox.description or roleIconCheckbox, "showMythicRating",
        "Displays Mythic+ rating/score in player tooltips. Helps assess player experience with high-level dungeon content.")
    
    local pvpCheckbox = CreateCheckbox(L["Show PvP Rating"], mythicCheckbox.description or mythicCheckbox, "showPvPRating",
        "Shows PvP rating/ranking in player tooltips. Useful for assessing PvP experience and skill level.")
    
    local itemInfoCheckbox = CreateCheckbox(L["Show Item Info"], pvpCheckbox.description or pvpCheckbox, "showItemInfo",
        "Enables enhanced item information including comparisons, upgrade indicators, and detailed stats.")
    
    local statValuesCheckbox = CreateCheckbox(L["Show Stat Values"], itemInfoCheckbox.description or itemInfoCheckbox, "showStatValues",
        "Displays calculated stat values and weights for items. Helps determine if an item is an upgrade for your character.")
    

    
    -- Debug checkbox removed for production

    local scaleSlider
    if ET.MemoryPool and ET.MemoryPool.GetFrame then
        scaleSlider = ET.MemoryPool.GetFrame("generic", "OptionsSliderTemplate", panel)
        -- Note: Pooled frames cannot be renamed after creation
    else
        -- Fallback creation with name
        scaleSlider = CreateFrame("Slider", "EpicTipScaleSlider", panel, "OptionsSliderTemplate")
    end
    
    scaleSlider:SetWidth(200)
    scaleSlider:SetHeight(20)
    scaleSlider:SetOrientation('HORIZONTAL')
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider:SetPoint("TOPLEFT", statValuesCheckbox.description or statValuesCheckbox, "BOTTOMLEFT", 0, -40)
    scaleSlider:SetValue(EpicTipDB.scale)
    EpicTipScaleSliderLow:SetText("0.5")
    EpicTipScaleSliderHigh:SetText("2.0")
    EpicTipScaleSliderText:SetText(L["Tooltip Scale"])

    -- Add description for scale slider
    local scaleDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    scaleDesc:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -5)
    scaleDesc:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -20, 0)
    scaleDesc:SetJustifyH("LEFT")
    scaleDesc:SetTextColor(0.8, 0.8, 0.8)
    scaleDesc:SetText("Adjusts the size of all tooltips. Use smaller values for less screen space, larger for better readability.")
    scaleDesc:SetWordWrap(true)

    scaleSlider:SetScript("OnValueChanged", function(self, value)
        EpicTipDB.scale = value
        if ET.SaveConfig then
            ET:SaveConfig()
        end
    end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, L["EpicTip"])
    Settings.RegisterAddOnCategory(category)
    
    return panel
end

function Config.SetupSlashCommands()
    -- NOTE: Slash commands are now handled by Core.lua using AceConsole
    -- to prevent conflicts with multiple registration systems
    -- This function is maintained for compatibility but does not register commands
end
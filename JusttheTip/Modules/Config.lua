local addonName, JTT = ...

JTT.Config = JTT.Config or {}
local Config = JTT.Config
local L = JTT.L

-- Default settings with descriptions
Config.defaults = {
    -- CORE FUNCTIONALITY
    enabled = true,              -- Master switch for entire addon
    enableInspect = true,        -- Allow inspecting other players for detailed info
    
    -- TOOLTIP BEHAVIOR  
    anchorToMouse = true,        -- Tooltips follow mouse cursor vs fixed position
    scale = 1.0,                 -- Tooltip size multiplier (0.5-2.0)
    hideHealthBar = false,       -- Remove health bars from unit tooltips
    hideInCombat = false,        -- Hide enhanced tooltips during combat
    
    -- PLAYER INFORMATION
    showSpec = true,             -- Show player specialization (e.g., "Protection Warrior")
    showTarget = true,           -- Show what the unit is currently targeting
    showClassIcon = true,        -- Display class icons next to player names
    showRoleIcon = true,         -- Show role icons (tank/healer/dps)
    showMythicRating = false,    -- Display Mythic+ rating/score (can be intrusive)
    showPvPRating = false,       -- Show PvP rating/ranking (can be intrusive)
    
    -- ITEM INFORMATION
    showIlvl = true,             -- Display item level on equipment
    showItemInfo = true,         -- Enhanced item details and comparisons
    showStatValues = true,       -- Calculated stat weights and upgrade indicators

    
    -- DEBUGGING & DEVELOPMENT
    debugMode = false,           -- Enable debug output (only for troubleshooting)
        
    }

function Config.InitializeDatabase()
    if not JustTheTipDB then
        JustTheTipDB = CopyTable(Config.defaults)
    else
        for k, v in pairs(Config.defaults) do
            if JustTheTipDB[k] == nil then
                JustTheTipDB[k] = v
            end
        end
        
        -- Handle nested minimap table
        if not JustTheTipDB.minimap then
            JustTheTipDB.minimap = CopyTable(Config.defaults.minimap)
        else
            for k, v in pairs(Config.defaults.minimap) do
                if JustTheTipDB.minimap[k] == nil then
                    JustTheTipDB.minimap[k] = v
                end
            end
        end
    end
end

function Config.CreateOptionsPanel()
    local panel = CreateFrame("Frame", "JustTheTipOptions", UIParent)
    panel.name = L["Just the Tip"]

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L["Just the Tip"] .. " - " .. L["Options"])

    local function CreateCheckbox(label, anchor, dbKey, description)
        local checkbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
        checkbox.Text:SetText(label)
        checkbox:SetChecked(JustTheTipDB[dbKey])
        checkbox:SetScript("OnClick", function(self)
            JustTheTipDB[dbKey] = self:GetChecked()
            if JTT.SaveConfig then
                JTT:SaveConfig()
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
        "Removes the health bar from unit tooltips for a cleaner appearance. Health percentage will still be shown as text.")
    
    local hideCombatCheckbox = CreateCheckbox(L["Hide Tooltip In Combat"], healthBarCheckbox.description or healthBarCheckbox, "hideInCombat",
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
    
    local debugCheckbox = CreateCheckbox(L["Debug Mode"], statValuesCheckbox.description or statValuesCheckbox, "debugMode",
        "Enables debug output in chat. Only enable this if you're troubleshooting issues or reporting bugs.")

    local scaleSlider = CreateFrame("Slider", "JustTheTipScaleSlider", panel, "OptionsSliderTemplate")
    scaleSlider:SetWidth(200)
    scaleSlider:SetHeight(20)
    scaleSlider:SetOrientation('HORIZONTAL')
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider:SetPoint("TOPLEFT", debugCheckbox.description or debugCheckbox, "BOTTOMLEFT", 0, -40)
    scaleSlider:SetValue(JustTheTipDB.scale)
    JustTheTipScaleSliderLow:SetText("0.5")
    JustTheTipScaleSliderHigh:SetText("2.0")
    JustTheTipScaleSliderText:SetText(L["Tooltip Scale"])

    -- Add description for scale slider
    local scaleDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    scaleDesc:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -5)
    scaleDesc:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -20, 0)
    scaleDesc:SetJustifyH("LEFT")
    scaleDesc:SetTextColor(0.8, 0.8, 0.8)
    scaleDesc:SetText("Adjusts the size of all tooltips. Use smaller values for less screen space, larger for better readability.")
    scaleDesc:SetWordWrap(true)

    scaleSlider:SetScript("OnValueChanged", function(self, value)
        JustTheTipDB.scale = value
        if JTT.SaveConfig then
            JTT:SaveConfig()
        end
    end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, L["Just the Tip"])
    Settings.RegisterAddOnCategory(category)
    
    return panel
end

function Config.SetupSlashCommands()
    SLASH_JUSTTHETI1 = "/jtt"
    SLASH_JUSTTHETI2 = "/justthetp"
    SlashCmdList["JUSTTHETI"] = function(msg)
        msg = string.lower(string.trim(msg))
        if msg == "debug" then
            JustTheTipDB.debugMode = not JustTheTipDB.debugMode
            if JTT.SaveConfig then
                JTT:SaveConfig()
            end
            print("|cFFFFD700Just the Tip:|r Debug mode " .. (JustTheTipDB.debugMode and "enabled" or "disabled"))
        elseif msg == "config" or msg == "options" then
            Settings.OpenToCategory(L["Just the Tip"])
        elseif msg == "minimap" then
            JustTheTipDB.minimap.hide = not JustTheTipDB.minimap.hide
            if JTT.SaveConfig then
                JTT:SaveConfig()
            end
            if JTT.Minimap and JTT.Minimap.UpdateMinimapButton then
                JTT.Minimap.UpdateMinimapButton()
            end
            print("|cFFFFD700Just the Tip:|r Minimap icon " .. (JustTheTipDB.minimap.hide and "hidden" or "shown"))
        else
            print("|cFFFFD700Just the Tip:|r Available commands:")
            print("/jtt debug - Toggle debug mode (shows technical info in chat)")
            print("/jtt config - Open the addon options panel")
            
        end
    end
end
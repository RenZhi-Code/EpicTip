local addonName, ET = ...

ET.UI = ET.UI or {}
ET.UI.Config = ET.UI.Config or {}
local L = ET.L

-- Appearance Configuration Panel
function ET.UI.Config.GetAppearanceConfig()
    -- Validate database exists before creating config
    if not EpicTipDB then
        return {
            name = "|cFFDDA0DDAppearance|r",
            type = "group",
            order = 3,
            args = {
                loading = {
                    name = "Appearance loading... (Database not ready)",
                    type = "description",
                    order = 1
                }
            }
        }
    end
    
    return {
        name = "|cFFDDA0DDAppearance|r",
        type = "group",
        order = 3,
        childGroups = "tab",
        args = {
            desc = {
                name = "|cFFDDA0DD» Customize the visual appearance of tooltips including colors, styling, and text filtering.|r",
                type = "description",
                order = 1,
                fontSize = "medium",
            },
            background = {
                name = "|cFF87CEEBBackground|r",
                type = "group",
                order = 2,
                args = {
                    backgroundHeader = {
                        name = "|cFF87CEEB» Background Settings|r",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    backgroundColor = {
                        name = "Background Color",
                        desc = "Color of the tooltip background",
                        type = "color",
                        order = 2,
                        hasAlpha = true,
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() 
                            if not EpicTipDB or not EpicTipDB.backgroundColor then return 0, 0, 0, 0.8 end
                            local c = EpicTipDB.backgroundColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            if EpicTipDB then EpicTipDB.backgroundColor = { r = r, g = g, b = b, a = a } end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    backgroundFade = {
                        name = "Background Fade",
                        desc = "Apply a fade effect to the tooltip background",
                        type = "toggle",
                        order = 3,
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.backgroundFade end,
                        set = function(_, val)
                            if EpicTipDB then EpicTipDB.backgroundFade = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    reactionColoredBackground = {
                        name = "Reaction-Based Background",
                        desc = "Color the background based on unit reaction (hostile = red, friendly = green, etc.)",
                        type = "toggle",
                        order = 4,
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.reactionColoredBackground end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.reactionColoredBackground = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    classColoredBackground = {
                        name = "Class-Colored Background",
                        desc = "Color the background based on the player's class color",
                        type = "toggle",
                        order = 5,
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.classColoredBackground end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.classColoredBackground = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                }
            },
            border = {
                name = "|cFFFFD700Border|r",
                type = "group",
                order = 3,
                args = {
                    borderHeader = {
                        name = "|cFFFFD700» Border Settings|r",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    borderColor = {
                        name = "Border Color",
                        desc = "Color of the tooltip border",
                        type = "color",
                        order = 2,
                        hasAlpha = true,
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() 
                            if not EpicTipDB or not EpicTipDB.borderColor then return 0.3, 0.3, 0.4, 1.0 end
                            local c = EpicTipDB.borderColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            if EpicTipDB then EpicTipDB.borderColor = { r = r, g = g, b = b, a = a } end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    borderWidth = {
                        name = "Border Width",
                        desc = "Width of the tooltip border in pixels",
                        type = "range",
                        order = 3,
                        min = 1,
                        max = 10,
                        step = 1,
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.borderWidth end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.borderWidth = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    classColoredBorder = {
                        name = "Class-Colored Border",
                        desc = "Color the border based on the player's class color",
                        type = "toggle",
                        order = 4,
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.classColoredBorder end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.classColoredBorder = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                }
            },
            textfiltering = {
                name = "|cFFDDA0DDText Filtering|r",
                type = "group",
                order = 4,
                args = {
                    filterHeader = {
                        name = "|cFFDDA0DD» Text Filtering Options|r",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    hideSpecializationAndClassText = {
                        name = "Hide Specialization/Class Text",
                        desc = "Remove specialization and class text lines (e.g., 'Shadow Priest')",
                        type = "toggle",
                        order = 2,
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.hideSpecializationAndClassText end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.hideSpecializationAndClassText = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    hidePvpText = {
                        name = "Hide PvP Text",
                        desc = "Remove 'PvP Enabled' text from tooltips",
                        type = "toggle",
                        order = 3,
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.hidePvpText end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.hidePvpText = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    hideRightClickText = {
                        name = "Hide Right-Click Text",
                        desc = "Remove 'Right click for more options' text from tooltips",
                        type = "toggle",
                        order = 4,
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.hideRightClickText end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.hideRightClickText = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    fontHeader = {
                        name = "|cFFDDA0DD» Font Configuration|r",
                        type = "description",
                        order = 5,
                        fontSize = "medium",
                    },
                    fontFamily = {
                        name = "Font Family",
                        desc = "Choose the font family for tooltip text",
                        type = "select",
                        order = 6,
                        width = 1.2,
                        values = {
                            ["Fonts\\FRIZQT__.TTF"] = "Friz Quadrata TT (Default)",
                            ["Fonts\\ARIALN.TTF"] = "Arial Narrow",
                            ["Fonts\\ARIALNB.TTF"] = "Arial Narrow Bold",
                            ["Fonts\\skurri.ttf"] = "Skurri",
                            ["Fonts\\MORPHEUS.TTF"] = "Morpheus",
                            ["Fonts\\NIM_____.ttf"] = "Nimrod MT",
                            ["Fonts\\FRIENDS.TTF"] = "Friends",
                            ["Fonts\\2002.TTF"] = "2002",
                            ["Fonts\\2002B.TTF"] = "2002 Bold",
                            ["Fonts\\ROADWAY.TTF"] = "Roadway",
                            ["Fonts\\FRITZ.TTF"] = "Fritz"
                        },
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.fontFamily or "Fonts\\FRIZQT__.TTF" end,
                        set = function(_, val) 
                            if EpicTipDB then 
                                EpicTipDB.fontFamily = val
                                if ET.FontManager then ET.FontManager.fontsInitialized = false end
                            end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    fontDemo = {
                        name = "Font Preview",
                        type = "description",
                        order = 6.5,
                        width = 0.8,
                        fontSize = "medium",
                        get = function()
                            local fontPath = (EpicTipDB and EpicTipDB.fontFamily) or "Fonts\\FRIZQT__.TTF"
                            local titleSize = (EpicTipDB and EpicTipDB.titleFontSize) or 14
                            local infoSize = (EpicTipDB and EpicTipDB.infoFontSize) or 12
                            return string.format("|cFFFFD700Title Text (%d)|r\n|cFFFFFFFFInfo Text (%d)|r\n|cFF00FF00Header Text|r\n|cFFCCCCCCDescription Text|r", titleSize, infoSize)
                        end,
                    },
                    titleFontSize = {
                        name = "Title Font Size",
                        desc = "Font size for tooltip titles and headers",
                        type = "range",
                        order = 7,
                        width = 1.2,
                        min = 8,
                        max = 20,
                        step = 1,
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.titleFontSize or 14 end,
                        set = function(_, val) 
                            if EpicTipDB then 
                                EpicTipDB.titleFontSize = val
                                if ET.FontManager then ET.FontManager.fontsInitialized = false end
                            end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    infoFontSize = {
                        name = "Info Font Size",
                        desc = "Font size for general tooltip information",
                        type = "range",
                        order = 8,
                        width = 1.2,
                        min = 8,
                        max = 18,
                        step = 1,
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.infoFontSize or 12 end,
                        set = function(_, val) 
                            if EpicTipDB then 
                                EpicTipDB.infoFontSize = val
                                if ET.FontManager then ET.FontManager.fontsInitialized = false end
                            end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    headerFontSize = {
                        name = "Header Font Size",
                        desc = "Font size for section headers in tooltips",
                        type = "range",
                        order = 9,
                        width = 1.2,
                        min = 8,
                        max = 18,
                        step = 1,
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.headerFontSize or 13 end,
                        set = function(_, val) 
                            if EpicTipDB then 
                                EpicTipDB.headerFontSize = val
                                if ET.FontManager then ET.FontManager.fontsInitialized = false end
                            end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    descriptionFontSize = {
                        name = "Description Font Size",
                        desc = "Font size for descriptions and secondary text",
                        type = "range",
                        order = 10,
                        width = 1.2,
                        min = 8,
                        max = 16,
                        step = 1,
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.descriptionFontSize or 11 end,
                        set = function(_, val) 
                            if EpicTipDB then 
                                EpicTipDB.descriptionFontSize = val
                                if ET.FontManager then ET.FontManager.fontsInitialized = false end
                            end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    resetFontSizes = {
                        name = "Reset Font Sizes",
                        desc = "Reset all font sizes to their default values",
                        type = "execute",
                        order = 11,
                        width = 0.8,
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        func = function()
                            if EpicTipDB then
                                EpicTipDB.titleFontSize = 14
                                EpicTipDB.infoFontSize = 12
                                EpicTipDB.headerFontSize = 13
                                EpicTipDB.descriptionFontSize = 11
                                if ET.FontManager then ET.FontManager.fontsInitialized = false end
                                if EpicTipDB.debugMode then
                                    print("|cFF00FF00EpicTip:|r Font sizes reset to defaults.")
                                end
                            end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                }
            },
        }
    }
end
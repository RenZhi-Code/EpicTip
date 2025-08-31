local addonName, ET = ...

ET.UI = ET.UI or {}
ET.UI.Config = ET.UI.Config or {}
local L = ET.L

-- TrueStat Configuration Panel
function ET.UI.Config.GetTrueStatConfig()
    return {
        name = "|cFFFFD700TrueStat|r",
        type = "group",
        order = 6,
        childGroups = "tab",
        args = {
            desc = {
                name = "|cFFFFD700» Enhanced Item Analysis and True Stat Values|r\n\nAccurate item information, stat calculations, and equipment analysis for informed decision making. TrueStat provides comprehensive item data beyond basic tooltips.",
                type = "description",
                order = 1,
                fontSize = "medium",
            },
            itemInfo = {
                name = "|cFFFF6347Item Information|r",
                type = "group",
                order = 2,
                args = {
                    itemInfoHeader = {
                        name = "|cFFFF6347» Enhanced Item Details and Analysis|r\n\nUpgrade your item tooltips with comprehensive information including vendor prices, drop sources, item comparisons, and upgrade paths.",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    showItemInfo = {
                        name = L["Enhanced Item Information"],
                        desc = "Adds comprehensive item details including vendor prices, drop sources, item comparisons, and upgrade paths. This feature significantly improves item tooltips with valuable context for equipment decisions.",
                        type = "toggle",
                        order = 2,
                        width = "full",
                        disabled = function() return not EpicTipDB.enabled end,
                        get = function() return EpicTipDB.showItemInfo end,
                        set = function(_, val) 
                            EpicTipDB.showItemInfo = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    itemInfoDetails = {
                        name = L["Show Detailed Item Analysis"],
                        desc = "Includes additional item analysis such as stat efficiency, upgrade potential, socket information, and set piece compatibility. Provides deeper insight into item value and optimization opportunities.",
                        type = "toggle",
                        order = 3,
                        width = "full",
                        disabled = function() return not EpicTipDB.enabled or not EpicTipDB.showItemInfo end,
                        get = function() return EpicTipDB.itemInfoDetails end,
                        set = function(_, val) 
                            EpicTipDB.itemInfoDetails = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    showItemSource = {
                        name = L["Show Item Source Information"],
                        desc = "Displays where items can be obtained including dungeon drops, vendor purchases, quest rewards, and crafting recipes. Essential for planning acquisition strategies.",
                        type = "toggle",
                        order = 4,
                        width = "full",
                        disabled = function() return not EpicTipDB.enabled or not EpicTipDB.showItemInfo end,
                        get = function() return EpicTipDB.showItemSource end,
                        set = function(_, val) 
                            EpicTipDB.showItemSource = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    showItemValue = {
                        name = L["Show Item Value Analysis"],
                        desc = "Displays vendor sell prices, estimated auction house values, and relative item worth. Helps with inventory management and financial decisions.",
                        type = "toggle",
                        order = 5,
                        width = "full",
                        disabled = function() return not EpicTipDB.enabled or not EpicTipDB.showItemInfo end,
                        get = function() return EpicTipDB.showItemValue end,
                        set = function(_, val) 
                            EpicTipDB.showItemValue = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                }
            },
            statValues = {
                name = "|cFF98FB98True Stat Values|r",
                type = "group",
                order = 3,
                args = {
                    statValuesHeader = {
                        name = "|cFF98FB98» Accurate Stat Calculations and Analysis|r\n\nReveal the true impact of stats with diminishing returns calculations, effective percentages, and real performance metrics beyond basic tooltip numbers.",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    showStatValues = {
                        name = L["True Stat Values"],
                        desc = "Shows accurate stat values including diminishing returns calculations, effective percentages, and real impact on character performance. Particularly useful for understanding how stats actually affect your character beyond the basic tooltip numbers.",
                        type = "toggle",
                        order = 2,
                        width = "full",
                        disabled = function() return not EpicTipDB.enabled end,
                        get = function() return EpicTipDB.showStatValues end,
                        set = function(_, val) 
                            EpicTipDB.showStatValues = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    showDiminishingReturns = {
                        name = L["Diminishing Returns Analysis"],
                        desc = "Displays how stat effectiveness decreases at higher values due to diminishing returns. Shows both current effectiveness and optimal stat distribution recommendations.",
                        type = "toggle",
                        order = 3,
                        width = "full",
                        disabled = function() return not EpicTipDB.enabled or not EpicTipDB.showStatValues end,
                        get = function() return EpicTipDB.showDiminishingReturns end,
                        set = function(_, val) 
                            EpicTipDB.showDiminishingReturns = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    showStatComparison = {
                        name = L["Stat Comparison Analysis"],
                        desc = "Compares current item stats with equipped gear, showing upgrade potential and stat changes. Includes percentage improvements and optimization suggestions.",
                        type = "toggle",
                        order = 4,
                        width = "full",
                        disabled = function() return not EpicTipDB.enabled or not EpicTipDB.showStatValues end,
                        get = function() return EpicTipDB.showStatComparison end,
                        set = function(_, val) 
                            EpicTipDB.showStatComparison = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    showStatWeights = {
                        name = L["Stat Weight Calculations"],
                        desc = "Displays stat weights and relative values for your current spec, helping prioritize stats for maximum performance improvement. Based on simulation data and community research.",
                        type = "toggle",
                        order = 5,
                        width = "full",
                        disabled = function() return not EpicTipDB.enabled or not EpicTipDB.showStatValues end,
                        get = function() return EpicTipDB.showStatWeights end,
                        set = function(_, val) 
                            EpicTipDB.showStatWeights = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    statPrecision = {
                        name = L["Stat Display Precision"],
                desc = L["Number of decimal places to show for stat calculations"],
                        type = "range",
                        order = 6,
                        min = 0,
                        max = 3,
                        step = 1,
                        disabled = function() return not EpicTipDB.enabled or not EpicTipDB.showStatValues end,
                        get = function() return EpicTipDB.statPrecision or 2 end,
                        set = function(_, val) 
                            EpicTipDB.statPrecision = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                }
            },
            advanced = {
                name = "|cFFFF69B4Advanced Options|r",
                type = "group",
                order = 4,
                args = {
                    advancedHeader = {
                        name = "|cFFFF69B4» Advanced Item and Stat Configuration|r\n\nFine-tune how item information and stat values are calculated and displayed. These options provide expert-level control over the TrueStat system.",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    useSimulationData = {
                        name = L["Use Simulation Data"],
                        desc = "Incorporate simulation data from popular theorycrafting tools for more accurate stat weights and recommendations. May require periodic updates.",
                        type = "toggle",
                        order = 2,
                        width = "full",
                        disabled = function() return not EpicTipDB.enabled end,
                        get = function() return EpicTipDB.useSimulationData end,
                        set = function(_, val) 
                            EpicTipDB.useSimulationData = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    itemLevelThreshold = {
                        name = L["Item Level Analysis Threshold"],
                        desc = "Only show detailed analysis for items above this item level to reduce tooltip clutter on low-level gear",
                        type = "range",
                        order = 3,
                        min = 1,
                        max = 500,
                        step = 1,
                        disabled = function() return not EpicTipDB.enabled end,
                        get = function() return EpicTipDB.itemLevelThreshold or 350 end,
                        set = function(_, val) 
                            EpicTipDB.itemLevelThreshold = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    cacheStatCalculations = {
                        name = L["Cache Stat Calculations"],
                        desc = "Cache complex stat calculations to improve performance. Recommended for high-end systems. Disable if experiencing memory issues.",
                        type = "toggle",
                        order = 4,
                        width = "full",
                        disabled = function() return not EpicTipDB.enabled end,
                        get = function() return EpicTipDB.cacheStatCalculations ~= false end, -- Default to true
                        set = function(_, val) 
                            EpicTipDB.cacheStatCalculations = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    showDeveloperInfo = {
                        name = L["Show Developer Information"],
                        desc = "Display technical item and stat information useful for addon development and debugging. Not recommended for normal use.",
                        type = "toggle",
                        order = 5,
                        width = "full",
                        disabled = function() return not EpicTipDB.enabled end,
                        get = function() return EpicTipDB.showDeveloperInfo end,
                        set = function(_, val) 
                            EpicTipDB.showDeveloperInfo = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                }
            },
        }
    }
end
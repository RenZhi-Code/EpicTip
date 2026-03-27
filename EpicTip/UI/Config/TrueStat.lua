local addonName, ET = ...

ET.UI = ET.UI or {}
ET.UI.Config = ET.UI.Config or {}
local L = ET.L

-- Check game version
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

-- TrueStat Configuration Panel
function ET.UI.Config.GetTrueStatConfig()
    local config = {
        name = "|cFFFFD700TrueStat|r",
        type = "group",
        order = 6,
        childGroups = "tab",
        args = {
            desc = {
                name = isRetail and "|cFFFFD700» Enhanced Item Analysis and True Stat Values|r\n\nAccurate item information, stat calculations, and equipment analysis for informed decision making. TrueStat provides comprehensive item data beyond basic tooltips."
                      or "|cFFFFD700» Enhanced Item Analysis|r\n\nAccurate item information and equipment analysis for informed decision making. Provides comprehensive item data beyond basic tooltips.",
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
                        name = "|cFFFF6347» Enhanced Item Details and Analysis|r\n\nUpgrade your item tooltips with comprehensive information including item ID, sell prices, stack counts, and item sources.",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    showItemInfo = {
                        name = L["Enhanced Item Information"],
                        desc = "Adds comprehensive item details including item ID, vendor prices, stack counts, and drop sources. This feature improves item tooltips with valuable context for equipment decisions.",
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
                }
            },
        }
    }

    -- Only add True Stat Values in Retail (Classic doesn't have Versatility/Mastery/etc)
    if isRetail then
        config.args.statValues = {
                name = "|cFF98FB98True Stat Values|r",
                type = "group",
                order = 3,
                args = {
                    statValuesHeader = {
                        name = "|cFF98FB98» Accurate Stat Calculations and Analysis|r\n\nReveal the true impact of stats with diminishing returns calculations, effective percentages, breakpoint information, and real performance metrics when hovering over character stats.",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    showStatValues = {
                        name = L["True Stat Values"],
                        desc = "Shows accurate stat values including diminishing returns penalties, effective percentages, and next breakpoint information when hovering over stats in your character panel. Helps you understand the real impact of Haste, Crit, Mastery, Versatility, and tertiary stats.",
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
                }
            }
        end

    return config
end
local addonName, ET = ...

ET.UI = ET.UI or {}
ET.UI.Config = ET.UI.Config or {}
local L = ET.L

-- Features Configuration Panel
function ET.UI.Config.GetFeaturesConfig()
    -- Validate database exists before creating config
    if not EpicTipDB then
        return {
            name = "|cFFFF69B4Features|r",
            type = "group",
            order = 4,
            args = {
                loading = {
                    name = "Features loading... (Database not ready)",
                    type = "description",
                    order = 1
                }
            }
        }
    end
    
    return {
        name = "|cFFFF69B4Features|r",
        type = "group",
        order = 4,
        childGroups = "tab",
        args = {
            desc = {
                name = "|cFFFF69B4» Enable advanced features for enhanced tooltip information. Each section contains related features with detailed explanations.|r",
                type = "description",
                order = 1,
                fontSize = "medium",
            },
            competitive = {
                name = "|cFFFF6347Competitive|r",
                type = "group",
                order = 2,
                args = {
                    competitiveHeader = {
                        name = "|cFFFF6347» Mythic+ and PvP Information|r\n\nDisplay competitive ratings and achievements to assess player skill and experience in challenging content.",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    showMythicRating = {
                        name = "Show Mythic+ Rating",
                        desc = "Displays the player's current Mythic+ rating and seasonal progress. This is crucial for understanding a player's experience level in high-end dungeon content and helps with group formation decisions.",
                        type = "toggle",
                        order = 2,
                        width = "full",
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.showMythicRating end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.showMythicRating = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    mythicRatingFormat = {
                        name = "Mythic+ Display Format",
                        desc = "Choose what specific Mythic+ information to display. 'Score Only' shows just the rating number, 'Highest Key' shows their best completed level, 'Both' shows rating and key level, 'Detailed' includes additional statistics.",
                        type = "select",
                        order = 3,
                        width = "full",
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled and EpicTipDB.showMythicRating) end,
                        values = {
                            ["score"] = L["Score Only"],
                    ["key"] = L["Highest Key Only"],
                    ["both"] = L["Score + Highest Key"],
                    ["detailed"] = L["Detailed Stats"]
                        },
                        get = function() return EpicTipDB and EpicTipDB.mythicRatingFormat end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.mythicRatingFormat = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    mythicRatingDetails = {
                        name = "Show Detailed M+ Statistics",
                        desc = "Adds additional Mythic+ statistics such as completion ratios, timing success rates, and seasonal progress. This provides deeper insight into a player's consistency and reliability in challenging content.",
                        type = "toggle",
                        order = 4,
                        width = "full",
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled and EpicTipDB.showMythicRating) end,
                        get = function() return EpicTipDB and EpicTipDB.mythicRatingDetails end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.mythicRatingDetails = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    showPvPRating = {
                        name = L["Show PvP Rating"],
                        desc = "Displays PvP ratings for Arena (2v2, 3v3, RBG) and current PvP achievements. Essential for understanding a player's PvP experience and skill level in competitive player-versus-player content.",
                        type = "toggle",
                        order = 5,
                        width = "full",
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.showPvPRating end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.showPvPRating = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                }
            },
            world = {
                name = "|cFF98FB98World Content|r",
                type = "group",
                order = 3,
                args = {
                    worldHeader = {
                        name = "|cFF98FB98» NPCs, Mounts, and World Information|r\n\nEnhance tooltips for world content including NPCs, mounts, and other interactive elements you encounter while exploring.",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    showMountInfo = {
                        name = L["Mount Information"],
                        desc = "Shows detailed mount information when hovering over mounted players, including mount name, rarity, acquisition method, and collection status. Perfect for mount collectors and those curious about rare mounts they see.",
                        type = "toggle",
                        order = 3,
                        width = "full",
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.showMountInfo end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.showMountInfo = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                }
            },
        }
    }
end
local addonName, ET = ...

ET.UI = ET.UI or {}
ET.UI.Config = ET.UI.Config or {}
local L = ET.L

-- Check game version for retail-only features
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

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

    local config = {
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
        }
    }

    -- Only add Competitive section in Retail (Mythic+ and modern PvP)
    if isRetail then
        config.args.competitive = {
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
            }
        end

    -- Only add World Content section with MountInfo in Retail
    if isRetail then
        config.args.world = {
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
            }
        end

    -- Unit Status & Auras section (All versions)
    config.args.unitStatus = {
        name = "|cFF87CEEB Unit Status|r",
        type = "group",
        order = 5,
        args = {
            statusHeader = {
                name = "|cFF87CEEB» Buffs, Debuffs, and Unit Status|r\n\nDisplay additional unit information including auras, raid markers, targeting info, and player status.",
                type = "description",
                order = 1,
                fontSize = "medium",
            },
            -- Buff/Debuff Display
            aurasHeader = {
                name = "|cFFFFD700Buff/Debuff Display|r",
                type = "header",
                order = 2,
            },
            showAuras = {
                name = L["Show Buffs/Debuffs"] or "Show Buffs/Debuffs",
                desc = "Display buff and debuff icons on unit tooltips. Shows active auras with their icons for quick assessment of the unit's current state.",
                type = "toggle",
                order = 3,
                width = "full",
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                get = function() return EpicTipDB and EpicTipDB.showAuras end,
                set = function(_, val)
                    if EpicTipDB then EpicTipDB.showAuras = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            showBuffs = {
                name = L["Show Buffs"] or "Show Buffs",
                desc = "Display beneficial auras (buffs) on the tooltip.",
                type = "toggle",
                order = 4,
                width = "normal",
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled and EpicTipDB.showAuras) end,
                get = function() return EpicTipDB and EpicTipDB.showBuffs ~= false end,
                set = function(_, val)
                    if EpicTipDB then EpicTipDB.showBuffs = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            showDebuffs = {
                name = L["Show Debuffs"] or "Show Debuffs",
                desc = "Display harmful auras (debuffs) on the tooltip.",
                type = "toggle",
                order = 5,
                width = "normal",
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled and EpicTipDB.showAuras) end,
                get = function() return EpicTipDB and EpicTipDB.showDebuffs ~= false end,
                set = function(_, val)
                    if EpicTipDB then EpicTipDB.showDebuffs = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            showOnlyMyAuras = {
                name = L["Only Show My Auras"] or "Only Show My Auras",
                desc = "Only display buffs and debuffs that you cast. Useful for tracking your own contributions in group content.",
                type = "toggle",
                order = 6,
                width = "full",
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled and EpicTipDB.showAuras) end,
                get = function() return EpicTipDB and EpicTipDB.showOnlyMyAuras end,
                set = function(_, val)
                    if EpicTipDB then EpicTipDB.showOnlyMyAuras = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            maxAurasDisplay = {
                name = L["Max Auras Displayed"] or "Max Auras Displayed",
                desc = "Maximum number of buff/debuff icons to show per category. Higher values may extend tooltip length.",
                type = "range",
                order = 7,
                min = 4,
                max = 16,
                step = 1,
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled and EpicTipDB.showAuras) end,
                get = function() return EpicTipDB and EpicTipDB.maxAurasDisplay or 8 end,
                set = function(_, val)
                    if EpicTipDB then EpicTipDB.maxAurasDisplay = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            auraIconSize = {
                name = L["Aura Icon Size"] or "Aura Icon Size",
                desc = "Size of buff/debuff icons in pixels.",
                type = "range",
                order = 8,
                min = 14,
                max = 32,
                step = 1,
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled and EpicTipDB.showAuras) end,
                get = function() return EpicTipDB and EpicTipDB.auraIconSize or 20 end,
                set = function(_, val)
                    if EpicTipDB then EpicTipDB.auraIconSize = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            -- Unit Status section
            statusHeader2 = {
                name = "|cFFFFD700Unit Status & Info|r",
                type = "header",
                order = 10,
            },
            showPlayerStatus = {
                name = L["Show AFK/DND Status"] or "Show AFK/DND Status",
                desc = "Display player status indicators such as AFK (Away From Keyboard), DND (Do Not Disturb), Offline, Dead, or Ghost status.",
                type = "toggle",
                order = 11,
                width = "full",
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                get = function() return EpicTipDB and EpicTipDB.showPlayerStatus end,
                set = function(_, val)
                    if EpicTipDB then EpicTipDB.showPlayerStatus = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            showRaidIcon = {
                name = L["Show Raid Target Icon"] or "Show Raid Target Icon",
                desc = "Display the raid target marker (skull, X, moon, etc.) assigned to the unit. Helpful for quickly identifying marked targets.",
                type = "toggle",
                order = 12,
                width = "full",
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                get = function() return EpicTipDB and EpicTipDB.showRaidIcon end,
                set = function(_, val)
                    if EpicTipDB then EpicTipDB.showRaidIcon = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            showTargetedBy = {
                name = L["Show 'Targeted By'"] or "Show 'Targeted By'",
                desc = "Display which party or raid members are currently targeting this unit. Very useful for tanks to see threat distribution and healers to coordinate healing assignments.",
                type = "toggle",
                order = 13,
                width = "full",
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                get = function() return EpicTipDB and EpicTipDB.showTargetedBy end,
                set = function(_, val)
                    if EpicTipDB then EpicTipDB.showTargetedBy = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
        }
    }

    return config
end
local addonName, ET = ...

ET.UI = ET.UI or {}
ET.UI.Config = ET.UI.Config or {}
local L = ET.L

-- Player Info Configuration Panel
function ET.UI.Config.GetPlayerInfoConfig()
    return {
        name = "|cFF87CEEBPlayer Info|r",
        type = "group",
        order = 2,
        childGroups = "tab",
        args = {
            desc = {
                name = "|cFF87CEEB» Configure what information to display on player tooltips. Hover over each option for detailed explanations.|r",
                type = "description",
                order = 1,
                fontSize = "medium",
            },
            character = {
                name = "|cFFFFD700Character Info|r",
                type = "group",
                order = 2,
                args = {
                    characterHeader = {
                        name = "|cFFFFD700» Basic Character Information|r\n\nThese options control the display of fundamental character data such as specialization, level, and visual indicators.",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    showIlvl = {
                        name = L["Show Item Level"],
                        desc = "Displays the player's average equipped item level, which is a key indicator of character progression and power. This feature requires player inspection to be enabled and may take a moment to load for players outside your group.",
                        type = "toggle",
                        order = 2,
                        width = "full",
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.showIlvl end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.showIlvl = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                }
            },
            visual = {
                name = "|cFF98FB98Visual Indicators|r",
                type = "group",
                order = 3,
                args = {
                    visualHeader = {
                        name = "|cFF98FB98» Icons and Visual Elements|r\n\nThese options add helpful icons and visual cues to make tooltips more informative and easier to scan quickly.",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    showClassIcon = {
                        name = L["Show Class Icons"],
                        desc = "Adds the appropriate class icon next to player names (sword for Warriors, crystal for Mages, etc.). This provides instant visual recognition of a player's class without reading the text.",
                        type = "toggle",
                        order = 2,
                        width = "full",
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.showClassIcon end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.showClassIcon = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    showRoleIcon = {
                        name = L["Show Role Icons"],
                        desc = "Displays role icons (shield Tank, heart Healer, sword DPS) for group and raid members. This is especially useful in dungeons and raids to quickly identify each player's role and responsibilities.",
                        type = "toggle",
                        order = 3,
                        width = "full",
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.showRoleIcon end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.showRoleIcon = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                }
            },
            social = {
                name = "|cFF87CEEBSocial Info|r",
                type = "group",
                order = 4,
                args = {
                    socialHeader = {
                        name = "|cFF87CEEB» Guild and Social Information|r\n\nOptions for displaying guild membership, current activities, and social context about other players.",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    showGuildRank = {
                        name = L["Show Guild Rank"],
                        desc = "Displays the player's rank within their guild (e.g., 'Guild Master', 'Officer', 'Member'). The guild name is already shown by WoW by default - this adds the specific rank for additional context about the player's standing.",
                        type = "toggle",
                        order = 2,
                        width = "full",
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.showGuildRank end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.showGuildRank = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    showTarget = {
                        name = L["Show Current Target"],
                        desc = "Shows what the player is currently targeting, which can provide valuable tactical information in PvP situations or help coordinate in group content. For example: 'Target: Ragnaros' or 'Target: Enemy Player'.",
                        type = "toggle",
                        order = 3,
                        width = "full",
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.showTarget end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.showTarget = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                }
            },
            healthbars = {
                name = "|cFFFF6347Health Bars|r",
                type = "group",
                order = 5,
                args = {
                    healthHeader = {
                        name = "|cFFFF6347» Health Bar Visibility|r\n\nControl the display of health bars in tooltips. Health bars show current HP but can clutter the interface for some users.",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    hideHealthBar = {
                        name = L["Hide Player Health Bars"],
                        desc = "Removes the health bar from player tooltips to create a cleaner, less cluttered appearance. Health information can still be seen in the text portion of the tooltip if needed.",
                        type = "toggle",
                        order = 2,
                        width = "full",
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.hideHealthBar end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.hideHealthBar = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    hideNPCHealthBar = {
                        name = L["Hide NPC Health Bars"],
                        desc = "Removes the health bar from NPC (Non-Player Character) tooltips, including enemies, vendors, quest givers, and neutral NPCs. This can significantly clean up the interface when interacting with many NPCs.",
                        type = "toggle",
                        order = 3,
                        width = "full",
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.hideNPCHealthBar end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.hideNPCHealthBar = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                    showHealthNumbers = {
                        name = L["Show Health Numbers"],
                        desc = "Display actual health values as text (e.g., '15,420 / 23,890 HP'). This shows exact current and maximum health instead of relying only on the health bar visualization.",
                        type = "toggle",
                        order = 4,
                        width = "full",
                        disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.showHealthNumbers end,
                        set = function(_, val) 
                            if EpicTipDB then EpicTipDB.showHealthNumbers = val end
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                        end,
                    },
                }
            },
        }
    }
end
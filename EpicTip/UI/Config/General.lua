local addonName, ET = ...

ET.UI = ET.UI or {}
ET.UI.Config = ET.UI.Config or {}
local L = ET.L

-- General Configuration Panel
function ET.UI.Config.GetGeneralConfig()
    return {
        name = "|cFFFFD700General|r",
        type = "group",
        order = 1,
        args = {
            headerDesc = {
                name = "|cFFFF0000Epic|r|cFF33CCFFTip|r - Enhanced tooltip addon with modern styling and advanced features\n\n|cFFFFA500» Modern Interface » Advanced Styling » Text Filtering » Performance Optimized|r\n\n|cFF90EE90Configure your tooltip experience below:|r",
                type = "description",
                order = 1,
                fontSize = "medium",
                width = "full",
            },
            enabled = {
                name = "|cFFFF6B6BEnable EpicTip|r",
                desc = L["Master switch to enable or disable the addon completely"],
                type = "toggle",
                order = 2,
                width = "full",
                get = function() return EpicTipDB and EpicTipDB.enabled end,
                set = function(_, val) 
                    if EpicTipDB then EpicTipDB.enabled = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            scale = {
                name = L["Tooltip Scale"],
                desc = "Overall size of tooltips (1.0 = normal size)",
                type = "range",
                order = 3,
                min = 0.5,
                max = 2.0,
                step = 0.05,
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                get = function() return EpicTipDB and EpicTipDB.scale end,
                set = function(_, val) 
                    if EpicTipDB then EpicTipDB.scale = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            hideInCombat = {
                name = L["Hide Tooltips In Combat"],
                desc = L["Hide all tooltips during combat"],
                type = "toggle",
                order = 4,
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                get = function() return EpicTipDB and EpicTipDB.hideInCombat end,
                set = function(_, val) 
                    if EpicTipDB then EpicTipDB.hideInCombat = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            anchoring = {
                name = L["Tooltip Positioning"],
                desc = L["Choose how tooltips are positioned relative to your cursor"],
                type = "select",
                order = 5,
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                values = {
                    ["default"] = L["Default (WoW Default)"],
                    ["mouse"] = L["Follow Mouse Cursor"],
                    ["smart"] = L["Smart Positioning"]
                },
                get = function() return EpicTipDB and EpicTipDB.anchoring end,
                set = function(_, val) 
                    if EpicTipDB then EpicTipDB.anchoring = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            enableInspect = {
                name = L["Enable Player Inspection"],
                desc = L["Allow addon to inspect other players for detailed information"],
                type = "toggle",
                order = 6,
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                get = function() return EpicTipDB and EpicTipDB.enableInspect end,
                set = function(_, val) 
                    if EpicTipDB then EpicTipDB.enableInspect = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
        }
    }
end
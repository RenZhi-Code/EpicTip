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
            allowRestrictedCosmetics = {
                name = "Apply Cosmetics In Instances",
                desc = "Experimental: allow scale, border/background, fonts, and max-width wrapping in dungeons/raids/scenarios (Midnight). Unit tooltip enhancements still stay paused to avoid taint/secret-value issues.",
                type = "toggle",
                order = 4,
                width = "full",
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                get = function() return EpicTipDB and EpicTipDB.allowRestrictedCosmetics end,
                set = function(_, val)
                    if EpicTipDB then EpicTipDB.allowRestrictedCosmetics = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            hideInCombat = {
                name = L["Hide Tooltips In Combat"],
                desc = L["Hide all tooltips during combat"],
                type = "toggle",
                order = 5,
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
                order = 6,
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                values = {
                    ["default"] = L["Default (WoW Default)"],
                    ["mouse"] = L["Follow Mouse Cursor"],
                    ["smart"] = L["Smart Positioning"],
                    ["fixed"] = L["Fixed Position"]
                },
                get = function() return EpicTipDB and EpicTipDB.anchoring end,
                set = function(_, val)
                    if EpicTipDB then EpicTipDB.anchoring = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            fixedAnchorPoint = {
                name = L["Anchor Point"],
                desc = L["Choose which corner or edge of the screen to anchor the tooltip to"],
                type = "select",
                order = 6.1,
                hidden = function() return not EpicTipDB or EpicTipDB.anchoring ~= "fixed" end,
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                values = {
                    ["TOPLEFT"] = "Top Left",
                    ["TOP"] = "Top",
                    ["TOPRIGHT"] = "Top Right",
                    ["LEFT"] = "Left",
                    ["CENTER"] = "Center",
                    ["RIGHT"] = "Right",
                    ["BOTTOMLEFT"] = "Bottom Left",
                    ["BOTTOM"] = "Bottom",
                    ["BOTTOMRIGHT"] = "Bottom Right",
                },
                get = function() return EpicTipDB and EpicTipDB.fixedAnchorPoint end,
                set = function(_, val)
                    if EpicTipDB then EpicTipDB.fixedAnchorPoint = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            fixedAnchorX = {
                name = L["X Offset"],
                desc = L["Horizontal offset from the anchor point"],
                type = "range",
                order = 6.2,
                min = -800,
                max = 800,
                step = 1,
                hidden = function() return not EpicTipDB or EpicTipDB.anchoring ~= "fixed" end,
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                get = function() return EpicTipDB and EpicTipDB.fixedAnchorX end,
                set = function(_, val)
                    if EpicTipDB then EpicTipDB.fixedAnchorX = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            fixedAnchorY = {
                name = L["Y Offset"],
                desc = L["Vertical offset from the anchor point"],
                type = "range",
                order = 6.3,
                min = -800,
                max = 800,
                step = 1,
                hidden = function() return not EpicTipDB or EpicTipDB.anchoring ~= "fixed" end,
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                get = function() return EpicTipDB and EpicTipDB.fixedAnchorY end,
                set = function(_, val)
                    if EpicTipDB then EpicTipDB.fixedAnchorY = val end
                    if ET and ET.SaveConfig then ET:SaveConfig() end
                end,
            },
            showAnchorFrame = {
                name = L["Show/Move Anchor"],
                desc = L["Show a draggable anchor to visually position the tooltip"],
                type = "execute",
                order = 6.4,
                hidden = function() return not EpicTipDB or EpicTipDB.anchoring ~= "fixed" end,
                disabled = function() return not (EpicTipDB and EpicTipDB.enabled) end,
                func = function()
                    if ET.TooltipAnchoring then
                        ET.TooltipAnchoring:ShowAnchorFrame()
                    end
                end,
            },
            enableInspect = {
                name = L["Enable Player Inspection"],
                desc = L["Allow addon to inspect other players for detailed information"],
                type = "toggle",
                order = 7,
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

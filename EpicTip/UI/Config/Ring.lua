local addonName, ET = ...

ET.UI = ET.UI or {}
ET.UI.Config = ET.UI.Config or {}
local L = ET.L

function ET.UI.Config.GetRingConfig()
    if not EpicTipDB then
        return {
            name = "|cFFFFD700Ring|r",
            type = "group",
            order = 6,
            args = {
                loading = {
                    name = "Ring effects loading... (Database not ready)",
                    type = "description",
                    order = 1
                }
            }
        }
    end
    
    if not EpicTipDB.ring then
        EpicTipDB.ring = {
            enabled         = false,
            ringRadius      = 28,
            textureKey      = "Default",
            inCombatAlpha   = 0.70,
            outCombatAlpha  = 0.30,
            useClassColor   = true,
            useHighVis      = false,
            customColor     = { r = 1, g = 1, b = 1 },
            visible         = true
        }
    end
    
    return {
        name = "|cFFFFD700Ring|r",
        type = "group",
        order = 6,
        args = {
            general = {
                name = "General",
                type = "group",
                order = 1,
                args = {
                    desc = {
                        name = "|cFFFFD700» Enable/disable ring effects.|r",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    
                    ringEnabled = {
                        name = "Ring",
                        desc = "Show ring effect that follows your cursor",
                        type = "toggle",
                        order = 10,
                        get = function() 
                            return EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.enabled 
                        end,
                        set = function(_, val) 
                            if not EpicTipDB.ring then
                                EpicTipDB.ring = {
                                    enabled         = val,
                                    ringRadius      = 28,
                                    textureKey      = "Default",
                                    inCombatAlpha   = 0.70,
                                    outCombatAlpha  = 0.30,
                                    useClassColor   = true,
                                    useHighVis      = false,
                                    customColor     = { r = 1, g = 1, b = 1 },
                                    visible         = true
                                }
                            else
                                EpicTipDB.ring.enabled = val
                            end
                            
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                            if ET.Ring and ET.Ring.SetEnabled then
                                ET.Ring.SetEnabled(val)
                            end
                        end,
                    },
                    
                    ringVisible = {
                        name = "Visible",
                        desc = "Show or hide the ring effect",
                        type = "toggle",
                        order = 20,
                        disabled = function() return not (EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.enabled) end,
                        get = function() 
                            return EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.visible 
                        end,
                        set = function(_, val) 
                            if not EpicTipDB.ring then
                                EpicTipDB.ring = {
                                    enabled         = false,
                                    ringRadius      = 28,
                                    textureKey      = "Default",
                                    inCombatAlpha   = 0.70,
                                    outCombatAlpha  = 0.30,
                                    useClassColor   = true,
                                    useHighVis      = false,
                                    customColor     = { r = 1, g = 1, b = 1 },
                                    visible         = val
                                }
                            else
                                EpicTipDB.ring.visible = val
                            end
                            
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                            if ET.Ring and ET.Ring.SetVisible then
                                ET.Ring.SetVisible(val)
                            end
                        end,
                    },
                },
            },
            
            appearance = {
                name = "Appearance",
                type = "group",
                order = 2,
                args = {
                    desc = {
                        name = "|cFFFFD700» Configure ring appearance settings.|r",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    
                    ringThickness = {
                        name = "Ring Thickness",
                        desc = "Thickness of the ring effect",
                        type = "range",
                        order = 10,
                        min = 10,
                        max = 40,
                        step = 10,
                        disabled = function() return not (EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.enabled) end,
                        get = function() 
                            -- Convert textureKey to thickness value
                            if not EpicTipDB or not EpicTipDB.ring then return 30 end
                            local thicknessMap = {
                                ["Thin"] = 10,
                                ["Default"] = 30,
                                ["Thick"] = 40,
                                ["Solid"] = 20
                            }
                            return thicknessMap[EpicTipDB.ring.textureKey] or 30
                        end,
                        set = function(_, val) 
                            if not EpicTipDB then EpicTipDB = {} end
                            if not EpicTipDB.ring then EpicTipDB.ring = {} end
                            
                            -- Convert thickness value to textureKey
                            local thicknessMap = {
                                [10] = "Thin",
                                [20] = "Solid",
                                [30] = "Default",
                                [40] = "Thick"
                            }
                            EpicTipDB.ring.textureKey = thicknessMap[val] or "Default"
                            
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                            if ET.Ring and ET.Ring.UpdateAppearance then
                                ET.Ring.UpdateAppearance()
                            end
                        end,
                    },
                    
                    ringRadius = {
                        name = "Ring Radius",
                        desc = "Size of the ring effect",
                        type = "range",
                        order = 20,
                        min = 10,
                        max = 100,
                        step = 1,
                        disabled = function() return not (EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.ringRadius or 28 end,
                        set = function(_, val) 
                            if not EpicTipDB then EpicTipDB = {} end
                            if not EpicTipDB.ring then EpicTipDB.ring = {} end
                            EpicTipDB.ring.ringRadius = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                            if ET.Ring and ET.Ring.UpdateAppearance then
                                ET.Ring.UpdateAppearance()
                            end
                        end,
                    },
                    
                    inCombatAlpha = {
                        name = "In Combat Alpha",
                        desc = "Transparency of the ring during combat",
                        type = "range",
                        order = 30,
                        min = 0.0,
                        max = 1.0,
                        step = 0.05,
                        disabled = function() return not (EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.inCombatAlpha or 0.7 end,
                        set = function(_, val) 
                            if not EpicTipDB then EpicTipDB = {} end
                            if not EpicTipDB.ring then EpicTipDB.ring = {} end
                            EpicTipDB.ring.inCombatAlpha = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                            if ET.Ring and ET.Ring.UpdateAppearance then
                                ET.Ring.UpdateAppearance()
                            end
                        end,
                    },
                    
                    outCombatAlpha = {
                        name = "Out of Combat Alpha",
                        desc = "Transparency of the ring when not in combat",
                        type = "range",
                        order = 40,
                        min = 0.0,
                        max = 1.0,
                        step = 0.05,
                        disabled = function() return not (EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.outCombatAlpha or 0.3 end,
                        set = function(_, val) 
                            if not EpicTipDB then EpicTipDB = {} end
                            if not EpicTipDB.ring then EpicTipDB.ring = {} end
                            EpicTipDB.ring.outCombatAlpha = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                            if ET.Ring and ET.Ring.UpdateAppearance then
                                ET.Ring.UpdateAppearance()
                            end
                        end,
                    },
                },
            },
            
            color = {
                name = "Color",
                type = "group",
                order = 3,
                args = {
                    desc = {
                        name = "|cFFFFD700» Configure ring color settings.|r",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    
                    useClassColor = {
                        name = "Use Class Color",
                        desc = "Use your character's class color for the ring",
                        type = "toggle",
                        order = 10,
                        disabled = function() return not (EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.useClassColor end,
                        set = function(_, val) 
                            if not EpicTipDB then EpicTipDB = {} end
                            if not EpicTipDB.ring then EpicTipDB.ring = {} end
                            EpicTipDB.ring.useClassColor = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                            if ET.Ring and ET.Ring.UpdateAppearance then
                                ET.Ring.UpdateAppearance()
                            end
                        end,
                    },
                    
                    useHighVis = {
                        name = "High Visibility Mode",
                        desc = "Use high visibility green color for the ring",
                        type = "toggle",
                        order = 20,
                        disabled = function() return not (EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.enabled) end,
                        get = function() return EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.useHighVis end,
                        set = function(_, val) 
                            if not EpicTipDB then EpicTipDB = {} end
                            if not EpicTipDB.ring then EpicTipDB.ring = {} end
                            EpicTipDB.ring.useHighVis = val
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                            if ET.Ring and ET.Ring.UpdateAppearance then
                                ET.Ring.UpdateAppearance()
                            end
                        end,
                    },
                    
                    customColor = {
                        name = "Custom Ring Color",
                        desc = "Choose a custom color for the ring effect",
                        type = "color",
                        order = 30,
                        disabled = function() return not (EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.enabled) or
                                   (EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.useHighVis) end,
                        get = function() 
                            local color = EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.customColor or { r = 1, g = 1, b = 1 }
                            return color.r, color.g, color.b
                        end,
                        set = function(_, r, g, b) 
                            if not EpicTipDB then EpicTipDB = {} end
                            if not EpicTipDB.ring then EpicTipDB.ring = {} end
                            EpicTipDB.ring.customColor = { r = r, g = g, b = b }
                            if ET and ET.SaveConfig then ET:SaveConfig() end
                            if ET.Ring and ET.Ring.UpdateAppearance then
                                ET.Ring.UpdateAppearance()
                            end
                        end,
                    },
                },
            },
        },
    }
end
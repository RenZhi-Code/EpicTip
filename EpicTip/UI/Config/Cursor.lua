local addonName, ET = ...

ET.UI = ET.UI or {}
ET.UI.Config = ET.UI.Config or {}
local L = ET.L

function ET.UI.Config.GetCursorConfig()
    if not EpicTipDB then
        return {
            name = "|cFFFFD700Cursor|r",
            type = "group",
            order = 5,
            args = {
                loading = {
                    name = "Cursor effects loading... (Database not ready)",
                    type = "description",
                    order = 1
                }
            }
        }
    end
    
    -- Ensure default values for cursorGlow
    if not EpicTipDB.cursorGlow then
        EpicTipDB.cursorGlow = {
            enabled = false,
            texture = "Star1",
            colour = { r = 1, g = 1, b = 1 },
            useClassColor = true,
            size = 32,
            opacity = 0.8,
            enableTail = false,
            tailLength = 20,
            tailEffect = "classic",
            tailFadeSpeed = 0.5,
            enablePulse = false,
            pulseMinSize = 32,
            pulseMaxSize = 64,
            pulseSpeed = 1.0,
            enableClickGlow = false,
            clickGlowSize = 100,
            clickGlowDuration = 1.0,
            combatOnly = false,
            hideInCombat = false
        }
    end
    
    -- Ensure default values for ring
    if not EpicTipDB.ring then
        EpicTipDB.ring = {
            enabled         = false,
            ringRadius      = 28,
            textureKey      = "Default",
            inCombatAlpha   = 0.70,
            outCombatAlpha  = 0.30,
            useClassColor   = true,
            useHighVis      = false,
            colorMode       = "class",
            customColor     = { r = 1, g = 1, b = 1 },
            visible         = true
        }
    end
    
    return {
        name = "|cFFFFD700Cursor|r",
        type = "group",
        order = 5,
        childGroups = "tab",
        args = {
            glow = {
                name = "|cFFFFD700Glow|r",
                type = "group",
                order = 1,
                args = {
                    general = {
                        name = "General",
                        type = "group",
                        order = 1,
                        args = {
                            desc = {
                                name = "|cFFFFD700» Enable/disable cursor glow effects.|r",
                                type = "description",
                                order = 1,
                                fontSize = "medium",
                            },
                            
                            cursorGlowEnabled = {
                                name = "Cursor Glow",
                                desc = "Show glowing effects that follow your cursor",
                                type = "toggle",
                                order = 10,
                                get = function() 
                                    return EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled 
                                end,
                                set = function(_, val) 
                                    if not EpicTipDB.cursorGlow then
                                        EpicTipDB.cursorGlow = {
                                            enabled = val,
                                            texture = "Star1",
                                            color = { r = 1, g = 1, b = 1 },
                                            useClassColor = true,
                                            size = 32,
                                            opacity = 0.8,
                                            enableTail = false,
                                            tailLength = 20,
                                            tailEffect = "classic",
                                            tailFadeSpeed = 0.5,
                                            enablePulse = false,
                                            pulseMinSize = 32,
                                            pulseMaxSize = 64,
                                            pulseSpeed = 1.0,
                                            enableClickGlow = false,
                                            clickGlowSize = 100,
                                            clickGlowDuration = 1.0,
                                            combatOnly = false,
                                            hideInCombat = false
                                        }
                                    else
                                        EpicTipDB.cursorGlow.enabled = val
                                    end
                                    
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.SetEnabled then
                                        ET.CursorGlow.SetEnabled(val)
                                    end
                                end,
                            },
                        },
                    },
                    
                    glowSettings = {
                        name = "Glow",
                        type = "group",
                        order = 2,
                        args = {
                            desc = {
                                name = "|cFFFFD700» Configure detailed cursor glow settings.|r",
                                type = "description",
                                order = 1,
                                fontSize = "medium",
                            },
                            
                            cursorGlowTexture = {
                                name = "Glow Texture",
                                desc = "Choose the texture for the cursor glow effect",
                                type = "select",
                                order = 10,
                                disabled = function() return not (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled) end,
                                values = {
                                    ["Star1"] = "Star (Blizzard)",
                                    ["Star2"] = "Starburst (Blizzard)",
                                    ["Ring"] = "Ring",
                                    ["Solid"] = "Solid Glow",
                                    ["Spark"] = "Spark",
                                    ["Glow"] = "Spell Glow",
                                    ["Burst"] = "Burst Effect",
                                },
                                get = function() return EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.texture or "Star1" end,
                                set = function(_, val) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.cursorGlow then EpicTipDB.cursorGlow = {} end
                                    EpicTipDB.cursorGlow.texture = val
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.Refresh then
                                        ET.CursorGlow.Refresh()
                                    end
                                end,
                            },
                            
                            cursorGlowSize = {
                                name = "Glow Size",
                                desc = "Size of the cursor glow effect",
                                type = "range",
                                order = 20,
                                min = 16,
                                max = 128,
                                step = 4,
                                disabled = function() return not (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled) end,
                                get = function() return EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.size or 32 end,
                                set = function(_, val) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.cursorGlow then EpicTipDB.cursorGlow = {} end
                                    EpicTipDB.cursorGlow.size = val
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.Refresh then
                                        ET.CursorGlow.Refresh()
                                    end
                                end,
                            },
                            
                            cursorGlowOpacity = {
                                name = "Glow Opacity",
                                desc = "Transparency of the glow effect",
                                type = "range",
                                order = 30,
                                min = 0.1,
                                max = 1.0,
                                step = 0.1,
                                disabled = function() return not (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled) end,
                                get = function() return EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.opacity or 0.8 end,
                                set = function(_, val) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.cursorGlow then EpicTipDB.cursorGlow = {} end
                                    EpicTipDB.cursorGlow.opacity = val
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.Refresh then
                                        ET.CursorGlow.Refresh()
                                    end
                                end,
                            },
                            
                            cursorGlowUseClassColor = {
                                name = "Use Class Colour",
                                desc = "Use your character's class colour for the glow",
                                type = "toggle",
                                order = 40,
                                disabled = function() return not (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled) end,
                                get = function() return EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.useClassColor end,
                                set = function(_, val) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.cursorGlow then EpicTipDB.cursorGlow = {} end
                                    EpicTipDB.cursorGlow.useClassColor = val
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.Refresh then
                                        ET.CursorGlow.Refresh()
                                    end
                                end,
                            },
                            
                            cursorGlowCustomColor = {
                                name = "Custom Glow Colour",
                                desc = "Choose a custom colour for the glow effect",
                                type = "color",
                                order = 50,
                                disabled = function() return not (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled) or (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.useClassColor) end,
                                get = function() 
                                    local colour = EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.color or { r = 1, g = 1, b = 1 }
                                    return colour.r, colour.g, colour.b
                                end,
                                set = function(_, r, g, b) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.cursorGlow then EpicTipDB.cursorGlow = {} end
                                    EpicTipDB.cursorGlow.color = { r = r, g = g, b = b }
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.Refresh then
                                        ET.CursorGlow.Refresh()
                                    end
                                end,
                            },
                            
                            cursorGlowEnableTail = {
                                name = "Enable Tail Effects",
                                desc = "Add trailing effects behind the cursor glow",
                                type = "toggle",
                                order = 60,
                                disabled = function() return not (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled) end,
                                get = function() return EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enableTail end,
                                set = function(_, val) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.cursorGlow then EpicTipDB.cursorGlow = {} end
                                    EpicTipDB.cursorGlow.enableTail = val
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.Refresh then
                                        ET.CursorGlow.Refresh()
                                    end
                                end,
                            },
                            
                            cursorGlowEnablePulse = {
                                name = "Enable Pulse Effect",
                                desc = "Make the glow pulsate in size",
                                type = "toggle",
                                order = 70,
                                disabled = function() return not (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled) end,
                                get = function() return EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enablePulse end,
                                set = function(_, val) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.cursorGlow then EpicTipDB.cursorGlow = {} end
                                    EpicTipDB.cursorGlow.enablePulse = val
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.Refresh then
                                        ET.CursorGlow.Refresh()
                                    end
                                end,
                            },
                        },
                    },
                    
                    advanced = {
                        name = "Advanced",
                        type = "group",
                        order = 3,
                        args = {
                            desc = {
                                name = "|cFFFFD700» Configure advanced cursor glow settings.|r",
                                type = "description",
                                order = 1,
                                fontSize = "medium",
                            },
                            
                            tailLength = {
                                name = "Tail Length",
                                desc = "Length of the trail effect (if enabled)",
                                type = "range",
                                order = 10,
                                min = 5,
                                max = 50,
                                step = 5,
                                disabled = function() return not (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled and EpicTipDB.cursorGlow.enableTail) end,
                                get = function() return EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.tailLength or 20 end,
                                set = function(_, val) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.cursorGlow then EpicTipDB.cursorGlow = {} end
                                    EpicTipDB.cursorGlow.tailLength = val
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.Refresh then
                                        ET.CursorGlow.Refresh()
                                    end
                                end,
                            },
                            
                            tailEffect = {
                                name = "Tail Effect",
                                desc = "Choose the style of the tail effect",
                                type = "select",
                                order = 20,
                                disabled = function() return not (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled and EpicTipDB.cursorGlow.enableTail) end,
                                values = {
                                    ["classic"] = "Classic",
                                    ["sparkle"] = "Sparkle",
                                    ["wobble"] = "Wobble",
                                    ["rainbow"] = "Rainbow",
                                },
                                get = function() return EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.tailEffect or "classic" end,
                                set = function(_, val) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.cursorGlow then EpicTipDB.cursorGlow = {} end
                                    EpicTipDB.cursorGlow.tailEffect = val
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.Refresh then
                                        ET.CursorGlow.Refresh()
                                    end
                                end,
                            },
                            
                            tailFadeSpeed = {
                                name = "Tail Fade Speed",
                                desc = "How quickly the tail fades out (higher = faster)",
                                type = "range",
                                order = 30,
                                min = 0.1,
                                max = 2.0,
                                step = 0.1,
                                disabled = function() return not (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled and EpicTipDB.cursorGlow.enableTail) end,
                                get = function() return EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.tailFadeSpeed or 0.5 end,
                                set = function(_, val) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.cursorGlow then EpicTipDB.cursorGlow = {} end
                                    EpicTipDB.cursorGlow.tailFadeSpeed = val
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.Refresh then
                                        ET.CursorGlow.Refresh()
                                    end
                                end,
                            },
                            
                            pulseMinSize = {
                                name = "Pulse Minimum Size",
                                desc = "Smallest size during pulse animation",
                                type = "range",
                                order = 40,
                                min = 16,
                                max = 64,
                                step = 4,
                                disabled = function() return not (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled and EpicTipDB.cursorGlow.enablePulse) end,
                                get = function() return EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.pulseMinSize or 32 end,
                                set = function(_, val) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.cursorGlow then EpicTipDB.cursorGlow = {} end
                                    EpicTipDB.cursorGlow.pulseMinSize = val
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.Refresh then
                                        ET.CursorGlow.Refresh()
                                    end
                                end,
                            },
                            
                            pulseMaxSize = {
                                name = "Pulse Maximum Size",
                                desc = "Largest size during pulse animation",
                                type = "range",
                                order = 50,
                                min = 32,
                                max = 128,
                                step = 4,
                                disabled = function() return not (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled and EpicTipDB.cursorGlow.enablePulse) end,
                                get = function() return EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.pulseMaxSize or 64 end,
                                set = function(_, val) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.cursorGlow then EpicTipDB.cursorGlow = {} end
                                    EpicTipDB.cursorGlow.pulseMaxSize = val
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.Refresh then
                                        ET.CursorGlow.Refresh()
                                    end
                                end,
                            },
                            
                            pulseSpeed = {
                                name = "Pulse Speed",
                                desc = "Speed of the pulse animation",
                                type = "range",
                                order = 60,
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                disabled = function() return not (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled and EpicTipDB.cursorGlow.enablePulse) end,
                                get = function() return EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.pulseSpeed or 1.0 end,
                                set = function(_, val) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.cursorGlow then EpicTipDB.cursorGlow = {} end
                                    EpicTipDB.cursorGlow.pulseSpeed = val
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.Refresh then
                                        ET.CursorGlow.Refresh()
                                    end
                                end,
                            },
                            
                            combatOnly = {
                                name = "Combat Only",
                                desc = "Only show the cursor glow during combat",
                                type = "toggle",
                                order = 70,
                                disabled = function() return not (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled) end,
                                get = function() return EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.combatOnly end,
                                set = function(_, val) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.cursorGlow then EpicTipDB.cursorGlow = {} end
                                    EpicTipDB.cursorGlow.combatOnly = val
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.Refresh then
                                        ET.CursorGlow.Refresh()
                                    end
                                end,
                            },
                            
                            hideInCombat = {
                                name = "Hide In Combat",
                                desc = "Hide the cursor glow during combat",
                                type = "toggle",
                                order = 80,
                                disabled = function() return not (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled) or (EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.combatOnly) end,
                                get = function() return EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.hideInCombat end,
                                set = function(_, val) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.cursorGlow then EpicTipDB.cursorGlow = {} end
                                    EpicTipDB.cursorGlow.hideInCombat = val
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.CursorGlow and ET.CursorGlow.Refresh then
                                        ET.CursorGlow.Refresh()
                                    end
                                end,
                            },
                        },
                    },
                },
            },
            
            ring = {
                name = "|cFFFFD700Ring|r",
                type = "group",
                order = 2,
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
                                            colorMode       = "class",
                                            customColor     = { r = 1, g = 1, b = 1 },
                                            visible         = true
                                        }
                                    else
                                        EpicTipDB.ring.enabled = val
                                        if EpicTipDB.ring then
                                            EpicTipDB.ring.visible = val
                                        end
                                    end
                                    
                                    if ET and ET.SaveConfig then ET:SaveConfig() end
                                    if ET.Ring and ET.Ring.SetEnabled then
                                        ET.Ring.SetEnabled(val)
                                    end
                                    if ET.Ring and ET.Ring.SetVisible then
                                        ET.Ring.SetVisible(val)
                                    end
                                end,
                            },
                            -- Removed redundant visible checkbox since it's controlled by the enabled toggle
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
                                    -- Map texture keys to thickness values
                                    local textureKey = EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.textureKey or "Default"
                                    if textureKey == "Thin" then
                                        return 10
                                    elseif textureKey == "Default" then
                                        return 30
                                    elseif textureKey == "Thick" then
                                        return 40
                                    else
                                        return 30
                                    end
                                end,
                                set = function(_, val) 
                                    if not EpicTipDB then EpicTipDB = {} end
                                    if not EpicTipDB.ring then EpicTipDB.ring = {} end
                                    
                                    -- Map thickness values to texture keys
                                    if val <= 10 then
                                        EpicTipDB.ring.textureKey = "Thin"
                                    elseif val <= 20 then
                                        EpicTipDB.ring.textureKey = "Solid"  -- Using Solid for 20px
                                    elseif val <= 30 then
                                        EpicTipDB.ring.textureKey = "Default"
                                    else
                                        EpicTipDB.ring.textureKey = "Thick"
                                    end
                                    
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
                        name = "Colour",
                        type = "group",
                        order = 3,
                        args = {
                            desc = {
                                name = "|cFFFFD700» Configure ring colour settings.|r",
                                type = "description",
                                order = 1,
                                fontSize = "medium",
                            },
                            
                            useClassColor = {
                                name = "Use Class Colour",
                                desc = "Use your character's class colour for the ring",
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
                                desc = "Use high visibility green colour for the ring",
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
                                name = "Custom Ring Colour",
                                desc = "Choose a custom colour for the ring effect",
                                type = "color",
                                order = 30,
                                disabled = function() 
                                    if not (EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.enabled) then
                                        return true
                                    end
                                    if EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.useHighVis then
                                        return true
                                    end
                                    return false
                                end,
                                get = function() 
                                    local colour = EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.customColor or { r = 1, g = 1, b = 1 }
                                    return colour.r, colour.g, colour.b
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
            },
        },
    }
end
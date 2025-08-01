local addonName, JTT = ...

if not LibStub then return end

local AceAddon = LibStub:GetLibrary("AceAddon-3.0", true)
if not AceAddon then return end

local existingModules = {}
if JTT then
    existingModules.Config = JTT.Config
    existingModules.Tooltip = JTT.Tooltip
    existingModules.ItemInfo = JTT.ItemInfo
    existingModules.StatValues = JTT.StatValues
    existingModules.MountInfo = JTT.MountInfo
    existingModules.Ring = JTT.Ring
    existingModules.Utils = JTT.Utils
    existingModules.L = JTT.L
end

JTT = LibStub("AceAddon-3.0"):NewAddon("JustTheTip", "AceConsole-3.0", "AceEvent-3.0")

for k, v in pairs(existingModules) do
    if v then
        JTT[k] = v
    end
end

JTT.L = JTT.L or {}
local L = JTT.L
JTT.VERSION = "01.08.25.10"
JTT.COLORED_TITLE = "|cFFFF0000Just|r the |cFF33CCFFTip|r"
JTT.CHAT_PREFIX = "|cFFFF0000Just|r the |cFF33CCFFTip|r:"
local defaults = {
    profile = {
        enabled = true,
        showIlvl = true,
        showTarget = true,
        showSpec = true,
        showItemInfo = true,
        showStatValues = true,
        showMountInfo = true,
        anchorToMouse = true,
        scale = 1.0,
        hideHealthBar = false,
        hideInCombat = false,
        showClassIcon = true,
        showRoleIcon = true,
        showMythicRating = false,
        showPvPRating = false,
        debugMode = false,
        enableInspect = true,
        backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
        backgroundOpacity = 0.8,
        ring = {
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
    }
}
local options = {
    name = JTT.COLORED_TITLE .. " v" .. JTT.VERSION,
    handler = JTT,
    type = "group",
    childGroups = "tab",
    args = {
        general = {
            name = "General",
            type = "group",
            order = 1,
            args = {
                enabled = {
                    name = "Enable Tooltip",
                    desc = "Enable or disable the addon",
                    type = "toggle",
                    order = 1,
                    get = function() return JTT.db.profile.enabled end,
                    set = function(_, val) 
                        JTT.db.profile.enabled = val
                        JTT:SaveConfig()
                    end,
                },
                showIlvl = {
                    name = "Show Item Level",
                    desc = "Show item level on player tooltips",
                    type = "toggle",
                    order = 2,
                    get = function() return JTT.db.profile.showIlvl end,
                    set = function(_, val) 
                        JTT.db.profile.showIlvl = val
                        JTT:SaveConfig()
                    end,
                },
                showSpec = {
                    name = "Show Specialization",
                    desc = "Show player specialization",
                    type = "toggle",
                    order = 3,
                    get = function() return JTT.db.profile.showSpec end,
                    set = function(_, val) 
                        JTT.db.profile.showSpec = val
                        JTT:SaveConfig()
                    end,
                },
                showTarget = {
                    name = "Show Target",
                    desc = "Show player's current target",
                    type = "toggle",
                    order = 4,
                    get = function() return JTT.db.profile.showTarget end,
                    set = function(_, val) 
                        JTT.db.profile.showTarget = val
                        JTT:SaveConfig()
                    end,
                },
                showClassIcon = {
                    name = "Show Class Icon",
                    desc = "Show class icons on player names",
                    type = "toggle",
                    order = 5,
                    get = function() return JTT.db.profile.showClassIcon end,
                    set = function(_, val) 
                        JTT.db.profile.showClassIcon = val
                        JTT:SaveConfig()
                    end,
                },
                showRoleIcon = {
                    name = "Show Role Icon",
                    desc = "Show role icons (Tank/Healer/DPS)",
                    type = "toggle",
                    order = 6,
                    get = function() return JTT.db.profile.showRoleIcon end,
                    set = function(_, val) 
                        JTT.db.profile.showRoleIcon = val
                        JTT:SaveConfig()
                    end,
                },
            }
        },
        appearance = {
            name = "Appearance",
            type = "group",
            order = 2,
            args = {
                anchorToMouse = {
                    name = "Anchor to Mouse Cursor",
                    desc = "Anchor tooltips to mouse cursor instead of default position",
                    type = "toggle",
                    order = 1,
                    get = function() return JTT.db.profile.anchorToMouse end,
                    set = function(_, val) 
                        JTT.db.profile.anchorToMouse = val
                        JTT:SaveConfig()
                    end,
                },
                scale = {
                    name = "Tooltip Scale",
                    desc = "Scale of the tooltip",
                    type = "range",
                    order = 2,
                    min = 0.5,
                    max = 2.0,
                    step = 0.05,
                    get = function() return JTT.db.profile.scale end,
                    set = function(_, val) 
                        JTT.db.profile.scale = val
                        JTT:SaveConfig()
                    end,
                },
                hideHealthBar = {
                    name = "Hide Health Bar",
                    desc = "Hide the tooltip health bar",
                    type = "toggle",
                    order = 3,
                    get = function() return JTT.db.profile.hideHealthBar end,
                    set = function(_, val) 
                        JTT.db.profile.hideHealthBar = val
                        JTT:SaveConfig()
                    end,
                },
                hideInCombat = {
                    name = "Hide In Combat",
                    desc = "Hide tooltips during combat",
                    type = "toggle",
                    order = 4,
                    get = function() return JTT.db.profile.hideInCombat end,
                    set = function(_, val) 
                        JTT.db.profile.hideInCombat = val
                        JTT:SaveConfig()
                    end,
                },
                bgColorHeader = {
                    name = "Background Settings",
                    type = "header",
                    order = 5,
                },
                backgroundColor = {
                    name = "Background Color",
                    desc = "Color of the tooltip background",
                    type = "color",
                    order = 6,
                    hasAlpha = true,
                    get = function()
                        local color = JTT.db.profile.backgroundColor
                        return color.r, color.g, color.b, color.a
                    end,
                    set = function(_, r, g, b, a)
                        JTT.db.profile.backgroundColor = { r = r, g = g, b = b, a = a }
                        JTT:SaveConfig()
                    end,
                },
                backgroundOpacity = {
                    name = "Background Opacity",
                    desc = "Opacity of the tooltip background (0 = transparent, 1 = opaque)",
                    type = "range",
                    order = 7,
                    min = 0,
                    max = 1,
                    step = 0.05,
                    get = function() return JTT.db.profile.backgroundOpacity end,
                    set = function(_, val) 
                        JTT.db.profile.backgroundOpacity = val
                        JTT:SaveConfig()
                    end,
                },
            }
        },
        features = {
            name = "Features",
            type = "group",
            order = 3,
            args = {
                showMythicRating = {
                    name = "Show Mythic+ Rating",
                    desc = "Show Mythic+ rating on player tooltips",
                    type = "toggle",
                    order = 1,
                    get = function() return JTT.db.profile.showMythicRating end,
                    set = function(_, val) 
                        JTT.db.profile.showMythicRating = val
                        JTT:SaveConfig()
                    end,
                },
                showPvPRating = {
                    name = "Show PvP Rating",
                    desc = "Show PvP rating on player tooltips",
                    type = "toggle",
                    order = 2,
                    get = function() return JTT.db.profile.showPvPRating end,
                    set = function(_, val) 
                        JTT.db.profile.showPvPRating = val
                        JTT:SaveConfig()
                    end,
                },
                showItemInfo = {
                    name = "Show Item Info",
                    desc = "Show enhanced item information on item tooltips",
                    type = "toggle",
                    order = 3,
                    get = function() return JTT.db.profile.showItemInfo end,
                    set = function(_, val) 
                        JTT.db.profile.showItemInfo = val
                        JTT:SaveConfig()
                    end,
                },
                showStatValues = {
                    name = "Show Stat Values",
                    desc = "Show true stat values with diminishing returns on stat tooltips",
                    type = "toggle",
                    order = 4,
                    get = function() return JTT.db.profile.showStatValues end,
                    set = function(_, val) 
                        JTT.db.profile.showStatValues = val
                        JTT:SaveConfig()
                    end,
                },
                showMountInfo = {
                    name = "Show Mount Info",
                    desc = "Show mount information when hovering over mounted players",
                    type = "toggle",
                    order = 5,
                    get = function() return JTT.db.profile.showMountInfo end,
                    set = function(_, val) 
                        JTT.db.profile.showMountInfo = val
                        JTT:SaveConfig()
                    end,
                },
        
                enableInspect = {
                    name = "Enable Inspect",
                    desc = "Enable inspecting other players for detailed information",
                    type = "toggle",
                    order = 7,
                    get = function() return JTT.db.profile.enableInspect end,
                    set = function(_, val) 
                        JTT.db.profile.enableInspect = val
                        JTT:SaveConfig()
                    end,
                },
            }
        },
        ring = {
            name = "Cursor Ring",
            type = "group",
            order = 4,
            args = {
                enabled = {
                    name = "Enable Cursor Ring",
                    desc = "Show a ring around your mouse cursor that changes appearance in combat",
                    type = "toggle",
                    order = 1,
                    get = function() return JTT.db.profile.ring.enabled end,
                    set = function(_, val) 
                        JTT.db.profile.ring.enabled = val
                        if JTT.Ring and JTT.Ring.SetEnabled then
                            JTT.Ring.SetEnabled(val)
                        end
                        JTT:SaveConfig()
                    end,
                },
                visible = {
                    name = "Visible",
                    desc = "Show/hide the cursor ring (ring must be enabled)",
                    type = "toggle",
                    order = 2,
                    disabled = function() return not JTT.db.profile.ring.enabled end,
                    get = function() return JTT.db.profile.ring.visible end,
                    set = function(_, val) 
                        JTT.db.profile.ring.visible = val
                        if JTT.Ring and JTT.Ring.Refresh then
                            JTT.Ring.Refresh()
                        end
                        JTT:SaveConfig()
                    end,
                },
                ringRadius = {
                    name = "Ring Size",
                    desc = "Size of the cursor ring",
                    type = "range",
                    order = 3,
                    min = 16,
                    max = 64,
                    step = 2,
                    disabled = function() return not JTT.db.profile.ring.enabled end,
                    get = function() return JTT.db.profile.ring.ringRadius end,
                    set = function(_, val) 
                        JTT.db.profile.ring.ringRadius = val
                        if JTT.Ring and JTT.Ring.Refresh then
                            JTT.Ring.Refresh()
                        end
                        JTT:SaveConfig()
                    end,
                },
                textureKey = {
                    name = "Ring Texture",
                    desc = "Visual style of the cursor ring",
                    type = "select",
                    order = 4,
                    values = {
                        Default = "Default",
                        Thin = "Thin",
                        Thick = "Thick",
                        Solid = "Solid"
                    },
                    disabled = function() return not JTT.db.profile.ring.enabled end,
                    get = function() return JTT.db.profile.ring.textureKey end,
                    set = function(_, val) 
                        JTT.db.profile.ring.textureKey = val
                        if JTT.Ring and JTT.Ring.Refresh then
                            JTT.Ring.Refresh()
                        end
                        JTT:SaveConfig()
                    end,
                },
                alphaHeader = {
                    name = "Transparency Settings",
                    type = "header",
                    order = 5,
                },
                inCombatAlpha = {
                    name = "Combat Transparency",
                    desc = "Ring transparency while in combat (0 = invisible, 1 = opaque)",
                    type = "range",
                    order = 6,
                    min = 0,
                    max = 1,
                    step = 0.05,
                    disabled = function() return not JTT.db.profile.ring.enabled end,
                    get = function() return JTT.db.profile.ring.inCombatAlpha end,
                    set = function(_, val) 
                        JTT.db.profile.ring.inCombatAlpha = val
                        if JTT.Ring and JTT.Ring.Refresh then
                            JTT.Ring.Refresh()
                        end
                        JTT:SaveConfig()
                    end,
                },
                outCombatAlpha = {
                    name = "Out of Combat Transparency",
                    desc = "Ring transparency while out of combat (0 = invisible, 1 = opaque)",
                    type = "range",
                    order = 7,
                    min = 0,
                    max = 1,
                    step = 0.05,
                    disabled = function() return not JTT.db.profile.ring.enabled end,
                    get = function() return JTT.db.profile.ring.outCombatAlpha end,
                    set = function(_, val) 
                        JTT.db.profile.ring.outCombatAlpha = val
                        if JTT.Ring and JTT.Ring.Refresh then
                            JTT.Ring.Refresh()
                        end
                        JTT:SaveConfig()
                    end,
                },
                colorHeader = {
                    name = "Color Settings",
                    type = "header",
                    order = 8,
                },
                useClassColor = {
                    name = "Use Class Color",
                    desc = "Use your character's class color for the ring",
                    type = "toggle",
                    order = 9,
                    disabled = function() return not JTT.db.profile.ring.enabled end,
                    get = function() return JTT.db.profile.ring.useClassColor end,
                    set = function(_, val) 
                        JTT.db.profile.ring.useClassColor = val
                        JTT.db.profile.ring.colorMode = val and "class" or "custom"
                        if JTT.Ring and JTT.Ring.Refresh then
                            JTT.Ring.Refresh()
                        end
                        JTT:SaveConfig()
                    end,
                },
                useHighVis = {
                    name = "High Visibility Mode",
                    desc = "Use bright green color for maximum visibility (overrides other color settings)",
                    type = "toggle",
                    order = 10,
                    disabled = function() return not JTT.db.profile.ring.enabled end,
                    get = function() return JTT.db.profile.ring.useHighVis end,
                    set = function(_, val) 
                        JTT.db.profile.ring.useHighVis = val
                        if JTT.Ring and JTT.Ring.Refresh then
                            JTT.Ring.Refresh()
                        end
                        JTT:SaveConfig()
                    end,
                },
                customColor = {
                    name = "Custom Color",
                    desc = "Custom color for the ring (only used when class color is disabled)",
                    type = "color",
                    order = 11,
                    disabled = function() return not JTT.db.profile.ring.enabled or JTT.db.profile.ring.useClassColor or JTT.db.profile.ring.useHighVis end,
                    get = function()
                        local color = JTT.db.profile.ring.customColor
                        return color.r, color.g, color.b
                    end,
                    set = function(_, r, g, b)
                        JTT.db.profile.ring.customColor = { r = r, g = g, b = b }
                        JTT.db.profile.ring.colorMode = "custom"
                        if JTT.Ring and JTT.Ring.Refresh then
                            JTT.Ring.Refresh()
                        end
                        JTT:SaveConfig()
                    end,
                },
            }
        },
        debug = {
            name = "Debug",
            type = "group",
            order = 5,
            args = {
                debugMode = {
                    name = "Debug Mode",
                    desc = "Enable debug information in tooltips",
                    type = "toggle",
                    order = 1,
                    get = function() return JTT.db.profile.debugMode end,
                    set = function(_, val) 
                        JTT.db.profile.debugMode = val
                        JTT:SaveConfig()
                    end,
                },
            }
        }
    }
}

function JTT:RefreshConfig()
    JustTheTipDB = self.db.profile
    
    if self.db then
        JustTheTipDB = self.db.profile
    end
end

function JTT:SaveConfig()
    if self.db then
        JustTheTipDB = self.db.profile
        
        if GameTooltip and GameTooltip:IsVisible() then
            local _, unit = GameTooltip:GetUnit()
            if unit then
                GameTooltip:Hide()
                GameTooltip:SetUnit(unit)
            end
        end
        
        if GameTooltip and JustTheTipDB and JustTheTipDB.scale then
            GameTooltip:SetScale(JustTheTipDB.scale)
        end
    end
end

function JTT:OnInitialize()
    if not LibStub then return end
    
    local AceAddon = LibStub:GetLibrary("AceAddon-3.0", true)
    if not AceAddon then return end
    
    local AceDB = LibStub:GetLibrary("AceDB-3.0", true)
    if not AceDB then return end
    
    self.db = AceDB:New("JustTheTipSettings", defaults, true)
    if not self.db then return end
    
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
    
    JustTheTipDB = self.db.profile
    
    local AceConfig = LibStub("AceConfig-3.0", true)
    if AceConfig then
        AceConfig:RegisterOptionsTable("JustTheTip", options)
    end
    
    local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
    if AceConfigDialog then
        self.optionsFrame = AceConfigDialog:AddToBlizOptions("JustTheTip", JTT.COLORED_TITLE)
    end
    
    self:RegisterChatCommand("jtt", "SlashCommand")
    self:RegisterChatCommand("justthetp", "SlashCommand")
end

function JTT:OnEnable()
    if JTT.Config and JTT.Config.Initialize then
        JTT.Config.Initialize()
    end
    if JTT.Tooltip and JTT.Tooltip.Initialize then
        JTT.Tooltip.Initialize()
    end
    if JTT.Ring and JTT.Ring.Initialize then
        JTT.Ring.Initialize()
    end
    
    if JTT.Tooltip and JTT.Tooltip.SetupTooltipProcessor then
        JTT.Tooltip.SetupTooltipProcessor()
    end
    
    if JTT.ItemInfo and JTT.ItemInfo.SetupItemTooltipProcessor then
        JTT.ItemInfo.SetupItemTooltipProcessor()
    end
    
    if JTT.StatValues and JTT.StatValues.SetupStatTooltipProcessor then
        JTT.StatValues.SetupStatTooltipProcessor()
    end
    
    if JTT.MountInfo and JTT.MountInfo.SetupMountTooltipProcessor then
        JTT.MountInfo.SetupMountTooltipProcessor()
    end
    
    if JTT.Ring and self.db.profile.ring.enabled then
        JTT.Ring.SetEnabled(true)
    end
    
    if JTT.Tooltip and JTT.Tooltip.SetupAnchorHook then
        JTT.Tooltip.SetupAnchorHook()
    end
    
    if JTT.ItemInfo and JTT.ItemInfo.SetupSlashCommands then
        JTT.ItemInfo.SetupSlashCommands()
    end
    
    local AceConfig = LibStub("AceConfig-3.0", true)
    local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
    if AceConfig and AceConfigDialog then
        AceConfig:RegisterOptionsTable("JustTheTip", options)
        AceConfigDialog:SetDefaultSize("JustTheTip", 600, 500)
    end
    
    self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnTargetChanged")
    self:RegisterEvent("INSPECT_READY", "OnInspectReady")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnCombatEnd")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnCombatStart")
end

function JTT:SlashCommand(input)
    input = string.trim(input or "")
    
    -- Parse command into parts
    local cmd, arg1, arg2 = strsplit(" ", input, 3)
    
    -- Try Ring commands first
    if JTT.Ring and JTT.Ring.HandleSlashCommand then
        if JTT.Ring.HandleSlashCommand(cmd, arg1, arg2) then
            return -- Ring handled the command
        end
    end
    
    -- Handle main addon commands
    if input == "debug" then
        self.db.profile.debugMode = not self.db.profile.debugMode
        print(JTT.CHAT_PREFIX .. " Debug mode " .. (self.db.profile.debugMode and "enabled" or "disabled"))
    elseif input == "config" or input == "options" then
        local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
        if AceConfigDialog then
            AceConfigDialog:Open("JustTheTip")
        end
    elseif input == "save" then
        print(JTT.CHAT_PREFIX .. " Saved Variables Check:")
        print(JTT.CHAT_PREFIX .. " JustTheTipSettings exists = " .. tostring(JustTheTipSettings ~= nil))
        print(JTT.CHAT_PREFIX .. " JTT.db exists = " .. tostring(self.db ~= nil))
        print(JTT.CHAT_PREFIX .. " JTT.db.profile exists = " .. tostring(self.db and self.db.profile ~= nil))
        if JustTheTipSettings then
            print(JTT.CHAT_PREFIX .. " JustTheTipSettings.profiles exists = " .. tostring(JustTheTipSettings.profiles ~= nil))
        end
        self:SaveConfig()
        print(JTT.CHAT_PREFIX .. " Config saved and refreshed")
    elseif input == "test" then
        print(JTT.CHAT_PREFIX .. " Database test (v" .. JTT.VERSION .. "):")
        print(JTT.CHAT_PREFIX .. " JustTheTipDB.enabled = " .. tostring(JustTheTipDB.enabled))
        print(JTT.CHAT_PREFIX .. " JustTheTipDB.hideHealthBar = " .. tostring(JustTheTipDB.hideHealthBar))
        print(JTT.CHAT_PREFIX .. " JustTheTipDB.scale = " .. tostring(JustTheTipDB.scale))
        print(JTT.CHAT_PREFIX .. " JustTheTipDB.showStatValues = " .. tostring(JustTheTipDB.showStatValues))
        print(JTT.CHAT_PREFIX .. " Tooltip module exists = " .. tostring(JTT.Tooltip ~= nil))
        print(JTT.CHAT_PREFIX .. " Utils module exists = " .. tostring(JTT.Utils ~= nil))
        print(JTT.CHAT_PREFIX .. " Ring module exists = " .. tostring(JTT.Ring ~= nil))
        print(JTT.CHAT_PREFIX .. " StatValues module exists = " .. tostring(JTT.StatValues ~= nil))
        print(JTT.CHAT_PREFIX .. " Localization exists = " .. tostring(JTT.L ~= nil))
    elseif input == "statdebug" then
        if JTT.StatValues and JTT.StatValues.DebugStatValues then
            JTT.StatValues.DebugStatValues()
        else
            print(JTT.CHAT_PREFIX .. " StatValues debug not available")
        end
    else
        -- Show help
        print(JTT.CHAT_PREFIX .. " Available commands:")
        print("  /jtt config - Open configuration panel")
        print("  /jtt ring show/hide/toggle - Control cursor ring")
        print("  /jtt debug - Toggle debug mode")
        print("  /jtt statdebug - Test stat values system")
    end
end

function JTT:OnTargetChanged()
    if JTT.Tooltip and JTT.Tooltip.OnTargetChanged then
        JTT.Tooltip.OnTargetChanged()
    end
end

function JTT:OnInspectReady(event, guid)
    if JTT.Tooltip and JTT.Tooltip.OnInspectReady then
        JTT.Tooltip.OnInspectReady(guid)
    end
end

function JTT:OnCombatStart()
    if JTT.Utils and JTT.Utils.pendingInspects then
        wipe(JTT.Utils.pendingInspects)
    end
    if JTT.Ring and JTT.Ring.OnCombatStart then
        JTT.Ring.OnCombatStart()
    end
end

function JTT:OnCombatEnd()
    if JTT.Ring and JTT.Ring.OnCombatEnd then
        JTT.Ring.OnCombatEnd()
    end
end
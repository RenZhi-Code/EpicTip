local addonName, ET = ...

if not LibStub then return end

local AceAddon = LibStub:GetLibrary("AceAddon-3.0", true)
if not AceAddon then return end

-- Preserve existing modules if already created
local existingModules = {}
if ET then
    existingModules.Config = ET.Config
    existingModules.Tooltip = ET.Tooltip
    existingModules.Utils = ET.Utils
    existingModules.L = ET.L
end

-- Create AceAddon instance
local existingET = ET
ET = LibStub("AceAddon-3.0"):NewAddon("EpicTip", "AceConsole-3.0", "AceEvent-3.0")

-- Restore existing modules
if existingET then
    for k, v in pairs(existingET) do
        if not ET[k] then
            ET[k] = v
        end
    end
end

for k, v in pairs(existingModules) do
    if v then
        ET[k] = v
    end
end

ET.L = ET.L or {}
ET.VERSION = "31.08.25.20"
ET.COLORED_TITLE = "|cFFFF0000Epic|r|cFF33CCFFTip|r"
ET.CHAT_PREFIX = "|cFFFF0000Epic|r|cFF33CCFFTip|r:"

-- AceDB defaults with profile system
local defaults = {
    profile = {
        enabled = true,
        showIlvl = true,
        showTarget = true,
        showSpec = true,
        showClassIcon = true,
        showRoleIcon = true,
        showMythicRating = true,
        showPvPRating = true,
        showItemInfo = true,
        showStatValues = true,
        showMountInfo = true,
        hideHealthBar = false,
        hideNPCHealthBar = false,
        hideInCombat = false,
        enableInspect = true,
        showGuildRank = true,
        showHealthNumbers = false,
        scale = 1.0,
        anchoring = "default",
        debugMode = false,
        
        -- Ring defaults
        ring = {
            enabled         = false,
            ringRadius      = 28,
            textureKey      = "Default",
            inCombatAlpha   = 0.70,
            outCombatAlpha  = 0.30,
            useClassColor   = true,
            useHighVis      = false,
            customColor     = { r = 1, g = 1, b = 1 },
            visible         = true
        },
        
        -- CursorGlow defaults (NEW)
        cursorGlow = {
            enabled = false,
            texture = "Star1",
            color = { r = 1, g = 1, b = 1 },
            useClassColor = true,
            size = 32,
            opacity = 0.8,
            
            -- Tail effect
            enableTail = false,
            tailLength = 20,
            tailEffect = "classic", -- classic, sparkle, wobble, rainbow
            tailFadeSpeed = 0.5,
            
            -- Pulse effect
            enablePulse = false,
            pulseMinSize = 32,
            pulseMaxSize = 64,
            pulseSpeed = 1.0,
            
            -- Click explosion
            enableClickGlow = false,
            clickGlowSize = 100,
            clickGlowDuration = 1.0,
            
            -- Combat settings
            combatOnly = false,
            hideInCombat = false
        }
    }
}

-- Config loading flag
ET.configLoaded = false

-- Refresh config after profile changes
function ET:RefreshConfig()
    EpicTipDB = self.db.profile
    
    -- Reinitialize feature modules with new profile settings
    self:InitializeFeatureModules()
    
    -- Clear any cached configuration
    if ET.ConfigManager and ET.ConfigManager.ClearCache then
        ET.ConfigManager.ClearCache()
    end
    
    -- Refresh font settings if FontManager exists
    if ET.FontManager then
        ET.FontManager.fontsInitialized = false
    end
    
    -- Print profile change notification if debug mode is enabled
    if EpicTipDB and EpicTipDB.debugMode then
        print("EpicTip: Profile changed to '" .. (self.db:GetCurrentProfile() or "Unknown") .. "'")
    end
end

-- Load config system on-demand (saves memory)
function ET:LoadConfigOnDemand()
    if self.configLoaded then return end
    
    if ET.ConfigManager then
        ET.ConfigManager.Initialize()
        
        local AceConfig = LibStub("AceConfig-3.0", true)
        if AceConfig then
            AceConfig:RegisterOptionsTable("EpicTip", function()
                return ET.ConfigManager.GetCachedOptionsTable()
            end)
        end
        
        ET.ConfigManager.InitializeBlizzardOptions()
    end
    
    self.configLoaded = true
end

-- Feature module initialization
function ET:InitializeFeatureModules()
    if not EpicTipDB then return end
    
    -- Initialize optional modules based on settings
    local modules = {
        { module = ET.ItemInfo, setting = "showItemInfo" },
        { module = ET.StatValues, setting = "showStatValues" },
        { module = ET.MountInfo, setting = "showMountInfo" },
        { module = ET.MythicPlusInfo, setting = "showMythicRating" },
        { module = ET.PvPInfo, setting = "showPvPRating" }
    }
    
    for _, mod in ipairs(modules) do
        if mod.module and EpicTipDB[mod.setting] and mod.module.Initialize then
            mod.module.Initialize()
        end
    end
end

-- AceAddon OnInitialize
function ET:OnInitialize()
    -- Initialize AceDB with profile support
    self.db = LibStub("AceDB-3.0"):New("EpicTipSettings", defaults, true)
    EpicTipDB = self.db.profile
    
    -- Register profile change callbacks
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
    
    -- Setup slash commands
    SLASH_EPICTIP1 = "/et"
    SLASH_EPICTIP2 = "/epictip"
    SlashCmdList["EPICTIP"] = function(input)
        self:SlashCommand(input)
    end
end

-- AceAddon OnEnable
function ET:OnEnable()
    -- Initialize core modules FIRST (including database)
    if ET.Config and ET.Config.InitializeDatabase then
        ET.Config.InitializeDatabase()
    end
    
    -- THEN initialize ConfigManager after database is ready
    if ET.ConfigManager and ET.ConfigManager.Initialize then
        ET.ConfigManager.Initialize()
    end
    
    if ET.Tooltip and ET.Tooltip.Initialize then
        ET.Tooltip.Initialize()
    end
    
    if ET.CursorGlow and ET.CursorGlow.Initialize then
        -- Always initialize the frame, but only start if enabled
        ET.CursorGlow.Initialize()
        
        -- Check if it should be enabled and start automatically
        local shouldStart = false
        if EpicTipDB and EpicTipDB.cursorGlow and EpicTipDB.cursorGlow.enabled then
            shouldStart = true
        elseif ET.db and ET.db.profile and ET.db.profile.cursorGlow and ET.db.profile.cursorGlow.enabled then
            shouldStart = true
        end
        
        if shouldStart then
            if ET.CursorGlow.UpdateVisibility then
                ET.CursorGlow.UpdateVisibility()
            end
        end
    end
    
    -- Initialize Ring module
    if ET.Ring and ET.Ring.Initialize then
        ET.Ring.Initialize()
        
        -- Check if it should be enabled and start automatically
        local shouldStart = false
        if EpicTipDB and EpicTipDB.ring and EpicTipDB.ring.enabled then
            shouldStart = true
        elseif ET.db and ET.db.profile and ET.db.profile.ring and ET.db.profile.ring.enabled then
            shouldStart = true
        end
        
        if shouldStart then
            ET.Ring.SetEnabled(true)
        end
    end
    
    -- Initialize feature modules
    self:InitializeFeatureModules()
    
    -- Note: MemoryPool disabled to reduce memory footprint
    -- The pool system was using more memory than it saved
    
    -- Setup tooltip system
    if ET.Tooltip and ET.Tooltip.SetupUnifiedTooltipProcessor then
        ET.Tooltip.SetupUnifiedTooltipProcessor()
    end
    
    -- Register events for tooltip updates
    self:RegisterEvent("INSPECT_READY")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
end

-- Event handlers
function ET:INSPECT_READY(event, guid)
    if guid and GameTooltip:IsShown() then
        local _, unit = GameTooltip:GetUnit()
        if unit and UnitGUID(unit) == guid then
            if ET.Tooltip and ET.Tooltip.ProcessUnitTooltip then
                ET.Tooltip.ProcessUnitTooltip(GameTooltip, unit)
            end
        end
    end
end

function ET:PLAYER_TARGET_CHANGED()
    -- Clear cached data when target changes
    if ET.Utils and ET.Utils.OnTargetChanged then
        ET.Utils:OnTargetChanged()
    end
end

function ET:UPDATE_MOUSEOVER_UNIT()
    local _, unit = GameTooltip:GetUnit()
    if unit and UnitExists(unit) and UnitIsPlayer(unit) then
        if ET.Tooltip and ET.Tooltip.ProcessUnitTooltip then
            ET.Tooltip.ProcessUnitTooltip(GameTooltip, unit)
        end
    end
end

-- Slash command handler
function ET:SlashCommand(input)
    input = string.trim(input or "")
    local cmd, arg1, arg2 = strsplit(" ", input, 3)
    
    -- Debug commands only available when debug mode is enabled
    if input == "statdebug" and EpicTipDB.debugMode then
        if ET.StatValues and ET.StatValues.DebugStatValues then
            ET.StatValues.DebugStatValues()
        else
            print(ET.CHAT_PREFIX .. " StatValues module not available")
        end
        
    elseif input == "stattest" and EpicTipDB.debugMode then
        if ET.StatValues and ET.StatValues.TestConfigOptions then
            ET.StatValues.TestConfigOptions()
        else
            print(ET.CHAT_PREFIX .. " StatValues module not available")
        end
        
    elseif input == "itemdebug" and EpicTipDB.debugMode then
        if ET.ItemInfo and ET.ItemInfo.DebugItemComparison then
            ET.ItemInfo.DebugItemComparison()
        else
            print(ET.CHAT_PREFIX .. " ItemInfo module not available")
        end
        
    elseif input == "cglow" and EpicTipDB.debugMode then
        print(ET.CHAT_PREFIX .. " CursorGlow Debug:")
        print("  EpicTipDB exists:", EpicTipDB and "YES" or "NO")
        if EpicTipDB then
            print("  EpicTipDB.cursorGlow exists:", EpicTipDB.cursorGlow and "YES" or "NO")
            if EpicTipDB.cursorGlow then
                print("  EpicTipDB.cursorGlow.enabled:", EpicTipDB.cursorGlow.enabled)
            end
        end
        print("  ET.db exists:", ET.db and "YES" or "NO")
        if ET.db and ET.db.profile then
            print("  ET.db.profile.cursorGlow exists:", ET.db.profile.cursorGlow and "YES" or "NO")
            if ET.db.profile.cursorGlow then
                print("  ET.db.profile.cursorGlow.enabled:", ET.db.profile.cursorGlow.enabled)
            end
        end
        print("  CursorGlow module exists:", ET.CursorGlow and "YES" or "NO")
        if ET.CursorGlow then
            local config = ET.CursorGlow.GetConfig()
            print("  GetConfig() returns:", config and "CONFIG FOUND" or "NO CONFIG")
            if config then
                print("  Config enabled:", config.enabled)
            end
        end
        
    elseif input == "debug" then
        self.db.profile.debugMode = not self.db.profile.debugMode
        EpicTipDB.debugMode = self.db.profile.debugMode
        print(string.format("%s Debug mode %s", ET.CHAT_PREFIX, 
              self.db.profile.debugMode and "enabled" or "disabled"))
              
    elseif input == "config" or input == "options" then
        if ET.ConfigManager and ET.ConfigManager.OpenConfigDialog then
            local success = ET.ConfigManager.OpenConfigDialog()
            if not success then
                print(ET.CHAT_PREFIX .. " Error opening config dialog. Trying fallback...")
                -- Fallback
                self:LoadConfigOnDemand()
                local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
                if AceConfigDialog then
                    AceConfigDialog:Open("EpicTip")
                else
                    print(ET.CHAT_PREFIX .. " Could not load config dialog. Try /reload")
                end
            end
        else
            print(ET.CHAT_PREFIX .. " ConfigManager not available. Loading...")
            -- Fallback
            self:LoadConfigOnDemand()
            local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
            if AceConfigDialog then
                AceConfigDialog:Open("EpicTip")
            else
                print(ET.CHAT_PREFIX .. " Could not load config dialog. Try /reload")
            end
        end
        
    elseif input == "anchor" or input == "anchoring" then
        local current = self.db.profile.anchoring or "default"
        local new = current == "mouse" and "default" or "mouse"
        
        self.db.profile.anchoring = new
        EpicTipDB.anchoring = new
        
        print(string.format("%s Tooltip positioning: %s", ET.CHAT_PREFIX,
              new == "mouse" and "Follow Mouse" or "Default Position"))
              
    elseif input == "enable" then
        self.db.profile.enabled = true
        EpicTipDB.enabled = true
        print(ET.CHAT_PREFIX .. " Enabled")
        
    elseif input == "disable" then
        self.db.profile.enabled = false
        EpicTipDB.enabled = false
        print(ET.CHAT_PREFIX .. " Disabled")
        
    elseif input == "status" then
        print(ET.CHAT_PREFIX .. " Status:")
        print("  Enabled: " .. (EpicTipDB.enabled and "Yes" or "No"))
        print("  Debug: " .. (EpicTipDB.debugMode and "Yes" or "No"))
        print("  Version: " .. ET.VERSION)
        
    elseif input == "reload" then
        print(ET.CHAT_PREFIX .. " Reloading...")
        ReloadUI()
        
    elseif input == "test" then
        -- Test tooltip on current target/mouseover
        local unit = "target"
        if not UnitExists(unit) then
            unit = "mouseover" 
        end
        
        if UnitExists(unit) then
            print(ET.CHAT_PREFIX .. " Testing tooltip on " .. (UnitName(unit) or "Unknown"))
            if ET.Tooltip and ET.Tooltip.ProcessUnitTooltip then
                ET.Tooltip.ProcessUnitTooltip(GameTooltip, unit)
            end
        else
            print(ET.CHAT_PREFIX .. " No valid target or mouseover unit found")
        end
        
    elseif input == "diagnostic" and EpicTipDB.debugMode then
        print(ET.CHAT_PREFIX .. " Diagnostic:")
        print("1. Database: " .. (EpicTipDB and "OK" or "MISSING"))
        print("2. Modules:")
        print("   Utils: " .. (ET.Utils and "OK" or "MISSING"))
        print("   Tooltip: " .. (ET.Tooltip and "OK" or "MISSING"))
        print("   Config: " .. (ET.Config and "OK" or "MISSING"))
        print("   ConfigManager: " .. (ET.ConfigManager and "OK" or "MISSING"))
        if ET.ConfigManager then
            print("   ConfigManager.OpenConfigDialog: " .. (ET.ConfigManager.OpenConfigDialog and "OK" or "MISSING"))
            print("   ConfigManager.Initialize: " .. (ET.ConfigManager.Initialize and "OK" or "MISSING"))
        end
        print("3. AceDB: " .. (self.db and "OK" or "MISSING"))
        print("4. Profile: " .. (self.db and self.db.profile and "OK" or "MISSING"))
        print("5. UI Config Modules:")
        if ET.UI and ET.UI.Config then
            print("   GetGeneralConfig: " .. (ET.UI.Config.GetGeneralConfig and "OK" or "MISSING"))
            print("   GetPlayerInfoConfig: " .. (ET.UI.Config.GetPlayerInfoConfig and "OK" or "MISSING"))
            print("   GetAppearanceConfig: " .. (ET.UI.Config.GetAppearanceConfig and "OK" or "MISSING"))
            print("   GetFeaturesConfig: " .. (ET.UI.Config.GetFeaturesConfig and "OK" or "MISSING"))
        else
            print("   UI.Config: MISSING")
        end
        print("6. Ace Libraries:")
        local AceConfig = LibStub("AceConfig-3.0", true)
        local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
        print("   AceConfig-3.0: " .. (AceConfig and "OK" or "MISSING"))
        print("   AceConfigDialog-3.0: " .. (AceConfigDialog and "OK" or "MISSING"))
        
    elseif input == "configtest" then
        print(ET.CHAT_PREFIX .. " Configuration Test:")
        
        -- Test ConfigManager availability
        if not ET.ConfigManager then
            print("  ❌ ConfigManager: NOT AVAILABLE")
            return
        end
        print("  ✅ ConfigManager: AVAILABLE")
        
        -- Test ConfigManager functions
        if ET.ConfigManager.Initialize then
            print("  ✅ ConfigManager.Initialize: AVAILABLE")
        else
            print("  ❌ ConfigManager.Initialize: MISSING")
        end
        
        if ET.ConfigManager.OpenConfigDialog then
            print("  ✅ ConfigManager.OpenConfigDialog: AVAILABLE")
        else
            print("  ❌ ConfigManager.OpenConfigDialog: MISSING")
        end
        
        -- Test UI config modules
        if ET.UI and ET.UI.Config then
            print("  ✅ UI.Config: AVAILABLE")
            local configModules = {
                "GetGeneralConfig",
                "GetPlayerInfoConfig", 
                "GetAppearanceConfig",
                "GetFeaturesConfig",
                "GetTrueStatConfig",
                "GetRingConfig"
            }
            
            for _, module in ipairs(configModules) do
                if ET.UI.Config[module] then
                    print("    ✅ " .. module .. ": AVAILABLE")
                else
                    print("    ❌ " .. module .. ": MISSING")
                end
            end
        else
            print("  ❌ UI.Config: NOT AVAILABLE")
        end
        
        -- Test Ace libraries
        local AceConfig = LibStub("AceConfig-3.0", true)
        local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
        print("  " .. (AceConfig and "✅" or "❌") .. " AceConfig-3.0: " .. (AceConfig and "AVAILABLE" or "MISSING"))
        print("  " .. (AceConfigDialog and "✅" or "❌") .. " AceConfigDialog-3.0: " .. (AceConfigDialog and "AVAILABLE" or "MISSING"))
        
        -- Test config table generation
        if ET.ConfigManager.GetOptionsTable then
            print("  Testing config table generation...")
            local success, result = pcall(ET.ConfigManager.GetOptionsTable)
            if success and result then
                print("  ✅ Config table generation: SUCCESS")
                if result.args then
                    local argCount = 0
                    for _ in pairs(result.args) do argCount = argCount + 1 end
                    print("    Found " .. argCount .. " config sections")
                end
            else
                print("  ❌ Config table generation: FAILED")
                if result then
                    print("    Error: " .. tostring(result))
                end
            end
        end
        
    elseif input == "tooltip" and EpicTipDB.debugMode then
        print(ET.CHAT_PREFIX .. " Tooltip System Diagnostic:")
        
        -- Test tooltip system components
        print("1. Core Systems:")
        print("   ET.Tooltip: " .. (ET.Tooltip and "✅ OK" or "❌ MISSING"))
        print("   ProcessUnitTooltip: " .. (ET.Tooltip and ET.Tooltip.ProcessUnitTooltip and "✅ OK" or "❌ MISSING"))
        
        print("2. Feature Modules:")
        print("   MythicPlusInfo: " .. (ET.MythicPlusInfo and "✅ OK" or "❌ MISSING"))
        print("   PvPInfo: " .. (ET.PvPInfo and "✅ OK" or "❌ MISSING"))
        print("   MountInfo: " .. (ET.MountInfo and "✅ OK" or "❌ MISSING"))
        
        print("3. Settings:")
        print("   Show Mythic+: " .. (EpicTipDB.showMythicRating and "✅ YES" or "❌ NO"))
        print("   Show PvP: " .. (EpicTipDB.showPvPRating and "✅ YES" or "❌ NO"))
        
        -- Test current unit
        local unit = "target"
        if not UnitExists(unit) then
            unit = "mouseover"
        end
        
        if UnitExists(unit) and UnitIsPlayer(unit) then
            print("4. Testing on: " .. (UnitName(unit) or "Unknown"))
            
            -- Test tooltip processing
            local success, err = pcall(function()
                if ET.Tooltip and ET.Tooltip.ProcessUnitTooltip then
                    ET.Tooltip.ProcessUnitTooltip(GameTooltip, unit)
                    print("   Tooltip Processing: ✅ SUCCESS")
                end
            end)
            if not success then
                print("   Tooltip Processing: ❌ FAILED - " .. tostring(err))
            end
        else
            print("4. No valid player target/mouseover for testing")
        end
        
    elseif input == "memory" then
        print(ET.CHAT_PREFIX .. " Memory Usage:")
        
        -- Get current memory usage
        local memBefore = collectgarbage("count")
        print("  Current Usage: " .. string.format("%.1f MB", memBefore / 1024))
        
        -- Check cache status
        if ET.CacheManager then
            local stats = ET.CacheManager.GetCacheStats()
            print("  Cache Status: " .. (stats.isHighTraffic and "High Traffic" or "Normal"))
            print("  Location: " .. (stats.zone or "Unknown"))
        end
        
        -- Check memory pools
        if ET.MemoryPool then
            local poolStats = ET.MemoryPool.GetPoolStats()
            local totalInUse = 0
            for poolType, stats in pairs(poolStats) do
                if poolType ~= "stats" then
                    totalInUse = totalInUse + (stats.inUse or 0)
                end
            end
            print("  Pool Tables In Use: " .. totalInUse)
        end
        
        -- Perform cleanup
        print("  Performing cleanup...")
        if ET.CacheManager then
            ET.CacheManager.ForceCleanup()
        end
        
        if ET.MemoryPool then
            ET.MemoryPool.CleanupPools()
        end
        
        -- Clear config cache
        if ET.ConfigManager then
            ET.ConfigManager.ClearCache()
        end
        
        -- Force garbage collection
        collectgarbage("collect")
        
        local memAfter = collectgarbage("count")
        local freed = memBefore - memAfter
        print("  After Cleanup: " .. string.format("%.1f MB", memAfter / 1024))
        if freed > 0 then
            print("  Freed: " .. string.format("%.1f MB", freed / 1024))
        else
            print("  No memory freed (may still be in use)")
        end
        
    elseif input == "repair" then
        print(ET.CHAT_PREFIX .. " Repairing configuration...")
        local fixes = 0
        
        if not EpicTipDB then
            print("  Reinitializing database...")
            self.db = LibStub("AceDB-3.0"):New("EpicTipSettings", defaults, true)
            EpicTipDB = self.db.profile
            fixes = fixes + 1
        end
        
        -- Fix essential settings
        local essentials = {
            enabled = true,
            scale = 1.0,
            anchoring = "default"
        }
        
        for setting, defaultValue in pairs(essentials) do
            if EpicTipDB[setting] == nil then
                EpicTipDB[setting] = defaultValue
                fixes = fixes + 1
            end
        end
        
        print(string.format("  Repair complete: %d issues fixed", fixes))
        if fixes > 0 then
            print("  Recommendation: /reload for changes to take effect")
        end
        
    else
        -- Help
        print(ET.CHAT_PREFIX .. " Commands:")
        print("  /et config - Open configuration")
        print("  /et enable/disable - Enable/disable addon")
        print("  /et status - Show current status")
        print("  /et test - Test tooltip on target/mouseover")
        print("  /et reload - Reload UI")
        if EpicTipDB.debugMode then
            print("  Debug Commands:")
            print("  /et configtest - Test configuration system")
            print("  /et tooltip - Test tooltip system")
            print("  /et memory - Check memory usage and cleanup")
            print("  /et debug - Toggle debug mode")
            print("  /et anchor - Toggle tooltip positioning")
            print("  /et diagnostic - System diagnostic")
            print("  /et repair - Repair configuration")
            print("  /et statdebug - Debug stat values")
            print("  /et itemdebug - Debug item comparison")
            print("  /et cglow - Cursor glow debug")
        end
        print("")
        print("  |cFFFFD700Ring Commands:|r")
        print("  /et ring show/hide/toggle - Control ring visibility")
        print("  /et ring enable/disable - Control ring functionality")
        print("  /et ring test - Ring diagnostics")
        print("  /et ring force - Force show ring at center screen")
        print("  /et ring db - Show ring database state")
        print("")
        print("  |cFF00FFFFCursorGlow Commands:|r")
        print("  /et glow enable/disable/toggle - Control cursor glow")
        print("  /et glow test - CursorGlow diagnostics")
        print("  /et glow force - Force show glow at center screen")
        print("  /et glow db - Show glow database state")
    end
end

-- Ring and CursorGlow command handling
if ET.Ring and ET.Ring.HandleSlashCommand then
    local originalSlashCommand = ET.SlashCommand
    function ET:SlashCommand(input)
        input = string.trim(input or "")
        local cmd, arg1, arg2 = strsplit(" ", input, 3)
        
        -- Check if Ring module wants to handle this command
        if ET.Ring.HandleSlashCommand(cmd, arg1, arg2) then
            return
        end
        
        -- Check if CursorGlow module wants to handle this command
        if ET.CursorGlow.HandleSlashCommand(cmd, arg1, arg2) then
            return
        end
        
        -- Otherwise use normal command handling
        originalSlashCommand(self, input)
    end
end

-- Auto-enable on load if not explicitly disabled
if EpicTipDB and EpicTipDB.enabled == nil then
    EpicTipDB.enabled = true
end

print(string.format("%s v%s loaded. Type /et for commands.", ET.COLORED_TITLE, ET.VERSION))
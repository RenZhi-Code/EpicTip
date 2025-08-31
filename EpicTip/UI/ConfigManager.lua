local addonName, ET = ...


if not ET then
    return
end

ET.UI = ET.UI or {}
ET.UI.ConfigManager = {}
-- Ensure ConfigManager is properly accessible
if not ET.ConfigManager then
    ET.ConfigManager = {}
end

-- Modular Configuration System
-- This replaces the massive config table in Core.lua with clean, organized modules

-- Ensure ConfigManager exists and assign functions directly
local ConfigManager = ET.ConfigManager

-- Initialize the modular config system
function ConfigManager.Initialize()
    -- Initialize the UI.Config namespace if not already done
    if not ET.UI.Config then
        ET.UI.Config = {}
    end
    
    -- Register with Blizzard Interface Options
    ConfigManager.InitializeBlizzardOptions()
    
    -- Clear any stale cache
    ConfigManager.ClearCache()
end

-- Get the complete options table by combining all modules
function ConfigManager.GetOptionsTable()
    -- Debug: Check what's available
    if EpicTipDB and EpicTipDB.debugMode then
        print("ConfigManager: ET.UI exists:", ET.UI ~= nil)
        print("ConfigManager: ET.UI.Config exists:", ET.UI and ET.UI.Config ~= nil)
        if ET.UI and ET.UI.Config then
            print("ConfigManager: GetGeneralConfig exists:", ET.UI.Config.GetGeneralConfig ~= nil)
            print("ConfigManager: GetPlayerInfoConfig exists:", ET.UI.Config.GetPlayerInfoConfig ~= nil)
        end
    end
    
    -- Ensure all config modules are available
    if not ET.UI or not ET.UI.Config then
        return {
            name = "|cFFFF0000Epic|r|cFF33CCFFTip|r v" .. (ET.VERSION or "31.08.25.20"),
            handler = ET,
            type = "group",
            args = {
                loading = {
                    name = "Configuration Loading...",
                    type = "description",
                    order = 1
                }
            }
        }
    end

    local success, result = pcall(function()
        local args = {}
        
        -- Safe loading of each config section with nil checks
        if ET.UI.Config and ET.UI.Config.GetGeneralConfig then
            args.general = ET.UI.Config.GetGeneralConfig()
        end
        
        if ET.UI.Config and ET.UI.Config.GetPlayerInfoConfig then
            args.playerinfo = ET.UI.Config.GetPlayerInfoConfig()
        end
        
        if ET.UI.Config and ET.UI.Config.GetAppearanceConfig then
            args.appearance = ET.UI.Config.GetAppearanceConfig()
        end
        
        if ET.UI.Config and ET.UI.Config.GetFeaturesConfig then
            args.features = ET.UI.Config.GetFeaturesConfig()
        end
        
        if ET.UI.Config and ET.UI.Config.GetTrueStatConfig then
            args.truestat = ET.UI.Config.GetTrueStatConfig()
        end
        
        -- Add Cursor config
        if ET.UI.Config and ET.UI.Config.GetCursorConfig then
            args.cursor = ET.UI.Config.GetCursorConfig()
        end
        
        -- Add profile management using AceDBOptions
        local AceDBOptions = LibStub("AceDBOptions-3.0", true)
        if AceDBOptions and ET.db then
            args.profiles = AceDBOptions:GetOptionsTable(ET.db)
            args.profiles.order = 10 -- Place profiles tab at the end
        end
        
        return {
            name = "|cFFFF0000Epic|r|cFF33CCFFTip|r v" .. (ET.VERSION or "31.08.25.20"),
            handler = ET,
            type = "group",
            childGroups = "tab",
            args = args
        }
    end)
    
    if not success then
        -- Print the actual error for debugging
        if EpicTipDB and EpicTipDB.debugMode then
            print("EpicTip Config Error:", result)
        end
        return {
            name = "|cFFFF0000Epic|r|cFF33CCFFTip|r",
            handler = ET,
            type = "group",
            args = {
                error = {
                    name = "Error loading configuration. Please reload your UI.\nError: " .. tostring(result),
                    type = "description",
                    order = 1
                }
            }
        }
    end
    
    return result
end

-- Cache system for config sections (memory optimization)
local configCache = {
    sections = {},
    fullTable = nil,
    lastGenerated = 0,
    stats = {
        cacheHits = 0,
        cacheMisses = 0,
        sectionsLoaded = 0
    }
}

-- Get cached options table for performance
function ConfigManager.GetCachedOptionsTable()
    local currentTime = GetTime()
    
    -- Check if we have a cached full table and it's recent (< 10 seconds old)
    -- Reduced from 30s to 10s to free memory faster
    if configCache.fullTable and (currentTime - configCache.lastGenerated < 10) then
        configCache.stats.cacheHits = configCache.stats.cacheHits + 1
        return configCache.fullTable
    end
    
    configCache.stats.cacheMisses = configCache.stats.cacheMisses + 1
    
    -- Generate fresh options table
    local options = ConfigManager.GetOptionsTable()
    
    -- Cache the generated table
    configCache.fullTable = options
    configCache.lastGenerated = currentTime
    configCache.stats.sectionsLoaded = 6  -- We have 6 main sections
    
    return options
end

-- Clear configuration cache (for memory management)
function ConfigManager.ClearCache()
    configCache.sections = {}
    configCache.fullTable = nil
    configCache.lastGenerated = 0
end

-- Get cache statistics (for debugging)
function ConfigManager.GetCacheStats()
    return {
        cacheHits = configCache.stats.cacheHits,
        cacheMisses = configCache.stats.cacheMisses,
        sectionsLoaded = configCache.stats.sectionsLoaded,
        lastGenerated = configCache.lastGenerated
    }
end

-- Open the configuration dialog
function ConfigManager.OpenConfigDialog()
    local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
    
    if not AceConfigDialog then
        return false
    end
    
    -- Open the configuration dialog (already registered in InitializeBlizzardOptions)
    local success, err = pcall(function()
        AceConfigDialog:Open("EpicTip")
    end)
    
    return success
end

-- Initialize Blizzard Options integration
function ConfigManager.InitializeBlizzardOptions()
    local AceConfig = LibStub("AceConfig-3.0", true)
    local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
    
    if not AceConfig or not AceConfigDialog then
        return false
    end
    
    -- Register options table FIRST
    local success, err = pcall(function()
        AceConfig:RegisterOptionsTable("EpicTip", function()
            return ConfigManager.GetCachedOptionsTable()
        end)
    end)
    
    if not success then
        return false
    end
    
    -- THEN add to Blizzard's Interface Options
    AceConfigDialog:AddToBlizOptions("EpicTip", ET.COLORED_TITLE)
    AceConfigDialog:SetDefaultSize("EpicTip", 800, 600)
    
    return true
end

-- Ensure all functions are properly exported to ET.ConfigManager
-- (Protection against Core.lua overwriting the table)
ET.ConfigManager.Initialize = ConfigManager.Initialize
ET.ConfigManager.GetOptionsTable = ConfigManager.GetOptionsTable
ET.ConfigManager.GetCachedOptionsTable = ConfigManager.GetCachedOptionsTable
ET.ConfigManager.ClearCache = ConfigManager.ClearCache
ET.ConfigManager.OpenConfigDialog = ConfigManager.OpenConfigDialog
ET.ConfigManager.InitializeBlizzardOptions = ConfigManager.InitializeBlizzardOptions
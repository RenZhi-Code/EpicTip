local addonName, ET = ...

-- CORE MODULE: Cache Management System
-- Extracted from Tooltip.lua to maintain 800-line file size targets
-- Handles high-traffic cache management, cleanup, and memory optimization

ET.CacheManager = ET.CacheManager or {}
local CacheManager = ET.CacheManager

-- High-Traffic Cache Management System
-- Prevents memory accumulation in busy areas by aggressive cache expiration
local trafficManager = {
    enabled = true,
    highTrafficThreshold = 50, -- Cache entries that indicate high traffic
    aggressiveCleanupInterval = 15, -- Seconds between aggressive cleanups
    lastAggressiveCleanup = 0,
    cacheHitRate = 0,
    totalAccesses = 0,
    lastTrafficCheck = 0
}

-- Enhanced cache with traffic-aware expiration
function CacheManager.ClearCache(aggressive)
    aggressive = aggressive or false
    
    -- Clear cached data for Tooltip module
    if ET.Tooltip then
        ET.Tooltip.cachedRole = ""
        ET.Tooltip.specName = ""
        ET.Tooltip.inspectedGUID = nil
    end
    
    -- High-traffic aggressive cleanup
    if aggressive or CacheManager.IsHighTrafficScenario() then
        -- Clear gradient frames cache
        if ET.TooltipStyling and ET.TooltipStyling.gradientFrames then
            for tooltip, frame in pairs(ET.TooltipStyling.gradientFrames) do
                if frame then
                    frame:Hide()
                    frame:SetParent(nil)
                end
            end
            wipe(ET.TooltipStyling.gradientFrames)
        end
        
        -- Clear font objects cache if not recently used
        local currentTime = GetTime()
        if ET.FontManager and ET.FontManager.fontObjects then
            if currentTime - (ET.FontManager.lastFontUpdate or 0) > 60 then
                for _, fontObj in pairs(ET.FontManager.fontObjects) do
                    fontObj = nil
                end
                ET.FontManager.fontObjects = {}
            end
        end
        
        -- Force garbage collection in high-traffic scenarios
        collectgarbage("step", 200)
    end
end

function CacheManager.IsHighTrafficScenario()
    local currentTime = GetTime()
    
    -- Dornogal is ALWAYS high traffic due to extreme player density
    local zone = GetZoneText()
    if zone == "Dornogal" or zone:find("Dornogal") then
        return true -- Dornogal is always considered high-traffic
    end
    
    -- Check traffic indicators for other areas
    local isHighTraffic = false
    
    -- Many visible nameplates = busy area (reduced scan for Dornogal performance)
    local nameplateCount = 0
    local maxScan = 25 -- Reduced from 40 for performance in capitals
    for i = 1, maxScan do
        if UnitExists("nameplate" .. i) then
            nameplateCount = nameplateCount + 1
        end
    end
    
    -- Lower thresholds for other capital cities
    local isCapital = CacheManager.IsInCapitalCity()
    local threshold = isCapital and 8 or 15 -- Lower threshold in capitals
    if nameplateCount > threshold then isHighTraffic = true end
    
    -- Large group = high traffic
    if IsInRaid() or GetNumGroupMembers() > 15 then isHighTraffic = true end
    
    -- Instance with many units (lower threshold)
    if IsInInstance() and nameplateCount > 6 then isHighTraffic = true end
    
    return isHighTraffic
end

function CacheManager.PerformTrafficAwareCleanup()
    local currentTime = GetTime()
    
    if not trafficManager.enabled then return end
    
    -- Check if we're in Dornogal for ultra-aggressive cleanup
    local zone = GetZoneText()
    local isDornogal = zone == "Dornogal" or zone:find("Dornogal")
    
    -- Ultra-aggressive cleanup intervals for Dornogal
    local cleanupInterval = isDornogal and 5 or trafficManager.aggressiveCleanupInterval -- 5s in Dornogal vs 15s normal
    
    -- Perform cleanup based on traffic and location
    local shouldCleanup = false
    if isDornogal then
        -- Always cleanup in Dornogal regardless of traffic indicators
        shouldCleanup = true
    elseif CacheManager.IsHighTrafficScenario() then
        shouldCleanup = true
    end
    
    if shouldCleanup and (currentTime - trafficManager.lastAggressiveCleanup) > cleanupInterval then
        trafficManager.lastAggressiveCleanup = currentTime
        
        -- Ultra-aggressive cache clearing for Dornogal
        CacheManager.ClearCache(true)
        
        -- Clean up frame pools more aggressively
        if ET.FrameFactory and ET.FrameFactory.CleanupPools then
            ET.FrameFactory.CleanupPools()
        end
        
        -- Clean up table pools
        if ET.MemoryPool and ET.MemoryPool.CleanupPools then
            ET.MemoryPool.CleanupPools()
        end
        
        -- Clean up processor data pool in capitals
        if isDornogal or CacheManager.IsInCapitalCity() then
            -- Emergency garbage collection in Dornogal
            if isDornogal then
                collectgarbage("step", 500) -- More aggressive GC
                collectgarbage("collect")
            end
        end
        
        if EpicTipDB and EpicTipDB.debugMode then
            local location = isDornogal and "Dornogal ultra-aggressive" or "high-traffic"
            print("EpicTip: " .. location .. " cleanup performed")
        end
    end
end

-- Helper function to detect capital cities
function CacheManager.IsInCapitalCity()
    local zone = GetZoneText()
    local capitalCities = {
        "Stormwind City", "Orgrimmar", "Ironforge", "Darnassus", 
        "Thunder Bluff", "Undercity", "Shattrath City", "Dalaran", 
        "Dornogal", "Boralus", "Dazar'alor"
    }
    
    for _, city in ipairs(capitalCities) do
        if zone == city or zone:find(city) then
            return true
        end
    end
    return false
end

-- Cache statistics and monitoring
function CacheManager.GetCacheStats()
    return {
        trafficEnabled = trafficManager.enabled,
        lastCleanup = trafficManager.lastAggressiveCleanup,
        isHighTraffic = CacheManager.IsHighTrafficScenario(),
        isInCapital = CacheManager.IsInCapitalCity(),
        zone = GetZoneText()
    }
end

-- Manual cache cleanup trigger
function CacheManager.ForceCleanup()
    trafficManager.lastAggressiveCleanup = 0 -- Reset timer to force immediate cleanup
    CacheManager.PerformTrafficAwareCleanup()
end

-- Initialize function for modular loading
function CacheManager.Initialize()
    -- Enable traffic management by default
    trafficManager.enabled = true
    
    if EpicTipDB and EpicTipDB.debugMode then
        print("EpicTip CacheManager: Initialized traffic-aware cache management")
    end
end

-- Export main functions for external access
CacheManager.ClearCache = CacheManager.ClearCache
CacheManager.IsHighTrafficScenario = CacheManager.IsHighTrafficScenario
CacheManager.PerformTrafficAwareCleanup = CacheManager.PerformTrafficAwareCleanup
CacheManager.IsInCapitalCity = CacheManager.IsInCapitalCity
CacheManager.GetCacheStats = CacheManager.GetCacheStats
CacheManager.ForceCleanup = CacheManager.ForceCleanup
CacheManager.Initialize = CacheManager.Initialize
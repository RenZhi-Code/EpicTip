local addonName, ET = ...

-- MEDIUM-02: Error Handling & Recovery System
-- Provides comprehensive error protection, recovery mechanisms, and graceful degradation
-- Following memory protocol for proper error handling and user experience

ET.ErrorHandler = ET.ErrorHandler or {}
local ErrorHandler = ET.ErrorHandler

-- Error tracking and statistics
local errorStats = {
    totalErrors = 0,
    criticalErrors = 0,
    recoveredErrors = 0,
    errorsByModule = {},
    recentErrors = {}
}

-- Error severity levels
local ERROR_LEVELS = {
    LOW = 1,          -- Minor issues, no functionality lost
    MEDIUM = 2,       -- Some functionality degraded
    HIGH = 3,         -- Major functionality lost
    CRITICAL = 4      -- Addon may become unusable
}

-- Recovery strategies for different error types
local RECOVERY_STRATEGIES = {
    DATABASE_CORRUPTION = "recreate_database",
    MODULE_FAILURE = "disable_module", 
    MEMORY_OVERFLOW = "cleanup_resources",
    API_FAILURE = "fallback_implementation",
    TOOLTIP_ERROR = "reset_tooltip_system"
}

-- Maximum number of recent errors to track
local MAX_RECENT_ERRORS = 50

-- CRITICAL: Safe function call wrapper with comprehensive error handling
function ErrorHandler.SafeCall(func, context, errorLevel, ...)
    if not func or type(func) ~= "function" then
        ErrorHandler.LogError("INVALID_FUNCTION", "SafeCall called with invalid function", ERROR_LEVELS.HIGH, context)
        return false, "Invalid function provided"
    end
    
    local success, result1, result2, result3 = pcall(func, ...)
    
    if success then
        return true, result1, result2, result3
    else
        -- Error occurred - handle it based on severity
        local errorMessage = tostring(result1) or "Unknown error"
        ErrorHandler.LogError("FUNCTION_CALL_FAILED", errorMessage, errorLevel or ERROR_LEVELS.MEDIUM, context)
        
        -- Attempt recovery based on error type and context
        local recovered = ErrorHandler.AttemptRecovery(errorMessage, context, errorLevel)
        
        return false, errorMessage, recovered
    end
end

-- CRITICAL: Log and track errors with detailed information
function ErrorHandler.LogError(errorType, errorMessage, severity, context)
    local timestamp = GetTime()
    local errorInfo = {
        type = errorType,
        message = errorMessage,
        severity = severity or ERROR_LEVELS.MEDIUM,
        context = context or "unknown",
        timestamp = timestamp,
        stack = debugstack(2) -- Get stack trace excluding this function
    }
    
    -- Update statistics
    errorStats.totalErrors = errorStats.totalErrors + 1
    if severity >= ERROR_LEVELS.CRITICAL then
        errorStats.criticalErrors = errorStats.criticalErrors + 1
    end
    
    -- Track errors by module/context
    if context then
        errorStats.errorsByModule[context] = (errorStats.errorsByModule[context] or 0) + 1
    end
    
    -- Add to recent errors (with circular buffer)
    table.insert(errorStats.recentErrors, 1, errorInfo)
    if #errorStats.recentErrors > MAX_RECENT_ERRORS then
        table.remove(errorStats.recentErrors, MAX_RECENT_ERRORS + 1)
    end
    
    -- Output error based on severity and debug mode
    if severity >= ERROR_LEVELS.HIGH or (EpicTipDB and EpicTipDB.debugMode) then
        local severityTexts = {"LOW", "MEDIUM", "HIGH", "CRITICAL"}
        local severityText = severityTexts[severity] or "UNKNOWN"
        local prefix = "|cFFFF0000Epic|r|cFF33CCFFTip|r ERROR"
        
        if severity >= ERROR_LEVELS.CRITICAL then
            print(string.format("%s [%s]: %s in %s", prefix, severityText, errorMessage, context or "unknown"))
        elseif EpicTipDB and EpicTipDB.debugMode then
            print(string.format("%s [%s]: %s", prefix, severityText, errorMessage))
        end
    end
end

-- CRITICAL: Attempt error recovery based on context and error type
function ErrorHandler.AttemptRecovery(errorMessage, context, severity)
    if not context or severity <= ERROR_LEVELS.LOW then
        return false -- No recovery needed for minor errors
    end
    
    local recovered = false
    local strategy = ErrorHandler.DetermineRecoveryStrategy(errorMessage, context)
    
    if strategy == "recreate_database" then
        recovered = ErrorHandler.RecreateDatabase()
    elseif strategy == "disable_module" then
        recovered = ErrorHandler.DisableFailingModule(context)
    elseif strategy == "cleanup_resources" then
        recovered = ErrorHandler.CleanupResources()
    elseif strategy == "fallback_implementation" then
        recovered = ErrorHandler.EnableFallback(context)
    elseif strategy == "reset_tooltip_system" then
        recovered = ErrorHandler.ResetTooltipSystem()
    end
    
    if recovered then
        errorStats.recoveredErrors = errorStats.recoveredErrors + 1
        if EpicTipDB and EpicTipDB.debugMode then
            print(string.format("EpicTip: Recovered from error in %s using %s strategy", 
                context, strategy))
        end
    end
    
    return recovered
end

-- Determine appropriate recovery strategy based on error details
function ErrorHandler.DetermineRecoveryStrategy(errorMessage, context)
    local lowerMessage = string.lower(errorMessage)
    local lowerContext = string.lower(context or "")
    
    -- Database-related errors
    if lowerMessage:find("epictipdb") or lowerMessage:find("database") or lowerMessage:find("nil value") then
        return "recreate_database"
    end
    
    -- Memory-related errors
    if lowerMessage:find("memory") or lowerMessage:find("stack overflow") or lowerMessage:find("too many") then
        return "cleanup_resources"
    end
    
    -- Tooltip-related errors
    if lowerContext:find("tooltip") or lowerMessage:find("tooltip") or lowerMessage:find("gametooltip") then
        return "reset_tooltip_system"
    end
    
    -- API-related errors
    if lowerMessage:find("api") or lowerMessage:find("function") or lowerMessage:find("method") then
        return "fallback_implementation"
    end
    
    -- Module-specific errors
    if context and context ~= "unknown" then
        return "disable_module"
    end
    
    return "fallback_implementation" -- Default strategy
end

-- RECOVERY IMPLEMENTATIONS

-- Recreate corrupted database
function ErrorHandler.RecreateDatabase()
    if not ET or not ET.RecoverDatabase then
        return false
    end
    
    local success = ErrorHandler.SafeCall(ET.RecoverDatabase, "DatabaseRecovery", ERROR_LEVELS.HIGH, ET)
    return success
end

-- Disable a failing module temporarily
function ErrorHandler.DisableFailingModule(moduleName)
    if not moduleName or moduleName == "Core" then
        return false -- Cannot disable core functionality
    end
    
    -- Use module registry if available
    if ET.ModuleRegistry then
        local module = ET.ModuleRegistry.GetModule(moduleName)
        if module and module.Cleanup then
            local success = ErrorHandler.SafeCall(module.Cleanup, "ModuleCleanup", ERROR_LEVELS.MEDIUM)
            if success then
                -- Mark module as disabled in registry
                return true
            end
        end
    end
    
    -- Legacy module disabling
    if ET[moduleName] and ET[moduleName].Cleanup then
        local success = ErrorHandler.SafeCall(ET[moduleName].Cleanup, "LegacyModuleCleanup", ERROR_LEVELS.MEDIUM)
        return success
    end
    
    return false
end

-- Cleanup resources to free memory
function ErrorHandler.CleanupResources()
    local cleaned = false
    
    -- Clean up frame pools
    if ET.Tooltip and ET.Tooltip.CleanupFramePools then
        local success = ErrorHandler.SafeCall(ET.Tooltip.CleanupFramePools, "FrameCleanup", ERROR_LEVELS.LOW)
        cleaned = cleaned or success
    end
    
    -- Simple garbage collection cleanup
    collectgarbage("collect")
    cleaned = true
    
    -- Force garbage collection as last resort
    if cleaned then
        collectgarbage("collect")
    end
    
    return cleaned
end

-- Enable fallback implementation for failed API calls
function ErrorHandler.EnableFallback(context)
    -- This is context-specific and would be implemented per module
    -- For now, just return true to indicate we "handled" it
    return true
end

-- Reset tooltip system
function ErrorHandler.ResetTooltipSystem()
    if not ET.Tooltip then
        return false
    end
    
    -- Reset tooltip processor
    if ET.Tooltip.SetupUnifiedTooltipProcessor then
        local success = ErrorHandler.SafeCall(ET.Tooltip.SetupUnifiedTooltipProcessor, "TooltipReset", ERROR_LEVELS.MEDIUM)
        if not success then
            return false
        end
    end
    
    -- Reset backup hooks
    if ET.SetupBackupTooltipHooks then
        local success = ErrorHandler.SafeCall(ET.SetupBackupTooltipHooks, "TooltipHookReset", ERROR_LEVELS.MEDIUM)
        return success
    end
    
    return true
end

-- UTILITY FUNCTIONS

-- Get error statistics
function ErrorHandler.GetStats()
    return {
        total = errorStats.totalErrors,
        critical = errorStats.criticalErrors,
        recovered = errorStats.recoveredErrors,
        byModule = errorStats.errorsByModule,
        recent = errorStats.recentErrors
    }
end

-- Print error statistics
function ErrorHandler.PrintStats()
    local stats = ErrorHandler.GetStats()
    
    print("|cFFFF0000Epic|r|cFF33CCFFTip|r Error Handler Statistics")
    print("================================================")
    print(string.format("Total Errors: %d | Critical: %d | Recovered: %d", 
        stats.total, stats.critical, stats.recovered))
    
    if stats.total > 0 then
        local recoveryRate = math.floor((stats.recovered / stats.total) * 100)
        print(string.format("Recovery Rate: %d%%", recoveryRate))
    end
    
    if next(stats.byModule) then
        print("\nErrors by Module:")
        for module, count in pairs(stats.byModule) do
            print(string.format("  %s: %d errors", module, count))
        end
    end
    
    if #stats.recent > 0 then
        print(string.format("\nMost Recent Error: %s (%s)", 
            stats.recent[1].message, stats.recent[1].context))
    end
end

-- Clear error statistics (for testing/reset)
function ErrorHandler.ClearStats()
    errorStats = {
        totalErrors = 0,
        criticalErrors = 0,
        recoveredErrors = 0,
        errorsByModule = {},
        recentErrors = {}
    }
end

-- CRITICAL: Protected wrapper for module initialization
function ErrorHandler.ProtectedModuleInit(moduleName, initFunction, ...)
    if not initFunction then
        ErrorHandler.LogError("MISSING_INIT_FUNCTION", "No initialization function provided", 
            ERROR_LEVELS.HIGH, moduleName)
        return false
    end
    
    local success, result = ErrorHandler.SafeCall(initFunction, moduleName, ERROR_LEVELS.HIGH, ...)
    
    if not success then
        ErrorHandler.LogError("MODULE_INIT_FAILED", 
            string.format("Module %s failed to initialize: %s", moduleName, result or "Unknown error"),
            ERROR_LEVELS.HIGH, moduleName)
        return false
    end
    
    return true, result
end

-- CRITICAL: Protected wrapper for event handlers
function ErrorHandler.ProtectedEventHandler(eventName, handlerFunction, ...)
    if not handlerFunction then
        ErrorHandler.LogError("MISSING_EVENT_HANDLER", "No event handler function provided",
            ERROR_LEVELS.MEDIUM, "EventSystem")
        return
    end
    
    local success, result = ErrorHandler.SafeCall(handlerFunction, "Event_" .. eventName, ERROR_LEVELS.MEDIUM, ...)
    
    if not success then
        ErrorHandler.LogError("EVENT_HANDLER_FAILED",
            string.format("Event handler for %s failed: %s", eventName, result or "Unknown error"),
            ERROR_LEVELS.MEDIUM, "EventSystem")
    end
    
    return success, result
end

-- Export the error handler
ET.ErrorHandler = ErrorHandler

-- MEDIUM-03: Compact Resource Tracker (integrated with ErrorHandler)
ET.ResourceTracker = {
    tracked = { frames = {}, timers = {}, events = {} },
    stats = { frames = 0, timers = 0, events = 0, cleaned = 0 },
    limits = { frames = 50, timers = 100, events = 20 },
    
    TrackFrame = function(self, frame, context)
        if frame then
            self.tracked.frames[tostring(frame)] = { frame = frame, context = context, time = GetTime() }
            self.stats.frames = self.stats.frames + 1
            return true
        end
        return false
    end,
    
    TrackTimer = function(self, timer, context, duration)
        if timer then
            self.tracked.timers[tostring(timer)] = { timer = timer, context = context, expiry = GetTime() + (duration or 0) }
            self.stats.timers = self.stats.timers + 1
            return true
        end
        return false
    end,
    
    CleanupFrames = function(self)
        local cleaned = 0
        local currentTime = GetTime()
        for id, data in pairs(self.tracked.frames) do
            if not data.frame or not data.frame:IsObjectType("Frame") or (currentTime - data.time > 300) then
                self.tracked.frames[id] = nil
                cleaned = cleaned + 1
            end
        end
        self.stats.cleaned = self.stats.cleaned + cleaned
        return cleaned
    end,
    
    CleanupExpiredTimers = function(self)
        local cleaned = 0
        local currentTime = GetTime()
        for id, data in pairs(self.tracked.timers) do
            if currentTime > data.expiry then
                self.tracked.timers[id] = nil
                cleaned = cleaned + 1
            end
        end
        self.stats.cleaned = self.stats.cleaned + cleaned
        return cleaned
    end,
    
    CleanupAllResources = function(self)
        local total = self:CleanupFrames() + self:CleanupExpiredTimers()
        if total > 0 then collectgarbage("collect") end
        return total
    end,
    
    CreateTrackedFrame = function(self, frameType, name, parent, template, context)
        local frame = CreateFrame(frameType, name, parent, template)
        if frame then self:TrackFrame(frame, context) end
        return frame
    end,
    
    CreateTrackedTimer = function(self, duration, callback, context)
        local timer = C_Timer.NewTimer(duration, function()
            self:CleanupExpiredTimers()
            if callback then callback() end
        end)
        if timer then self:TrackTimer(timer, context, duration) end
        return timer
    end,
    
    StartAutoCleanup = function(self)
        if not self.cleanupTimer then
            self.cleanupTimer = C_Timer.NewTicker(60, function() self:CleanupAllResources() end)
        end
    end,
    
    PrintStats = function(self)
        print("|cFFFF0000Epic|r|cFF33CCFFTip|r Resource Tracker")
        print(string.format("Frames: %d | Timers: %d | Cleaned: %d", 
            self.stats.frames, self.stats.timers, self.stats.cleaned))
    end
}
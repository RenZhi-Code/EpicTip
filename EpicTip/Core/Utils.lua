local addonName, ET = ...

-- Cached globals for performance
local GetInspectSpecialization = GetInspectSpecialization
local GetSpecializationInfoByID = GetSpecializationInfoByID
local GetTime = GetTime
local UnitGUID = UnitGUID
local UnitIsPlayer = UnitIsPlayer
local CanInspect = CanInspect
local InCombatLockdown = InCombatLockdown
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage
local GetAddOnMemoryUsage = GetAddOnMemoryUsage

-- Enhanced inspection throttling configuration
local INSPECT_THROTTLE = 1.0 -- Increased from 0.5 to reduce API calls
local INSPECT_CLEANUP_INTERVAL = 30 -- Clean up old entries every 30 seconds
local MAX_PENDING_INSPECTS = 50 -- Limit pending inspects to prevent memory bloat

-- Utils Mixin (following Blizzard standards)
EpicTipUtilsMixin = {}

function EpicTipUtilsMixin:OnLoad()
    -- Enhanced inspection tracking with cleanup
    self.pendingInspects = {}
    self.inspectCount = 0
    self.lastCleanup = GetTime()
    self:InitializeStaticData()
    
    -- Start cleanup timer for inspection throttling
    self.cleanupTimer = C_Timer.NewTicker(INSPECT_CLEANUP_INTERVAL, function()
        self:CleanupInspectCache()
    end)
end

function EpicTipUtilsMixin:InitializeStaticData()
    -- Class and role icons are now generated dynamically
    -- No static data initialization needed - saves ~100KB of memory
end

function EpicTipUtilsMixin:GetSpec(unit)
    if not unit then return "" end
    
    local specID = GetInspectSpecialization(unit)
    if specID and specID ~= 0 then
        local _, name = GetSpecializationInfoByID(specID)
        return name or ""
    end
    return ""
end

function EpicTipUtilsMixin:GetRole(unit)
    if not unit then return "" end
    
    local specID = GetInspectSpecialization(unit)
    if specID and specID ~= 0 then
        local _, _, _, _, _, role = GetSpecializationInfoByID(specID)
        if role then
            if role == "TANK" then
                return "Tank"
            elseif role == "HEALER" then
                return "Healer"
            elseif role == "DAMAGER" then
                return "DPS"
            end
        end
    end
    return ""
end

function EpicTipUtilsMixin:CanInspectThrottled(unit)
    if not EpicTipDB or not EpicTipDB.enableInspect then
        return false
    end
    
    if InCombatLockdown() then
        return false
    end
    
    if not UnitIsPlayer(unit) or not CanInspect(unit) then
        return false
    end
    
    local currentTime = GetTime()
    local guid = UnitGUID(unit)
    
    if not guid then
        return false
    end
    
    -- Check if we've hit the maximum pending inspects limit
    if self.inspectCount >= MAX_PENDING_INSPECTS then
        self:CleanupInspectCache()
        if self.inspectCount >= MAX_PENDING_INSPECTS then
            return false -- Still at limit after cleanup
        end
    end
    
    -- Check throttling
    if self.pendingInspects[guid] then
        if currentTime - self.pendingInspects[guid] < INSPECT_THROTTLE then
            return false
        end
    end
    
    return true
end

-- Enhanced cleanup function for inspection cache
function EpicTipUtilsMixin:CleanupInspectCache()
    local currentTime = GetTime()
    local cleanupThreshold = currentTime - (INSPECT_THROTTLE * 2) -- Clean entries older than 2x throttle time
    
    for guid, timestamp in pairs(self.pendingInspects) do
        if timestamp < cleanupThreshold then
            self.pendingInspects[guid] = nil
            self.inspectCount = self.inspectCount - 1
        end
    end
    
    self.lastCleanup = currentTime
    
    if EpicTipDB and EpicTipDB.debugMode then
        print("EpicTip: Cleaned up inspection cache, remaining entries:", self.inspectCount)
    end
end

-- Track inspection requests
function EpicTipUtilsMixin:TrackInspectRequest(guid)
    if guid and not self.pendingInspects[guid] then
        self.inspectCount = self.inspectCount + 1
    end
    self.pendingInspects[guid] = GetTime()
end

function EpicTipUtilsMixin:GetClassIcon(classFileName)
    if not classFileName or classFileName == "" then
        return "|TInterface\\Icons\\INV_Misc_QuestionMark:16:16:0:0:64:64:4:60:4:60|t"
    end
    
    -- Generate class icon dynamically using the classFileName pattern
    -- This saves ~100KB by not storing all class icons in memory
    if classFileName == "DEATHKNIGHT" then
        return "|TInterface\\Icons\\ClassIcon_DeathKnight:16:16:0:0:64:64:4:60:4:60|t"
    elseif classFileName == "DEMONHUNTER" then
        return "|TInterface\\Icons\\ClassIcon_DemonHunter:16:16:0:0:64:64:4:60:4:60|t"
    else
        -- Use Blizzard's native class icon system when available
        if GetClassIcon then
            local icon = GetClassIcon(classFileName)
            if icon then
                return string.format("|T%s:16:16:0:0:64:64:4:60:4:60|t", icon)
            end
        end
        
        -- Fallback to optimized string formatting
        local className = string.format("%s%s", classFileName:sub(1,1):upper(), classFileName:sub(2):lower())
        return string.format("|TInterface\\Icons\\ClassIcon_%s:16:16:0:0:64:64:4:60:4:60|t", className)
    end
end

function EpicTipUtilsMixin:GetRoleIcon(role)
    -- Generate role icons dynamically instead of storing static table
    -- This saves memory and follows WoW's standard coordinate system
    if role == "Tank" then
        return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t"
    elseif role == "Healer" then
        return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t"
    elseif role == "DPS" then
        return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t"
    else
        return ""
    end
end

function EpicTipUtilsMixin:ClearPendingInspects()
    -- Use efficient table.wipe instead of creating new table
    table.wipe(self.pendingInspects)
end

function EpicTipUtilsMixin:OnCombatStart()
    self:ClearPendingInspects()
end

function EpicTipUtilsMixin:OnTargetChanged()
    self:ClearPendingInspects()
end

-- Memory debugging utilities
function EpicTipUtilsMixin:GetMemoryUsage()
    UpdateAddOnMemoryUsage()
    return GetAddOnMemoryUsage("EpicTip")
end

function EpicTipUtilsMixin:PrintMemoryUsage()
    local usage = self:GetMemoryUsage()
    print(string.format("|cFFFF0000Epic|r|cFF33CCFFTip|r Memory Usage: %.2f KB", usage))
end

-- Cleanup function for proper timer management
function EpicTipUtilsMixin:Cleanup()
    if self.cleanupTimer then
        self.cleanupTimer:Cancel()
        self.cleanupTimer = nil
    end
    if self.pendingInspects then
        wipe(self.pendingInspects)
        self.inspectCount = 0
    end
end

-- Create and initialize the Utils instance
ET.Utils = Mixin({}, EpicTipUtilsMixin)
ET.Utils:OnLoad()

-- MEDIUM-01: Compact Module Registry (integrated into Utils)
ET.ModuleRegistry = {
    modules = {},
    
    RegisterModule = function(self, name, module, deps)
        if name and module then
            self.modules[name] = { module = module, deps = deps or {}, ready = false }
            return true
        end
        return false
    end,
    
    GetModule = function(self, name)
        local moduleData = self.modules[name]
        return moduleData and moduleData.module or nil
    end,
    
    SafeCall = function(self, name, funcName, ...)
        local module = self:GetModule(name)
        if module and module[funcName] then
            local success, result = pcall(module[funcName], ...)
            return success, result
        end
        return false, "Module or function not found"
    end,
    
    InitializeAllModules = function(self)
        local count = 0
        for name, data in pairs(self.modules) do
            if not data.ready and data.module.Initialize then
                local success = pcall(data.module.Initialize)
                if success then
                    data.ready = true
                    count = count + 1
                end
            end
        end
        return count
    end,
    
    PrintStatus = function(self)
        print("|cFFFF0000Epic|r|cFF33CCFFTip|r Module Registry Status")
        for name, data in pairs(self.modules) do
            local status = data.ready and "|cFF00FF00Ready|r" or "|cFFFF0000Not Ready|r"
            print(string.format("  %s: %s", name, status))
        end
    end,
    
    SafeAccessors = {
        GetTooltipModule = function() return ET.ModuleRegistry:GetModule("Tooltip") end,
        GetMemoryPoolModule = function() return ET.ModuleRegistry:GetModule("MemoryPool") end,
        GetUtilsModule = function() return ET.Utils end,
        GetConfigModule = function() return ET.ModuleRegistry:GetModule("Config") end
    }
}
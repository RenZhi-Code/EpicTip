local addonName, ET = ...

-- CORE MODULE: Memory Pool Management System
-- Extracted from Tooltip.lua to maintain 800-line file size targets
-- Handles table pooling, factory patterns, and memory optimization

ET.MemoryPool = ET.MemoryPool or {}
local MemoryPool = ET.MemoryPool

-- Comprehensive Table Pool System (WoW 11.2 Optimization)
-- Reduced pool sizes to minimize memory footprint
local TABLE_POOLS = {
    -- Small tables (1-10 entries) - most common
    small = {
        pool = {},
        inUse = {},
        created = 0,
        maxPool = 20  -- Reduced from 50
    },
    -- Medium tables (11-50 entries)
    medium = {
        pool = {},
        inUse = {},
        created = 0,
        maxPool = 10  -- Reduced from 20
    },
    -- Large tables (50+ entries)
    large = {
        pool = {},
        inUse = {},
        created = 0,
        maxPool = 5   -- Reduced from 10
    },
    -- Temporary iteration tables
    temp = {
        pool = {},
        inUse = {},
        created = 0,
        maxPool = 15  -- Reduced from 30
    }
}

-- Table Factory for efficient table management
MemoryPool.TableFactory = {}
local TableFactory = MemoryPool.TableFactory

function TableFactory:GetTable(size)
    size = size or "small"
    if type(size) == "number" then
        if size <= 10 then
            size = "small"
        elseif size <= 50 then
            size = "medium"
        else
            size = "large"
        end
    end
    
    local pool = TABLE_POOLS[size]
    if not pool then
        pool = TABLE_POOLS.small
    end
    
    -- Try to reuse existing table from pool
    local tbl = table.remove(pool.pool)
    if tbl then
        -- Ensure table is clean (should already be from ReturnTable)
        assert(next(tbl) == nil, "Pool table was not properly cleaned")
        pool.inUse[tbl] = true
        return tbl
    end
    
    -- Create new table if pool is empty and under limit
    if pool.created < pool.maxPool then
        tbl = {}
        pool.created = pool.created + 1
        pool.inUse[tbl] = true
        return tbl
    end
    
    -- Pool exhausted, create temporary table (will be GC'd)
    return {}
end

function TableFactory:ReturnTable(tbl, size)
    if not tbl then return end
    
    size = size or "small"
    if type(size) == "number" then
        if size <= 10 then
            size = "small"
        elseif size <= 50 then
            size = "medium"
        else
            size = "large"
        end
    end
    
    local pool = TABLE_POOLS[size]
    if not pool or not pool.inUse[tbl] then
        -- Clean orphaned table for potential reuse
        table.wipe(tbl)
        return
    end
    
    -- Clean table completely
    table.wipe(tbl)
    
    -- Return to pool
    pool.inUse[tbl] = nil
    table.insert(pool.pool, tbl)
end

function TableFactory:GetTempTable()
    return TableFactory:GetTable("temp")
end

function TableFactory:ReturnTempTable(tbl)
    return TableFactory:ReturnTable(tbl, "temp")
end

function TableFactory:GetPoolStats()
    local stats = {}
    for poolType, pool in pairs(TABLE_POOLS) do
        stats[poolType] = {
            pooled = #pool.pool,
            inUse = 0,
            created = pool.created
        }
        for _ in pairs(pool.inUse) do
            stats[poolType].inUse = stats[poolType].inUse + 1
        end
    end
    return stats
end

function TableFactory:CleanupPools()
    for _, pool in pairs(TABLE_POOLS) do
        -- Clear pools but keep created count for monitoring
        table.wipe(pool.pool)
        table.wipe(pool.inUse)
    end
end

-- Initialize function for modular loading
function MemoryPool.Initialize()
    -- Initialize pool monitoring if debug mode is enabled
    if EpicTipDB and EpicTipDB.debugMode then
        print("EpicTip MemoryPool: Initialized table pools")
    end
end

-- Frame Pool System for UI element reuse
local FRAME_POOLS = {
    -- Explosion frames for CursorGlow effects
    explosion = {
        pool = {},
        inUse = {},
        created = 0,
        maxPool = 10
    },
    -- Background frames for tooltip styling
    background = {
        pool = {},
        inUse = {},
        created = 0,
        maxPool = 5
    },
    -- Border frames for tooltip styling
    border = {
        pool = {},
        inUse = {},
        created = 0,
        maxPool = 5
    },
    -- Generic frames for various uses
    generic = {
        pool = {},
        inUse = {},
        created = 0,
        maxPool = 15
    }
}

-- Frame Factory for efficient frame management
MemoryPool.FrameFactory = {}
local FrameFactory = MemoryPool.FrameFactory

function FrameFactory:GetFrame(frameType, frameTemplate, parent, name)
    frameType = frameType or "generic"
    local pool = FRAME_POOLS[frameType]
    if not pool then
        pool = FRAME_POOLS.generic
    end
    
    -- Try to reuse existing frame from pool
    local frame = table.remove(pool.pool)
    if frame then
        -- Reset frame properties
        frame:ClearAllPoints()
        frame:SetParent(parent or UIParent)
        frame:SetSize(1, 1)
        frame:SetAlpha(1)
        frame:Show()
        frame:SetFrameStrata("MEDIUM")
        frame:SetFrameLevel(0)
        
        -- Clear any existing textures (keep first texture for reuse)
        local regions = {frame:GetRegions()}
        for i = 2, #regions do
            if regions[i]:GetObjectType() == "Texture" then
                regions[i]:Hide()
            end
        end
        
        pool.inUse[frame] = true
        return frame
    end
    
    -- Create new frame if pool is empty and under limit
    if pool.created < pool.maxPool then
        frame = CreateFrame("Frame", name, parent or UIParent, frameTemplate)
        if frame then
            pool.created = pool.created + 1
            pool.inUse[frame] = true
            return frame
        end
    end
    
    -- Pool exhausted, create temporary frame (will be GC'd)
    return CreateFrame("Frame", name, parent or UIParent, frameTemplate)
end

function FrameFactory:ReturnFrame(frame, frameType)
    if not frame or not frame:IsObjectType("Frame") then return end
    
    frameType = frameType or "generic"
    local pool = FRAME_POOLS[frameType]
    if not pool or not pool.inUse[frame] then
        -- Clean orphaned frame
        frame:Hide()
        frame:ClearAllPoints()
        return
    end
    
    -- Clean frame for reuse
    frame:Hide()
    frame:ClearAllPoints()
    frame:SetParent(UIParent)
    frame:SetAlpha(1)
    frame:SetSize(1, 1)
    
    -- Clear scripts
    frame:SetScript("OnUpdate", nil)
    frame:SetScript("OnShow", nil)
    frame:SetScript("OnHide", nil)
    
    -- Return to pool
    pool.inUse[frame] = nil
    table.insert(pool.pool, frame)
end

function FrameFactory:GetExplosionFrame(parent, name)
    local frame = self:GetFrame("explosion", nil, parent, name)
    if frame then
        frame:SetFrameStrata("TOOLTIP")
        -- Ensure explosion frame has a texture
        if not frame.explosionTexture then
            frame.explosionTexture = frame:CreateTexture(nil, "OVERLAY")
            frame.explosionTexture:SetAllPoints()
            frame.explosionTexture:SetBlendMode("ADD")
        end
        frame.explosionTexture:Show()
    end
    return frame
end

function FrameFactory:ReturnExplosionFrame(frame)
    if frame and frame.explosionTexture then
        frame.explosionTexture:Hide()
    end
    self:ReturnFrame(frame, "explosion")
end

function FrameFactory:GetFramePoolStats()
    local stats = {}
    for poolType, pool in pairs(FRAME_POOLS) do
        stats[poolType] = {
            pooled = #pool.pool,
            inUse = 0,
            created = pool.created
        }
        for _ in pairs(pool.inUse) do
            stats[poolType].inUse = stats[poolType].inUse + 1
        end
    end
    return stats
end

function FrameFactory:CleanupFramePools()
    for _, pool in pairs(FRAME_POOLS) do
        -- Hide and clear all pooled frames
        for _, frame in ipairs(pool.pool) do
            if frame and frame:IsObjectType("Frame") then
                frame:Hide()
                frame:ClearAllPoints()
            end
        end
        -- Clear pools but keep created count for monitoring
        table.wipe(pool.pool)
        table.wipe(pool.inUse)
    end
end

-- Export functions for external access
MemoryPool.GetTable = function(size) return TableFactory:GetTable(size) end
MemoryPool.ReturnTable = function(tbl, size) return TableFactory:ReturnTable(tbl, size) end
MemoryPool.GetTempTable = function() return TableFactory:GetTempTable() end
MemoryPool.ReturnTempTable = function(tbl) return TableFactory:ReturnTempTable(tbl) end
MemoryPool.GetPoolStats = function() return TableFactory:GetPoolStats() end
MemoryPool.CleanupPools = function() return TableFactory:CleanupPools() end

-- Frame pooling exports
MemoryPool.GetFrame = function(frameType, frameTemplate, parent, name) return FrameFactory:GetFrame(frameType, frameTemplate, parent, name) end
MemoryPool.ReturnFrame = function(frame, frameType) return FrameFactory:ReturnFrame(frame, frameType) end
MemoryPool.GetExplosionFrame = function(parent, name) return FrameFactory:GetExplosionFrame(parent, name) end
MemoryPool.ReturnExplosionFrame = function(frame) return FrameFactory:ReturnExplosionFrame(frame) end
MemoryPool.GetFramePoolStats = function() return FrameFactory:GetFramePoolStats() end
MemoryPool.CleanupFramePools = function() return FrameFactory:CleanupFramePools() end
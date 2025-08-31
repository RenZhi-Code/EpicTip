local addonName, ET = ...

-- CORE MODULE: Iteration Utilities System  
-- Extracted from Tooltip.lua to maintain 800-line file size targets
-- Handles optimized iteration patterns, table operations, and performance utilities

ET.IterationUtils = ET.IterationUtils or {}
local IterationUtils = ET.IterationUtils

-- Efficient iteration for arrays (replaces ipairs where possible)
function IterationUtils.ForEach(tbl, func)
    if not tbl or not func then return end
    
    -- Use numeric iteration for arrays (faster than ipairs)
    local len = #tbl
    for i = 1, len do
        local value = tbl[i]
        if value ~= nil then
            func(i, value)
        end
    end
end

-- Efficient iteration for hash tables with early termination
function IterationUtils.ForEachUntil(tbl, func)
    if not tbl or not func then return end
    
    -- Use next() directly for better performance than pairs()
    local key, value = next(tbl)
    while key ~= nil do
        local shouldContinue = func(key, value)
        if shouldContinue == false then
            break
        end
        key, value = next(tbl, key)
    end
end

-- Count table entries efficiently without creating iterator
function IterationUtils.Count(tbl)
    if not tbl then return 0 end
    
    -- For arrays, use length operator
    if tbl[1] ~= nil then
        return #tbl
    end
    
    -- For hash tables, count manually (more efficient than using pairs)
    local count = 0
    for _ in next, tbl do
        count = count + 1
    end
    return count
end

-- Find value in table without creating iterator overhead
function IterationUtils.Find(tbl, predicate)
    if not tbl or not predicate then return nil end
    
    -- Optimize for arrays first
    local len = #tbl
    if len > 0 then
        for i = 1, len do
            local value = tbl[i]
            if value ~= nil and predicate(value, i) then
                return value, i
            end
        end
    end
    
    -- Fall back to hash table search
    for key, value in next, tbl do
        if predicate(value, key) then
            return value, key
        end
    end
    
    return nil
end

-- Map operation with table pooling
function IterationUtils.Map(tbl, func, resultSize)
    if not tbl or not func then return {} end
    
    -- Get pooled table for results if MemoryPool is available
    local result = {}
    if ET.MemoryPool and ET.MemoryPool.GetTable then
        result = ET.MemoryPool.GetTable(resultSize or IterationUtils.Count(tbl))
    end
    
    -- Optimized mapping for arrays
    local len = #tbl
    if len > 0 then
        for i = 1, len do
            local value = tbl[i]
            if value ~= nil then
                result[i] = func(value, i)
            end
        end
        return result
    end
    
    -- Hash table mapping
    for key, value in next, tbl do
        result[key] = func(value, key)
    end
    
    return result
end

-- Filter operation with table pooling
function IterationUtils.Filter(tbl, predicate)
    if not tbl or not predicate then return {} end
    
    local result = {}
    if ET.MemoryPool and ET.MemoryPool.GetTable then
        result = ET.MemoryPool.GetTable("small")
    end
    
    -- Optimized filtering for arrays
    local len = #tbl
    if len > 0 then
        local resultIndex = 1
        for i = 1, len do
            local value = tbl[i]
            if value ~= nil and predicate(value, i) then
                result[resultIndex] = value
                resultIndex = resultIndex + 1
            end
        end
        return result
    end
    
    -- Hash table filtering
    for key, value in next, tbl do
        if predicate(value, key) then
            result[key] = value
        end
    end
    
    return result
end

-- Safely get table values with fallback
function IterationUtils.SafeGet(tbl, key, defaultValue)
    if not tbl then return defaultValue end
    local value = tbl[key]
    return value ~= nil and value or defaultValue
end

-- Efficiently merge tables
function IterationUtils.Merge(target, source, overwrite)
    if not target or not source then return target end
    overwrite = overwrite ~= false -- Default to true
    
    for key, value in next, source do
        if overwrite or target[key] == nil then
            target[key] = value
        end
    end
    
    return target
end

-- Create a shallow copy of table
function IterationUtils.Copy(tbl)
    if not tbl then return {} end
    
    local copy = {}
    if ET.MemoryPool and ET.MemoryPool.GetTable then
        copy = ET.MemoryPool.GetTable(IterationUtils.Count(tbl))
    end
    
    -- Handle arrays efficiently
    local len = #tbl
    if len > 0 then
        for i = 1, len do
            copy[i] = tbl[i]
        end
    end
    
    -- Handle hash table entries
    for key, value in next, tbl do
        if type(key) ~= "number" or key > len or key < 1 then
            copy[key] = value
        end
    end
    
    return copy
end

-- Initialize function for modular loading
function IterationUtils.Initialize()
    if EpicTipDB and EpicTipDB.debugMode then
        print("EpicTip IterationUtils: Initialized optimized iteration patterns")
    end
end

-- Export main functions for external access
IterationUtils.ForEach = IterationUtils.ForEach
IterationUtils.ForEachUntil = IterationUtils.ForEachUntil
IterationUtils.Count = IterationUtils.Count
IterationUtils.Find = IterationUtils.Find
IterationUtils.Map = IterationUtils.Map
IterationUtils.Filter = IterationUtils.Filter
IterationUtils.SafeGet = IterationUtils.SafeGet
IterationUtils.Merge = IterationUtils.Merge
IterationUtils.Copy = IterationUtils.Copy
IterationUtils.Initialize = IterationUtils.Initialize
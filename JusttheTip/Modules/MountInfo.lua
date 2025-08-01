local addonName, JTT = ...


JTT.MountInfo = JTT.MountInfo or {}
local MountInfo = JTT.MountInfo
local L = JTT.L or {}

JustTheTipMountInfoMixin = {}

-- Cache for mount information to avoid repeated API calls
local mountCache = {}
local mountSourceCache = {}

-- Mount source types
local MOUNT_SOURCES = {
    [1] = "Drop",
    [2] = "Quest", 
    [3] = "Vendor",
    [4] = "World Event",
    [5] = "Achievement",
    [6] = "Profession",
    [7] = "Reputation",
    [8] = "Trading Card Game",
    [9] = "Promotion",
    [10] = "Pet Store", -- Blizzard Store
    [11] = "Discovery",
    [12] = "Activity", -- Dungeon/Raid/PvP
}

function JustTheTipMountInfoMixin:GetMountInfo(unit)
    if not unit or not UnitExists(unit) then return nil end
    
    -- Safety check for mount journal availability
    if not C_MountJournal or not C_MountJournal.GetMountIDs then return nil end
    
    -- Check if unit is mounted
    if not UnitOnTaxi(unit) and not self:IsUnitMounted(unit) then
        return nil
    end
    
    -- Try to get mount information
    local mountID = self:GetUnitMountID(unit)
    if not mountID then return nil end
    
    -- Check cache first
    if mountCache[mountID] then
        return mountCache[mountID]
    end
    
    -- Get mount details from Blizzard API with safety checks
    local success, name, spellID, icon, isActive, isUsable, sourceType, isFavorite, 
          isFactionSpecific, faction, shouldHideOnChar, isCollected, mountType = pcall(C_MountJournal.GetMountInfoByID, mountID)
    
    if not success or not name then return nil end
    
    -- Get additional mount info with safety checks
    local success2, creatureDisplayID, description, source, isSelfMount, mountTypeID, uiModelSceneID = pcall(C_MountJournal.GetMountInfoExtraByID, mountID)
    
    if not success2 then
        -- Use basic info if extra info fails
        description = ""
        source = ""
        mountTypeID = nil
    end
    
    -- Determine mount type string
    local mountTypeStr = self:GetMountTypeString(mountTypeID)
    
    -- Get source information
    local sourceStr = self:GetMountSource(sourceType, source, mountID)
    
    local mountInfo = {
        id = mountID,
        name = name,
        spellID = spellID,
        icon = icon,
        description = description or "",
        source = sourceStr,
        sourceType = sourceType,
        mountType = mountTypeStr,
        mountTypeID = mountTypeID,
        isCollected = isCollected,
        faction = faction,
        isFactionSpecific = isFactionSpecific
    }
    
    -- Cache the result
    mountCache[mountID] = mountInfo
    
    return mountInfo
end

function JustTheTipMountInfoMixin:IsUnitMounted(unit)
    -- Check if unit is mounted using modern API
    if UnitIsUnit(unit, "player") then
        return IsMounted()
    end
    
    -- For other units, check for mount auras
    local auraIndex = 1
    while true do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, auraIndex, "HELPFUL")
        if not auraData then break end
        
        -- Check if this aura indicates mounting
        if auraData.name and (
            auraData.name:find("Mount") or 
            auraData.name:find("Flying") or
            auraData.name:find("Riding") or
            self:IsMountAura(auraData.spellId)
        ) then
            return true
        end
        
        auraIndex = auraIndex + 1
    end
    
    return false
end

function JustTheTipMountInfoMixin:GetUnitMountID(unit)
    -- This is tricky - we need to identify the mount from the unit
    -- We can try several approaches:
    
    -- Method 1: Check if it's the player
    if UnitIsUnit(unit, "player") then
        -- For the player, we can get the current mount more easily
        local mountIDs = C_MountJournal.GetMountIDs()
        for i = 1, #mountIDs do
            local mountID = mountIDs[i]
            local name, spellID, icon, isActive = C_MountJournal.GetMountInfoByID(mountID)
            if isActive then
                return mountID
            end
        end
    end
    
    -- Method 2: Try to get from aura information
    -- This is more complex and may not always work for other players
    local auraIndex = 1
    while true do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, auraIndex, "HELPFUL")
        if not auraData then break end
        
        -- Check if this aura is mount-related
        if auraData.name and self:IsMountAura(auraData.spellId) then
            local mountID = self:GetMountIDFromSpell(auraData.spellId)
            if mountID then
                return mountID
            end
        end
        
        auraIndex = auraIndex + 1
    end
    
    -- Method 3: Fallback - return nil if we can't detect the mount
    -- For other players, mount detection is limited by API restrictions
    
    return nil
end

function JustTheTipMountInfoMixin:IsMountAura(spellID)
    if not spellID or not C_MountJournal or not C_MountJournal.GetMountIDs then return false end
    
    -- Check if the spell is in our mount database
    local success, mountIDs = pcall(C_MountJournal.GetMountIDs)
    if not success or not mountIDs then return false end
    
    for i = 1, #mountIDs do
        local mountID = mountIDs[i]
        local success2, name, mountSpellID = pcall(C_MountJournal.GetMountInfoByID, mountID)
        if success2 and mountSpellID == spellID then
            return true
        end
    end
    
    return false
end

function JustTheTipMountInfoMixin:GetMountIDFromSpell(spellID)
    if not spellID or not C_MountJournal or not C_MountJournal.GetMountIDs then return nil end
    
    local success, mountIDs = pcall(C_MountJournal.GetMountIDs)
    if not success or not mountIDs then return nil end
    
    for i = 1, #mountIDs do
        local mountID = mountIDs[i]
        local success2, name, mountSpellID = pcall(C_MountJournal.GetMountInfoByID, mountID)
        if success2 and mountSpellID == spellID then
            return mountID
        end
    end
    
    return nil
end

function JustTheTipMountInfoMixin:GetMountTypeString(mountTypeID)
    if not mountTypeID then return "Unknown" end
    
    -- Mount type mappings
    local mountTypes = {
        [230] = "Ground",
        [231] = "Flying", 
        [232] = "Aquatic",
        [241] = "Flying",
        [247] = "Flying",
        [248] = "Flying",
        [254] = "Aquatic",
        [269] = "Flying",
        [284] = "Ground",
        [398] = "Flying",
        [407] = "Ground",
        [408] = "Ground",
        [424] = "Flying",
    }
    
    return mountTypes[mountTypeID] or string.format("Type %d", mountTypeID)
end

function JustTheTipMountInfoMixin:GetMountSource(sourceType, sourceText, mountID)
    -- Check cache first
    if mountSourceCache[mountID] then
        return mountSourceCache[mountID]
    end
    
    local source = "Unknown"
    
    -- Use source text if available
    if sourceText and sourceText ~= "" then
        source = sourceText
    elseif sourceType and MOUNT_SOURCES[sourceType] then
        source = MOUNT_SOURCES[sourceType]
    end
    
    -- Try to get more specific source information
    source = self:EnhanceSourceInfo(source, mountID)
    
    -- Cache the result
    mountSourceCache[mountID] = source
    
    return source
end

function JustTheTipMountInfoMixin:EnhanceSourceInfo(source, mountID)
    -- This could be enhanced with a database of specific mount sources
    -- For now, we'll use the basic source information
    
    -- Some common enhancements
    if source:find("Achievement") then
        return source .. " Reward"
    elseif source:find("Vendor") then
        return source .. " Purchase"
    elseif source:find("Drop") then
        return source .. " (Rare)"
    end
    
    return source
end

function JustTheTipMountInfoMixin:ProcessUnitTooltip(tooltip, unit)
    if not tooltip or not unit then return end
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    
    -- Check if another mount addon is already providing info
    if self:HasOtherMountAddonInfo(tooltip) then
        return -- Don't add duplicate info
    end
    
    -- Get mount information
    local mountInfo = self:GetMountInfo(unit)
    if not mountInfo then return end
    
    -- Only show if we have meaningful information
    if not mountInfo.name or mountInfo.name == "" then return end
    
    -- Add mount information to tooltip with proper spacing
    tooltip:AddLine(" ") -- Separator
    
    -- Mount name with icon
    local mountLine = string.format("|T%s:16:16|t %s", mountInfo.icon or "", mountInfo.name)
    tooltip:AddLine(mountLine, 0.9, 0.8, 1)
    
    -- Only show mount type if we have valid info
    if mountInfo.mountType and mountInfo.mountType ~= "Unknown" and mountInfo.mountType ~= "" then
        tooltip:AddLine(string.format("%s %s", L["Mount Type:"] or "Mount Type:", mountInfo.mountType), 0.8, 0.8, 1)
    end
    
    -- Only show source if we have valid info  
    if mountInfo.source and mountInfo.source ~= "Unknown" and mountInfo.source ~= "" then
        tooltip:AddLine(string.format("%s %s", L["Source:"] or "Source:", mountInfo.source), 0.7, 1, 0.7)
    end
    
    -- Only show collection status if we have valid info
    if mountInfo.isCollected ~= nil then
        local collectedText = mountInfo.isCollected and "|cff00ff00Collected|r" or "|cffff6666Not Collected|r"
        tooltip:AddLine(string.format("%s %s", L["Status:"] or "Status:", collectedText), 0.8, 0.8, 1)
    end
    
    -- Only show faction if it's faction specific
    if mountInfo.isFactionSpecific and mountInfo.faction then
        local factionName = mountInfo.faction == 0 and "Horde" or "Alliance"
        tooltip:AddLine(string.format("%s %s", L["Faction:"] or "Faction:", factionName), 0.8, 0.8, 1)
    end
    
    -- Description removed per user request - too much information
    -- if mountInfo.description and mountInfo.description ~= "" and #mountInfo.description < 100 then
    --     tooltip:AddLine(" ") -- Small separator
    --     tooltip:AddLine(mountInfo.description, 0.8, 0.8, 0.8, true) -- Wrap text
    -- end
end

function JustTheTipMountInfoMixin:HasOtherMountAddonInfo(tooltip)
    -- Check if tooltip already has mount information from other addons
    for i = 1, tooltip:NumLines() do
        local line = _G[tooltip:GetName() .. "TextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                -- Check for common mount addon patterns
                if text:find("Vendor:") or 
                   text:find("Zone:") or 
                   text:find("Cost:") or
                   text:find("Drop:") or
                   (text:find("Mount") and text:find("Type:")) then
                    return true
                end
            end
        end
    end
    return false
end

-- Module functions
function MountInfo.SetupMountTooltipProcessor()
    -- Create mixin instance
    local mountProcessor = {}
    Mixin(mountProcessor, JustTheTipMountInfoMixin)
    
    -- Hook into the main tooltip processor
    if JTT.Tooltip and JTT.Tooltip.InsertCustomInfo then
        local originalInsertCustomInfo = JTT.Tooltip.InsertCustomInfo
        JTT.Tooltip.InsertCustomInfo = function(tooltip, unit)
            -- Call original function first
            originalInsertCustomInfo(tooltip, unit)
            
            -- Add mount information if enabled and no conflicts detected
            if JustTheTipDB.enabled and JustTheTipDB.showMountInfo then
                mountProcessor:ProcessUnitTooltip(tooltip, unit)
            end
        end
    end
end

-- Debug function
function MountInfo.DebugMountInfo(unit)
    unit = unit or "player"
    
    if not JTT or not JTT.Print then
        print("JTT not available")
        return
    end
    
    local processor = {}
    Mixin(processor, JustTheTipMountInfoMixin)
    
    local mountInfo = processor:GetMountInfo(unit)
    
    if mountInfo then
        JTT:Print("=== Mount Information ===")
        JTT:Print("Name: " .. (mountInfo.name or "Unknown"))
        JTT:Print("Type: " .. (mountInfo.mountType or "Unknown"))
        JTT:Print("Source: " .. (mountInfo.source or "Unknown"))
        JTT:Print("Collected: " .. tostring(mountInfo.isCollected))
        if mountInfo.description then
            JTT:Print("Description: " .. mountInfo.description)
        end
    else
        JTT:Print("No mount information found for " .. unit)
    end
end


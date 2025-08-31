local addonName, ET = ...

ET.ItemInfo = ET.ItemInfo or {}
local ItemInfo = ET.ItemInfo
local L = ET.L

-- Equipped item cache for faster comparisons
local equippedItemCache = {
    data = {},
    lastUpdate = 0,
    updateInterval = 2 -- Update cache every 2 seconds max
}

-- Pre-populate equipped item cache for instant comparisons
local function UpdateEquippedItemCache()
    local currentTime = GetTime()
    if currentTime - equippedItemCache.lastUpdate < equippedItemCache.updateInterval then
        return -- Don't update too frequently
    end
    
    equippedItemCache.lastUpdate = currentTime
    equippedItemCache.data = {}
    
    -- Cache all equipped items for instant lookup
    local slotMap = {
        ["INVTYPE_HEAD"] = 1, ["INVTYPE_NECK"] = 2, ["INVTYPE_SHOULDER"] = 3,
        ["INVTYPE_BODY"] = 4, ["INVTYPE_CHEST"] = 5, ["INVTYPE_ROBE"] = 5,
        ["INVTYPE_WAIST"] = 6, ["INVTYPE_LEGS"] = 7, ["INVTYPE_FEET"] = 8,
        ["INVTYPE_WRIST"] = 9, ["INVTYPE_HAND"] = 10, ["INVTYPE_FINGER"] = {11, 12},
        ["INVTYPE_TRINKET"] = {13, 14}, ["INVTYPE_CLOAK"] = 15,
        ["INVTYPE_WEAPON"] = 16, ["INVTYPE_2HWEAPON"] = 16, ["INVTYPE_WEAPONMAINHAND"] = 16,
        ["INVTYPE_WEAPONOFFHAND"] = 17, ["INVTYPE_SHIELD"] = 17, ["INVTYPE_HOLDABLE"] = 17,
        ["INVTYPE_RANGED"] = 18, ["INVTYPE_THROWN"] = 18, ["INVTYPE_RANGEDRIGHT"] = 18, ["INVTYPE_RELIC"] = 18
    }
    
    for equipLoc, slotID in pairs(slotMap) do
        if type(slotID) == "table" then
            -- Handle multiple slots (rings, trinkets)
            local items = {}
            for _, slot in ipairs(slotID) do
                local itemLink = GetInventoryItemLink("player", slot)
                if itemLink then
                    local itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink) or GetDetailedItemLevelInfo(itemLink) or 0
                    table.insert(items, {link = itemLink, level = itemLevel})
                end
            end
            equippedItemCache.data[equipLoc] = items
        else
            -- Handle single slot
            local itemLink = GetInventoryItemLink("player", slotID)
            if itemLink then
                local itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink) or GetDetailedItemLevelInfo(itemLink) or 0
                equippedItemCache.data[equipLoc] = {link = itemLink, level = itemLevel}
            end
        end
    end
end

-- Add initialization function
function ItemInfo.Initialize()
    -- Module initialization code
    if EpicTipDB.debugMode then
        print("EpicTip: ItemInfo module initialized")
    end
    
    -- Make sure the cache is populated
    -- Create a temporary mixin instance to call the update function
    if EpicTipItemInfoMixin and EpicTipItemInfoMixin.UpdateEquippedItemCache then
        EpicTipItemInfoMixin:UpdateEquippedItemCache()
    end
end

EpicTipItemInfoMixin = {}

-- Attach the cache update function to the mixin so it can be called properly
EpicTipItemInfoMixin.UpdateEquippedItemCache = UpdateEquippedItemCache

-- Add the missing detailed comparison function
function EpicTipItemInfoMixin:ShowDetailedComparison(tooltip, itemLink, itemEquipLoc)
    if not itemLink or not itemEquipLoc then return end
    
    -- Get stats for the item being compared
    local itemStats = C_Item.GetItemStats(itemLink)
    if not itemStats then return end
    
    -- Update cache and get equipped item for comparison
    self:UpdateEquippedItemCache()
    local equippedItems = equippedItemCache.data[itemEquipLoc]
    if not equippedItems or #equippedItems == 0 then 
        tooltip:AddLine(" ", 1, 1, 1)
        tooltip:AddLine("|cFFFFD700Comparison:|r", 1, 1, 1)
        tooltip:AddLine("|cff999999No equipped item in this slot|r", 0.6, 0.6, 0.6)
        return 
    end
    
    -- For multiple slots (rings, trinkets), compare with the first one or best one
    local equippedLink = nil
    if equippedItems.link then
        equippedLink = equippedItems.link
    elseif type(equippedItems) == "table" and equippedItems[1] then
        equippedLink = equippedItems[1].link
    end
    
    if not equippedLink then 
        tooltip:AddLine(" ", 1, 1, 1)
        tooltip:AddLine("|cFFFFD700Comparison:|r", 1, 1, 1)
        tooltip:AddLine("|cff999999No equipped item in this slot|r", 0.6, 0.6, 0.6)
        return 
    end
    
    -- Get stats for equipped item
    local equippedStats = C_Item.GetItemStats(equippedLink)
    if not equippedStats then 
        tooltip:AddLine(" ", 1, 1, 1)
        tooltip:AddLine("|cFFFFD700Comparison:|r", 1, 1, 1)
        tooltip:AddLine("|cff999999Unable to get equipped item stats|r", 0.6, 0.6, 0.6)
        return 
    end
    
    -- Add comparison header
    tooltip:AddLine(" ", 1, 1, 1)
    tooltip:AddLine("|cFFFFD700Comparison with equipped item:|r", 1, 1, 1)
    
    -- Compare stats
    local hasDifferences = false
    
    -- Create a list of all stat types to compare
    local allStats = {}
    for stat in pairs(itemStats) do
        allStats[stat] = true
    end
    for stat in pairs(equippedStats) do
        allStats[stat] = true
    end
    
    -- Compare each stat
    for statName in pairs(allStats) do
        local itemValue = itemStats[statName] or 0
        local equippedValue = equippedStats[statName] or 0
        local difference = itemValue - equippedValue
        
        if difference ~= 0 then
            hasDifferences = true
            local statDisplayName = statName:gsub("ITEM_MOD_", ""):gsub("_SHORT", ""):gsub("_", " ")
            statDisplayName = statDisplayName:gsub("^%l", string.upper)
            
            local color = "|cff00ff00" -- Green for upgrade
            if difference < 0 then
                color = "|cffff0000" -- Red for downgrade
            end
            
            local sign = "+"
            if difference < 0 then
                sign = ""
            end
            
            tooltip:AddDoubleLine(
                statDisplayName .. ":", 
                string.format("%s%s%d|r", color, sign, difference),
                1, 1, 1, 1, 1, 1
            )
        end
    end
    
    if not hasDifferences then
        tooltip:AddLine("|cff999999No stat differences|r", 0.6, 0.6, 0.6)
    end
end

function EpicTipItemInfoMixin:GetItemSource(itemID)
    if not itemID then return nil end
    
    -- Basic source detection using Blizzard APIs with error handling
    local success1, sourceInfo = pcall(C_Item.GetItemInventoryTypeByID, itemID)
    if success1 and sourceInfo then
        return "Equipment"
    end
    
    -- Check if it's a quest item with error handling
    local success2, itemInfo = pcall(C_Item.GetItemInfo, itemID)
    if success2 and itemInfo and itemInfo.classID == Enum.ItemClass.Questitem then
        return "Quest"
    end
    
    -- Check if it's a consumable
    if success2 and itemInfo and itemInfo.classID == Enum.ItemClass.Consumable then
        return "Consumable"
    end
    
    return "Unknown"
end

function EpicTipItemInfoMixin:GetEquippedItemComparison(itemEquipLoc)
    if not itemEquipLoc or itemEquipLoc == "" then return nil end
    
    -- Update cache if needed (very fast check)
    self:UpdateEquippedItemCache()
    
    -- Use cached data for instant response
    local cachedData = equippedItemCache.data[itemEquipLoc]
    if not cachedData then return nil end
    
    if type(cachedData) == "table" and cachedData.level then
        -- Single item slot
        return cachedData.level
    elseif type(cachedData) == "table" and #cachedData > 0 then
        -- Multiple items (rings, trinkets) - return lowest for conservative comparison
        local lowestLevel = cachedData[1].level
        for i = 2, #cachedData do
            if cachedData[i].level < lowestLevel then
                lowestLevel = cachedData[i].level
            end
        end
        return lowestLevel
    end
    
    return nil
end

function EpicTipItemInfoMixin:ProcessItemTooltip(tooltip)
    -- Enhanced safety checks for modern WoW 11.2 tooltip system
    if not tooltip or not tooltip.GetItem then return end
    
    -- Safely get item information with modern error handling
    local success, name, link = pcall(tooltip.GetItem, tooltip)
    if not success or not link then return end
    
    -- Modern item ID extraction with C_Item integration
    local itemID = GetItemInfoFromHyperlink(link)
    if not itemID then return end
    
    -- Modern WoW 11.2 Item Information Gathering using C_Item API with error handling
    local success, itemInfo = pcall(C_Item.GetItemInfo, itemID)
    if not success or not itemInfo then return end
    
    -- Extract item properties from modern API structure
    local itemName = itemInfo.itemName
    local itemLink = link -- Use the link we already have
    local itemRarity = itemInfo.itemQuality
    local itemLevel = itemInfo.itemLevel
    local itemMinLevel = itemInfo.itemMinLevel
    local itemType = itemInfo.itemType
    local itemSubType = itemInfo.itemSubType
    local itemStackCount = itemInfo.itemStackCount
    local itemEquipLoc = itemInfo.itemEquipLoc
    local itemTexture = itemInfo.itemTexture
    local sellPrice = itemInfo.sellPrice
    
    -- Enhanced item level detection with multiple modern methods
    local actualItemLevel = nil
    
    -- Method 1: Modern C_Item.GetDetailedItemLevelInfo (most accurate for equipped/inspected items)
    local success1, level1 = pcall(C_Item.GetDetailedItemLevelInfo, link)
    if success1 and level1 and level1 > 0 then
        actualItemLevel = level1
    end
    
    -- Method 2: Enhanced C_Item.GetItemStats with better error handling
    if not actualItemLevel then
        local success2, stats = pcall(C_Item.GetItemStats, link)
        if success2 and stats and stats.ITEM_MOD_ITEM_LEVEL then
            actualItemLevel = stats.ITEM_MOD_ITEM_LEVEL
        end
    end
    
    -- Method 3: Modern link parsing with enhanced validation
    if not actualItemLevel then
        local linkItemLevel = link:match(":(%d+):")
        if linkItemLevel then
            actualItemLevel = tonumber(linkItemLevel)
        end
    end
    
    -- Use the most accurate item level we found (WoW 11.2 enhanced)
    if actualItemLevel and actualItemLevel > 0 then
        itemLevel = actualItemLevel
    end
    
    if not itemName then return end
    
    -- Add item information following Blizzard tooltip standards
    if EpicTipDB.showItemInfo then
        -- Item Type and Subtype
        if itemType then
            local typeText = itemType
            if itemSubType and itemSubType ~= itemType then
                typeText = itemType .. " - " .. itemSubType
            end
            tooltip:AddDoubleLine(L["Type:"] or "Type:", typeText, 0.8, 0.8, 1, 1, 1, 1)
        end
        
        -- Equipment Slot
        if itemEquipLoc and itemEquipLoc ~= "" then
            local slotName = _G[itemEquipLoc] or itemEquipLoc
            tooltip:AddDoubleLine(L["Slot:"] or "Slot:", slotName, 0.8, 0.8, 1, 1, 1, 1)
        end
        
        -- Item Level Comparison for equipment
        if itemLevel and itemLevel > 0 and itemEquipLoc and itemEquipLoc ~= "" then
            local equippedItemLevel = self:GetEquippedItemComparison(itemEquipLoc)
            if equippedItemLevel then
                local comparison = itemLevel - equippedItemLevel
                local comparisonText = ""
                local r, g, b = 1, 1, 1
                
                if comparison > 0 then
                    comparisonText = string.format("(+%d)", comparison)
                    r, g, b = 0, 1, 0 -- Green for upgrade
                elseif comparison < 0 then
                    comparisonText = string.format("(%d)", comparison)
                    r, g, b = 1, 0, 0 -- Red for downgrade
                else
                    comparisonText = "(=)"
                    r, g, b = 1, 1, 0 -- Yellow for same level
                end
                
                tooltip:AddDoubleLine(L["Item Level:"] or "Item Level:", 
                    string.format("%d %s", itemLevel, comparisonText), 
                    0.8, 0.8, 1, r, g, b)
            else
                tooltip:AddDoubleLine(L["Item Level:"] or "Item Level:", tostring(itemLevel), 0.8, 0.8, 1, 1, 1, 1)
            end
        end
        
        -- Stack Count for stackable items
        if itemStackCount and itemStackCount > 1 then
            tooltip:AddDoubleLine(L["Stack:"] or "Stack:", tostring(itemStackCount), 0.8, 0.8, 1, 1, 1, 1)
        end
        
        -- Source information
        local source = self:GetItemSource(itemID)
        if source then
            tooltip:AddDoubleLine(L["Source:"] or "Source:", source, 0.5, 1, 0.5, 1, 1, 1)
        end
        
        -- Add "Press Shift to compare" hint for equipment items
        if itemEquipLoc and itemEquipLoc ~= "" then
            if not IsShiftKeyDown() then
                tooltip:AddLine(" ", 1, 1, 1)
                tooltip:AddLine("|cff999999Press Shift to compare|r", 0.6, 0.6, 0.6)
            else
                -- Show detailed comparison when shift is held
                self:ShowDetailedComparison(tooltip, link, itemEquipLoc)
            end
        end

    end
end



-- Modern WoW 11.2 Item Search with C_Item API Integration
-- Replaces deprecated GetItemInfo with modern C_Item methods for better performance
function ItemInfo.SearchItemByName(itemName)
    if not itemName or itemName == "" then
        if EpicTipDB.debugMode then
            print("|cFFFFD700EpicTip:|r Please provide an item name to search for.")
        end
        return
    end
    
    -- Modern item search using C_Item APIs (WoW 11.2 optimized)
    local results = {} -- Use standard Lua table
    local searchPattern = itemName:lower()
    
    -- Enhanced search range with modern item ID handling for WoW 11.2
    for itemID = 1, 200000 do
        -- Use modern C_Item API with error handling (always available in WoW 11.2)
        local success, itemInfo = pcall(C_Item.GetItemInfo, itemID)
        if success and itemInfo and itemInfo.itemName then
            local name = itemInfo.itemName:lower()
            if name:find(searchPattern, 1, true) then -- Plain text search for performance
                table.insert(results, {id = itemID, name = itemInfo.itemName, quality = itemInfo.itemQuality})
                if #results >= 10 then break end -- Limit results for performance
            end
        end
    end
    
    if #results == 0 then
        if EpicTipDB.debugMode then
            print("|cFFFFD700EpicTip:|r No items found matching '" .. itemName .. "'")
        end
        return
    end
    
    if EpicTipDB.debugMode then
        print("|cFFFFD700EpicTip:|r Found " .. #results .. " items:")
    end
    
    -- Modern display with quality colors (WoW 11.2 enhanced)
    for index, item in ipairs(results) do
        -- Use modern C_Item.GetItemLink (always available in WoW 11.2)
        local success, link = pcall(C_Item.GetItemLink, item.id)
        
        if success and link then
            -- Enhanced display with quality indication
            local qualityText = ""
            if item.quality and item.quality >= 0 then
                local qualityColor = ITEM_QUALITY_COLORS[item.quality]
                if qualityColor then
                    qualityText = qualityColor.hex .. "[Q" .. item.quality .. "]|r "
                end
            end
            print(index .. ". " .. qualityText .. link)
        end
    end

end

-- Module functions (Processor registration removed - now handled by unified system)
function ItemInfo.SetupItemTooltipProcessor()
    -- Note: Tooltip processing is now handled by the unified TooltipDataProcessor system
    -- in Tooltip.lua to eliminate redundancy and improve performance (WoW 11.2 optimization)
    -- This function is maintained for API compatibility but no longer registers separate processors
    
    -- Register events to keep equipped item cache updated for instant comparisons
    if not ItemInfo.eventsRegistered then
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        frame:RegisterEvent("BAG_UPDATE_DELAYED")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        
        frame:SetScript("OnEvent", function(self, event, ...)
            if event == "PLAYER_EQUIPMENT_CHANGED" or 
               event == "BAG_UPDATE_DELAYED" or 
               event == "PLAYER_ENTERING_WORLD" then
                -- Force immediate cache update when equipment changes
                equippedItemCache.lastUpdate = 0
                UpdateEquippedItemCache()
            end
        end)
        
        ItemInfo.eventsRegistered = true
        
        -- Initial cache population
        UpdateEquippedItemCache()
    end
end

function ItemInfo.SetupSlashCommands()
    -- NOTE: Slash commands are now handled by Core.lua using unified system
    -- to prevent conflicts with multiple registration systems. The /etitem and /etsearch
    -- commands have been removed as they violate slash command design standards.
    -- Only /et, /et config, and /et reset are supported.
    -- Item search functionality can be accessed through the main config interface.
end

-- Debug function to test item comparison
function ItemInfo.DebugItemComparison()
    if not ET or not ET.Print then return end
    
    ET:Print("=== Item Comparison Debug Info ===")
    ET:Print("Equipped Item Cache Status:")
    ET:Print("  Last Update: " .. tostring(equippedItemCache.lastUpdate))
    ET:Print("  Update Interval: " .. tostring(equippedItemCache.updateInterval))
    ET:Print("  Cached Slots: " .. tostring(#equippedItemCache.data))
    
    -- Show some cached items
    local count = 0
    for slot, items in pairs(equippedItemCache.data) do
        if count < 5 then
            if items.link then
                ET:Print("  " .. slot .. ": " .. tostring(items.link))
            elseif type(items) == "table" and items[1] then
                ET:Print("  " .. slot .. ": " .. tostring(items[1].link))
            end
            count = count + 1
        end
    end
    
    if count == 0 then
        ET:Print("  No items cached")
    end
end

local addonName, JTT = ...

JTT.ItemInfo = JTT.ItemInfo or {}
local ItemInfo = JTT.ItemInfo
local L = JTT.L

JustTheTipItemInfoMixin = {}



function JustTheTipItemInfoMixin:GetItemSource(itemID)
    if not itemID then return nil end
    
    -- Basic source detection using Blizzard APIs
    local sourceInfo = C_Item.GetItemInventoryTypeByID(itemID)
    if sourceInfo then
        return "Equipment"
    end
    
    -- Check if it's a quest item
    local itemInfo = C_Item.GetItemInfo(itemID)
    if itemInfo and itemInfo.classID == Enum.ItemClass.Questitem then
        return "Quest"
    end
    
    -- Check if it's a consumable
    if itemInfo and itemInfo.classID == Enum.ItemClass.Consumable then
        return "Consumable"
    end
    
    return "Unknown"
end

function JustTheTipItemInfoMixin:GetEquippedItemComparison(itemEquipLoc)
    if not itemEquipLoc or itemEquipLoc == "" then return nil end
    
    -- Map item equip locations to inventory slot IDs
    local slotMap = {
        ["INVTYPE_HEAD"] = 1,
        ["INVTYPE_NECK"] = 2,
        ["INVTYPE_SHOULDER"] = 3,
        ["INVTYPE_BODY"] = 4,
        ["INVTYPE_CHEST"] = 5,
        ["INVTYPE_ROBE"] = 5, -- Robes use chest slot
        ["INVTYPE_WAIST"] = 6,
        ["INVTYPE_LEGS"] = 7,
        ["INVTYPE_FEET"] = 8,
        ["INVTYPE_WRIST"] = 9,
        ["INVTYPE_HAND"] = 10,
        ["INVTYPE_FINGER"] = {11, 12}, -- Two ring slots
        ["INVTYPE_TRINKET"] = {13, 14}, -- Two trinket slots
        ["INVTYPE_CLOAK"] = 15,
        ["INVTYPE_WEAPON"] = 16, -- Main hand
        ["INVTYPE_2HWEAPON"] = 16, -- Two-handed weapons
        ["INVTYPE_WEAPONMAINHAND"] = 16,
        ["INVTYPE_WEAPONOFFHAND"] = 17,
        ["INVTYPE_SHIELD"] = 17,
        ["INVTYPE_HOLDABLE"] = 17,
        ["INVTYPE_RANGED"] = 18,
        ["INVTYPE_THROWN"] = 18,
        ["INVTYPE_RANGEDRIGHT"] = 18,
        ["INVTYPE_RELIC"] = 18,
    }
    
    local slotID = slotMap[itemEquipLoc]
    if not slotID then return nil end
    
    -- Handle slots with multiple options (rings, trinkets)
    if type(slotID) == "table" then
        -- For rings and trinkets, check both slots and return the lower ilvl for comparison
        local ilvl1, ilvl2
        local link1 = GetInventoryItemLink("player", slotID[1])
        local link2 = GetInventoryItemLink("player", slotID[2])
        
        if link1 then
            local success, itemLevel = pcall(C_Item.GetDetailedItemLevelInfo, link1)
            if success then ilvl1 = itemLevel end
        end
        if link2 then
            local success, itemLevel = pcall(C_Item.GetDetailedItemLevelInfo, link2)
            if success then ilvl2 = itemLevel end
        end
        
        -- Return the lower of the two (or the only one equipped)
        if ilvl1 and ilvl2 then
            return math.min(ilvl1, ilvl2)
        elseif ilvl1 then
            return ilvl1
        elseif ilvl2 then
            return ilvl2
        else
            return nil
        end
    else
        -- Single slot item
        local equippedLink = GetInventoryItemLink("player", slotID)
        if not equippedLink then return nil end
        
        local success, equippedItemLevel = pcall(C_Item.GetDetailedItemLevelInfo, equippedLink)
        if success then
            return equippedItemLevel
        else
            return nil
        end
    end
end

function JustTheTipItemInfoMixin:ProcessItemTooltip(tooltip)
    -- Safety checks for tooltip validity
    if not tooltip then return end
    if not tooltip.GetItem then return end
    
    -- Safely get item information
    local success, name, link = pcall(tooltip.GetItem, tooltip)
    if not success or not link then return end
    
    local itemID = GetItemInfoFromHyperlink(link)
    if not itemID then return end
    
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, 
          itemStackCount, itemEquipLoc, itemTexture, sellPrice = GetItemInfo(itemID)
    
    -- Try multiple methods to get the correct item level
    local actualItemLevel = nil
    
    -- Method 1: C_Item.GetDetailedItemLevelInfo (most accurate for equipped/inspected items)
    local success1, level1 = pcall(C_Item.GetDetailedItemLevelInfo, link)
    if success1 and level1 and level1 > 0 then
        actualItemLevel = level1
    end
    
    -- Method 2: Try getting from item stats if available
    if not actualItemLevel then
        local stats = C_Item.GetItemStats(link)
        if stats and stats.ITEM_MOD_ITEM_LEVEL then
            actualItemLevel = stats.ITEM_MOD_ITEM_LEVEL
        end
    end
    
    -- Method 3: Parse from the item link itself
    if not actualItemLevel then
        local linkItemLevel = link:match(":(%d+):")
        if linkItemLevel then
            actualItemLevel = tonumber(linkItemLevel)
        end
    end
    
    -- Use the most accurate item level we found
    if actualItemLevel and actualItemLevel > 0 then
        itemLevel = actualItemLevel
    end
    
    -- Debug output to compare values
    if JustTheTipDB and JustTheTipDB.debugMode then
        print("Debug - Item:", itemName or "unknown")
        print("Debug - GetItemInfo itemLevel:", itemLevel or "nil")
        print("Debug - C_Item.GetDetailedItemLevelInfo:", level1 or "nil")
        print("Debug - Final itemLevel used:", actualItemLevel or itemLevel or "nil")
        print("Debug - sellPrice:", sellPrice or "nil")
    end
    
    if not itemName then return end
    
    -- Add item information following Blizzard tooltip standards
    if JustTheTipDB.showItemInfo then
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
        if itemEquipLoc and itemEquipLoc ~= "" and not IsShiftKeyDown() then
            tooltip:AddLine(" ", 1, 1, 1)
            tooltip:AddLine("|cff999999Press Shift to compare|r", 0.6, 0.6, 0.6)
        end

    end
end



-- Item search functionality (Kiwi feature)
function ItemInfo.SearchItemByName(itemName)
    if not itemName or itemName == "" then
        print("|cFFFFD700Just the Tip:|r Please provide an item name to search for.")
        return
    end
    
    -- Search for items matching the name
    local results = {}
    for itemID = 1, 200000 do -- Search range (adjust as needed)
        local name = GetItemInfo(itemID)
        if name and name:lower():find(itemName:lower()) then
            table.insert(results, {id = itemID, name = name})
            if #results >= 10 then break end -- Limit results
        end
    end
    
    if #results == 0 then
        print("|cFFFFD700Just the Tip:|r No items found matching '" .. itemName .. "'")
        return
    end
    
    print("|cFFFFD700Just the Tip:|r Found " .. #results .. " items:")
    for i, item in ipairs(results) do
        local link = select(2, GetItemInfo(item.id))
        if link then
            print(i .. ". " .. link)
        end
    end
end

-- Module functions
function ItemInfo.SetupItemTooltipProcessor()
    -- Create mixin instance
    local itemInfoProcessor = {}
    Mixin(itemInfoProcessor, JustTheTipItemInfoMixin)
    
    -- Register tooltip processor using Blizzard's system
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
        if not JustTheTipDB.enabled or not JustTheTipDB.showItemInfo then return end
        
        -- Only process main GameTooltip and ItemRefTooltip, skip shopping tooltips
        if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
        
        itemInfoProcessor:ProcessItemTooltip(tooltip)
    end)
end

function ItemInfo.SetupSlashCommands()
    SLASH_JTTITEM1 = "/jttitem"
    SLASH_JTTITEM2 = "/jttsearch"
    SlashCmdList["JTTITEM"] = function(msg)
        msg = string.trim(msg)
        if msg == "" then
            print("|cFFFFD700Just the Tip Item Search:|r Usage: /jttitem <item name>")
            print("Example: /jttitem thunderfury")
        else
            ItemInfo.SearchItemByName(msg)
        end
    end
end
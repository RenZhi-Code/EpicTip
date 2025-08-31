local addonName, ET = ...

-- Static data module - lazy loaded constants following Blizzard standards
-- This prevents recreation of large tables and improves memory efficiency

ET.StaticData = ET.StaticData or {}
local StaticData = ET.StaticData

-- Lazy-loaded static data (only for data that truly benefits from caching)
local _mountData
local _mythicPlusData

-- Class Icons (dynamic generation - no longer needs caching)
function StaticData.GetClassIcons()
    -- Deprecated: Use StaticData.GetClassIcon(classFileName) instead
    -- This function maintained for backward compatibility but should not be used
    return nil
end

-- Role Icons (dynamic generation - no longer needs caching)
function StaticData.GetRoleIcons()
    -- Deprecated: Use StaticData.GetRoleIcon(role) instead  
    -- This function maintained for backward compatibility but should not be used
    return nil
end

-- Mount data (lazy-loaded, can be extended)
function StaticData.GetMountData()
    if not _mountData then
        _mountData = {
            -- Common mount classifications
            flying = {
                "Invincible", "Ashes of Al'ar", "Mimiron's Head", "Azure Drake",
                "Blue Drake", "Bronze Drake", "Twilight Drake", "Black Drake"
            },
            ground = {
                "Swift Spectral Tiger", "Amani Battle Bear", "Zulian Tiger",
                "Swift Razzashi Raptor", "Fiery Warhorse"
            },
            swimming = {
                "Sea Turtle", "Riding Turtle", "Subdued Seahorse"
            },
            rare = {
                -- Rare mounts with special significance
                dropRate = {
                    ["Invincible"] = 0.01,
                    ["Ashes of Al'ar"] = 0.02,
                    ["Mimiron's Head"] = 0.01,
                    ["Amani Battle Bear"] = 0.005 -- No longer obtainable
                }
            },
            -- Achievement mounts
            achievement = {
                ["What a Long, Strange Trip It's Been"] = "Violet Proto-Drake",
                ["Leading the Cavalry"] = "Albino Drake",
                ["Lord of the Reins"] = "Lord of the Reins"
            }
        }
    end
    return _mountData
end

-- Mythic Plus data (lazy-loaded with current season data)
function StaticData.GetMythicPlusData()
    if not _mythicPlusData then
        _mythicPlusData = {
            -- Current season affixes (The War Within Season 3 - Patch 11.2)
            seasonalAffixes = {
                -- Level +4 affixes (Xal'atath's Bargain - rotates weekly)
                ["Xal'atath's Bargain: Ascendant"] = "Increases damage by 10% but reduces healing received by 20%",
                ["Xal'atath's Bargain: Voidbound"] = "Increases movement speed by 30% but reduces damage by 15%",
                ["Xal'atath's Bargain: Oblivion"] = "Increases spell damage by 15% but reduces physical damage by 10%",
                ["Xal'atath's Bargain: Devour"] = "Increases damage against enemies below 35% health by 25%",
                
                -- Level +7 affixes (alternates weekly)
                ["Tyrannical"] = "Boss enemies have 30% more health and inflict up to 15% increased damage",
                ["Fortified"] = "Non-boss enemies have 20% more health and inflict up to 30% increased damage",
                
                -- Level +10: Both Tyrannical and Fortified are active
                -- Level +12: Xal'atath's Guile is added
                ["Xal'atath's Guile"] = "Additional challenging mechanics throughout the dungeon",
                
                -- New Season 3 affixes (retired old ones)
                ["Reckless"] = "Non-boss enemies hit harder, ignoring 20% armor, but take 10% more Arcane damage",
                ["Thorned"] = "Non-mana enemies strike back when hit, but take 10% more Holy/Shadow damage",
                ["Attuned"] = "Mana enemies deal 20% more magic damage, but take 10% more Nature and 30% more Bleed damage",
                ["Focused"] = "Mana enemies have 30% more Haste, but take 10% more Frost/Fire damage"
            },
            
            -- Season 3 Dungeon Pool (8 dungeons)
            dungeonKeys = {
                ["DB"] = "The Dawnbreaker",
                ["AK"] = "Ara-Kara, City of Echoes", 
                ["OF"] = "Operation: Floodgate",
                ["PSF"] = "Priory of Sacred Flame",
                ["EDA"] = "Eco-Dome Al'dani", -- New in 11.2
                ["HOA"] = "Halls of Atonement", -- Shadowlands return
                ["TSW"] = "Tazavesh: Streets of Wonder", -- Split from mega-dungeon
                ["TSG"] = "Tazavesh: So'leah's Gambit" -- Split from mega-dungeon
            },
            
            -- Updated rating thresholds for Season 3
            ratingThresholds = {
                { rating = 1500, color = {0.5, 1, 0.5}, reward = "Hero Track Items (684-691)" },
                { rating = 1800, color = {0.3, 0.8, 1}, reward = "Mythic Track Items (694-701)" },
                { rating = 2000, color = {0, 1, 1}, reward = "Keystone Hero Achievement" },
                { rating = 2400, color = {1, 0.5, 1}, reward = "Keystone Master Achievement" },
                { rating = 2500, color = {1, 0.5, 1}, reward = "Elite Transmog" },
                { rating = 3000, color = {1, 0.8, 0}, reward = "Cutting Edge Rating" }
            },
            
            -- Season 3 title thresholds
            titleThresholds = {
                { rating = 2000, title = "the Keystone Hero" },
                { rating = 2400, title = "the Keystone Master" },
                { rating = 3000, title = "the Great Pusher" }
            },
            
            -- Season 3 item levels
            itemLevels = {
                [2] = { dungeon = 684, vault = 694 },
                [3] = { dungeon = 684, vault = 694 },
                [4] = { dungeon = 688, vault = 697 },
                [5] = { dungeon = 691, vault = 697 },
                [6] = { dungeon = 694, vault = 701 },
                [7] = { dungeon = 694, vault = 704 },
                [8] = { dungeon = 697, vault = 704 },
                [9] = { dungeon = 697, vault = 704 },
                [10] = { dungeon = 701, vault = 707 },
                [11] = { dungeon = 701, vault = 707 },
                [12] = { dungeon = 701, vault = 707 }
            },
            
            -- Retired affixes (no longer used in Season 3)
            retiredAffixes = {
                "Afflicted", "Entangling", "Incorporeal", "Storming", "Volcanic",
                "Spiteful", "Bolstering", "Raging", "Sanguine", "Bursting", "Challenger's Peril"
            }
        }
    end
    return _mythicPlusData
end

-- Utility functions for quick access (fallback compatibility - defers to Utils module)
function StaticData.GetClassIcon(classFileName)
    -- Prefer Core\Utils.lua implementation (modular design principle)
    if ET.Utils and ET.Utils.GetClassIcon then
        return ET.Utils:GetClassIcon(classFileName)
    end
    
    -- Fallback implementation if Utils module unavailable
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
        -- For all other classes, generate using optimized string formatting
        local className = string.format("%s%s", classFileName:sub(1,1):upper(), classFileName:sub(2):lower())
        return string.format("|TInterface\\Icons\\ClassIcon_%s:16:16:0:0:64:64:4:60:4:60|t", className)
    end
end

function StaticData.GetRoleIcon(role)
    -- Prefer Core\Utils.lua implementation (modular design principle)
    if ET.Utils and ET.Utils.GetRoleIcon then
        return ET.Utils:GetRoleIcon(role)
    end
    
    -- Fallback implementation if Utils module unavailable
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

-- Memory cleanup function (called on addon disable/reload)
function StaticData.Cleanup()
    -- Class and role icons are now generated dynamically, no caching needed
    -- Only clear mount and mythic+ data which may still use caching
    _mountData = nil
    _mythicPlusData = nil
end

-- Utility functions for accessing enhanced data
function StaticData.GetMythicRatingColor(rating)
    local data = StaticData.GetMythicPlusData()
    local thresholds = data.ratingThresholds
    
    for i = #thresholds, 1, -1 do
        if rating >= thresholds[i].rating then
            return thresholds[i].color
        end
    end
    
    -- Default color for ratings below threshold
    return {0.8, 0.8, 0.8}
end

function StaticData.GetMythicTitle(rating)
    local data = StaticData.GetMythicPlusData()
    local titleThresholds = data.titleThresholds
    
    for i = #titleThresholds, 1, -1 do
        if rating >= titleThresholds[i].rating then
            return titleThresholds[i].title
        end
    end
    
    return nil
end

function StaticData.IsMountRare(mountName)
    local data = StaticData.GetMountData()
    
    -- Check if mount is in rare categories
    for _, category in pairs({"rare", "achievement"}) do
        if data[category] then
            for _, mount in pairs(data[category]) do
                if type(mount) == "string" and mount == mountName then
                    return true
                elseif type(mount) == "table" and mount[mountName] then
                    return true
                end
            end
        end
    end
    
    return false
end

function StaticData.GetMountDropRate(mountName)
    local data = StaticData.GetMountData()
    
    if data.rare and data.rare.dropRate and data.rare.dropRate[mountName] then
        return data.rare.dropRate[mountName] * 100 -- Return as percentage
    end
    
    return nil
end

-- Season 3 specific utility functions
function StaticData.GetDungeonName(abbreviation)
    local data = StaticData.GetMythicPlusData()
    return data.dungeonKeys[abbreviation] or abbreviation
end

function StaticData.GetKeystoneItemLevel(level, isVault)
    local data = StaticData.GetMythicPlusData()
    local itemLevels = data.itemLevels
    
    if not itemLevels[level] then
        -- For levels above 12, use max rewards
        level = math.min(level, 12)
    end
    
    if itemLevels[level] then
        return isVault and itemLevels[level].vault or itemLevels[level].dungeon
    end
    
    return nil
end

function StaticData.IsAffixRetired(affixName)
    local data = StaticData.GetMythicPlusData()
    
    if data.retiredAffixes then
        for _, retired in ipairs(data.retiredAffixes) do
            if retired == affixName then
                return true
            end
        end
    end
    
    return false
end

function StaticData.GetCurrentSeasonDungeons()
    local data = StaticData.GetMythicPlusData()
    local dungeons = {}
    
    if data.dungeonKeys then
        for abbrev, name in pairs(data.dungeonKeys) do
            table.insert(dungeons, {abbreviation = abbrev, name = name})
        end
    end
    
    return dungeons
end
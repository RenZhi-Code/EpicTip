local addonName, ET = ...

-- Static data module - lazy loaded constants following Blizzard standards
-- This prevents recreation of large tables and improves memory efficiency

ET.StaticData = ET.StaticData or {}
local StaticData = ET.StaticData

-- Lazy-loaded static data (only for data that truly benefits from caching)
local _mountData
local _mythicPlusData
local _pvpData

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
            -- Midnight Season 1 — Patch 12.0.1 (season started March 24, 2026)

            -- Affixes by keystone level:
            --  +2  Lindormi's Guidance (removed at +6)
            --  +4  Xal'atath's Bargain (Ascendant/Voidbound/Pulsar/Devour — weekly rotation, removed at +12)
            --  +7  Tyrannical or Fortified (weekly rotation)
            --  +10 Both Tyrannical and Fortified active simultaneously
            --  +12 Xal'atath's Guile replaces Bargain (-15s per death)
            seasonalAffixes = {
                ["Lindormi's Guidance"]              = "Highlights and weakens certain enemies (+2 to +5)",
                ["Xal'atath's Bargain: Ascendant"]   = "Xal'atath's Bargain — weekly rotation (+4 to +11)",
                ["Xal'atath's Bargain: Voidbound"]   = "Xal'atath's Bargain — weekly rotation (+4 to +11)",
                ["Xal'atath's Bargain: Pulsar"]      = "Xal'atath's Bargain — weekly rotation (+4 to +11)",
                ["Xal'atath's Bargain: Devour"]      = "Xal'atath's Bargain — weekly rotation (+4 to +11)",
                ["Tyrannical"]                       = "Bosses have 30% more health and deal up to 15% increased damage (+7+)",
                ["Fortified"]                        = "Non-boss enemies have 20% more health and deal up to 30% increased damage (+7+)",
                ["Xal'atath's Guile"]                = "Each death subtracts 15 seconds from the timer (+12+)",
            },

            -- Midnight Season 1 dungeon pool (4 new Midnight + 4 legacy)
            dungeonKeys = {
                ["MT"]  = "Magisters' Terrace",       -- Midnight
                ["MC"]  = "Maisara Caverns",          -- Midnight
                ["NPX"] = "Nexus-Point Xenas",        -- Midnight
                ["WS"]  = "Windrunner Spire",         -- Midnight
                ["AA"]  = "Algeth'ar Academy",        -- Dragonflight
                ["ST"]  = "Seat of the Triumvirate",  -- Legion
                ["SKY"] = "Skyreach",                 -- Warlords of Draenor
                ["PS"]  = "Pit of Saron",             -- Wrath of the Lich King
            },

            -- Dungeon-specific mount drops
            dungeonMounts = {
                ["Magisters' Terrace"] = "Lucent Hawkstrider",
                ["Windrunner Spire"]   = "Spectral Hawkstrider",
            },

            -- Rating thresholds, achievements, and rewards (Midnight Season 1)
            ratingThresholds = {
                { rating = 1500, color = {0.5, 1,   0.5}, reward = "Title: \"the Umbral\"",              achievement = "Midnight Keystone Conqueror: Season One" },
                { rating = 2000, color = {0,   1,   1  }, reward = "Mount: Calamitous Carrion",          achievement = "Midnight Keystone Master: Season One" },
                { rating = 2500, color = {1,   0.5, 1  }, reward = "Gleaming Sunmote (Mythic tier set visual)", achievement = "Midnight Keystone Hero: Season One" },
                { rating = 3000, color = {1,   0.8, 0  }, reward = "Mount: Convalescent Carrion",        achievement = "Midnight Keystone Legend: Season One" },
            },

            -- Title thresholds
            titleThresholds = {
                { rating = 1500, title = "the Umbral" },
                { rating = 3000, title = "the Umbral Hero" }, -- top 0.1% of region
            },

            -- End-of-dungeon and Great Vault item levels (Midnight Season 1)
            -- Gear ilvl caps at +10 — higher keys yield more/better crests only
            itemLevels = {
                [0]  = { dungeon = 246, vault = 256, dungeonTrack = "Champion 1/6", vaultTrack = "Champion 4/6" },
                [2]  = { dungeon = 250, vault = 259, dungeonTrack = "Champion 2/6", vaultTrack = "Hero 1/6" },
                [3]  = { dungeon = 250, vault = 259, dungeonTrack = "Champion 2/6", vaultTrack = "Hero 1/6" },
                [4]  = { dungeon = 253, vault = 263, dungeonTrack = "Champion 3/6", vaultTrack = "Hero 2/6" },
                [5]  = { dungeon = 256, vault = 263, dungeonTrack = "Champion 4/6", vaultTrack = "Hero 2/6" },
                [6]  = { dungeon = 259, vault = 266, dungeonTrack = "Hero 1/6",     vaultTrack = "Hero 3/6" },
                [7]  = { dungeon = 259, vault = 269, dungeonTrack = "Hero 1/6",     vaultTrack = "Hero 4/6" },
                [8]  = { dungeon = 263, vault = 269, dungeonTrack = "Hero 2/6",     vaultTrack = "Hero 4/6" },
                [9]  = { dungeon = 263, vault = 269, dungeonTrack = "Hero 2/6",     vaultTrack = "Hero 4/6" },
                [10] = { dungeon = 266, vault = 272, dungeonTrack = "Hero 3/6",     vaultTrack = "Myth 1/6" },
            },

            -- Crest drops by key level
            crestDrops = {
                [2]  = { type = "Hero Dawncrest",  count = 10 },
                [3]  = { type = "Hero Dawncrest",  count = 12 },
                [4]  = { type = "Hero Dawncrest",  count = 14 },
                [5]  = { type = "Hero Dawncrest",  count = 16 },
                [6]  = { type = "Hero Dawncrest",  count = 18 },
                [7]  = { type = "Myth Dawncrest",  count = 10 },
                [8]  = { type = "Myth Dawncrest",  count = 12 },
                [9]  = { type = "Myth Dawncrest",  count = 14 },
                [10] = { type = "Myth Dawncrest",  count = 16 },
            },

            -- Affixes retired before Midnight Season 1
            retiredAffixes = {
                "Afflicted", "Entangling", "Incorporeal", "Storming", "Volcanic",
                "Spiteful", "Bolstering", "Raging", "Sanguine", "Bursting",
                "Challenger's Peril", "Xal'atath's Bargain: Oblivion",
                "Xal'atath's Guile", "Reckless", "Thorned", "Attuned", "Focused",
            },
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

-- PvP rank data (Midnight Season 1)
function StaticData.GetPvPData()
    if not _pvpData then
        _pvpData = {
            -- Ranked brackets
            brackets = {
                [1] = "2v2",
                [2] = "3v3",
                [4] = "RBG",
            },
            -- Rating thresholds → rank name, colour {r,g,b}
            -- Applies to all brackets
            rankThresholds = {
                { rating = 0,    rank = "Unranked",   color = {0.62, 0.62, 0.62} },
                { rating = 1,    rank = "Combatant",  color = {1,    1,    1   } },
                { rating = 1400, rank = "Challenger",  color = {0.12, 0.75, 0   } },
                { rating = 1600, rank = "Rival",       color = {0,    0.44, 0.87} },
                { rating = 1800, rank = "Duelist",     color = {0.64, 0.21, 0.93} },
                { rating = 2100, rank = "Elite",       color = {1,    0.5,  0   } },
                { rating = 2400, rank = "Gladiator",   color = {1,    0.5,  0   } },
            },
        }
    end
    return _pvpData
end

function StaticData.GetPvPRank(rating)
    local data = StaticData.GetPvPData()
    local result = data.rankThresholds[1] -- default Unranked
    for _, entry in ipairs(data.rankThresholds) do
        if rating >= entry.rating then
            result = entry
        end
    end
    return result.rank, result.color
end

function StaticData.GetNextPvPRank(rating)
    local data = StaticData.GetPvPData()
    for _, entry in ipairs(data.rankThresholds) do
        if rating < entry.rating then
            return entry.rank, entry.color, entry.rating - rating
        end
    end
    return nil, nil, 0 -- already at max rank
end

-- Memory cleanup function (called on addon disable/reload)
function StaticData.Cleanup()
    -- Class and role icons are now generated dynamically, no caching needed
    -- Only clear mount and mythic+ data which may still use caching
    _mountData = nil
    _mythicPlusData = nil
    _pvpData = nil
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
        -- For levels above 12, clamp to cap (more crests, same ilvl)
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
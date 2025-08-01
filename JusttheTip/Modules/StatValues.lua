local addonName, JTT = ...

JTT.StatValues = JTT.StatValues or {}
local StatValues = JTT.StatValues
local L = JTT.L


JustTheTipStatValuesMixin = {}

-- Conversion factors from Pawn/SimulationCraft data (updated for TWW)
-- Based on https://github.com/VgerMods/Pawn and latest SimC data
local CONVERSION_FACTORS = {
    -- Haste conversion factors by level
    haste = {
        2.948095354, 2.948095354, 2.948095354, 2.948095354, 2.948095354, -- 5
        2.948095354, 2.948095354, 2.948095354, 2.948095354, 2.948095354, -- 10
        2.948095354, 3.095500122, 3.242904889, 3.390309657, 3.537714425, -- 15
        3.685119192, 3.83252396, 3.979928728, 4.127333496, 4.274738263, -- 20
        4.453978039, 4.649329515, 4.862222314, 5.094247563, 5.347176954, -- 25
        5.622984341, 5.923870234, 6.252289599, 6.610983454, 7.003014772, -- 30
        7.431809367, 7.901202447, 8.415491714, 8.979497968, 9.598634353, -- 35
        10.27898556, 11.02739849, 11.85158626, 12.76024738, 13.76320282, -- 40
        14.87155354, 16.09786185, 17.45636041, 18.96319344, 20.63669526, -- 45
        22.49771244, 24.56997673, 26.88053735, 29.46026251, 32.34442221, -- 50
        35.57336588, 39.1933116, 43.25726608, 47.82609852, 52.96979542, -- 55
        58.76892862, 65.31637495, 72.71933289, 81.10169039, 90.60680851, -- 60
        95.70270333, 101.0852007, 106.7704197, 112.775386, 119.1180827, -- 65
        125.8175044, 132.893714, 140.3679028, 148.2624537, 174.7114226, -- 70
        195.1745499, 218.0344269, 243.5717739, 272.1001901, 303.9700056, -- 75
        339.5725827, 379.3451222, 423.7760322, 473.4109257, 706 -- 80 (updated)
    },
    -- Critical Strike conversion factors
    crit = {
        3.1267678, 3.1267678, 3.1267678, 3.1267678, 3.1267678, -- 5
        3.1267678, 3.1267678, 3.1267678, 3.1267678, 3.1267678, -- 10
        3.1267678, 3.28310619, 3.43944458, 3.59578297, 3.75212136, -- 15
        3.90845975, 4.06479814, 4.221136529, 4.377474919, 4.533813309, -- 20
        4.723916102, 4.931107062, 5.156902454, 5.402989839, 5.671248285, -- 25
        5.963771271, 6.282892672, 6.631216242, 7.011649117, 7.42743991, -- 30
        7.882222056, 8.380063201, 8.925521515, 9.523709967, 10.18036977, -- 35
        10.90195438, 11.69572568, 12.56986421, 13.5335957, 14.59733632, -- 40
        15.77285982, 17.07348984, 18.51432165, 20.11247789, 21.88740407, -- 45
        23.86121016, 26.05906623, 28.50966082, 31.24573297, 34.30469023, -- 50
        37.72932745, 41.56866382, 45.87891857, 50.72464994, 56.18008605, -- 55
        62.33068187, 69.27494313, 77.12656519, 86.01694436, 96.09813024, -- 60
        101.5028672, 107.2115765, 113.2413543, 119.6102579, 126.3373604, -- 65
        133.4428077, 140.9478785, 148.8750484, 157.248057, 185.2999937, -- 70
        207.0033105, 231.2486346, 258.3336995, 288.5911108, 322.3924302, -- 75
        360.1527393, 402.3357357, 449.4594281, 502.102497, 749 -- 80 (updated)
    },
    -- Mastery conversion factors (same as crit)
    mastery = {
        3.1267678, 3.1267678, 3.1267678, 3.1267678, 3.1267678, -- 5
        3.1267678, 3.1267678, 3.1267678, 3.1267678, 3.1267678, -- 10
        3.1267678, 3.28310619, 3.43944458, 3.59578297, 3.75212136, -- 15
        3.90845975, 4.06479814, 4.221136529, 4.377474919, 4.533813309, -- 20
        4.723916102, 4.931107062, 5.156902454, 5.402989839, 5.671248285, -- 25
        5.963771271, 6.282892672, 6.631216242, 7.011649117, 7.42743991, -- 30
        7.882222056, 8.380063201, 8.925521515, 9.523709967, 10.18036977, -- 35
        10.90195438, 11.69572568, 12.56986421, 13.5335957, 14.59733632, -- 40
        15.77285982, 17.07348984, 18.51432165, 20.11247789, 21.88740407, -- 45
        23.86121016, 26.05906623, 28.50966082, 31.24573297, 34.30469023, -- 50
        37.72932745, 41.56866382, 45.87891857, 50.72464994, 56.18008605, -- 55
        62.33068187, 69.27494313, 77.12656519, 86.01694436, 96.09813024, -- 60
        101.5028672, 107.2115765, 113.2413543, 119.6102579, 126.3373604, -- 65
        133.4428077, 140.9478785, 148.8750484, 157.248057, 185.2999937, -- 70
        207.0033105, 231.2486346, 258.3336995, 288.5911108, 322.3924302, -- 75
        360.1527393, 402.3357357, 449.4594281, 502.102497, 749 -- 80 (updated)
    },
    -- Versatility conversion factors
    versatility = {
        3.484112691, 3.484112691, 3.484112691, 3.484112691, 3.484112691, -- 5
        3.484112691, 3.484112691, 3.484112691, 3.484112691, 3.484112691, -- 10
        3.484112691, 3.658318326, 3.83252396, 4.006729595, 4.180935229, -- 15
        4.355140864, 4.529346498, 4.703552133, 4.877757767, 5.051963402, -- 20
        5.263792227, 5.494662155, 5.746262735, 6.020474392, 6.319390946, -- 25
        6.645345131, 7.000937549, 7.389069526, 7.812980445, 8.276290186, -- 30
        8.783047434, 9.33778471, 9.945581116, 10.61213396, 11.3438406, -- 35
        12.14789202, 13.03238004, 14.00642012, 15.08029235, 16.26560333, -- 40
        17.57547237, 19.02474582, 20.63024412, 22.41104679, 24.38882167, -- 45
        26.58820561, 29.03724523, 31.76790777, 34.81667388, 38.22522625, -- 50
        42.04125059, 46.31936825, 51.12222354, 56.5217528, 62.60066731, -- 55
        69.45418837, 77.19207949, 85.94102978, 95.84745228, 107.0807737, -- 60
        113.1031948, 119.4643281, 126.1832233, 133.2800016, 140.7759159, -- 65
        148.6934143, 157.0562075, 165.8893396, 175.2192635, 206.4771359, -- 70
        230.6608317, 257.67705, 287.8575509, 321.572952, 359.2372794, -- 75
        401.3130523, 448.3169626, 500.8262199, 559.4856395, 835 -- 80 (updated)
    },
    -- Leech conversion factors
    leech = {
        4.556125589, 4.556125589, 4.556125589, 4.556125589, 4.556125589, -- 5
        4.556125589, 4.556125589, 4.556125589, 4.556125589, 4.556125589, -- 10
        4.556125589, 4.783931869, 5.011738148, 5.239544428, 5.467350707, -- 15
        5.695156987, 5.922963266, 6.150769545, 6.378575825, 6.606382104, -- 20
        6.883387706, 7.185293091, 7.514307661, 7.872890423, 8.263779433, -- 25
        8.690025176, 9.155028423, 9.662583199, 10.2169256, 10.82278928, -- 30
        11.48546867, 12.21089087, 13.00569776, 13.87733962, 14.83418219, -- 35
        15.88562903, 17.04226168, 18.31600031, 19.72028806, 21.2703027, -- 40
        22.98320017, 24.87839486, 26.9778826, 29.30661343, 31.89292206, -- 45
        34.76902578, 37.97160074, 41.54245007, 45.52927901, 49.98659542, -- 50
        54.97675724, 60.57119206, 66.85181896, 73.91270808, 81.86201984, -- 55
        90.82427377, 100.9430061, 112.3838864, 125.338377, 140.0280348, -- 60
        147.903471, 156.2218363, 165.0080418, 174.2883999, 184.0907025, -- 65
        194.4443047, 205.3802128, 216.9311765, 229.1317879, 270.0072718, -- 70
        301.6319536, 336.9606856, 376.4273059, 420.5164658, 469.7695816, -- 75
        524.7914833, 586.2578415, 654.9234651, 731.6315702, 1091 -- 80 (updated)
    },
    -- Avoidance conversion factors
    avoidance = {
        2.429933648, 2.429933648, 2.429933648, 2.429933648, 2.429933648, -- 5
        2.429933648, 2.429933648, 2.429933648, 2.429933648, 2.429933648, -- 10
        2.429933648, 2.55143033, 2.672927012, 2.794423695, 2.915920377, -- 15
        3.03741706, 3.158913742, 3.280410424, 3.401907107, 3.523403789, -- 20
        3.67114011, 3.832156315, 4.007630753, 4.198874892, 4.407349031, -- 25
        4.634680094, 4.882681826, 5.153377706, 5.449026985, 5.772154285, -- 30
        6.125583292, 6.512475133, 6.936372139, 7.4012478, 7.911563836, -- 35
        8.47233548, 9.089206227, 9.7685335, 10.51748696, 11.34416144, -- 40
        12.25770676, 13.26847726, 14.38820405, 15.63019383, 17.00955843, -- 45
        18.54348041, 20.25152039, 22.15597337, 24.28228214, 26.65951756, -- 50
        29.3209372, 32.30463577, 35.65430345, 39.42011098, 43.65974391, -- 55
        48.43961268, 53.83626993, 59.93807276, 66.84713441, 74.68161856, -- 60
        78.88185118, 83.31831267, 88.00428898, 92.95381328, 98.18170799, -- 65
        103.7036292, 109.5361135, 115.6966275, 122.2036202, 144.0038783, -- 70
        160.8703752, 179.7123657, 200.7612298, 224.2754484, 250.5437769, -- 75
        279.8887911, 312.6708488, 349.2925147, 390.2035041, 582 -- 80 (updated)
    },
    -- Speed conversion factors
    speed = {
        0.759354265, 0.759354265, 0.759354265, 0.759354265, 0.759354265, -- 5
        0.759354265, 0.759354265, 0.759354265, 0.759354265, 0.759354265, -- 10
        0.759354265, 0.797321978, 0.835289691, 0.873257405, 0.911225118, -- 15
        0.949192831, 0.987160544, 1.025128258, 1.063095971, 1.101063684, -- 20
        1.147231284, 1.197548848, 1.25238461, 1.312148404, 1.377296572, -- 25
        1.448337529, 1.52583807, 1.610430533, 1.702820933, 1.803798214, -- 30
        1.914244779, 2.035148479, 2.167616293, 2.312889937, 2.472363699, -- 35
        2.647604838, 2.840376946, 3.052666719, 3.286714676, 3.54505045, -- 40
        3.830533362, 4.146399143, 4.496313767, 4.884435572, 5.315487011, -- 45
        5.794837629, 6.328600123, 6.923741679, 7.588213168, 8.331099237, -- 50
        9.162792874, 10.09519868, 11.14196983, 12.31878468, 13.64366997, -- 55
        15.13737896, 16.82383435, 18.73064774, 20.8897295, 23.3380058, -- 60
        24.65057849, 26.03697271, 27.50134031, 29.04806665, 30.68178375, -- 65
        32.40738412, 34.23003546, 36.15519609, 38.18863132, 45.00121196, -- 70
        50.27199227, 56.16011427, 62.73788432, 70.08607764, 78.29493027, -- 75
        87.46524721, 97.70964024, 109.1539108, 121.938595, 182 -- 80 (updated)
    }
}

-- Diminishing returns brackets for secondary stats
local SECONDARY_BRACKETS = {
    {size = 30, penalty = 0},    -- 0-30%: no penalty
    {size = 10, penalty = 0.1},  -- 30-39%: 10% penalty  
    {size = 10, penalty = 0.2},  -- 39-47%: 20% penalty
    {size = 10, penalty = 0.3},  -- 47-54%: 30% penalty
    {size = 20, penalty = 0.4},  -- 54-66%: 40% penalty
    {size = 120, penalty = 0.5}, -- 66-126%: 50% penalty
    {size = 100000, penalty = 1.0} -- 126%+: 100% penalty (cap)
}

-- Diminishing returns brackets for tertiary stats (leech, avoidance, speed)
local TERTIARY_BRACKETS = {
    {size = 10, penalty = 0},    -- 0-10%: no penalty
    {size = 5, penalty = 0.2},   -- 10-14%: 20% penalty
    {size = 5, penalty = 0.4},   -- 14-17%: 40% penalty
    {size = 80, penalty = 0.6},  -- 17-49%: 60% penalty
    {size = 100000, penalty = 1.0} -- 49%+: 100% penalty (cap)
}

-- Stat ID mapping
local STAT_MAP = {
    [CR_CRIT_SPELL] = {
        name = "Critical Strike",
        conversion = "crit",
        pattern = "%s([,0-9]+) " .. STAT_CRITICAL_STRIKE,
        brackets = "secondary"
    },
    [CR_HASTE_SPELL] = {
        name = "Haste", 
        conversion = "haste",
        pattern = "%s([,0-9]+) " .. STAT_HASTE,
        brackets = "secondary"
    },
    [CR_VERSATILITY_DAMAGE_DONE] = {
        name = "Versatility",
        conversion = "versatility", 
        pattern = "%s([,0-9]+) " .. STAT_VERSATILITY,
        brackets = "secondary"
    },
    [CR_MASTERY] = {
        name = "Mastery",
        conversion = "mastery",
        pattern = "%s([,0-9]+) " .. STAT_MASTERY,
        brackets = "secondary"
    },
    [CR_LIFESTEAL] = {
        name = "Leech",
        conversion = "leech",
        pattern = "%s([,0-9]+) " .. STAT_LIFESTEAL,
        brackets = "tertiary"
    },
    [CR_AVOIDANCE] = {
        name = "Avoidance",
        conversion = "avoidance",
        pattern = "%s([,0-9]+) " .. STAT_AVOIDANCE,
        brackets = "tertiary"
    },
    [CR_SPEED] = {
        name = "Speed",
        conversion = "speed",
        pattern = "%s([,0-9]+) " .. STAT_SPEED,
        brackets = "tertiary"
    }
}

function JustTheTipStatValuesMixin:GetConversionFactor(statType)
    local level = UnitLevel("player")
    level = math.max(math.min(level, 80), 1) -- Clamp between 1-80
    
    local factors = CONVERSION_FACTORS[statType]
    if factors then
        return factors[level] or factors[80] -- Default to max level if not found
    end
    return 1
end

function JustTheTipStatValuesMixin:CalculateDiminishedValue(rating, conversionFactor, bracketType)
    local brackets = bracketType == "tertiary" and TERTIARY_BRACKETS or SECONDARY_BRACKETS
    local percent = rating / conversionFactor
    local trueRating = 0
    local currentPenalty = 0
    
    for i, bracket in ipairs(brackets) do
        if percent <= bracket.size then
            -- We're in this bracket
            trueRating = trueRating + (percent * conversionFactor * (1.0 - bracket.penalty))
            currentPenalty = bracket.penalty
            break
        else
            -- Add this full bracket and continue
            trueRating = trueRating + (bracket.size * conversionFactor * (1.0 - bracket.penalty))
            percent = percent - bracket.size
            currentPenalty = bracket.penalty
        end
    end
    
    return math.floor(trueRating * 100 + 0.5) / 100, currentPenalty
end

function JustTheTipStatValuesMixin:GetStatInfo(statID)
    local statInfo = STAT_MAP[statID]
    if not statInfo then return nil end
    
    local currentRating = GetCombatRating(statID)
    local conversionFactor = self:GetConversionFactor(statInfo.conversion)
    local trueRating, penalty = self:CalculateDiminishedValue(currentRating, conversionFactor, statInfo.brackets)
    
    return {
        name = statInfo.name,
        currentRating = currentRating,
        trueRating = trueRating,
        penalty = penalty,
        conversionFactor = conversionFactor,
        brackets = statInfo.brackets
    }
end

function JustTheTipStatValuesMixin:ProcessStatTooltip(tooltip)
    if not tooltip then return end
    
    -- Store current scale to reapply after processing
    local currentScale = tooltip:GetScale()
    
    -- Get the first line of the tooltip to identify the stat
    local line1 = _G[tooltip:GetName() .. "TextLeft1"]
    if not line1 then return end
    
    local text = line1:GetText()
    if not text then return end
    
    -- Check each stat type
    for statID, statInfo in pairs(STAT_MAP) do
        local ratingMatch = text:match(statInfo.pattern)
        if ratingMatch then
            local rating = tonumber(ratingMatch:gsub(",", ""))
            if rating then
                local conversionFactor = self:GetConversionFactor(statInfo.conversion)
                local trueRating, penalty = self:CalculateDiminishedValue(rating, conversionFactor, statInfo.brackets)
                
                -- Add separator line
                tooltip:AddLine(" ", 1, 1, 1)
                
                -- Add true stat value information (Pawn-style)
                local penaltyText = ""
                if penalty > 0 then
                    penaltyText = string.format(" |cffff6666(-%.0f%% DR)|r", penalty * 100)
                end
                
                local trueValueText = string.format("|cff00ff96True Value: %.1f|r%s", trueRating, penaltyText)
                tooltip:AddLine(trueValueText, 1, 1, 1)
                
                -- Add percentage information with better formatting
                local percent = (rating / conversionFactor)
                local truePercent = (trueRating / conversionFactor)
                
                if statID == CR_VERSATILITY_DAMAGE_DONE then
                    -- Versatility shows damage/healing bonus
                    tooltip:AddLine(string.format("|cff68ccff%.2f%% Damage/Healing|r", truePercent), 0.8, 0.8, 1)
                    tooltip:AddLine(string.format("|cff68ccff%.2f%% Damage Reduction|r", truePercent / 2), 0.8, 0.8, 1)
                elseif statID == CR_LIFESTEAL then
                    tooltip:AddLine(string.format("|cff68ccff%.2f%% Leech|r", truePercent), 0.8, 0.8, 1)
                elseif statID == CR_AVOIDANCE then
                    tooltip:AddLine(string.format("|cff68ccff%.2f%% Avoidance|r", truePercent), 0.8, 0.8, 1)
                elseif statID == CR_SPEED then
                    tooltip:AddLine(string.format("|cff68ccff%.2f%% Speed|r", truePercent), 0.8, 0.8, 1)
                else
                    tooltip:AddLine(string.format("|cff68ccff%.2f%% Effective|r", truePercent), 0.8, 0.8, 1)
                end
                
                -- Add next breakpoint information (Pawn-inspired)
                local nextBreakpoint = self:GetNextBreakpoint(rating, conversionFactor, statInfo.brackets)
                if nextBreakpoint then
                    local ratingNeeded = nextBreakpoint - rating
                    if ratingNeeded > 0 and ratingNeeded < 1000 then -- Only show if reasonable
                        tooltip:AddLine(string.format("|cffffcc00+%d rating to next breakpoint|r", math.ceil(ratingNeeded)), 0.7, 0.7, 0.7)
                    end
                end
                
                -- Maintain the tooltip scale after adding lines
                local targetScale = (JustTheTipDB and JustTheTipDB.scale) or currentScale or 1.0
                if targetScale ~= tooltip:GetScale() then
                    tooltip:SetScale(targetScale)
                end
                
                break
            end
        end
    end
end

function JustTheTipStatValuesMixin:GetNextBreakpoint(currentRating, conversionFactor, bracketType)
    local brackets = bracketType == "tertiary" and TERTIARY_BRACKETS or SECONDARY_BRACKETS
    local percent = currentRating / conversionFactor
    local totalPercent = 0
    
    for i, bracket in ipairs(brackets) do
        totalPercent = totalPercent + bracket.size
        if percent < totalPercent then
            -- This is the next breakpoint
            return totalPercent * conversionFactor
        end
    end
    
    return nil -- No more breakpoints
end


function StatValues.ValidateCurrentData()
    -- Test current player's stats against our conversion factors
    local level = UnitLevel("player")
    local results = {}
    
    for statID, statInfo in pairs(STAT_MAP) do
        local currentRating = GetCombatRating(statID)
        if currentRating > 0 then
            local ourFactor = CONVERSION_FACTORS[statInfo.conversion][level]
            local gamePercent = 0
            
            -- Get actual game percentage for comparison
            if statID == CR_HASTE_SPELL then
                gamePercent = GetHaste()
            elseif statID == CR_CRIT_SPELL then
                gamePercent = GetCritChance()
            elseif statID == CR_VERSATILITY_DAMAGE_DONE then
                gamePercent = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
            elseif statID == CR_MASTERY then
                gamePercent = GetMastery()
            end
            
            if gamePercent > 0 then
                local calculatedFactor = currentRating / (gamePercent / 100)
                local difference = math.abs(ourFactor - calculatedFactor)
                
                results[statInfo.name] = {
                    ourFactor = ourFactor,
                    calculatedFactor = calculatedFactor,
                    difference = difference,
                    accurate = difference < (ourFactor * 0.05) -- Within 5%
                }
            end
        end
    end
    
    return results
end

-- Pawn-style item stat value calculation
function JustTheTipStatValuesMixin:CalculateItemValue(itemLink)
    if not itemLink then return 0 end
    
    local stats = C_Item.GetItemStats(itemLink)
    if not stats then return 0 end
    
    local totalValue = 0
    local level = UnitLevel("player")
    
    -- Basic stat weights (can be customized per spec)
    local statWeights = self:GetStatWeights()
    
    for statName, amount in pairs(stats) do
        local weight = statWeights[statName] or 0
        if weight > 0 then
            -- Apply diminishing returns if it's a secondary stat
            local trueValue = amount
            if statName:find("CRIT") or statName:find("HASTE") or statName:find("MASTERY") or statName:find("VERSATILITY") then
                local conversionFactor = self:GetConversionFactorByStat(statName)
                if conversionFactor then
                    local currentRating = self:GetCurrentStatRating(statName)
                    local newTotal = currentRating + amount
                    local currentTrue = self:CalculateDiminishedValue(currentRating, conversionFactor, "secondary")
                    local newTrue = self:CalculateDiminishedValue(newTotal, conversionFactor, "secondary")
                    trueValue = newTrue - currentTrue
                end
            end
            totalValue = totalValue + (trueValue * weight)
        end
    end
    
    return totalValue
end

function JustTheTipStatValuesMixin:GetStatWeights()
    -- Basic stat weights - could be expanded to be spec-specific
    -- These are rough estimates and should be customized per spec
    return {
        ITEM_MOD_CRIT_RATING_SHORT = 1.0,
        ITEM_MOD_HASTE_RATING_SHORT = 1.1,
        ITEM_MOD_MASTERY_RATING_SHORT = 0.9,
        ITEM_MOD_VERSATILITY = 0.8,
        ITEM_MOD_STAMINA_SHORT = 0.1,
        ITEM_MOD_STRENGTH_SHORT = 1.5,
        ITEM_MOD_AGILITY_SHORT = 1.5,
        ITEM_MOD_INTELLECT_SHORT = 1.5,
        ITEM_MOD_SPIRIT_SHORT = 0.0, -- Deprecated
    }
end

function JustTheTipStatValuesMixin:GetConversionFactorByStat(statName)
    if statName:find("CRIT") then
        return self:GetConversionFactor("crit")
    elseif statName:find("HASTE") then
        return self:GetConversionFactor("haste")
    elseif statName:find("MASTERY") then
        return self:GetConversionFactor("mastery")
    elseif statName:find("VERSATILITY") then
        return self:GetConversionFactor("versatility")
    end
    return nil
end

function JustTheTipStatValuesMixin:GetCurrentStatRating(statName)
    if statName:find("CRIT") then
        return GetCombatRating(CR_CRIT_SPELL)
    elseif statName:find("HASTE") then
        return GetCombatRating(CR_HASTE_SPELL)
    elseif statName:find("MASTERY") then
        return GetCombatRating(CR_MASTERY)
    elseif statName:find("VERSATILITY") then
        return GetCombatRating(CR_VERSATILITY_DAMAGE_DONE)
    end
    return 0
end

-- Debug command for testing
function StatValues.DebugStatValues()
    if not JTT or not JTT.Print then return end
    
    local results = StatValues.ValidateCurrentData()
    JTT:Print("=== Stat Values Validation (Pawn-Enhanced) ===")
    
    for statName, data in pairs(results) do
        local status = data.accurate and "|cff00ff00✓|r" or "|cffff0000✗|r"
        JTT:Print(string.format("%s %s: Our=%.2f Game=%.2f Diff=%.2f", 
            status, statName, data.ourFactor, data.calculatedFactor, data.difference))
    end
    
    -- Test item value calculation
    local mainHandLink = GetInventoryItemLink("player", 16)
    if mainHandLink then
        local processor = {}
        Mixin(processor, JustTheTipStatValuesMixin)
        local value = processor:CalculateItemValue(mainHandLink)
        JTT:Print(string.format("Main hand item value: %.1f", value))
    end
end

-- Module functions
function StatValues.SetupStatTooltipProcessor()
    local statProcessor = {}
    Mixin(statProcessor, JustTheTipStatValuesMixin)
    
    local function OnTooltipShow(tooltip)
        if not JustTheTipDB or not JustTheTipDB.enabled or not JustTheTipDB.showStatValues then return end
        if tooltip ~= GameTooltip then return end
        
        statProcessor:ProcessStatTooltip(tooltip)
    end
    
    GameTooltip:HookScript("OnShow", OnTooltipShow)
    
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip)
            if not JustTheTipDB or not JustTheTipDB.enabled or not JustTheTipDB.showStatValues then return end
            if tooltip ~= GameTooltip then return end
            
            statProcessor:ProcessStatTooltip(tooltip)
        end)
        
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
            if not JustTheTipDB or not JustTheTipDB.enabled or not JustTheTipDB.showStatValues then return end
            if tooltip ~= GameTooltip then return end
            
            statProcessor:ProcessStatTooltip(tooltip)
        end)
    end
end
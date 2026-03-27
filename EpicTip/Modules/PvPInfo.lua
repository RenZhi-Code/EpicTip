local addonName, ET = ...

ET.PvPInfo = ET.PvPInfo or {}
local PvPInfo = ET.PvPInfo
local L = ET.L or {}

-- Modern PvP rating system is Retail-only
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
    -- Create empty stubs for Classic
    PvPInfo.GetPvPRating = function() return nil end
    PvPInfo.AddToTooltip = function() end
    PvPInfo.Initialize = function() return true end
    if EpicTipDB and EpicTipDB.debugMode then
        print("EpicTip: PvPInfo disabled (Classic/Era uses different PvP system)")
    end
    return
end

-- Bracket names for display (fallback if StaticData unavailable)
local BRACKET_NAMES = {
    [1] = "2v2",
    [2] = "3v3",
    [4] = "RBG",
}

local function GetBracketName(bracket)
    if ET.StaticData then
        local data = ET.StaticData.GetPvPData()
        if data and data.brackets and data.brackets[bracket] then
            return data.brackets[bracket]
        end
    end
    return BRACKET_NAMES[bracket] or ("Bracket " .. bracket)
end

-- Cache inspected player's PvP data (keyed by GUID)
local inspectCache = {}
local inspectCacheGUID = nil  -- Currently cached GUID

-- Get the player's own PvP ratings using C_PvP API
function PvPInfo.GetSelfPvPRatings()
    local ratings = {}
    local highest = 0

    local success = pcall(function()
        -- Try modern C_PvP API first (Retail 10.0+)
        if C_PvP and C_PvP.GetPersonalRatedInfo then
            for _, bracket in ipairs({1, 2, 4}) do -- 2v2, 3v3, RBG
                local info = C_PvP.GetPersonalRatedInfo(bracket)
                if info and info.rating and info.rating > 0 then
                    ratings[bracket] = {
                        rating = info.rating,
                        seasonPlayed = info.seasonPlayed or 0,
                        seasonWon = info.seasonWon or 0,
                    }
                    if info.rating > highest then
                        highest = info.rating
                    end
                end
            end
        end

        -- Fallback to legacy API
        if highest == 0 and GetPersonalRatedInfo then
            for _, bracket in ipairs({1, 2, 4}) do
                local rating, seasonPlayed, seasonWon = GetPersonalRatedInfo(bracket)
                if rating and rating > 0 then
                    ratings[bracket] = {
                        rating = rating,
                        seasonPlayed = seasonPlayed or 0,
                        seasonWon = seasonWon or 0,
                    }
                    if rating > highest then
                        highest = rating
                    end
                end
            end
        end
    end)

    if not success then return nil, 0 end
    return (highest > 0) and ratings or nil, highest
end

-- Get inspected player's PvP ratings using GetInspectArenaData
-- Requires: NotifyInspect() + RequestInspectHonorData() called first,
-- then INSPECT_HONOR_UPDATE event fires before this data is available.
function PvPInfo.GetInspectPvPRatings()
    -- HasInspectHonorData tells us if the server has sent the data yet
    if not HasInspectHonorData or not HasInspectHonorData() then
        return nil, 0
    end

    if not GetInspectArenaData then
        return nil, 0
    end

    local ratings = {}
    local highest = 0

    local success = pcall(function()
        -- GetInspectArenaData(bracketId): rating, seasonPlayed, seasonWon, weeklyPlayed, weeklyWon
        for _, bracket in ipairs({1, 2, 4}) do
            local rating, seasonPlayed, seasonWon = GetInspectArenaData(bracket)
            if rating and rating > 0 then
                ratings[bracket] = {
                    rating = rating,
                    seasonPlayed = seasonPlayed or 0,
                    seasonWon = seasonWon or 0,
                }
                if rating > highest then
                    highest = rating
                end
            end
        end
    end)

    if not success then return nil, 0 end
    return (highest > 0) and ratings or nil, highest
end

-- Main function: get PvP ratings for any unit
function PvPInfo.GetPvPRating(unit)
    if not unit then return nil, 0 end

    -- For the player, use C_PvP API directly (always available)
    if UnitIsUnit(unit, "player") then
        return PvPInfo.GetSelfPvPRatings()
    end

    -- For other players, check if we have cached inspect data
    local guid = UnitGUID(unit)
    if guid and inspectCacheGUID == guid and inspectCache.ratings then
        return inspectCache.ratings, inspectCache.highest or 0
    end

    -- Try to read inspect data if available (INSPECT_HONOR_UPDATE may have fired)
    if HasInspectHonorData and HasInspectHonorData() then
        local ratings, highest = PvPInfo.GetInspectPvPRatings()
        if ratings and guid then
            -- Cache it
            inspectCache.ratings = ratings
            inspectCache.highest = highest
            inspectCacheGUID = guid
        end
        return ratings, highest
    end

    return nil, 0
end

-- Called when INSPECT_HONOR_UPDATE fires - cache the data
function PvPInfo.OnInspectHonorUpdate()
    -- The inspect data is now ready - cache it for the currently inspected unit
    if not ET.Tooltip or not ET.Tooltip.inspectedGUID then return end

    local ratings, highest = PvPInfo.GetInspectPvPRatings()
    if ratings then
        inspectCacheGUID = ET.Tooltip.inspectedGUID
        inspectCache.ratings = ratings
        inspectCache.highest = highest

        if EpicTipDB and EpicTipDB.debugMode then
            print("EpicTip: PvP inspect data cached, highest rating:", highest)
        end
    end
end

-- Clear cache when inspecting a new target
function PvPInfo.ClearCache()
    inspectCache = {}
    inspectCacheGUID = nil
end


function PvPInfo.AddToTooltip(tooltip, unit)
    if not EpicTipDB or not EpicTipDB.showPvPRating then return end
    if not tooltip or not unit then return end

    local success, result = pcall(function()
        local ratings, highest = PvPInfo.GetPvPRating(unit)
        if not ratings or highest == 0 then return end

        tooltip:AddLine(L["PvP Rating:"] or "PvP Rating:", 0.5, 1, 0.5)

        local highestRank, highestColor, highestNext, highestNeeded = nil, nil, nil, nil

        for _, bracket in ipairs({1, 2, 4}) do
            local data = ratings[bracket]
            if data and data.rating > 0 then
                local bracketName = GetBracketName(bracket)

                -- Rank name and colour from StaticData
                local rank, col = bracketName, {1, 1, 1}
                if ET.StaticData then
                    local rName, rCol = ET.StaticData.GetPvPRank(data.rating)
                    if rName then rank = rName ; col = rCol end
                end

                local r, g, b = col[1], col[2], col[3]
                local ratingStr = string.format("%d |cff%02x%02x%02x(%s)|r",
                    data.rating, r*255, g*255, b*255, rank)

                -- Win rate if available
                local winStr = ""
                if data.seasonPlayed and data.seasonPlayed > 0 then
                    local winPct = math.floor((data.seasonWon / data.seasonPlayed) * 100 + 0.5)
                    winStr = string.format(" |cffaaaaaa%dW/%dL (%d%%)|r",
                        data.seasonWon,
                        data.seasonPlayed - data.seasonWon,
                        winPct)
                end

                tooltip:AddDoubleLine(
                    "  " .. bracketName .. ":",
                    ratingStr .. winStr,
                    0.8, 0.8, 0.8,
                    1, 1, 1
                )

                -- Track overall highest for next milestone
                if data.rating == highest then
                    highestRank = rank
                    highestColor = col
                    if ET.StaticData then
                        local nRank, nCol, needed = ET.StaticData.GetNextPvPRank(data.rating)
                        highestNext = nRank
                        highestNeeded = needed
                        highestColor = nCol
                    end
                end
            end
        end

        -- Next rank milestone based on highest bracket
        if highestNext and highestNeeded and highestNeeded > 0 then
            local c = highestColor or {1, 1, 1}
            tooltip:AddDoubleLine(
                string.format("|cffaaaaaaaNext rank (%d pts):|r", highestNeeded),
                highestNext,
                1, 1, 1,
                c[1], c[2], c[3]
            )
        end
    end)

    if not success and EpicTipDB and EpicTipDB.debugMode then
        print("EpicTip: PvP AddToTooltip error:", result)
    end
end

function PvPInfo.Initialize()
    return true
end

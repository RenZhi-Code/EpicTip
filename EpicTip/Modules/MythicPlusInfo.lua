local addonName, ET = ...

ET.MythicPlusInfo = ET.MythicPlusInfo or {}
local MythicPlusInfo = ET.MythicPlusInfo
local L = ET.L or {}

-- Mythic+ is Retail-only (doesn't exist in Classic/Era)
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
    -- Create empty stubs for Classic
    MythicPlusInfo.GetMythicPlusRating = function() return nil end
    MythicPlusInfo.GetMythicPlusInfo = function() return nil end
    if EpicTipDB and EpicTipDB.debugMode then
        print("EpicTip: MythicPlusInfo disabled (Classic/Era detected)")
    end
    return
end

-- Get M+ data for self — pass unit token "player" directly, not a GUID
local function GetSelfMythicData()
    local ok, summary = pcall(C_PlayerInfo.GetPlayerMythicPlusRatingSummary, "player")
    if not ok or not summary or not summary.currentSeasonScore then
        if EpicTipDB and EpicTipDB.debugMode then
            print("EpicTip M+ (self): summary nil or no score")
        end
        return nil
    end

    local result = {}

    if summary.currentSeasonScore > 0 then
        result.score = summary.currentSeasonScore
        if C_ChallengeMode and C_ChallengeMode.GetDungeonScoreRarityColor then
            local cok, col = pcall(C_ChallengeMode.GetDungeonScoreRarityColor, summary.currentSeasonScore)
            if cok and col and col.GetRGB then result.scoreColor = col end
        end
    end

    if summary.runs then
        local highest, total, completed = 0, 0, 0
        for _, run in ipairs(summary.runs) do
            if run.bestRunLevel and run.bestRunLevel > 0 then
                total = total + 1
                if run.finishedSuccess then
                    completed = completed + 1
                    if run.bestRunLevel > highest then highest = run.bestRunLevel end
                end
            end
        end
        if highest > 0 then result.highestKey = highest end
        result.totalRuns = total
        result.completedRuns = completed
    end

    if EpicTipDB and EpicTipDB.debugMode then
        print("EpicTip M+ (self): score=", tostring(result.score), "highestKey=", tostring(result.highestKey))
    end

    return (result.score or result.highestKey) and result or nil
end

function MythicPlusInfo.GetMythicPlusRating(unit)
    if not unit then return nil end

    if not C_PlayerInfo or not C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        return nil
    end

    if not UnitIsPlayer(unit) then return nil end

    -- Self: GetPlayerMythicPlusRatingSummary returns nil outside a group — use C_MythicPlus directly
    if UnitIsUnit(unit, "player") then
        return GetSelfMythicData()
    end

    local guid = UnitGUID(unit)
    if not guid then return nil end

    local success, summary = pcall(C_PlayerInfo.GetPlayerMythicPlusRatingSummary, guid)
    if not success or not summary or not summary.currentSeasonScore then
        return nil
    end

    local result = {}

    if summary.currentSeasonScore > 0 then
        result.score = summary.currentSeasonScore
        if C_ChallengeMode and C_ChallengeMode.GetDungeonScoreRarityColor then
            local cok, col = pcall(C_ChallengeMode.GetDungeonScoreRarityColor, summary.currentSeasonScore)
            if cok and col and col.GetRGB then result.scoreColor = col end
        end
    end

    if summary.runs then
        local highest, total, completed = 0, 0, 0
        for _, run in ipairs(summary.runs) do
            if run.bestRunLevel and run.bestRunLevel > 0 then
                total = total + 1
                if run.finishedSuccess then
                    completed = completed + 1
                    if run.bestRunLevel > highest then highest = run.bestRunLevel end
                end
            end
        end
        if highest > 0 then result.highestKey = highest end
        result.totalRuns = total
        result.completedRuns = completed
    end

    return (result.score or result.highestKey) and result or nil
end

function MythicPlusInfo.AddToTooltip(tooltip, unit)
    if not EpicTipDB.showMythicRating then 
        return 
    end
    
    -- Wrap in pcall to prevent errors from breaking tooltip processing
    local success, result = pcall(function()
        local mythicData = MythicPlusInfo.GetMythicPlusRating(unit)
        if not mythicData then 
            return 
        end
        
        local format = EpicTipDB.mythicRatingFormat or "both"
        local displayText = ""
        local scoreColor = mythicData.scoreColor
        
        if format == "score" and mythicData.score then
            displayText = tostring(mythicData.score)
        elseif format == "key" and mythicData.highestKey then
            displayText = "+" .. tostring(mythicData.highestKey)
        elseif format == "both" then
            local parts = {}
            if mythicData.score then
                table.insert(parts, tostring(mythicData.score))
            end
            if mythicData.highestKey then
                table.insert(parts, "|cffffff99(+" .. tostring(mythicData.highestKey) .. ")|r")
            end
            displayText = table.concat(parts, " ")
        elseif format == "detailed" then
            local parts = {}
            if mythicData.score then
                table.insert(parts, tostring(mythicData.score))
            end
            if mythicData.highestKey then
                table.insert(parts, "|cffffff99(+" .. tostring(mythicData.highestKey) .. ")|r")
            end
            displayText = table.concat(parts, " ")
        end
        
        if displayText ~= "" then
            -- Use Blizzard's score color first, fall back to StaticData thresholds
            local r, g, b = 1, 0.5, 0
            if scoreColor and scoreColor.GetRGB then
                local colorSuccess, colorR, colorG, colorB = pcall(scoreColor.GetRGB, scoreColor)
                if colorSuccess and colorR then
                    r, g, b = colorR, colorG, colorB
                end
            elseif mythicData.score and ET.StaticData then
                local col = ET.StaticData.GetMythicRatingColor(mythicData.score)
                if col then r, g, b = col[1], col[2], col[3] end
            end

            tooltip:AddDoubleLine(L["Mythic+ Rating:"] or "Mythic+ Rating:", displayText, 1, 0.5, 0, r, g, b)

            -- Show tier title on its own line if earned
            if mythicData.score and ET.StaticData then
                local title = ET.StaticData.GetMythicTitle(mythicData.score)
                if title then
                    tooltip:AddLine("|cFFFFD700" .. title .. "|r", 1, 1, 1)
                end
            end

            -- Show next rating reward milestone
            if mythicData.score and ET.StaticData then
                local data = ET.StaticData.GetMythicPlusData()
                if data and data.ratingThresholds then
                    for _, threshold in ipairs(data.ratingThresholds) do
                        if mythicData.score < threshold.rating then
                            local needed = threshold.rating - mythicData.score
                            local col = threshold.color
                            tooltip:AddDoubleLine(
                                string.format("|cffaaaaaaNext reward (%d pts):|r", needed),
                                threshold.reward,
                                1, 1, 1,
                                col[1], col[2], col[3]
                            )
                            break
                        end
                    end
                end
            end

            -- Show per-dungeon best keys if available
            if mythicData.runs and ET.StaticData then
                local data = ET.StaticData.GetMythicPlusData()
                local dungeonKeys = data and data.dungeonKeys
                tooltip:AddLine(" ")
                tooltip:AddLine("|cffaaaaaa-- Best Keys --|r", 1, 1, 1)
                for _, run in ipairs(mythicData.runs) do
                    if run.bestRunLevel and run.bestRunLevel > 0 and run.finishedSuccess then
                        -- Resolve map ID to a dungeon name via C_ChallengeMode
                        local mapName = nil
                        if run.mapChallengeModeID and C_ChallengeMode and C_ChallengeMode.GetMapInfo then
                            local ok, info = pcall(C_ChallengeMode.GetMapInfo, run.mapChallengeModeID)
                            if ok and info and info.name then mapName = info.name end
                        end
                        if mapName then
                            tooltip:AddDoubleLine(
                                mapName,
                                "+" .. run.bestRunLevel,
                                0.8, 0.8, 0.8,
                                1, 1, 0.6
                            )
                        end
                    end
                end
            end

            -- Show detailed statistics if enabled (optional toggle)
            if EpicTipDB.mythicRatingDetails and mythicData.totalRuns and mythicData.completedRuns then
                tooltip:AddLine(" ")
                local runStatsText = string.format("%d/%d runs completed", mythicData.completedRuns, mythicData.totalRuns)
                tooltip:AddLine(runStatsText, 0.8, 0.8, 0.8)
                if mythicData.totalRuns > 0 then
                    local completionRate = math.floor((mythicData.completedRuns / mythicData.totalRuns) * 100)
                    local cr, cg, cb = 0.5, 1, 0.5
                    if completionRate < 50 then cr, cg, cb = 1, 0.5, 0.5
                    elseif completionRate < 80 then cr, cg, cb = 1, 1, 0.5 end
                    tooltip:AddLine(completionRate .. "% success rate", cr, cg, cb)
                end
            end
        end
        
        -- Ensure tooltip resizes to accommodate Mythic+ content
        if tooltip.SetSize then
            tooltip:SetSize(0, 0) -- Allow natural resize
        end
    end)
    
    if not success then
        if EpicTipDB.debugMode then
            print("EpicTip: Error in MythicPlusInfo.AddToTooltip:", result)
        end
        -- Don't break tooltip processing, just skip this module
    end
end

function MythicPlusInfo.Initialize()
    return true
end
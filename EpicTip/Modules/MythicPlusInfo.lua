local addonName, ET = ...

ET.MythicPlusInfo = ET.MythicPlusInfo or {}
local MythicPlusInfo = ET.MythicPlusInfo
local L = ET.L or {}

function MythicPlusInfo.GetMythicPlusRating(unit)
    if not unit then return nil end
    
    -- Enhanced API availability check with fallback
    if not C_PlayerInfo then
        return nil -- API not available
    end
    
    -- Check for the specific function we need
    if not C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        return nil -- Function not available
    end
    
    local guid = UnitGUID(unit)
    if not guid then 
        return nil 
    end
    
    -- For other players, try to get their M+ info
    -- Don't restrict to only party/raid members - allow inspect data
    if not UnitIsUnit(unit, "player") then
        -- Check if we can inspect this unit
        if not UnitIsPlayer(unit) then
            return nil -- Only players have M+ ratings
        end
        -- Note: For players outside party/raid, data may be limited
        -- but we should still attempt to get available information
    end
    
    -- Try to get the rating summary with enhanced error handling
    local success, summary = pcall(C_PlayerInfo.GetPlayerMythicPlusRatingSummary, guid)
    if not success then
        -- Silent failure for non-critical errors
        return nil
    end
    
    if not summary or not summary.currentSeasonScore then
        -- No M+ data available for this player
        return nil
    end
    
    local result = {}
    
    -- Get current season score with validation
    if summary.currentSeasonScore and summary.currentSeasonScore > 0 then
        result.score = summary.currentSeasonScore
        
        -- Get score color using Blizzard's color system with error protection
        if C_ChallengeMode and C_ChallengeMode.GetDungeonScoreRarityColor then
            local colorSuccess, scoreColor = pcall(C_ChallengeMode.GetDungeonScoreRarityColor, summary.currentSeasonScore)
            if colorSuccess and scoreColor and scoreColor.GetRGB then
                result.scoreColor = scoreColor
            end
        end
    end
    
    -- Get highest successful key level and more detailed run information
    if summary.runs then
        local highestLevel = 0
        local totalRuns = 0
        local completedRuns = 0
        
        for _, run in ipairs(summary.runs) do
            if run.bestRunLevel and run.bestRunLevel > 0 then
                totalRuns = totalRuns + 1
                if run.finishedSuccess then
                    completedRuns = completedRuns + 1
                    if run.bestRunLevel > highestLevel then
                        highestLevel = run.bestRunLevel
                    end
                end
            end
        end
        
        if highestLevel > 0 then
            result.highestKey = highestLevel
        end
        
        -- Additional stats
        result.totalRuns = totalRuns
        result.completedRuns = completedRuns
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
            local r, g, b = 1, 0.5, 0
            if scoreColor and scoreColor.GetRGB then
                local colorSuccess, colorR, colorG, colorB = pcall(scoreColor.GetRGB, scoreColor)
                if colorSuccess and colorR then
                    r, g, b = colorR, colorG, colorB
                end
            end
            tooltip:AddDoubleLine(L["Mythic+ Rating:"] or "Mythic+ Rating:", displayText, 1, 0.5, 0, r, g, b)
            
            -- Show detailed statistics if enabled
            if EpicTipDB.mythicRatingDetails and mythicData.totalRuns and mythicData.completedRuns then
                local runStatsText = string.format("%d/%d runs completed", mythicData.completedRuns, mythicData.totalRuns)
                tooltip:AddDoubleLine("", runStatsText, 0, 0, 0, 0.8, 0.8, 0.8)
                
                -- Show completion percentage if there are runs
                if mythicData.totalRuns > 0 then
                    local completionRate = math.floor((mythicData.completedRuns / mythicData.totalRuns) * 100)
                    local percentText = completionRate .. "% success rate"
                    local percentColor = { r = 0.5, g = 1, b = 0.5 }
                    if completionRate < 50 then
                        percentColor = { r = 1, g = 0.5, b = 0.5 }
                    elseif completionRate < 80 then
                        percentColor = { r = 1, g = 1, b = 0.5 }
                    end
                    tooltip:AddDoubleLine("", percentText, 0, 0, 0, percentColor.r, percentColor.g, percentColor.b)
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
local addonName, ET = ...

ET.PvPInfo = ET.PvPInfo or {}
local PvPInfo = ET.PvPInfo
local L = ET.L or {}

function PvPInfo.GetPvPRating(unit)
    if not unit then return nil end
    
    -- Only get PvP rating for the player themselves to avoid API issues
    if not UnitIsUnit(unit, "player") then
        return nil
    end
    
    -- Wrap entire function in pcall for safety
    local success, rating = pcall(function()
        local highest = 0
        
        -- Try modern C_PvP API first
        if C_PvP and C_PvP.GetPersonalRatedInfo then
            for _, bracket in ipairs({1, 2, 4}) do -- 2v2, 3v3, RBG
                local info = C_PvP.GetPersonalRatedInfo(bracket)
                if info and info.rating and info.rating > highest then
                    highest = info.rating
                end
            end
        end
        
        -- Fallback to legacy API if modern failed
        if highest == 0 and GetPersonalRatedInfo then
            for _, bracket in ipairs({1, 2, 4}) do
                local rating = GetPersonalRatedInfo(bracket)
                if rating and rating > highest then
                    highest = rating
                end
            end
        end
        
        return highest > 0 and highest or nil
    end)
    
    if success then
        return rating
    else
        if EpicTipDB and EpicTipDB.debugMode then
            print("EpicTip: PvP rating API error:", rating)
        end
        return nil
    end
end

function PvPInfo.AddToTooltip(tooltip, unit)
    if not EpicTipDB.showPvPRating then 
        return 
    end
    
    if not tooltip or not unit then
        return
    end
    
    local success, result = pcall(function()
        local pvpRating = PvPInfo.GetPvPRating(unit)
        if pvpRating and pvpRating > 0 then
            tooltip:AddDoubleLine(L["PvP Rating:"] or "PvP Rating:", tostring(pvpRating), 0.5, 1, 0.5, 1, 1, 1)
        end
    end)
    
    if not success and EpicTipDB.debugMode then
        print("EpicTip: PvP AddToTooltip error:", result)
    end
end

function PvPInfo.Initialize()
    return true
end
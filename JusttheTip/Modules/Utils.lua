local addonName, JTT = ...

JTT.Utils = JTT.Utils or {}
local Utils = JTT.Utils

Utils.pendingInspects = {}
Utils.INSPECT_THROTTLE = 0.5

function Utils.GetSpec(unit)
    local specID = GetInspectSpecialization(unit)
    if specID and specID ~= 0 then
        local id, name = GetSpecializationInfoByID(specID)
        return name or ""
    end
    return ""
end

function Utils.GetRole(unit)
    local specID = GetInspectSpecialization(unit)
    if specID and specID ~= 0 then
        local id, name, description, icon, background, role = GetSpecializationInfoByID(specID)
        if role then
            if role == "TANK" then
                return "Tank"
            elseif role == "HEALER" then
                return "Healer"
            elseif role == "DAMAGER" then
                return "DPS"
            end
        end
    end
    return ""
end

function Utils.GetMythicPlusRating(unit)
    if not C_PlayerInfo or not C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        return nil
    end
    
    local guid = UnitGUID(unit)
    if not guid then return nil end
    
    local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(guid)
    if summary and summary.currentSeasonScore then
        return summary.currentSeasonScore
    end
    return nil
end

function Utils.GetPvPRating(unit)
    if not C_PlayerInfo or not C_PlayerInfo.GetPlayerPvPRatingSummary then
        return nil
    end
    
    local guid = UnitGUID(unit)
    if not guid then return nil end
    
    local summary = C_PlayerInfo.GetPlayerPvPRatingSummary(guid)
    if summary and summary.rating then
        return summary.rating
    end
    return nil
end

function Utils.CanInspectThrottled(unit)
    if not JustTheTipDB.enableInspect then
        return false
    end
    
    if InCombatLockdown() then
        return false
    end
    
    if not UnitIsPlayer(unit) or not CanInspect(unit) then
        return false
    end
    
    local currentTime = GetTime()
    local guid = UnitGUID(unit)
    
    if guid and Utils.pendingInspects[guid] and currentTime - Utils.pendingInspects[guid] < Utils.INSPECT_THROTTLE then
        return false
    end
    
    return true
end

function Utils.GetClassIcon(classFileName)
    if not classFileName or classFileName == "" then return "" end
    
    local classIcons = {
        ["WARRIOR"] = "|TInterface\\Icons\\ClassIcon_Warrior:16:16:0:0:64:64:4:60:4:60|t",
        ["PALADIN"] = "|TInterface\\Icons\\ClassIcon_Paladin:16:16:0:0:64:64:4:60:4:60|t",
        ["HUNTER"] = "|TInterface\\Icons\\ClassIcon_Hunter:16:16:0:0:64:64:4:60:4:60|t",
        ["ROGUE"] = "|TInterface\\Icons\\ClassIcon_Rogue:16:16:0:0:64:64:4:60:4:60|t",
        ["PRIEST"] = "|TInterface\\Icons\\ClassIcon_Priest:16:16:0:0:64:64:4:60:4:60|t",
        ["DEATHKNIGHT"] = "|TInterface\\Icons\\ClassIcon_DeathKnight:16:16:0:0:64:64:4:60:4:60|t",
        ["SHAMAN"] = "|TInterface\\Icons\\ClassIcon_Shaman:16:16:0:0:64:64:4:60:4:60|t",
        ["MAGE"] = "|TInterface\\Icons\\ClassIcon_Mage:16:16:0:0:64:64:4:60:4:60|t",
        ["WARLOCK"] = "|TInterface\\Icons\\ClassIcon_Warlock:16:16:0:0:64:64:4:60:4:60|t",
        ["MONK"] = "|TInterface\\Icons\\ClassIcon_Monk:16:16:0:0:64:64:4:60:4:60|t",
        ["DRUID"] = "|TInterface\\Icons\\ClassIcon_Druid:16:16:0:0:64:64:4:60:4:60|t",
        ["DEMONHUNTER"] = "|TInterface\\Icons\\ClassIcon_DemonHunter:16:16:0:0:64:64:4:60:4:60|t",
        ["EVOKER"] = "|TInterface\\Icons\\ClassIcon_Evoker:16:16:0:0:64:64:4:60:4:60|t"
    }
    
    local icon = classIcons[classFileName]
    if not icon then
        return "|TInterface\\Icons\\INV_Misc_QuestionMark:16:16:0:0:64:64:4:60:4:60|t"
    end
    
    return icon
end

function Utils.GetRoleIcon(role)
    local roleIcons = {
        ["Tank"] = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t",
        ["Healer"] = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t",
        ["DPS"] = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t"
    }
    return roleIcons[role] or ""
end
local addonName, JTT = ...

JTT.Ring = JTT.Ring or {}
local Ring = JTT.Ring
local L = JTT.L or {}

Ring.textures = {
    Default = "Interface\\AddOns\\JustTheTip\\Media\\Default.png",
    Thin    = "Interface\\AddOns\\JustTheTip\\Media\\Thin.png",
    Thick   = "Interface\\AddOns\\JustTheTip\\Media\\Thick.png",
    Solid   = "Interface\\AddOns\\JustTheTip\\Media\\Solid.png"
}
Ring.defaults = {
    ring = {
        enabled         = false,
        ringRadius      = 28,
        textureKey      = "Default",
        inCombatAlpha   = 0.70,
        outCombatAlpha  = 0.30,
        useClassColor   = true,
        useHighVis      = false,
        colorMode       = "class",
        customColor     = { r = 1, g = 1, b = 1 },
        visible         = true
    }
}

local ring = nil
local tex = nil
local lastInCombat = nil
Ring.colorAlias = {
    red         = "deathknight",
    magenta     = "demonhunter",
    orange      = "druid",
    darkgreen   = "evoker",
    green       = "hunter",
    lightgreen  = "monk",
    blue        = "shaman",
    lightblue   = "mage",
    pink        = "paladin",
    white       = "priest",
    yellow      = "rogue",
    purple      = "warlock",
    tan         = "warrior"
}

local function GetColor()
    local db = nil
    if JTT and JTT.db and JTT.db.profile and JTT.db.profile.ring then
        db = JTT.db.profile.ring
    elseif JustTheTipDB and JustTheTipDB.ring then
        db = JustTheTipDB.ring
    end
    
    if not db then return 1, 1, 1 end
    
    if db.useHighVis then
        return 0, 1, 0
    end
    if db.useClassColor then
        local _, classFile = UnitClass("player")
        if classFile and RAID_CLASS_COLORS[classFile] then
            local color = RAID_CLASS_COLORS[classFile]
            return color.r, color.g, color.b
        end
    end
    if db.colorMode == "custom" then
        return db.customColor.r, db.customColor.g, db.customColor.b
    end
    
    local classFile = Ring.colorAlias[db.colorMode] or db.colorMode
    if classFile and RAID_CLASS_COLORS[strupper(classFile)] then
        local color = RAID_CLASS_COLORS[strupper(classFile)]
        return color.r, color.g, color.b
    end
    return 1, 1, 1
end

local function UpdateAppearance()
    if not ring or not tex then return end
    
    local db = nil
    if JTT and JTT.db and JTT.db.profile and JTT.db.profile.ring then
        db = JTT.db.profile.ring
    elseif JustTheTipDB and JustTheTipDB.ring then
        db = JustTheTipDB.ring
    end
    
    if not db then return end
    local texture = Ring.textures[db.textureKey] or Ring.textures.Default
    local radius = db.ringRadius
    local alpha = InCombatLockdown() and db.inCombatAlpha or db.outCombatAlpha
    local r, g, b = GetColor()

    tex:SetTexture(texture)
    tex:SetVertexColor(r, g, b)
    tex:SetAlpha(alpha)
    ring:SetSize(radius * 2, radius * 2)
end

function Ring.Initialize()
    if ring then 
        return 
    end
    
    ring = CreateFrame("Frame", "JTTRing", UIParent)
    ring:SetFrameStrata("TOOLTIP")
    ring:SetSize(64, 64)
    ring:SetPoint("CENTER", 0, 0)
    ring:Hide()
    
    tex = ring:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
end

function Ring.SetEnabled(enabled)
    if not JTT or not JTT.db or not JTT.db.profile then
        C_Timer.After(0.01, function()
            if JTT and JTT.db and JTT.db.profile then
                Ring.SetEnabled(enabled)
            else
                Ring._SetEnabled(enabled)
            end
        end)
        return
    end
    
    Ring._SetEnabled(enabled)
end

function Ring._SetEnabled(enabled)
    local db = nil
    if JTT and JTT.db and JTT.db.profile and JTT.db.profile.ring then
        db = JTT.db.profile.ring
        
        if JustTheTipDB and JustTheTipDB.ring then
            local needsMigration = false
            
            for k, v in pairs(JustTheTipDB.ring) do
                if JTT.db.profile.ring[k] ~= v then
                    needsMigration = true
                    break
                end
            end
            
            if needsMigration then
                for k, v in pairs(JustTheTipDB.ring) do
                    JTT.db.profile.ring[k] = v
                end
                
                if JTT.SaveConfig then
                    JTT:SaveConfig()
                end
            end
        end
    elseif JustTheTipDB and JustTheTipDB.ring then
        db = JustTheTipDB.ring
    else
        if not JustTheTipDB then
            JustTheTipDB = {}
        end
        
        if not JustTheTipDB.ring then
            local hasOtherSettings = false
            for k, v in pairs(JustTheTipDB) do
                if k ~= nil and v ~= nil then
                    hasOtherSettings = true
                    break
                end
            end
            
            if not JustTheTipDB.ring then
                JustTheTipDB.ring = {
                    ringRadius      = 28,
                    textureKey      = "Default",
                    inCombatAlpha   = 0.70,
                    outCombatAlpha  = 0.30,
                    useClassColor   = true,
                    useHighVis      = false,
                    colorMode       = "class",
                    customColor     = { r = 1, g = 1, b = 1 },
                    visible         = true
                }
            end
        end
        db = JustTheTipDB.ring
    end
    
    db.enabled = enabled
    
    if JTT and JTT.db and JTT.db.profile and JTT.db.profile.ring then
        JTT.db.profile.ring.enabled = enabled
        JTT.db.profile.ring.visible = db.visible
    end
    if not ring then
        Ring.Initialize()
    end
    
    if enabled then
        Ring.Refresh()
        Ring.StartTracking()
    else
        Ring.StopTracking()
        if ring then
            ring:Hide()
        end
    end
end

function Ring._Initialize()
end
function Ring.StartTracking()
    if not ring then 
        Ring.Initialize()
    end
    
    if not ring then 
        return 
    end
    local db = nil
    if JTT and JTT.db and JTT.db.profile and JTT.db.profile.ring then
        db = JTT.db.profile.ring
    elseif JustTheTipDB and JustTheTipDB.ring then
        db = JustTheTipDB.ring
    end
    
    if db and db.enabled and db.visible then
        ring:Show()
    end
    
    ring:SetScript("OnUpdate", function(self, elapsed)
        local enabled = false
        local visible = true
        local db = nil
        
        if JTT and JTT.db and JTT.db.profile and JTT.db.profile.ring then
            db = JTT.db.profile.ring
            enabled = JTT.db.profile.ring.enabled
            visible = JTT.db.profile.ring.visible
        elseif JustTheTipDB and JustTheTipDB.ring then
            db = JustTheTipDB.ring
            enabled = JustTheTipDB.ring.enabled
            visible = JustTheTipDB.ring.visible
        end
        
        enabled = enabled == true
        
        if not enabled then
            ring:Hide()
            return
        end
        
        local x, y = GetCursorPosition()
        local scale = ring:GetEffectiveScale()
        ring:ClearAllPoints()
        ring:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
        
        if visible then
            ring:Show()
        else
            ring:Hide()
        end

        local nowInCombat = InCombatLockdown()
        if nowInCombat ~= lastInCombat then
            lastInCombat = nowInCombat
            UpdateAppearance()
        end
    end)
end

function Ring.StopTracking()
    if ring then
        ring:SetScript("OnUpdate", nil)
    end
end

function Ring.Refresh()
    local db = nil
    
    if JTT and JTT.db and JTT.db.profile and JTT.db.profile.ring then
        db = JTT.db.profile.ring
    elseif JustTheTipDB and JustTheTipDB.ring then
        db = JustTheTipDB.ring
    end
    
    if not db then 
        return 
    end
    
    if ring then
        local enabled = db.enabled == true
        local shouldShow = enabled and db.visible
        if shouldShow then
            ring:Show()
        else
            ring:Hide()
        end
        UpdateAppearance()
    end
end

function Ring.OnCombatStart()
    UpdateAppearance()
end

function Ring.OnCombatEnd()
    UpdateAppearance()
end

function Ring.HandleSlashCommand(cmd, arg1, arg2)
    local db = nil
    if JTT and JTT.db and JTT.db.profile and JTT.db.profile.ring then
        db = JTT.db.profile.ring
    elseif JustTheTipDB and JustTheTipDB.ring then
        db = JustTheTipDB.ring
    else
        return false
    end
        
    if cmd == "ring" then
        if arg1 == "show" then
            db.enabled = true
            db.visible = true
            Ring.SetEnabled(true)
            return true
        elseif arg1 == "hide" then
            db.visible = false
            if JTT and JTT.db and JTT.db.profile and JTT.db.profile.ring then
                JTT.db.profile.ring.visible = false
                JTT.db.profile.ring.enabled = db.enabled
            end
            if JTT and JTT.SaveConfig then JTT:SaveConfig() end
            Ring.Refresh()
            return true
        elseif arg1 == "toggle" then
            db.visible = not db.visible
            if db.visible and not db.enabled then
                db.enabled = true
                if JTT and JTT.db and JTT.db.profile and JTT.db.profile.ring then
                    JTT.db.profile.ring.enabled = true
                    JTT.db.profile.ring.visible = true
                end
                Ring.SetEnabled(true)
            else
                if JTT and JTT.db and JTT.db.profile and JTT.db.profile.ring then
                    JTT.db.profile.ring.visible = db.visible
                    JTT.db.profile.ring.enabled = db.enabled
                end
                if JTT and JTT.SaveConfig then JTT:SaveConfig() end
                Ring.Refresh()
            end
            return true
        elseif arg1 == "enable" then
            Ring.SetEnabled(true)
            return true
        elseif arg1 == "disable" then
            Ring.SetEnabled(false)
            return true
        end
    end
    return false
end

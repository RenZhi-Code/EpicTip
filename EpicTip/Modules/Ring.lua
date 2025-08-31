local addonName, ET = ...

ET.Ring = ET.Ring or {}
local Ring = ET.Ring
local L = ET.L or {}

Ring.textures = {
    Thin    = "Interface\\AddOns\\EpicTip\\Media\\Ring_10px.tga",
    Solid   = "Interface\\AddOns\\EpicTip\\Media\\Ring_20px.tga",
    Default = "Interface\\AddOns\\EpicTip\\Media\\Ring_30px.tga",
    Thick   = "Interface\\AddOns\\EpicTip\\Media\\Ring_40px.tga"
}

Ring.defaults = {
    enabled         = false,
    ringRadius      = 28,
    textureKey      = "Default",
    inCombatAlpha   = 0.70,
    outCombatAlpha  = 0.30,
    useClassColor   = true,
    useHighVis      = false,
    customColor     = { r = 1, g = 1, b = 1 },
    visible         = true
}

local ring = nil
local tex = nil
local lastInCombat = nil

local function GetColor()
    local db = nil
    if ET and ET.db and ET.db.profile and ET.db.profile.ring then
        db = ET.db.profile.ring
    elseif EpicTipDB and EpicTipDB.ring then
        db = EpicTipDB.ring
    end
    
    if not db then return 1, 1, 1 end
    
    -- High visibility mode takes priority
    if db.useHighVis then
        return 0, 1, 0
    end
    
    -- Use class color if enabled
    if db.useClassColor then
        local _, classFile = UnitClass("player")
        if classFile and ET.ColorUtils then
            local r, g, b = ET.ColorUtils:GetClassColor(classFile)
            return r, g, b
        elseif classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] then
            local colour = RAID_CLASS_COLORS[classFile]
            return colour.r, colour.g, colour.b
        end
    end
    
    -- Use custom color as fallback
    return db.customColor.r, db.customColor.g, db.customColor.b
end

local function UpdateAppearance()
    if not ring or not tex then return end
    
    local db = nil
    if ET and ET.db and ET.db.profile and ET.db.profile.ring then
        db = ET.db.profile.ring
    elseif EpicTipDB and EpicTipDB.ring then
        db = EpicTipDB.ring
    end
    
    if not db then return end
    local texture = Ring.textures[db.textureKey] or Ring.textures.Default
    local radius = db.ringRadius
    local alpha = InCombatLockdown() and db.inCombatAlpha or db.outCombatAlpha
    -- Ensure alpha is a valid number
    if not alpha or type(alpha) ~= "number" then
        alpha = 1.0
    end
    local r, g, b = GetColor()

    -- Debug: Print to chat if debug mode is enabled
    if ET and ET.db and ET.db.profile and ET.db.profile.debugMode then
        print("EpicTip: Updating ring appearance - texture:", texture, "radius:", radius, "alpha:", alpha, "color:", r, g, b)
    end

    -- Ensure texture is set
    if tex and tex.SetTexture and type(tex.SetTexture) == "function" then
        tex:SetTexture(texture or Ring.textures.Default)
    end
    if tex and tex.SetVertexColor and type(tex.SetVertexColor) == "function" then
        tex:SetVertexColor(r, g, b)
    end
    if tex and tex.SetAlpha and type(tex.SetAlpha) == "function" then
        tex:SetAlpha(alpha)
    end
    ring:SetSize(radius * 2, radius * 2)
    
    -- Ensure the ring is shown if it should be visible
    if db.visible and db.enabled then
        ring:Show()
    end
end

-- Expose UpdateAppearance function for UI configuration
Ring.UpdateAppearance = UpdateAppearance

-- Add SetVisible function for UI configuration
function Ring.SetVisible(visible)
    local db = nil
    if ET and ET.db and ET.db.profile and ET.db.profile.ring then
        db = ET.db.profile.ring
        db.visible = db.enabled and visible  -- Only visible if enabled
    elseif EpicTipDB and EpicTipDB.ring then
        db = EpicTipDB.ring
        db.visible = db.enabled and visible  -- Only visible if enabled
    end
    
    if ET and ET.SaveConfig then 
        ET:SaveConfig() 
    end
    
    Ring.Refresh()
end

function Ring.Initialize()
    if ring then 
        return 
    end
    
    -- Use frame pool for ring creation if available
    if ET.Tooltip and ET.Tooltip.FrameFactory then
        ring = ET.Tooltip.FrameFactory:GetFrame("generic", nil, UIParent)
        -- Note: Pooled frames cannot be renamed after creation
    else
        -- Fallback for initialization order - create with name
        ring = CreateFrame("Frame", "ETRing", UIParent)
    end
    
    ring:SetFrameStrata("TOOLTIP")
    ring:SetSize(64, 64)
    ring:SetPoint("CENTER", 0, 0)
    ring:Hide()
    
    -- Create or reuse texture
    if not ring.epicTipRingTexture then
        tex = ring:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints()
        ring.epicTipRingTexture = tex
    else
        tex = ring.epicTipRingTexture
    end
    
    -- Ensure texture is set
    if tex and Ring.textures then
        tex:SetTexture(Ring.textures.Default)
    end
    
    -- Register for combat events
    if ET and ET.RegisterEvent then
        ET:RegisterEvent("PLAYER_REGEN_ENABLED", function()
            if ring and ring:IsShown() then
                UpdateAppearance()
            end
        end)
        
        ET:RegisterEvent("PLAYER_REGEN_DISABLED", function()
            if ring and ring:IsShown() then
                UpdateAppearance()
            end
        end)
    end
end







function Ring.SetEnabled(enabled)
    if not ET or not ET.db or not ET.db.profile then
        C_Timer.After(0.01, function()
            if ET and ET.db and ET.db.profile then
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
    if ET and ET.db and ET.db.profile and ET.db.profile.ring then
        db = ET.db.profile.ring
        
        if EpicTipDB and EpicTipDB.ring then
            local needsMigration = false
            
            for k, v in pairs(EpicTipDB.ring) do
                if ET.db.profile.ring[k] ~= v then
                    needsMigration = true
                    break
                end
            end
            
            if needsMigration then
                for k, v in pairs(EpicTipDB.ring) do
                    ET.db.profile.ring[k] = v
                end
                
                if ET.SaveConfig then
                    ET:SaveConfig()
                end
            end
        end
    elseif EpicTipDB and EpicTipDB.ring then
        db = EpicTipDB.ring
    else
        if not EpicTipDB then
            EpicTipDB = {}
        end
        
        if not EpicTipDB.ring then
            EpicTipDB.ring = {}
            for k, v in pairs(Ring.defaults) do
                EpicTipDB.ring[k] = v
            end
        end
        db = EpicTipDB.ring
    end
    
    db.enabled = enabled
    db.visible = enabled  -- Sync visible state with enabled state
    
    if ET and ET.db and ET.db.profile and ET.db.profile.ring then
        ET.db.profile.ring.enabled = enabled
        ET.db.profile.ring.visible = enabled  -- Sync visible state with enabled state
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
    
    if ET and ET.SaveConfig then 
        ET:SaveConfig() 
    end
end

function Ring._Initialize()
end
-- Memory Leak Fix: Replace OnUpdate with event-driven + throttled approach
-- This eliminates the primary cause of 7MB accumulation in busy areas
local ringUpdateThrottle = 0.05 -- 50ms throttle to prevent excessive updates
local lastUpdateTime = 0
local updateTimer = nil

function Ring.StartTracking()
    if not ring then 
        Ring.Initialize()
    end
    
    if not ring then 
        return 
    end
    
    local db = nil
    if ET and ET.db and ET.db.profile and ET.db.profile.ring then
        db = ET.db.profile.ring
    elseif EpicTipDB and EpicTipDB.ring then
        db = EpicTipDB.ring
    end
    
    if db and db.enabled and db.visible then
        ring:Show()
        -- Debug: Print to chat if debug mode is enabled
        if ET and ET.db and ET.db.profile and ET.db.profile.debugMode then
            print("EpicTip: Starting ring tracking - showing ring")
        end
    else
        -- Debug: Print to chat if debug mode is enabled
        if ET and ET.db and ET.db.profile and ET.db.profile.debugMode then
            print("EpicTip: Starting ring tracking - not showing ring - enabled:", db and db.enabled, "visible:", db and db.visible)
        end
    end
    
    -- MEMORY LEAK FIX: Replace OnUpdate with throttled C_Timer approach
    Ring.StopTracking() -- Ensure no duplicate timers
    
    updateTimer = C_Timer.NewTicker(ringUpdateThrottle, function()
        Ring.UpdateRingPosition()
    end)
end

function Ring.UpdateRingPosition()
    if not ring then return end
    
    local enabled = false
    local visible = true
    local db = nil
    
    if ET and ET.db and ET.db.profile and ET.db.profile.ring then
        db = ET.db.profile.ring
        enabled = ET.db.profile.ring.enabled
        visible = ET.db.profile.ring.visible
    elseif EpicTipDB and EpicTipDB.ring then
        db = EpicTipDB.ring
        enabled = EpicTipDB.ring.enabled
        visible = EpicTipDB.ring.visible
    end
    
    enabled = enabled == true
    
    if not enabled then
        ring:Hide()
        Ring.StopTracking() -- Stop timer when disabled
        -- Debug: Print to chat if debug mode is enabled
        if ET and ET.db and ET.db.profile and ET.db.profile.debugMode then
            print("EpicTip: Hiding ring - tracking stopped")
        end
        return
    end
    
    -- Throttled cursor position update
    local currentTime = GetTime()
    if currentTime - lastUpdateTime < ringUpdateThrottle then
        return
    end
    lastUpdateTime = currentTime
    
    local x, y = GetCursorPosition()
    local scale = ring:GetEffectiveScale()
    ring:ClearAllPoints()
    ring:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    
    if visible then
        ring:Show()
        -- Debug: Print to chat if debug mode is enabled
        if ET and ET.db and ET.db.profile and ET.db.profile.debugMode then
            print("EpicTip: Showing ring at cursor position")
        end
    else
        ring:Hide()
        -- Debug: Print to chat if debug mode is enabled
        if ET and ET.db and ET.db.profile and ET.db.profile.debugMode then
            print("EpicTip: Hiding ring - visible flag is false")
        end
    end

    local nowInCombat = InCombatLockdown()
    if nowInCombat ~= lastInCombat then
        lastInCombat = nowInCombat
        UpdateAppearance()
    end
end

function Ring.StopTracking()
    -- MEMORY LEAK FIX: Properly cleanup timer and OnUpdate script
    if updateTimer then
        updateTimer:Cancel()
        updateTimer = nil
    end
    
    if ring then
        ring:SetScript("OnUpdate", nil)
    end
end

function Ring.Refresh()
    local db = nil
    
    if ET and ET.db and ET.db.profile and ET.db.profile.ring then
        db = ET.db.profile.ring
    elseif EpicTipDB and EpicTipDB.ring then
        db = EpicTipDB.ring
    end
    
    if not db then 
        return 
    end
    
    if ring then
        local enabled = db.enabled == true
        local shouldShow = enabled and db.visible
        if shouldShow then
            ring:Show()
            -- Debug: Print to chat if debug mode is enabled
            if ET and ET.db and ET.db.profile and ET.db.profile.debugMode then
                print("EpicTip: Showing ring - enabled:", enabled, "visible:", db.visible)
            end
        else
            ring:Hide()
            -- Debug: Print to chat if debug mode is enabled
            if ET and ET.db and ET.db.profile and ET.db.profile.debugMode then
                print("EpicTip: Hiding ring - enabled:", enabled, "visible:", db.visible)
            end
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
    if ET and ET.db and ET.db.profile and ET.db.profile.ring then
        db = ET.db.profile.ring
    elseif EpicTipDB and EpicTipDB.ring then
        db = EpicTipDB.ring
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
            if ET and ET.db and ET.db.profile and ET.db.profile.ring then
                ET.db.profile.ring.visible = false
                ET.db.profile.ring.enabled = db.enabled
            end
            if ET and ET.SaveConfig then ET:SaveConfig() end
            Ring.Refresh()
            return true
        elseif arg1 == "toggle" then
            db.visible = not db.visible
            if db.visible and not db.enabled then
                db.enabled = true
                if ET and ET.db and ET.db.profile and ET.db.profile.ring then
                    ET.db.profile.ring.enabled = true
                    ET.db.profile.ring.visible = true
                end
                Ring.SetEnabled(true)
            else
                if ET and ET.db and ET.db.profile and ET.db.profile.ring then
                    ET.db.profile.ring.visible = db.visible
                    ET.db.profile.ring.enabled = db.enabled
                end
                if ET and ET.SaveConfig then ET:SaveConfig() end
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

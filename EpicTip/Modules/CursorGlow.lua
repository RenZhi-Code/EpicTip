local addonName, addonTable = ...
ET = ET or addonTable or {}
ET.CursorGlow = ET.CursorGlow or {}
local CursorGlow = ET.CursorGlow
local L = ET.L or {}

CursorGlow.textures = {
    Star1 = "Interface\\Cooldown\\star4",
    Star2 = "Interface\\Cooldown\\starburst", 
    Ring = "Interface\\TargetingFrame\\UI-StatusBar",
    Solid = "Interface\\Buttons\\WHITE8X8",
    Spark = "Interface\\CastingBar\\UI-CastingBar-Spark",
    Glow = "Interface\\SpellActivationOverlay\\IconAlert",
    Burst = "Interface\\GLUES\\MODELS\\UI_Draenei\\GenericGlow64"
}

CursorGlow.defaults = {
    cursorGlow = {
        enabled = false,
        texture = "Star1",
        color = { r = 1, g = 1, b = 1 },
        useClassColor = true,
        size = 32,
        opacity = 0.8,
        
        enableTail = false,
        tailLength = 20,
        tailEffect = "classic", -- classic, sparkle, wobble, rainbow
        tailFadeSpeed = 0.5,
        
        enablePulse = false,
        pulseMinSize = 32,
        pulseMaxSize = 64,
        pulseSpeed = 1.0,
        
        enableClickGlow = false,
        clickGlowSize = 100,
        clickGlowDuration = 1.0,
        
        combatOnly = false,
        hideInCombat = false
    }
}

local glowFrame = nil
local mainTexture = nil
local tailTextures = {}
local tailPositions = {}
local pulseTimer = 0
local lastCursorX, lastCursorY = 0, 0
local speed = 0
local stationaryTime = 0

local function GetColor()
    local db = nil
    if ET and ET.db and ET.db.profile and ET.db.profile.cursorGlow then
        db = ET.db.profile.cursorGlow
    elseif EpicTipDB and EpicTipDB.cursorGlow then
        db = EpicTipDB.cursorGlow
    end
    
    if not db then return 1, 1, 1 end
    
    if db.useClassColor then
        local _, classFile = UnitClass("player")
        if classFile and RAID_CLASS_COLORS[classFile] then
            local color = RAID_CLASS_COLORS[classFile]
            return color.r, color.g, color.b
        end
    end
    
    if db.color then
        return db.color.r, db.color.g, db.color.b
    end
    
    return 1, 1, 1
end

function CursorGlow.Initialize()
    if glowFrame then 
        return 
    end
    
    glowFrame = CreateFrame("Frame", "ETCursorGlow", UIParent)
    
    if not glowFrame then
        return
    end
    
    glowFrame:SetFrameStrata("TOOLTIP")
    glowFrame:SetFrameLevel(1000)
    glowFrame:SetSize(64, 64)
    glowFrame:Hide()
    glowFrame:SetAlpha(0)
    
    glowFrame:EnableMouse(false)
    
    mainTexture = glowFrame:CreateTexture(nil, "OVERLAY")
    if mainTexture then
        mainTexture:SetAllPoints(glowFrame)
        mainTexture:SetBlendMode("ADD")
        mainTexture:SetTexture(CursorGlow.textures.Star1)
        mainTexture:SetAlpha(0)
        mainTexture:Hide()
    else
        return
    end
    
    CursorGlow.InitializeTails()
    
    glowFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    glowFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    glowFrame:SetScript("OnEvent", function(self, event)
        CursorGlow.UpdateVisibility()
    end)
    
    CursorGlow.UpdateVisibility()
end

function CursorGlow.InitializeTails()
    for _, texture in ipairs(tailTextures) do
        if texture and texture.Hide then
            texture:Hide()
        end
    end
    wipe(tailTextures)
    wipe(tailPositions)
    
    local db = CursorGlow.GetConfig()
    if not db or not db.enableTail then return end
    
    local tailLength = db.tailLength or 20
    local r, g, b = GetColor()
    local texturePath = CursorGlow.textures[db.texture] or CursorGlow.textures.Star1
    
    for i = 1, tailLength do
        local tailTexture = glowFrame:CreateTexture(nil, "BACKGROUND")
        tailTexture:SetTexture(texturePath)
        tailTexture:SetBlendMode("ADD")
        tailTexture:SetSize(32, 32)
        tailTexture:SetVertexColor(r, g, b, db.opacity or 0.8)
        tailTexture:Hide()
        tailTextures[i] = tailTexture
    end
end

function CursorGlow.GetConfig()
    if ET and ET.db and ET.db.profile and ET.db.profile.cursorGlow then
        return ET.db.profile.cursorGlow
    elseif EpicTipDB and EpicTipDB.cursorGlow then
        return EpicTipDB.cursorGlow
    end
    return {
        enabled = false,
        texture = "Star1",
        color = { r = 1, g = 1, b = 1 },
        useClassColor = true,
        size = 32,
        opacity = 0.8,
        combatOnly = false,
        hideInCombat = false
    }
end

function CursorGlow.UpdateAppearance()
    if not glowFrame or not mainTexture then 
        return 
    end
    
    local db = CursorGlow.GetConfig()
    if not db then 
        return 
    end
    
    local r, g, b = GetColor()
    local texture = CursorGlow.textures[db.texture] or CursorGlow.textures.Star1
    local size = db.size or 32
    local opacity = db.opacity or 0.8
    
    
    mainTexture:SetTexture(texture)
    mainTexture:SetVertexColor(r, g, b, opacity)
    glowFrame:SetSize(size, size)
    
    mainTexture:SetAlpha(opacity)
    mainTexture:Show()
    glowFrame:SetAlpha(1.0)
    
    if db.enableTail then
        for _, tailTexture in ipairs(tailTextures) do
            if tailTexture then
                tailTexture:SetTexture(texture)
                tailTexture:SetVertexColor(r, g, b, opacity)
            end
        end
    end
end

function CursorGlow.UpdateVisibility()
    if not glowFrame then 
        return 
    end
    
    local db = CursorGlow.GetConfig()
    if not db then
        glowFrame:Hide()
        CursorGlow.StopTracking()
        return
    end
    
    if not db.enabled then
        glowFrame:Hide()
        CursorGlow.StopTracking()
        return
    end
    
    local inCombat = InCombatLockdown()
    
    if db.combatOnly and not inCombat then
        glowFrame:Hide()
        CursorGlow.StopTracking()
        return
    end
    
    if db.hideInCombat and inCombat then
        glowFrame:Hide()
        CursorGlow.StopTracking()
        return
    end
    
    CursorGlow.UpdateAppearance()
    
    glowFrame:SetFrameStrata("TOOLTIP")
    glowFrame:SetFrameLevel(1000)
    glowFrame:EnableMouse(false)
    
    glowFrame:Show()
    CursorGlow.StartTracking()
end

local updateTimer = nil
local animationTime = 0

local function UpdateCursorPosition()
    if not glowFrame or not glowFrame:IsShown() then 
        return 
    end
    
    local db = CursorGlow.GetConfig()
    if not db or not db.enabled then
        CursorGlow.StopTracking()
        return
    end
    
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    
    glowFrame:ClearAllPoints()
    glowFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    
    animationTime = animationTime + 0.016
    
    local deltaX = x - lastCursorX
    local deltaY = y - lastCursorY
    local distance = math.sqrt(deltaX * deltaX + deltaY * deltaY)
    
    local elapsed = 0.016
    local isMoving = distance > 1
    
    if isMoving then
        speed = math.min(speed * 0.9 + distance / elapsed * 0.1, 1000)
        stationaryTime = 0
        
        if db.enableTail then
            CursorGlow.UpdateTailEffect(x / scale, y / scale, elapsed)
        end
        
        if db.enablePulse then
            local pulseProgress = (math.sin(animationTime * (db.pulseSpeed or 1) * math.pi * 2) + 1) / 2
            local size = (db.pulseMinSize or 32) + ((db.pulseMaxSize or 64) - (db.pulseMinSize or 32)) * pulseProgress
            glowFrame:SetSize(size, size)
        else
            glowFrame:SetSize(db.size or 32, db.size or 32)
        end
        
    else
        stationaryTime = stationaryTime + elapsed
        speed = speed * 0.95
        
        if db.enableTail and stationaryTime > 0.1 then
            for _, tailTexture in ipairs(tailTextures) do
                if tailTexture then tailTexture:Hide() end
            end
            wipe(tailPositions)
        end
        
        if db.enablePulse then
            local pulseProgress = (math.sin(animationTime * (db.pulseSpeed or 1) * math.pi * 2) + 1) / 2
            local size = (db.pulseMinSize or 32) + ((db.pulseMaxSize or 64) - (db.pulseMinSize or 32)) * pulseProgress
            glowFrame:SetSize(size, size)
        end
    end
    
    lastCursorX, lastCursorY = x, y
end

function CursorGlow.StartTracking()
    if updateTimer then 
        updateTimer:Cancel()
        updateTimer = nil
    end
    
    if not glowFrame then
        return
    end
    
    glowFrame:Show()
    
    animationTime = 0
    
    updateTimer = C_Timer.NewTicker(0.016, UpdateCursorPosition)
end

function CursorGlow.StopTracking()
    if updateTimer then
        updateTimer:Cancel()
        updateTimer = nil
    end
    
    for _, tailTexture in ipairs(tailTextures) do
        if tailTexture then tailTexture:Hide() end
    end
end

function CursorGlow.UpdateTailEffect(cursorX, cursorY, elapsed)
    local db = CursorGlow.GetConfig()
    if not db or not db.enableTail then return end
    
    local tailLength = math.min(db.tailLength or 20, 30)
    local effect = db.tailEffect or "classic"
    local fadeSpeed = (db.tailFadeSpeed or 0.5) * 2
    
    table.insert(tailPositions, 1, {x = cursorX, y = cursorY, time = GetTime()})
    
    while #tailPositions > tailLength do
        table.remove(tailPositions)
    end
    
    if effect == "classic" then
        CursorGlow.UpdateClassicTail()
    elseif effect == "sparkle" then
        CursorGlow.UpdateSparkleTail(fadeSpeed)
    elseif effect == "wobble" then
        CursorGlow.UpdateWobbleTail(fadeSpeed)
    elseif effect == "rainbow" then
        CursorGlow.UpdateRainbowTail()
    end
end

function CursorGlow.UpdateClassicTail()
    local db = CursorGlow.GetConfig()
    local tailLength = #tailPositions
    
    for i, tailTexture in ipairs(tailTextures) do
        local pos = tailPositions[i]
        if pos and tailTexture and i <= tailLength then
            local alpha = math.pow((tailLength - i + 1) / tailLength, 1.5) * (db.opacity or 0.8)
            tailTexture:ClearAllPoints()
            tailTexture:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x, pos.y)
            tailTexture:SetAlpha(alpha)
            tailTexture:Show()
        elseif tailTexture then
            tailTexture:Hide()
        end
    end
end

function CursorGlow.UpdateSparkleTail(fadeSpeed)
    local db = CursorGlow.GetConfig()
    local currentTime = GetTime()
    
    for i, tailTexture in ipairs(tailTextures) do
        local pos = tailPositions[i]
        if pos and tailTexture then
            local age = currentTime - pos.time
            local fade = math.max(1 - (age / fadeSpeed), 0)
            if fade > 0.1 then
                local scatter = 8
                local offsetX = math.random(-scatter, scatter)
                local offsetY = math.random(-scatter, scatter)
                tailTexture:ClearAllPoints()
                tailTexture:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x + offsetX, pos.y + offsetY)
                tailTexture:SetAlpha(fade * (db.opacity or 0.8))
                tailTexture:Show()
            else
                tailTexture:Hide()
            end
        elseif tailTexture then
            tailTexture:Hide()
        end
    end
end

function CursorGlow.UpdateWobbleTail(fadeSpeed)
    local db = CursorGlow.GetConfig()
    local currentTime = GetTime()
    
    for i, tailTexture in ipairs(tailTextures) do
        local pos = tailPositions[i]
        if pos and tailTexture then
            local age = currentTime - pos.time
            local fade = math.max(1 - (age / fadeSpeed), 0)
            if fade > 0 then
                local wobble = math.sin(currentTime * 8 + i) * 10 * fade
                tailTexture:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x + wobble, pos.y + wobble)
                tailTexture:SetAlpha(fade * (db.opacity or 0.8))
                tailTexture:Show()
            else
                tailTexture:Hide()
            end
        elseif tailTexture then
            tailTexture:Hide()
        end
    end
end

function CursorGlow.UpdateRainbowTail()
    local db = CursorGlow.GetConfig()
    local tailLength = #tailPositions
    
    for i, tailTexture in ipairs(tailTextures) do
        local pos = tailPositions[i]
        if pos and tailTexture and i <= tailLength then
            local hue = ((i / tailLength) + (GetTime() * 0.5)) % 1
            local r, g, b = CursorGlow.HSVtoRGB(hue, 1, 1)
            local alpha = (tailLength - i + 1) / tailLength * (db.opacity or 0.8)
            
            tailTexture:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x, pos.y)
            tailTexture:SetVertexColor(r, g, b, alpha)
            tailTexture:SetAlpha(alpha)
            tailTexture:Show()
        elseif tailTexture then
            tailTexture:Hide()
        end
    end
end

function CursorGlow.HSVtoRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    
    return r, g, b
end

function CursorGlow.TriggerClickGlow()
    local db = CursorGlow.GetConfig()
    if not db or not db.enableClickGlow then return end
    
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local size = db.clickGlowSize or 100
    local duration = db.clickGlowDuration or 1.0
    
    local explosionFrame = ET.MemoryPool and ET.MemoryPool.GetExplosionFrame and ET.MemoryPool.GetExplosionFrame(UIParent) or CreateFrame("Frame", nil, UIParent)
    
    if not explosionFrame then return end
    
    explosionFrame:SetFrameStrata("TOOLTIP")
    explosionFrame:SetSize(size, size)
    explosionFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    
    local explosionTexture = explosionFrame.explosionTexture
    if not explosionTexture then
        explosionTexture = explosionFrame:CreateTexture(nil, "OVERLAY")
        explosionTexture:SetAllPoints()
        explosionTexture:SetBlendMode("ADD")
        explosionFrame.explosionTexture = explosionTexture
    end
    
    explosionTexture:SetTexture(CursorGlow.textures.Burst)
    explosionTexture:Show()
    
    local r, g, b = GetColor()
    explosionTexture:SetVertexColor(r, g, b, 1)
    
    local startTime = GetTime()
    local animationTimer = C_Timer.NewTicker(0.016, function()
        local progress = (GetTime() - startTime) / duration
        if progress >= 1 then
            explosionFrame:Hide()
            animationTimer:Cancel()
            if ET.MemoryPool and ET.MemoryPool.ReturnExplosionFrame then
                ET.MemoryPool.ReturnExplosionFrame(explosionFrame)
            end
            return
        end
        
        local currentSize = size * (1 + progress * 2)
        local alpha = 1 - progress
        
        explosionFrame:SetSize(currentSize, currentSize)
        explosionTexture:SetAlpha(alpha)
    end)
    
end

function CursorGlow.SetEnabled(enabled)
    local db = CursorGlow.GetConfig()
    
    if not db then
        if EpicTipDB then
            if not EpicTipDB.cursorGlow then
                EpicTipDB.cursorGlow = {
                    enabled = enabled,
                    texture = "Star1",
                    color = { r = 1, g = 1, b = 1 },
                    useClassColor = true,
                    size = 32,
                    opacity = 0.8,
                    enableTail = false,
                    tailLength = 20,
                    tailEffect = "classic",
                    tailFadeSpeed = 0.5,
                    enablePulse = false,
                    pulseMinSize = 32,
                    pulseMaxSize = 64,
                    pulseSpeed = 1.0,
                    enableClickGlow = false,
                    clickGlowSize = 100,
                    clickGlowDuration = 1.0,
                    combatOnly = false,
                    hideInCombat = false
                }
            end
            db = EpicTipDB.cursorGlow
        elseif ET and ET.db and ET.db.profile then
            if not ET.db.profile.cursorGlow then
                ET.db.profile.cursorGlow = {
                    enabled = enabled,
                    texture = "Star1",
                    color = { r = 1, g = 1, b = 1 },
                    useClassColor = true,
                    size = 32,
                    opacity = 0.8,
                    enableTail = false,
                    tailLength = 20,
                    tailEffect = "classic",
                    tailFadeSpeed = 0.5,
                    enablePulse = false,
                    pulseMinSize = 32,
                    pulseMaxSize = 64,
                    pulseSpeed = 1.0,
                    enableClickGlow = false,
                    clickGlowSize = 100,
                    clickGlowDuration = 1.0,
                    combatOnly = false,
                    hideInCombat = false
                }
            end
            db = ET.db.profile.cursorGlow
        else
            return
        end
    end
    
    db.enabled = enabled
    
    if not glowFrame then
        CursorGlow.Initialize()
    end
    
    if enabled then
        CursorGlow.UpdateVisibility()
    else
        CursorGlow.StopTracking()
        if glowFrame then glowFrame:Hide() end
    end
    
    if ET and ET.SaveConfig then ET:SaveConfig() end
end

function CursorGlow.Refresh()
    if not glowFrame then return end
    
    CursorGlow.UpdateAppearance()
    CursorGlow.InitializeTails()
    CursorGlow.UpdateVisibility()
end

function CursorGlow.HandleSlashCommand(cmd, arg1, arg2)
    if cmd == "cursorglow" or cmd == "glow" then
        if arg1 == "enable" then
            CursorGlow.SetEnabled(true)
            return true
        elseif arg1 == "disable" then
            CursorGlow.SetEnabled(false)
            return true
        elseif arg1 == "toggle" then
            local db = CursorGlow.GetConfig()
            if db then
                CursorGlow.SetEnabled(not db.enabled)
            end
            return true
        elseif arg1 == "force" then
            if not glowFrame then
                CursorGlow.Initialize()
            end
            
            if glowFrame then
                glowFrame:SetSize(64, 64)
                glowFrame:ClearAllPoints()
                glowFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                glowFrame:SetFrameStrata("TOOLTIP")
                glowFrame:Show()
                
                if mainTexture then
                    mainTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
                    mainTexture:SetAllPoints()
                    mainTexture:SetVertexColor(0, 1, 1)
                    mainTexture:SetAlpha(1.0)
                    mainTexture:Show()
                else
                end
                
                
                C_Timer.After(10, function()
                    if glowFrame then
                        glowFrame:Hide()
                    end
                end)
            else
            end
            return true
        elseif arg1 == "db" then
            
            if ET and ET.db and ET.db.profile and ET.db.profile.cursorGlow then
                local dbET = ET.db.profile.cursorGlow
            else
            end
            
            if EpicTipDB and EpicTipDB.cursorGlow then
                local dbEpic = EpicTipDB.cursorGlow
            else
            end
            
            if EpicTipDB then
                if EpicTipDB.enabled ~= nil then
                end
            else
            end
            
            if glowFrame then
            end
            return true
        elseif arg1 == "cursor" then
            
            if not glowFrame then
                CursorGlow.Initialize()
            end
            
            if glowFrame then
                local db = CursorGlow.GetConfig()
                if not db then
                    if not EpicTipDB then EpicTipDB = {} end
                    if not EpicTipDB.cursorGlow then
                        EpicTipDB.cursorGlow = {
                            enabled = true,
                            texture = "Star1",
                            size = 64,
                            opacity = 1.0,
                            useClassColor = false,
                            color = { r = 0, g = 1, b = 1 }
                        }
                    end
                    db = EpicTipDB.cursorGlow
                end
                
                db.enabled = true
                
                mainTexture:SetVertexColor(0, 1, 1, 1)
                glowFrame:SetSize(64, 64)
                
                CursorGlow.StartTracking()
                
                C_Timer.After(15, function()
                    CursorGlow.StopTracking()
                    if glowFrame then glowFrame:Hide() end
                end)
            else
            end
            return true
        elseif arg1 == "clear" then
            
            CursorGlow.StopTracking()
            
            if glowFrame then
                glowFrame:Hide()
                glowFrame:ClearAllPoints()
                glowFrame:SetAlpha(0)
                glowFrame:SetSize(1, 1)
                
                if mainTexture then
                    mainTexture:Hide()
                    mainTexture:SetAlpha(0)
                    mainTexture:SetTexture(nil)
                end
                
            end
            
            -- Hide all tail textures
            for i, tailTexture in ipairs(tailTextures) do
                if tailTexture then
                    tailTexture:Hide()
                    tailTexture:SetAlpha(0)
                    tailTexture:ClearAllPoints()
                    tailTexture:SetTexture(nil)
                end
            end
            
            local stuckFrame = _G["ETCursorGlow"]
            if stuckFrame then
                stuckFrame:Hide()
                stuckFrame:SetAlpha(0)
                stuckFrame:SetSize(1, 1)
                stuckFrame:ClearAllPoints()
            end
            
            collectgarbage()
            
            return true
        elseif arg1 == "fresh" then
            
            if glowFrame then
                CursorGlow.StopTracking()
                glowFrame:Hide()
                glowFrame:SetParent(nil)
                glowFrame = nil
                mainTexture = nil
                
                for i, tailTexture in ipairs(tailTextures) do
                    if tailTexture then
                        tailTexture:Hide()
                        tailTexture:SetParent(nil)
                    end
                end
                wipe(tailTextures)
                wipe(tailPositions)
            end
            
            collectgarbage()
            
            CursorGlow.Initialize()
            
            if glowFrame then
                local db = CursorGlow.GetConfig()
                if not db then
                    if not EpicTipDB then EpicTipDB = {} end
                    if not EpicTipDB.cursorGlow then
                        EpicTipDB.cursorGlow = {
                            enabled = true,
                            texture = "Star1",
                            size = 64,
                            opacity = 1.0,
                            useClassColor = false,
                            color = { r = 1, g = 0, b = 1 }
                        }
                    end
                    db = EpicTipDB.cursorGlow
                end
                
                db.enabled = true
                
                if mainTexture then
                    mainTexture:SetVertexColor(1, 0, 1, 1)
                end
                glowFrame:SetSize(64, 64)
                
                CursorGlow.StartTracking()
                
                C_Timer.After(20, function()
                    CursorGlow.StopTracking()
                    if glowFrame then glowFrame:Hide() end
                end)
            else
            end
            return true
        elseif arg1 == "simple" then
            
            if not glowFrame then
                CursorGlow.Initialize()
            end
            
            if glowFrame and mainTexture then
                glowFrame:SetSize(64, 64)
                mainTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
                mainTexture:SetVertexColor(1, 1, 0, 0.8)
                
                glowFrame:Show()
                
                local simpleTimer = C_Timer.NewTicker(1/60, function()
                    if not glowFrame or not glowFrame:IsShown() then
                        return
                    end
                    
                    local x, y = GetCursorPosition()
                    local scale = UIParent:GetEffectiveScale()
                    
                    glowFrame:ClearAllPoints()
                    glowFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
                end)
                
                
                C_Timer.After(15, function()
                    if simpleTimer then
                        simpleTimer:Cancel()
                    end
                    if glowFrame then
                        glowFrame:Hide()
                    end
                end)
            else
            end
            return true
        end
    end
    return false
end

function CursorGlow.Refresh()
    local config = CursorGlow.GetConfig()
    if config and config.enabled then
        CursorGlow.Cleanup()
        CursorGlow.Initialize()
    else
        CursorGlow.Cleanup()
    end
end

function CursorGlow.GetConfig()
    if ET and ET.db and ET.db.profile and ET.db.profile.cursorGlow then
        return ET.db.profile.cursorGlow
    elseif EpicTipDB and EpicTipDB.cursorGlow then
        return EpicTipDB.cursorGlow
    end
    return nil
end

function CursorGlow.Cleanup()
    if CursorGlow.frame then
        CursorGlow.frame:Hide()
    end
    if CursorGlow.ticker then
        CursorGlow.ticker:Cancel()
        CursorGlow.ticker = nil
    end
    if CursorGlow.glowFrame then
        CursorGlow.glowFrame:Hide()
    end
end

if ET and ET.db then
    if ET.db.profile and ET.db.profile.cursorGlow and ET.db.profile.cursorGlow.enabled then
        CursorGlow.Initialize()
    end
else
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, event, addonName)
        if addonName == "EpicTip" and ET and ET.db and ET.db.profile then
            if ET.db.profile.cursorGlow and ET.db.profile.cursorGlow.enabled then
                CursorGlow.Initialize()
            end
            frame:UnregisterEvent("ADDON_LOADED")
            frame:SetScript("OnEvent", nil)
        end
    end)
end
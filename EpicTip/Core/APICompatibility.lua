local addonName, ET = ...

-- MEDIUM-05: Compact WoW API Compatibility Layer
-- Updated for Patch 12.0.1 Beta 6 (2026-01-14)
ET.APICompatibility = {
    features = {},
    isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
    isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC,
    isMists = WOW_PROJECT_ID == (WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5),
    gameVersion = tonumber((select(4, GetBuildInfo()))),

    DetectFeature = function(self, feature)
        if self.features[feature] ~= nil then return self.features[feature] end

        local available = false
        if feature == "TooltipDataProcessor" then
            available = TooltipDataProcessor ~= nil
        elseif feature == "Timer" then
            available = C_Timer ~= nil
        elseif feature == "ModernFonts" then
            available = CreateFont ~= nil
        elseif feature == "UnitToken" then
            available = UnitTokenFromGUID ~= nil
        elseif feature == "SecretValues" then
            -- Patch 12.0.0+ Secret Values system (Retail only)
            available = issecretvalue ~= nil and self.isRetail
        elseif feature == "NineSlice" then
            -- Modern tooltip borders (Retail 11.0+)
            available = self.isRetail and self.gameVersion >= 110000
        elseif feature == "C_MythicPlus" then
            -- Mythic+ system (Retail only)
            available = C_MythicPlus ~= nil and self.isRetail
        elseif feature == "C_PvP" then
            -- Modern PvP API (Retail only)
            available = C_PvP ~= nil and C_PvP.GetSeasonBestInfo ~= nil
        elseif feature == "MountJournal" then
            -- Mount collection API (Retail only)
            available = C_MountJournal ~= nil and self.isRetail
        elseif feature == "C_Item" then
            -- Modern item API (Retail 9.0+)
            available = C_Item ~= nil and C_Item.GetItemInfo ~= nil
        elseif feature == "InspectUnit" then
            -- Unit inspection (All versions but different APIs)
            available = CanInspect ~= nil
        elseif feature == "AuraBySpellID" then
            -- Patch 12.0.1 Pre-patch: GetUnitAuraBySpellID/GetPlayerAuraBySpellID fixed for non-secret spells
            available = GetUnitAuraBySpellID ~= nil and self.isRetail and self.gameVersion >= 120001
        elseif feature == "UnitHealPredictionCalculator" then
            -- Patch 12.0.1 Beta 6: New UnitHealPredictionCalculator APIs
            available = UnitHealPredictionCalculator ~= nil and self.isRetail and self.gameVersion >= 120001
        elseif feature == "TooltipLineTypes" then
            -- Patch 12.0.1: New tooltip line types (UsageRequirement, ItemQuality, ErrorLine, etc.)
            available = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.UsageRequirement ~= nil
        end

        self.features[feature] = available
        return available
    end,

    -- Patch 12.0.0+ Secret Values helper functions
    IsSecretValue = function(self, value)
        if self:DetectFeature("SecretValues") then
            return issecretvalue(value)
        end
        return false
    end,

    CanAccessSecrets = function(self)
        if self:DetectFeature("SecretValues") then
            return canaccesssecrets and canaccesssecrets()
        end
        return true -- Assume we can access if API not available
    end,

    SafeArithmetic = function(self, operation, a, b)
        -- Safely perform arithmetic operations that might involve secret values
        if self:DetectFeature("SecretValues") then
            if issecretvalue(a) or issecretvalue(b) then
                if EpicTipDB and EpicTipDB.debugMode then
                    print("EpicTip: Secret value detected in arithmetic operation")
                end
                return nil
            end
        end

        local success, result = pcall(function()
            if operation == "add" then
                return a + b
            elseif operation == "subtract" then
                return a - b
            elseif operation == "multiply" then
                return a * b
            elseif operation == "divide" then
                if b ~= 0 then
                    return a / b
                end
                return nil
            end
        end)

        return success and result or nil
    end,
    
    GetUnitFromGUID = function(self, guid)
        if self:DetectFeature("UnitToken") then
            return UnitTokenFromGUID(guid)
        else
            local tokens = {"player", "target", "focus", "mouseover"}
            for i = 1, 40 do
                table.insert(tokens, "party" .. i)
                table.insert(tokens, "raid" .. i)
            end
            for _, token in ipairs(tokens) do
                if UnitExists(token) and UnitGUID(token) == guid then
                    return token
                end
            end
        end
        return nil
    end,
    
    CreateFont = function(self, name)
        if self:DetectFeature("ModernFonts") then
            return CreateFont(name)
        else
            local font = CreateFrame("Frame"):CreateFontString()
            font:SetFontObject(GameFontNormal)
            return font
        end
    end,
    
    After = function(self, delay, callback)
        if self:DetectFeature("Timer") then
            C_Timer.After(delay, callback)
        else
            local frame = CreateFrame("Frame")
            local elapsed = 0
            frame:SetScript("OnUpdate", function(self, dt)
                elapsed = elapsed + dt
                if elapsed >= delay then
                    frame:SetScript("OnUpdate", nil)
                    callback()
                end
            end)
        end
    end,
    
    CreateTicker = function(self, interval, callback)
        if self:DetectFeature("Timer") then
            return C_Timer.NewTicker(interval, callback)
        else
            local frame = CreateFrame("Frame")
            local elapsed = 0
            frame:SetScript("OnUpdate", function(self, dt)
                elapsed = elapsed + dt
                if elapsed >= interval then
                    elapsed = 0
                    callback()
                end
            end)
            frame.Cancel = function() frame:SetScript("OnUpdate", nil) end
            return frame
        end
    end,
    
    -- Patch 12.0.1 Pre-patch: GetUnitAuraBySpellID wrapper (now fixed for non-secret spells)
    GetUnitAuraBySpellID = function(self, unit, spellID, filter)
        if self:DetectFeature("AuraBySpellID") then
            -- Use the now-fixed API directly
            local success, result = pcall(GetUnitAuraBySpellID, unit, spellID, filter)
            if success then
                return result
            end
        end
        -- Fallback to iteration method
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local auraIndex = 1
            while true do
                local auraData = C_UnitAuras.GetAuraDataByIndex(unit, auraIndex, filter or "HELPFUL")
                if not auraData then break end
                if auraData.spellId == spellID then
                    return auraData
                end
                auraIndex = auraIndex + 1
            end
        end
        return nil
    end,

    -- Patch 12.0.1 Pre-patch: GetPlayerAuraBySpellID wrapper (now fixed for non-secret spells)
    GetPlayerAuraBySpellID = function(self, spellID, filter)
        if self:DetectFeature("AuraBySpellID") and GetPlayerAuraBySpellID then
            local success, result = pcall(GetPlayerAuraBySpellID, spellID, filter)
            if success then
                return result
            end
        end
        -- Fallback to unit version
        return self:GetUnitAuraBySpellID("player", spellID, filter)
    end,

    Initialize = function(self)
        local module = self or ET.APICompatibility
        local features = {"TooltipDataProcessor", "Timer", "ModernFonts", "UnitToken", "SecretValues", "AuraBySpellID", "TooltipLineTypes"}
        for _, feature in ipairs(features) do
            module:DetectFeature(feature)
        end

        if EpicTipDB and EpicTipDB.debugMode then
            local clientType = module.isRetail and "Retail" or "Classic"
            print("EpicTip APICompat: Initialized for " .. clientType)
            if module.features["SecretValues"] then
                print("EpicTip APICompat: Secret Values system detected (Patch 12.0.0+)")
            end
            if module.features["AuraBySpellID"] then
                print("EpicTip APICompat: GetUnitAuraBySpellID/GetPlayerAuraBySpellID available (Patch 12.0.1+)")
            end
            if module.features["TooltipLineTypes"] then
                print("EpicTip APICompat: New tooltip line types detected (Patch 12.0.1+)")
            end
        end
    end,
    
    PrintStatus = function(self)
        local module = self or ET.APICompatibility
        print("|cFFFF0000Epic|r|cFF33CCFFTip|r API Compatibility")
        local available, total = 0, 0
        for feature, isAvailable in pairs(module.features) do
            total = total + 1
            if isAvailable then
                available = available + 1
                print(string.format("  |cFF00FF00✓|r %s", feature))
            else
                print(string.format("  |cFFFF0000✗|r %s (fallback)", feature))
            end
        end
        
        local compatibility = total > 0 and math.floor((available / total) * 100) or 100
        local color = compatibility >= 80 and "FF00FF00" or "FFFFFF00"
        print(string.format("Compatibility: |c%s%d%%|r", color, compatibility))
    end
}

ET.APICompatibility = ET.APICompatibility
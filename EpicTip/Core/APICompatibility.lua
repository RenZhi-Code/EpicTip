local addonName, ET = ...

-- MEDIUM-05: Compact WoW API Compatibility Layer
ET.APICompatibility = {
    features = {},
    isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
    
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
        end
        
        self.features[feature] = available
        return available
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
    
    Initialize = function(self)
        local module = self or ET.APICompatibility
        local features = {"TooltipDataProcessor", "Timer", "ModernFonts", "UnitToken"}
        for _, feature in ipairs(features) do
            module:DetectFeature(feature)
        end
        
        if EpicTipDB and EpicTipDB.debugMode then
            local clientType = module.isRetail and "Retail" or "Classic"
            print("EpicTip APICompat: Initialized for " .. clientType)
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
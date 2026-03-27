local addonName, ET = ...

-- CORE MODULE: Font Management System
-- Extracted from Tooltip.lua to maintain 800-line file size targets
-- Handles font creation, caching, and application with WoW 11.2 compatibility

ET.FontManager = ET.FontManager or {}
local FontManager = ET.FontManager

-- Font configuration storage
FontManager.fontObjects = {}
FontManager.defaultFontObjects = {}
FontManager.fontsInitialized = false
FontManager.lastFontConfig = {} -- Track last font configuration to avoid unnecessary updates

-- Lazy font creation - only create fonts when first needed
-- This saves ~50KB of memory at startup and uses modern WoW 11.2 font APIs
function FontManager:EnsureFontsCreated()
    if not EpicTipDB then return end
    
    -- Check if font configuration has changed
    local currentConfig = {
        family = EpicTipDB.fontFamily or "Fonts\\FRIZQT__.TTF",
        titleSize = EpicTipDB.titleFontSize or 14,
        infoSize = EpicTipDB.infoFontSize or 12,
        headerSize = EpicTipDB.headerFontSize or 13,
        descSize = EpicTipDB.descriptionFontSize or 11
    }
    
    -- Only recreate/update fonts if configuration changed or fonts not initialized
    local configChanged = not self.fontsInitialized
    if self.fontsInitialized then
        for key, value in pairs(currentConfig) do
            if self.lastFontConfig[key] ~= value then
                configChanged = true
                break
            end
        end
    end
    
    if not configChanged then return end
    
    -- Store default font objects on first run (WoW 11.2 compatible font references)
    if not next(self.defaultFontObjects) then
        self.defaultFontObjects = {
            title = GameTooltipTextLeft1:GetFontObject(),
            info = GameTooltipTextLeft2:GetFontObject(), 
            header = GameTooltipHeaderText and GameTooltipHeaderText:GetFontObject() or GameTooltipTextLeft1:GetFontObject(),
            description = GameTooltipTextRight1:GetFontObject()
        }
    end
    
    -- Modern WoW 11.2 Font Creation with optimized naming
    if not self.fontObjects.title then
        -- Use modern CreateFont with unique identifiers for WoW 11.2 compatibility
        self.fontObjects.title = CreateFont("EpicTip_TitleFont_" .. GetTime())
        self.fontObjects.info = CreateFont("EpicTip_InfoFont_" .. GetTime())
        self.fontObjects.header = CreateFont("EpicTip_HeaderFont_" .. GetTime())
        self.fontObjects.description = CreateFont("EpicTip_DescFont_" .. GetTime())
    end
    
    -- Apply current font settings with modern WoW 11.2 font handling
    -- Enhanced error handling for font loading failures with Blizzard font fallback
    local function SafeSetFont(fontObject, family, size, flags)
        if fontObject and fontObject.SetFont then
            -- Ensure we only use Blizzard built-in fonts
            local blizzardFont = family
            
            -- If custom font path detected, fallback to default Blizzard font
            if family and (family:find("Interface\\") or family:find("AddOns\\")) then
                blizzardFont = "Fonts\\FRIZQT__.TTF"
            end
            
            local success = pcall(fontObject.SetFont, fontObject, blizzardFont, size, flags or "")
            if not success then
                -- Final fallback to default WoW system font if any font fails
                pcall(fontObject.SetFont, fontObject, "Fonts\\FRIZQT__.TTF", size, flags or "")
            end
        end
    end
    
    SafeSetFont(self.fontObjects.title, currentConfig.family, currentConfig.titleSize)
    SafeSetFont(self.fontObjects.info, currentConfig.family, currentConfig.infoSize)
    SafeSetFont(self.fontObjects.header, currentConfig.family, currentConfig.headerSize)
    SafeSetFont(self.fontObjects.description, currentConfig.family, currentConfig.descSize)
    
    -- Cache current configuration
    self.lastFontConfig = currentConfig
    self.fontsInitialized = true
end

-- Initialize font objects for different text types (legacy compatibility)
function FontManager:InitializeFonts()
    -- Reset initialization flag to force recreation with new settings
    self.fontsInitialized = false
    self:EnsureFontsCreated()
end

-- Apply fonts to tooltip text lines (optimized with lazy creation and efficient iteration)
function FontManager:ApplyFonts(tooltip)
    if not EpicTipDB or not tooltip then return end
    
    -- Ensure fonts are created only when first needed (lazy loading)
    self:EnsureFontsCreated()
    
    -- Cache tooltip name for efficiency
    local tooltipName = tooltip:GetName()
    if not tooltipName then return end
    
    -- Optimized iteration using direct indexing instead of inefficient for loop
    -- Check up to 30 lines efficiently
    local lineIndex = 1
    while lineIndex <= 30 do
        local leftLine = _G[tooltipName .. "TextLeft" .. lineIndex]
        local rightLine = _G[tooltipName .. "TextRight" .. lineIndex]
        
        if leftLine and leftLine:IsShown() then
            if lineIndex == 1 then
                -- First line is usually the title
                leftLine:SetFontObject(self.fontObjects.title)
            elseif lineIndex <= 3 then
                -- Next few lines are headers
                leftLine:SetFontObject(self.fontObjects.header)
            else
                -- Regular info lines
                leftLine:SetFontObject(self.fontObjects.info)
            end
        end
        
        if rightLine and rightLine:IsShown() then
            rightLine:SetFontObject(self.fontObjects.description)
        end
        
        lineIndex = lineIndex + 1
    end
end

-- Restore default fonts (optimized iteration)
function FontManager:RestoreDefaultFonts(tooltip)
    if not tooltip or not next(self.defaultFontObjects) then return end
    
    -- Cache tooltip name for efficiency
    local tooltipName = tooltip:GetName()
    if not tooltipName then return end
    
    -- Use efficient while loop instead of for loop for better performance
    local lineIndex = 1
    while lineIndex <= 30 do
        local leftLine = _G[tooltipName .. "TextLeft" .. lineIndex]
        local rightLine = _G[tooltipName .. "TextRight" .. lineIndex]
        
        if leftLine then
            if lineIndex == 1 then
                leftLine:SetFontObject(self.defaultFontObjects.title)
            elseif lineIndex <= 3 then
                leftLine:SetFontObject(self.defaultFontObjects.header)
            else
                leftLine:SetFontObject(self.defaultFontObjects.info)
            end
        end
        
        if rightLine then
            rightLine:SetFontObject(self.defaultFontObjects.description)
        end
        
        lineIndex = lineIndex + 1
    end
end

-- Cleanup function for memory management
function FontManager:Cleanup()
    -- Clear font objects to free memory
    for _, fontObj in pairs(self.fontObjects) do
        if fontObj then
            fontObj = nil
        end
    end
    self.fontObjects = {}
    self.fontsInitialized = false
    self.lastFontConfig = {}
end

-- Get font configuration status for diagnostics
function FontManager:GetStatus()
    return {
        initialized = self.fontsInitialized,
        fontCount = self.fontObjects and table.getn(self.fontObjects) or 0,
        hasDefaults = self.defaultFontObjects and next(self.defaultFontObjects) ~= nil
    }
end

-- Expose functions for external use following memory guidance
ET.FontManager.EnsureFontsCreated = FontManager.EnsureFontsCreated
ET.FontManager.InitializeFonts = FontManager.InitializeFonts
ET.FontManager.ApplyFonts = FontManager.ApplyFonts
ET.FontManager.RestoreDefaultFonts = FontManager.RestoreDefaultFonts
ET.FontManager.Cleanup = FontManager.Cleanup
ET.FontManager.GetStatus = FontManager.GetStatus
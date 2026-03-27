local addonName, ET = ...

-- EVENTS MODULE: Event handlers for EpicTip
-- Extracted from Core.lua to maintain 800-line file size targets
-- Handles all WoW event processing with error protection

local function IsSecretValue(value)
    if not issecretvalue then return false end
    local ok, res = pcall(issecretvalue, value)
    return ok and res or false
end

local function SafeGetUnit(tooltip)
    if not tooltip or not tooltip.GetUnit then return nil end
    local ok, _, unit = pcall(tooltip.GetUnit, tooltip)
    if not ok or not unit or IsSecretValue(unit) then return nil end
    return unit
end

local function SafeGetItemLink(tooltip)
    if not tooltip or not tooltip.GetItem then return nil end
    local ok, _, itemLink = pcall(tooltip.GetItem, tooltip)
    if not ok or not itemLink or IsSecretValue(itemLink) then return nil end
    return itemLink
end

local function TooltipHasSpell(tooltip)
    if not tooltip or not tooltip.GetSpell then return false end

    -- GetSpell() returns (name, rank, spellID) on most builds; be tolerant.
    local ok, spellName, _, spellId = pcall(tooltip.GetSpell, tooltip)
    if not ok then return false end

    if spellId and not IsSecretValue(spellId) then return true end
    if spellName and not IsSecretValue(spellName) then return true end
    return false
end

-- Event handlers for tooltip functionality
function ET:INSPECT_READY(event, guid)
    -- MEDIUM-02: Protected event handler with error recovery
    if ET.ErrorHandler then
        ET.ErrorHandler.ProtectedEventHandler("INSPECT_READY", function()
            if guid and GameTooltip:IsShown() then
                local unit = SafeGetUnit(GameTooltip)
                if unit and UnitGUID(unit) == guid then
                    -- Refresh tooltip with new inspect data
                    if ET.Tooltip and ET.Tooltip.ProcessUnitTooltip then
                        ET.Tooltip.ProcessUnitTooltip(GameTooltip, unit)
                    end
                end
            end
        end)
    else
        -- Legacy fallback without error protection
        if guid and GameTooltip:IsShown() then
            local unit = SafeGetUnit(GameTooltip)
            if unit and UnitGUID(unit) == guid then
                -- Refresh tooltip with new inspect data
                if ET.Tooltip and ET.Tooltip.ProcessUnitTooltip then
                    ET.Tooltip.ProcessUnitTooltip(GameTooltip, unit)
                end
            end
        end
    end
end

function ET:INSPECT_HONOR_UPDATE()
    -- Fires when RequestInspectHonorData() returns data
    -- Cache the arena ratings and refresh tooltip if shown
    if ET.PvPInfo and ET.PvPInfo.OnInspectHonorUpdate then
        ET.PvPInfo.OnInspectHonorUpdate()
    end
    -- Also let Tooltip module handle it for refresh
    if ET.Tooltip and ET.Tooltip.OnInspectHonorUpdate then
        ET.Tooltip.OnInspectHonorUpdate()
    end
end

function ET:PLAYER_TARGET_CHANGED()
    -- MEDIUM-02: Protected event handler with error recovery
    if ET.ErrorHandler then
        ET.ErrorHandler.ProtectedEventHandler("PLAYER_TARGET_CHANGED", function()
            -- Clear any cached data when target changes
            if ET.Utils and ET.Utils.OnTargetChanged then
                ET.Utils:OnTargetChanged()
            end
        end)
    else
        -- Legacy fallback without error protection
        if ET.Utils and ET.Utils.OnTargetChanged then
            ET.Utils:OnTargetChanged()
        end
    end
end

function ET:UPDATE_MOUSEOVER_UNIT()
    -- Handle mouseover unit changes for tooltips
    if not EpicTipDB or not EpicTipDB.enabled then 
        if EpicTipDB and EpicTipDB.debugMode then
            print("EpicTip: UPDATE_MOUSEOVER_UNIT - Addon disabled")
        end
        return 
    end
    
    if EpicTipDB.debugMode then
        print("EpicTip: UPDATE_MOUSEOVER_UNIT triggered")
        print("  GameTooltip shown:", GameTooltip:IsShown())
    end
    
    -- Only process if GameTooltip is shown and has been stable for a moment
    if not GameTooltip:IsShown() then 
        if EpicTipDB.debugMode then
            print("  GameTooltip not shown, skipping")
        end
        return 
    end
    
    local unit = SafeGetUnit(GameTooltip)
    if EpicTipDB.debugMode then
        if unit then
            print("  Tooltip unit:", unit, "(", UnitName(unit) or "Unknown", ")")
            print("  Unit exists:", UnitExists(unit))
            print("  Unit is player:", UnitIsPlayer(unit))
        else
            print("  No tooltip unit found")
        end
    end
    
    if unit and UnitExists(unit) and UnitIsPlayer(unit) then
        -- Check if tooltip already has EpicTip enhancements
        local nameLine = _G["GameTooltipTextLeft1"]
        if nameLine then
            local okText, nameText = pcall(nameLine.GetText, nameLine)
            if EpicTipDB.debugMode then
                print("  Name line text:", (okText and nameText) or "nil")
                print("  Has class icon:", okText and nameText and not IsSecretValue(nameText) and nameText:find("Interface\\Icons\\ClassIcon_") ~= nil)
            end
            if okText and nameText and not IsSecretValue(nameText) and not nameText:find("Interface\\Icons\\ClassIcon_") then
                if EpicTipDB.debugMode then
                    print("  Processing needed - adding timer for", UnitName(unit) or "Unknown")
                end
                -- Delay processing to avoid conflicts
                local timerFunc = function()
                    if GameTooltip:IsShown() then
                        local currentUnit = SafeGetUnit(GameTooltip)
                        if currentUnit == unit and UnitIsPlayer(unit) then
                            if EpicTipDB.debugMode then
                                print("EpicTip: UPDATE_MOUSEOVER_UNIT processing", UnitName(unit) or "Unknown")
                            end
                            
                            if ET.Tooltip and ET.Tooltip.ProcessUnitTooltip then
                                ET.Tooltip.ProcessUnitTooltip(GameTooltip, unit)
                                if EpicTipDB.debugMode then
                                    print("  Processing completed successfully")
                                end
                            else
                                if EpicTipDB.debugMode then
                                    print("  ERROR: ET.Tooltip or ProcessUnitTooltip not available")
                                end
                            end
                        else
                            if EpicTipDB.debugMode then
                                print("  Timer: Unit changed or tooltip hidden, skipping")
                            end
                        end
                    else
                        if EpicTipDB.debugMode then
                            print("  Timer: GameTooltip no longer shown, skipping")
                        end
                    end
                end
                
                if ET.ResourceTracker and ET.ResourceTracker.CreateTrackedTimer then
                    ET.ResourceTracker:CreateTrackedTimer(0.1, timerFunc, "UPDATE_MOUSEOVER_UNIT_delay")
                elseif ET.APICompatibility and ET.APICompatibility.After then
                    ET.APICompatibility:After(0.1, timerFunc)
                else
                    C_Timer.After(0.1, timerFunc)
                end
            else
                if EpicTipDB.debugMode then
                    print("  Already processed or no name text, skipping")
                end
            end
        else
            if EpicTipDB.debugMode then
                print("  No name line found in tooltip")
            end
        end
    else
        if EpicTipDB.debugMode then
            print("  Not a valid player unit, skipping")
        end
    end
end

function ET:MODIFIER_STATE_CHANGED(key, down)
    -- Handle modifier key changes that might affect tooltips (optimized for speed)
    if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" then
        if GameTooltip:IsShown() then
            local unit = SafeGetUnit(GameTooltip)
            if unit and UnitExists(unit) then
                -- Refresh unit tooltip when modifiers change
                pcall(GameTooltip.SetUnit, GameTooltip, unit)
            else
                -- Optimized item tooltip refresh for instant response
                local itemLink = SafeGetItemLink(GameTooltip)
                if itemLink then
                    -- Use immediate refresh without delay
                    pcall(GameTooltip.ClearLines, GameTooltip)
                    pcall(GameTooltip.SetHyperlink, GameTooltip, itemLink)
                    pcall(GameTooltip.Show, GameTooltip)
                    
                    if EpicTipDB and EpicTipDB.debugMode then
                        print("EpicTip Debug: Instant modifier", key, "refresh for item tooltip")
                    end
                end
            end
        end
        
        -- Optimized handling for other tooltips with immediate refresh
        local tooltipsToRefresh = {
            {tooltip = ItemRefTooltip, name = "ItemRefTooltip"},
            {tooltip = ShoppingTooltip1, name = "ShoppingTooltip1"},
            {tooltip = ShoppingTooltip2, name = "ShoppingTooltip2"}
        }
        
        for _, tooltipInfo in ipairs(tooltipsToRefresh) do
            local tooltip = tooltipInfo.tooltip
            if tooltip and tooltip:IsShown() then
                local itemLink = SafeGetItemLink(tooltip)
                if itemLink then
                    pcall(tooltip.ClearLines, tooltip)
                    pcall(tooltip.SetHyperlink, tooltip, itemLink)
                    pcall(tooltip.Show, tooltip)
                end
            end
        end
    end
end

-- Backup tooltip hooks for when TooltipDataProcessor doesn't work as expected
function ET:SetupBackupTooltipHooks()
    if not GameTooltip then return end
    
    if EpicTipDB.debugMode then
        print("EpicTip: Setting up backup tooltip hooks")
    end
    
    -- Backup hook for GameTooltip OnShow
    -- CRITICAL: All tooltip modifications MUST be deferred to avoid tainting
    -- Blizzard's secure tooltip processing chain. SetWatch on the health bar
    -- will fail with "Lua Taint: EpicTip" if we modify during the secure chain.
    GameTooltip:HookScript("OnShow", function(self)
        if not EpicTipDB or not EpicTipDB.enabled then return end
        
        -- Skip World Quest tooltips to prevent interference
        if ET.Tooltip and ET.Tooltip.IsWorldQuestTooltip and ET.Tooltip.IsWorldQuestTooltip(self) then return end

        -- Defer ALL modifications to next frame to avoid taint
        C_Timer.After(0, function()
            if not self:IsShown() then return end
            pcall(function()
                local isSpellTooltip = TooltipHasSpell(self)
                local unit = (not isSpellTooltip) and SafeGetUnit(self) or nil

                -- Apply basic styling to ALL tooltips (items, NPCs, units, spells, etc.)
                local scale = EpicTipDB.scale or 1.0
                self:SetScale(scale)

                -- Apply background and border styling (only pass unit for real unit tooltips)
                if ET.TooltipStyling then
                    ET.TooltipStyling:ApplyAdvancedStyling(self, unit)
                end

                -- Apply fonts
                if ET.FontManager and ET.FontManager.ApplyFonts then
                    ET.FontManager:ApplyFonts(self)
                end

                -- Apply max width wrapping
                if ET.Tooltip and ET.Tooltip.ApplyMaxWidthAndWrap then
                    ET.Tooltip:ApplyMaxWidthAndWrap(self)
                end

                -- Process unit tooltips (players, NPCs) - avoid spell/aura tooltips with a unit
                if unit and UnitExists(unit) and not isSpellTooltip then
                    if ET.Tooltip and ET.Tooltip.ProcessUnitTooltip then
                        ET.Tooltip.ProcessUnitTooltip(self, unit)
                    end
                end

                -- Process item tooltips
                local itemLink = SafeGetItemLink(self)
                if itemLink and ET.ItemInfo and ET.ItemInfo.ProcessItemTooltip and EpicTipDB.showItemInfo then
                    ET.ItemInfo:ProcessItemTooltip(self)
                end
            end)
        end)

        -- Additional delayed backup to catch cases where unit info isn't ready immediately
        C_Timer.After(0.01, function()
            pcall(function()
                if not self:IsShown() then 
                    if EpicTipDB.debugMode then
                        print("EpicTip: OnShow timer - Tooltip no longer shown")
                    end
                    return 
                end

                if TooltipHasSpell(self) then return end

                local delayedUnit = SafeGetUnit(self)
                if delayedUnit and UnitExists(delayedUnit) and UnitIsPlayer(delayedUnit) then
                    -- Check if EpicTip processing already happened by looking for class icons
                    local nameLine = _G["GameTooltipTextLeft1"]
                    if nameLine and nameLine.GetText then
                        local ok, nameText = pcall(nameLine.GetText, nameLine)
                        if ok and nameText and not IsSecretValue(nameText) and not nameText:find("Interface\\Icons\\ClassIcon_") then
                            -- No class icon found, process with EpicTip
                            if ET.Tooltip and ET.Tooltip.ProcessUnitTooltip then
                                if EpicTipDB.debugMode then
                                    print("EpicTip: Delayed backup processing for", UnitName(delayedUnit) or "Unknown")
                                end
                                ET.Tooltip.ProcessUnitTooltip(self, delayedUnit)
                            else
                                if EpicTipDB.debugMode then
                                    print("EpicTip: Timer - ET.Tooltip or ProcessUnitTooltip not available")
                                end
                            end
                        else
                            if EpicTipDB.debugMode then
                                print("EpicTip: Timer - Already processed, secret text, or no text found")
                            end
                        end
                    else
                        if EpicTipDB.debugMode then
                            print("EpicTip: Timer - No name line found")
                        end
                    end
                end
            end)
        end)
    end)
    
    -- Additional fallback: Hook GameTooltip_SetDefaultAnchor for cases where OnShow doesn't catch it
    -- CRITICAL FIX: Add existence check to prevent nil reference errors in older clients
    if GameTooltip_SetDefaultAnchor then
        hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
            if tooltip == GameTooltip and EpicTipDB and EpicTipDB.enabled then
                -- Skip World Quest tooltips to prevent interference
                if ET.Tooltip and ET.Tooltip.IsWorldQuestTooltip and ET.Tooltip.IsWorldQuestTooltip(tooltip) then return end
                
                -- Small delay to let the tooltip populate
                C_Timer.After(0.05, function()
                    if tooltip:IsShown() then
                        if TooltipHasSpell(tooltip) then return end
                        local unit = SafeGetUnit(tooltip)
                        if unit and UnitExists(unit) and UnitIsPlayer(unit) then
                            if EpicTipDB.debugMode then
                                print("EpicTip: GameTooltip_SetDefaultAnchor fallback processing for", UnitName(unit) or "Unknown")
                            end
                            
                            -- Check if already processed
                            local nameLine = _G["GameTooltipTextLeft1"]
                            if nameLine then
                                local ok, nameText = pcall(nameLine.GetText, nameLine)
                                if ok and nameText and not IsSecretValue(nameText) and not nameText:find("Interface\\Icons\\ClassIcon_") then
                                    if ET.Tooltip and ET.Tooltip.ProcessUnitTooltip then
                                        ET.Tooltip.ProcessUnitTooltip(tooltip, unit)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end)
        
        if EpicTipDB.debugMode then
            print("EpicTip: GameTooltip_SetDefaultAnchor fallback hook installed")
        end
    else
        if EpicTipDB and EpicTipDB.debugMode then
            print("EpicTip: GameTooltip_SetDefaultAnchor not available - backup hooks only")
        end
    end
    
    if EpicTipDB.debugMode then
        print("EpicTip: Enhanced backup tooltip hooks initialized (WoW 11.2 compatible)")
    end
end

local addonName, ET = ...

-- EVENTS MODULE: Event handlers for EpicTip
-- Extracted from Core.lua to maintain 800-line file size targets
-- Handles all WoW event processing with error protection

-- Event handlers for tooltip functionality
function ET:INSPECT_READY(event, guid)
    -- MEDIUM-02: Protected event handler with error recovery
    if ET.ErrorHandler then
        ET.ErrorHandler.ProtectedEventHandler("INSPECT_READY", function()
            if guid and GameTooltip:IsShown() then
                local _, unit = GameTooltip:GetUnit()
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
            local _, unit = GameTooltip:GetUnit()
            if unit and UnitGUID(unit) == guid then
                -- Refresh tooltip with new inspect data
                if ET.Tooltip and ET.Tooltip.ProcessUnitTooltip then
                    ET.Tooltip.ProcessUnitTooltip(GameTooltip, unit)
                end
            end
        end
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
    
    local _, unit = GameTooltip:GetUnit()
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
            local nameText = nameLine:GetText()
            if EpicTipDB.debugMode then
                print("  Name line text:", nameText or "nil")
                print("  Has class icon:", nameText and nameText:find("Interface\\Icons\\ClassIcon_") ~= nil)
            end
            if nameText and not nameText:find("Interface\\Icons\\ClassIcon_") then
                if EpicTipDB.debugMode then
                    print("  Processing needed - adding timer for", UnitName(unit) or "Unknown")
                end
                -- Delay processing to avoid conflicts
                local timerFunc = function()
                    if GameTooltip:IsShown() then
                        local _, currentUnit = GameTooltip:GetUnit()
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
            local _, unit = GameTooltip:GetUnit()
            if unit and UnitExists(unit) then
                -- Refresh unit tooltip when modifiers change
                GameTooltip:SetUnit(unit)
            else
                -- Optimized item tooltip refresh for instant response
                local itemName, itemLink = GameTooltip:GetItem()
                if itemLink then
                    -- Use immediate refresh without delay
                    GameTooltip:ClearLines()
                    GameTooltip:SetHyperlink(itemLink)
                    GameTooltip:Show()
                    
                    if EpicTipDB and EpicTipDB.debugMode then
                        print("EpicTip Debug: Instant modifier", key, "refresh for", itemName or "Unknown Item")
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
                local itemName, itemLink = tooltip:GetItem()
                if itemLink then
                    tooltip:ClearLines()
                    tooltip:SetHyperlink(itemLink)
                    tooltip:Show()
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
    
    -- Aggressive hook for GameTooltip OnShow to catch missed tooltips
    GameTooltip:HookScript("OnShow", function(self)
        if EpicTipDB.debugMode then
            print("EpicTip: OnShow hook triggered")
        end
        
        -- Immediate processing attempt
        local _, unit = self:GetUnit()
        if unit and UnitExists(unit) and UnitIsPlayer(unit) then
            if ET.Tooltip and ET.Tooltip.ProcessUnitTooltip then
                if EpicTipDB.debugMode then
                    print("EpicTip: Immediate OnShow processing for", UnitName(unit) or "Unknown")
                end
                ET.Tooltip.ProcessUnitTooltip(self, unit)
            else
                if EpicTipDB.debugMode then
                    print("EpicTip: OnShow - ET.Tooltip or ProcessUnitTooltip not available")
                end
            end
        else
            if EpicTipDB.debugMode then
                if unit then
                    print("EpicTip: OnShow - Unit is not a player:", unit, UnitName(unit) or "Unknown")
                else
                    print("EpicTip: OnShow - No unit found")
                end
            end
        end
        
        -- Also add a small delay backup to catch cases where unit info isn't ready immediately
        C_Timer.After(0.01, function()
            if not self:IsShown() then 
                if EpicTipDB.debugMode then
                    print("EpicTip: OnShow timer - Tooltip no longer shown")
                end
                return 
            end
            
            local _, delayedUnit = self:GetUnit()
            if delayedUnit and UnitExists(delayedUnit) and UnitIsPlayer(delayedUnit) then
                -- Check if EpicTip processing already happened by looking for class icons
                local nameLine = _G["GameTooltipTextLeft1"]
                if nameLine then
                    local nameText = nameLine:GetText()
                    if nameText and not nameText:find("Interface\\Icons\\ClassIcon_") then
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
                            print("EpicTip: Timer - Already processed or no text found")
                        end
                    end
                else
                    if EpicTipDB.debugMode then
                        print("EpicTip: Timer - No name line found")
                    end
                end
            else
                if EpicTipDB.debugMode then
                    if delayedUnit then
                        print("EpicTip: Timer - Unit is not a player:", delayedUnit, UnitName(delayedUnit) or "Unknown")
                    else
                        print("EpicTip: Timer - No delayed unit found")
                    end
                end
            end
        end)
    end)
    
    -- Additional fallback: Hook GameTooltip_SetDefaultAnchor for cases where OnShow doesn't catch it
    -- CRITICAL FIX: Add existence check to prevent nil reference errors in older clients
    if GameTooltip_SetDefaultAnchor then
        hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
            if tooltip == GameTooltip and EpicTipDB and EpicTipDB.enabled then
                -- Small delay to let the tooltip populate
                C_Timer.After(0.05, function()
                    if tooltip:IsShown() then
                        local _, unit = tooltip:GetUnit()
                        if unit and UnitExists(unit) and UnitIsPlayer(unit) then
                            if EpicTipDB.debugMode then
                                print("EpicTip: GameTooltip_SetDefaultAnchor fallback processing for", UnitName(unit) or "Unknown")
                            end
                            
                            -- Check if already processed
                            local nameLine = _G["GameTooltipTextLeft1"]
                            if nameLine then
                                local nameText = nameLine:GetText()
                                if nameText and not nameText:find("Interface\\Icons\\ClassIcon_") then
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
local addonName, ET = ...

-- Only load German translations if the client is set to German
if GetLocale() ~= "deDE" then
    return
end

ET.L = ET.L or {}
local L = ET.L

-- German Localization
L["Just the Tip"] = "Nur die Spitze"
L["Options"] = "Optionen"
L["Enable Tooltip"] = "Tooltip aktivieren"
L["Show Item Level"] = "Gegenstandsstufe anzeigen"
L["Show Target"] = "Ziel anzeigen"
L["Show Specialization"] = "Spezialisierung anzeigen"
L["Anchor Tooltip to Mouse Cursor"] = "Tooltip an Mauszeiger verankern"
L["Hide Tooltip Health Bar"] = "Tooltip-Gesundheitsleiste ausblenden"
L["Hide Tooltip In Combat"] = "Tooltip im Kampf ausblenden"
L["Show Class Icon"] = "Klassensymbol anzeigen"
L["Show Role Icon"] = "Rollensymbol anzeigen"
L["Show Mythic+ Rating"] = "Mythic+ Wertung anzeigen"
L["Show PvP Rating"] = "PvP-Wertung anzeigen"
L["Show Item Info"] = "Gegenstandsinfo anzeigen"
L["Show Stat Values"] = "Attributwerte anzeigen"
L["Highlight Grey Items (Ctrl)"] = "Graue Gegenstände hervorheben (Strg)"
L["Debug Mode"] = "Debug-Modus"
L["Tooltip Scale"] = "Tooltip-Skalierung"
L["Target:"] = "Ziel:"
L["Specialization:"] = "Spezialisierung:"
L["Role:"] = "Rolle:"
L["Mythic+ Rating:"] = "Mythic+ Wertung:"
L["PvP Rating:"] = "PvP-Wertung:"
L["Item Level:"] = "Gegenstandsstufe:"
L["GUID:"] = "GUID:"
L["Unit ID:"] = "Einheiten-ID:"
L["Class ID:"] = "Klassen-ID:"
L["Spec ID:"] = "Spezialisierungs-ID:"
L["Inspect cooldown active"] = "Inspizieren-Abklingzeit aktiv"
L["Source:"] = "Quelle:"
L["Type:"] = "Typ:"
L["Subtype:"] = "Untertyp:"
L["Slot:"] = "Platz:"
L["Stack:"] = "Stapel:"
L["Vendor Price:"] = "Händlerpreis:"
L["Mount Type:"] = "Reittiertyp:"
L["Status:"] = "Status:"
L["Faction:"] = "Fraktion:"

-- New Configuration Keys (Translation needed)
-- General Configuration
L["General"] = "General" -- TODO: Translate
L["Features"] = "Features" -- TODO: Translate
L["Enable EpicTip"] = "Enable EpicTip" -- TODO: Translate
L["Overall size of tooltips"] = "Overall size of tooltips" -- TODO: Translate
L["Competitive"] = "Competitive" -- TODO: Translate
L["Mythic+ Display Format"] = "Mythic+ Display Format" -- TODO: Translate
L["Mount Information"] = "Mount Information" -- TODO: Translate

-- Ring Configuration
L["Ring Configuration"] = "Ring Configuration" -- TODO: Translate
L["Cursor Glow Effects"] = "Cursor Glow Effects" -- TODO: Translate
L["Tail Effects"] = "Tail Effects" -- TODO: Translate
L["Pulse Effects"] = "Pulse Effects" -- TODO: Translate
L["Click Effects"] = "Click Effects" -- TODO: Translate
L["Combat Settings"] = "Combat Settings" -- TODO: Translate

-- Appearance Configuration
L["Appearance"] = "Appearance" -- TODO: Translate
L["Background"] = "Background" -- TODO: Translate
L["Border"] = "Border" -- TODO: Translate
L["Text Filtering"] = "Text Filtering" -- TODO: Translate
L["Font Configuration"] = "Font Configuration" -- TODO: Translate

-- TrueStat Configuration
L["Enhanced Item Analysis and True Stat Values"] = "Enhanced Item Analysis and True Stat Values" -- TODO: Translate
L["Item Information"] = "Item Information" -- TODO: Translate
L["True Stat Values"] = "True Stat Values" -- TODO: Translate
L["Advanced Options"] = "Advanced Options" -- TODO: Translate

-- Player Info Configuration
L["Player Information Display"] = "Player Information Display" -- TODO: Translate
L["Player Info Display Options"] = "Player Info Display Options" -- TODO: Translate

-- Debug and Status Messages
L["Loading"] = "Laden"
L["Loaded"] = "Geladen"
L["Enabled"] = "Aktiviert"
L["Disabled"] = "Deaktiviert"
L["Error"] = "Fehler"
L["Warning"] = "Warnung"
L["Ready"] = "Bereit"

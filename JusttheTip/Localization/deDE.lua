local addonName, JTT = ...

-- Only load German translations if the client is set to German
if GetLocale() ~= "deDE" then
    return
end

JTT.L = JTT.L or {}
local L = JTT.L

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

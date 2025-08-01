local addonName, JTT = ...

-- Only load French translations if the client is set to French
if GetLocale() ~= "frFR" then
    return
end

JTT.L = JTT.L or {}
local L = JTT.L

-- French Localization
L["Just the Tip"] = "Juste le conseil"
L["Options"] = "Options"
L["Enable Tooltip"] = "Activer l'info-bulle"
L["Show Item Level"] = "Afficher le niveau d'objet"
L["Show Target"] = "Afficher la cible"
L["Show Specialization"] = "Afficher la spécialisation"
L["Anchor Tooltip to Mouse Cursor"] = "Ancrer l'info-bulle au curseur de la souris"
L["Hide Tooltip Health Bar"] = "Masquer la barre de vie de l'info-bulle"
L["Hide Tooltip In Combat"] = "Masquer l'info-bulle en combat"
L["Show Class Icon"] = "Afficher l'icône de classe"
L["Show Role Icon"] = "Afficher l'icône de rôle"
L["Show Mythic+ Rating"] = "Afficher le classement Mythic+"
L["Show PvP Rating"] = "Afficher le classement JcJ"
L["Show Item Info"] = "Afficher les informations sur les objets"
L["Show Stat Values"] = "Afficher les valeurs des statistiques"
L["Highlight Grey Items (Ctrl)"] = "Mettre en surbrillance les objets gris (Ctrl)"
L["Debug Mode"] = "Mode débogage"
L["Tooltip Scale"] = "Échelle de l'info-bulle"
L["Target:"] = "Cible :"
L["Specialization:"] = "Spécialisation :"
L["Role:"] = "Rôle :"
L["Mythic+ Rating:"] = "Classement Mythic+ :"
L["PvP Rating:"] = "Classement JcJ :"
L["Item Level:"] = "Niveau d'objet :"
L["GUID:"] = "GUID :"
L["Unit ID:"] = "ID d'unité :"
L["Class ID:"] = "ID de classe :"
L["Spec ID:"] = "ID de spécialisation :"
L["Inspect cooldown active"] = "Temps de recharge d'inspection actif"
L["Source:"] = "Source :"
L["Type:"] = "Type :"
L["Subtype:"] = "Sous-type :"
L["Slot:"] = "Emplacement :"
L["Stack:"] = "Pile :"
L["Vendor Price:"] = "Prix du vendeur :"
L["Mount Type:"] = "Type de monture :"
L["Status:"] = "Statut :"
L["Faction:"] = "Faction :"

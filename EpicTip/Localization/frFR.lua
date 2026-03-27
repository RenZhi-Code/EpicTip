local addonName, ET = ...

-- Only load French translations if the client is set to French
if GetLocale() ~= "frFR" then
    return
end

ET.L = ET.L or {}
local L = ET.L

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

-- New Configuration Keys (Translation needed)
-- General Configuration
L["General"] = "Général"
L["Features"] = "Fonctionnalités"
L["Enable EpicTip"] = "Activer EpicTip"
L["Overall size of tooltips"] = "Overall size of tooltips" -- TODO: Translate
L["Competitive"] = "Compétitif"
L["Mythic+ Display Format"] = "Format d'affichage Mythique+"
L["Mount Information"] = "Informations de monture"

-- Ring Configuration
L["Ring Configuration"] = "Configuration de l'anneau"
L["Cursor Glow Effects"] = "Effets de lueur du curseur"
L["Tail Effects"] = "Effets de queue"
L["Pulse Effects"] = "Effets de pulsation"
L["Click Effects"] = "Effets de clic"
L["Combat Settings"] = "Paramètres de combat"

-- Appearance Configuration
L["Appearance"] = "Apparence"
L["Background"] = "Arrière-plan"
L["Border"] = "Bordure"
L["Text Filtering"] = "Filtrage de texte"
L["Font Configuration"] = "Configuration de police"

-- TrueStat Configuration
L["Enhanced Item Analysis and True Stat Values"] = "Enhanced Item Analysis and True Stat Values" -- TODO: Translate
L["Item Information"] = "Informations d'objet"
L["True Stat Values"] = "Vraies valeurs de statistiques"
L["Advanced Options"] = "Options avancées"

-- Player Info Configuration
L["Player Information Display"] = "Affichage des informations du joueur"
L["Player Info Display Options"] = "Options d'affichage des infos joueur"

-- Debug and Status Messages
L["Loading"] = "Chargement"
L["Loaded"] = "Chargé"
L["Enabled"] = "Activé"
L["Disabled"] = "Désactivé"
L["Error"] = "Erreur"
L["Warning"] = "Avertissement"
L["Ready"] = "Prêt"

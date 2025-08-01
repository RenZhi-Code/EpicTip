local addonName, JTT = ...

-- Only load Spanish translations if the client is set to Spanish
if GetLocale() ~= "esES" and GetLocale() ~= "esMX" then
    return
end

JTT.L = JTT.L or {}
local L = JTT.L

-- Spanish Localization
L["Just the Tip"] = "Solo el consejo"
L["Options"] = "Opciones"
L["Enable Tooltip"] = "Habilitar descripción emergente"
L["Show Item Level"] = "Mostrar nivel de objeto"
L["Show Target"] = "Mostrar objetivo"
L["Show Specialization"] = "Mostrar especialización"
L["Anchor Tooltip to Mouse Cursor"] = "Anclar descripción emergente al cursor del ratón"
L["Hide Tooltip Health Bar"] = "Ocultar barra de salud de la descripción emergente"
L["Hide Tooltip In Combat"] = "Ocultar descripción emergente en combate"
L["Show Class Icon"] = "Mostrar icono de clase"
L["Show Role Icon"] = "Mostrar icono de rol"
L["Show Mythic+ Rating"] = "Mostrar puntuación de Míticas+"
L["Show PvP Rating"] = "Mostrar puntuación JcJ"
L["Show Item Info"] = "Mostrar información del objeto"
L["Show Stat Values"] = "Mostrar valores de estadísticas"
L["Highlight Grey Items (Ctrl)"] = "Resaltar objetos grises (Ctrl)"
L["Debug Mode"] = "Modo depuración"
L["Tooltip Scale"] = "Escala de la descripción emergente"
L["Target:"] = "Objetivo:"
L["Specialization:"] = "Especialización:"
L["Role:"] = "Rol:"
L["Mythic+ Rating:"] = "Puntuación de Míticas+:"
L["PvP Rating:"] = "Puntuación JcJ:"
L["Item Level:"] = "Nivel de objeto:"
L["GUID:"] = "GUID:"
L["Unit ID:"] = "ID de unidad:"
L["Class ID:"] = "ID de clase:"
L["Spec ID:"] = "ID de especialización:"
L["Inspect cooldown active"] = "Tiempo de reutilización de inspección activo"
L["Source:"] = "Fuente:"
L["Type:"] = "Tipo:"
L["Subtype:"] = "Subtipo:"
L["Slot:"] = "Espacio:"
L["Stack:"] = "Montón:"
L["Vendor Price:"] = "Precio del vendedor:"
L["Mount Type:"] = "Tipo de montura:"
L["Status:"] = "Estado:"
L["Faction:"] = "Facción:"

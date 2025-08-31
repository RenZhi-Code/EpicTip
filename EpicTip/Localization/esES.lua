local addonName, ET = ...

-- Only load Spanish translations if the client is set to Spanish
if GetLocale() ~= "esES" and GetLocale() ~= "esMX" then
    return
end

ET.L = ET.L or {}
local L = ET.L

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

-- New Configuration Keys (Translation needed)
-- General Configuration
L["General"] = "General"
L["Features"] = "Características"
L["Enable EpicTip"] = "Habilitar EpicTip"
L["Overall size of tooltips"] = "Overall size of tooltips" -- TODO: Translate
L["Competitive"] = "Competitivo"
L["Mythic+ Display Format"] = "Formato de visualización Mítica+"
L["Mount Information"] = "Información de montura"

-- Ring Configuration
L["Ring Configuration"] = "Configuración del anillo"
L["Cursor Glow Effects"] = "Efectos de brillo del cursor"
L["Tail Effects"] = "Efectos de cola"
L["Pulse Effects"] = "Efectos de pulso"
L["Click Effects"] = "Efectos de clic"
L["Combat Settings"] = "Configuración de combate"

-- Appearance Configuration
L["Appearance"] = "Apariencia"
L["Background"] = "Fondo"
L["Border"] = "Borde"
L["Text Filtering"] = "Filtrado de texto"
L["Font Configuration"] = "Configuración de fuente"

-- TrueStat Configuration
L["Enhanced Item Analysis and True Stat Values"] = "Enhanced Item Analysis and True Stat Values" -- TODO: Translate
L["Item Information"] = "Información de objeto"
L["True Stat Values"] = "Valores de estadísticas reales"
L["Advanced Options"] = "Opciones avanzadas"

-- Player Info Configuration
L["Player Information Display"] = "Visualización de información del jugador"
L["Player Info Display Options"] = "Opciones de visualización de info del jugador"

-- Debug and Status Messages
L["Loading"] = "Cargando"
L["Loaded"] = "Cargado"
L["Enabled"] = "Habilitado"
L["Disabled"] = "Deshabilitado"
L["Error"] = "Error"
L["Warning"] = "Advertencia"
L["Ready"] = "Listo"

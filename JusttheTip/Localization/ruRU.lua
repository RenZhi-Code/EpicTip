local addonName, JTT = ...

-- Only load Russian translations if the client is set to Russian
if GetLocale() ~= "ruRU" then
    return
end

JTT.L = JTT.L or {}
local L = JTT.L

-- Russian Localization
L["Just the Tip"] = "Просто подсказка"
L["Options"] = "Настройки"
L["Enable Tooltip"] = "Включить подсказку"
L["Show Item Level"] = "Показать уровень предмета"
L["Show Target"] = "Показать цель"
L["Show Specialization"] = "Показать специализацию"
L["Anchor Tooltip to Mouse Cursor"] = "Привязать подсказку к курсору мыши"
L["Hide Tooltip Health Bar"] = "Скрыть полосу здоровья в подсказке"
L["Hide Tooltip In Combat"] = "Скрыть подсказку в бою"
L["Show Class Icon"] = "Показать значок класса"
L["Show Role Icon"] = "Показать значок роли"
L["Show Mythic+ Rating"] = "Показать рейтинг Мифик+"
L["Show PvP Rating"] = "Показать рейтинг PvP"
L["Show Item Info"] = "Показать информацию о предмете"
L["Show Stat Values"] = "Показать значения характеристик"
L["Highlight Grey Items (Ctrl)"] = "Выделить серые предметы (Ctrl)"
L["Debug Mode"] = "Режим отладки"
L["Tooltip Scale"] = "Масштаб подсказки"
L["Target:"] = "Цель:"
L["Specialization:"] = "Специализация:"
L["Role:"] = "Роль:"
L["Mythic+ Rating:"] = "Рейтинг Мифик+:"
L["PvP Rating:"] = "Рейтинг PvP:"
L["Item Level:"] = "Уровень предмета:"
L["GUID:"] = "GUID:"
L["Unit ID:"] = "ID юнита:"
L["Class ID:"] = "ID класса:"
L["Spec ID:"] = "ID специализации:"
L["Inspect cooldown active"] = "Действует задержка осмотра"
L["Source:"] = "Источник:"
L["Type:"] = "Тип:"
L["Subtype:"] = "Подтип:"
L["Slot:"] = "Ячейка:"
L["Stack:"] = "Стак:"
L["Vendor Price:"] = "Цена у торговца:"
L["Mount Type:"] = "Тип маунта:"
L["Status:"] = "Статус:"
L["Faction:"] = "Фракция:"

local addonName, ET = ...

-- Only load Russian translations if the client is set to Russian
if GetLocale() ~= "ruRU" then
    return
end

ET.L = ET.L or {}
local L = ET.L

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

-- New Configuration Keys (Translation needed)
-- General Configuration
L["General"] = "Общие"
L["Features"] = "Функции"
L["Enable EpicTip"] = "Включить EpicTip"
L["Overall size of tooltips"] = "Overall size of tooltips" -- TODO: Translate
L["Competitive"] = "Соревновательный"
L["Mythic+ Display Format"] = "Формат отображения Мифик+"
L["Mount Information"] = "Информация о транспорте"

-- Ring Configuration
L["Ring Configuration"] = "Настройка кольца"
L["Cursor Glow Effects"] = "Эффекты свечения курсора"
L["Tail Effects"] = "Эффекты хвоста"
L["Pulse Effects"] = "Эффекты пульсации"
L["Click Effects"] = "Эффекты клика"
L["Combat Settings"] = "Настройки боя"

-- Appearance Configuration
L["Appearance"] = "Внешний вид"
L["Background"] = "Фон"
L["Border"] = "Граница"
L["Text Filtering"] = "Фильтрация текста"
L["Font Configuration"] = "Настройка шрифта"

-- TrueStat Configuration
L["Enhanced Item Analysis and True Stat Values"] = "Enhanced Item Analysis and True Stat Values" -- TODO: Translate
L["Item Information"] = "Информация о предмете"
L["True Stat Values"] = "Истинные значения характеристик"
L["Advanced Options"] = "Дополнительные опции"

-- Player Info Configuration
L["Player Information Display"] = "Отображение информации об игроке"
L["Player Info Display Options"] = "Опции отображения информации об игроке"

-- Debug and Status Messages
L["Loading"] = "Загрузка"
L["Loaded"] = "Загружено"
L["Enabled"] = "Включено"
L["Disabled"] = "Отключено"
L["Error"] = "Ошибка"
L["Warning"] = "Предупреждение"
L["Ready"] = "Готово"

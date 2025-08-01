local addonName, JTT = ...

-- Only load Traditional Chinese translations if the client is set to Traditional Chinese
if GetLocale() ~= "zhTW" then
    return
end

JTT.L = JTT.L or {}
local L = JTT.L

-- Traditional Chinese Localization
L["Just the Tip"] = "只是提示"
L["Options"] = "選項"
L["Enable Tooltip"] = "啟用滑鼠提示"
L["Show Item Level"] = "顯示物品等級"
L["Show Target"] = "顯示目標"
L["Show Specialization"] = "顯示專精"
L["Anchor Tooltip to Mouse Cursor"] = "滑鼠提示錨定到滑鼠游標"
L["Hide Tooltip Health Bar"] = "隱藏滑鼠提示生命條"
L["Hide Tooltip In Combat"] = "戰鬥中隱藏滑鼠提示"
L["Show Class Icon"] = "顯示職業圖示"
L["Show Role Icon"] = "顯示角色圖示"
L["Show Mythic+ Rating"] = "顯示大秘境評級"
L["Show PvP Rating"] = "顯示PvP評級"
L["Show Item Info"] = "顯示物品資訊"
L["Show Stat Values"] = "顯示屬性價值"
L["Highlight Grey Items (Ctrl)"] = "高亮灰色物品 (Ctrl)"
L["Debug Mode"] = "除錯模式"
L["Tooltip Scale"] = "滑鼠提示縮放"
L["Target:"] = "目標:"
L["Specialization:"] = "專精:"
L["Role:"] = "角色:"
L["Mythic+ Rating:"] = "大秘境評級:"
L["PvP Rating:"] = "PvP評級:"
L["Item Level:"] = "物品等級:"
L["GUID:"] = "GUID:"
L["Unit ID:"] = "單位ID:"
L["Class ID:"] = "職業ID:"
L["Spec ID:"] = "專精ID:"
L["Inspect cooldown active"] = "觀察冷卻時間啟動"
L["Source:"] = "來源:"
L["Type:"] = "類型:"
L["Subtype:"] = "子類型:"
L["Slot:"] = "位置:"
L["Stack:"] = "堆疊:"
L["Vendor Price:"] = "商人價格:"
L["Mount Type:"] = "坐騎類型:"
L["Status:"] = "狀態:"
L["Faction:"] = "陣營:"

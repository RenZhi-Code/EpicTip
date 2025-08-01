local addonName, JTT = ...

-- Only load Simplified Chinese translations if the client is set to Simplified Chinese
if GetLocale() ~= "zhCN" then
    return
end

JTT.L = JTT.L or {}
local L = JTT.L

-- Simplified Chinese Localization
L["Just the Tip"] = "只是提示"
L["Options"] = "选项"
L["Enable Tooltip"] = "启用鼠标提示"
L["Show Item Level"] = "显示物品等级"
L["Show Target"] = "显示目标"
L["Show Specialization"] = "显示专精"
L["Anchor Tooltip to Mouse Cursor"] = "鼠标提示锚定到鼠标光标"
L["Hide Tooltip Health Bar"] = "隐藏鼠标提示生命条"
L["Hide Tooltip In Combat"] = "战斗中隐藏鼠标提示"
L["Show Class Icon"] = "显示职业图标"
L["Show Role Icon"] = "显示角色图标"
L["Show Mythic+ Rating"] = "显示大秘境评级"
L["Show PvP Rating"] = "显示PvP评级"
L["Show Item Info"] = "显示物品信息"
L["Show Stat Values"] = "显示属性价值"
L["Highlight Grey Items (Ctrl)"] = "高亮灰色物品 (Ctrl)"
L["Debug Mode"] = "调试模式"
L["Tooltip Scale"] = "鼠标提示缩放"
L["Target:"] = "目标:"
L["Specialization:"] = "专精:"
L["Role:"] = "角色:"
L["Mythic+ Rating:"] = "大秘境评级:"
L["PvP Rating:"] = "PvP评级:"
L["Item Level:"] = "物品等级:"
L["GUID:"] = "GUID:"
L["Unit ID:"] = "单位ID:"
L["Class ID:"] = "职业ID:"
L["Spec ID:"] = "专精ID:"
L["Inspect cooldown active"] = "观察冷却时间激活"
L["Source:"] = "来源:"
L["Type:"] = "类型:"
L["Subtype:"] = "子类型:"
L["Slot:"] = "位置:"
L["Stack:"] = "堆叠:"
L["Vendor Price:"] = "商人价格:"
L["Mount Type:"] = "坐骑类型:"
L["Status:"] = "状态:"
L["Faction:"] = "阵营:"

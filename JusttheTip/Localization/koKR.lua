local addonName, JTT = ...

-- Only load Korean translations if the client is set to Korean
if GetLocale() ~= "koKR" then
    return
end

JTT.L = JTT.L or {}
local L = JTT.L

-- Korean Localization
L["Just the Tip"] = "그저 팁"
L["Options"] = "옵션"
L["Enable Tooltip"] = "툴팁 활성화"
L["Show Item Level"] = "아이템 레벨 표시"
L["Show Target"] = "대상 표시"
L["Show Specialization"] = "전문화 표시"
L["Anchor Tooltip to Mouse Cursor"] = "툴팁을 마우스 커서에 고정"
L["Hide Tooltip Health Bar"] = "툴팁 체력 바 숨기기"
L["Hide Tooltip In Combat"] = "전투 중 툴팁 숨기기"
L["Show Class Icon"] = "직업 아이콘 표시"
L["Show Role Icon"] = "역할 아이콘 표시"
L["Show Mythic+ Rating"] = "쐐기돌 등급 표시"
L["Show PvP Rating"] = "PvP 등급 표시"
L["Show Item Info"] = "아이템 정보 표시"
L["Show Stat Values"] = "능력치 가치 표시"
L["Highlight Grey Items (Ctrl)"] = "회색 아이템 강조 (Ctrl)"
L["Debug Mode"] = "디버그 모드"
L["Tooltip Scale"] = "툴팁 크기"
L["Target:"] = "대상:"
L["Specialization:"] = "전문화:"
L["Role:"] = "역할:"
L["Mythic+ Rating:"] = "쐐기돌 등급:"
L["PvP Rating:"] = "PvP 등급:"
L["Item Level:"] = "아이템 레벨:"
L["GUID:"] = "GUID:"
L["Unit ID:"] = "유닛 ID:"
L["Class ID:"] = "직업 ID:"
L["Spec ID:"] = "전문화 ID:"
L["Inspect cooldown active"] = "살펴보기 재사용 대기시간 활성"
L["Source:"] = "출처:"
L["Type:"] = "유형:"
L["Subtype:"] = "하위 유형:"
L["Slot:"] = "슬롯:"
L["Stack:"] = "묶음:"
L["Vendor Price:"] = "상점 가격:"
L["Mount Type:"] = "탈것 유형:"
L["Status:"] = "상태:"
L["Faction:"] = "진영:"

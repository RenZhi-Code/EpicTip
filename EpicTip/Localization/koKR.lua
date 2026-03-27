local addonName, ET = ...

-- Only load Korean translations if the client is set to Korean
if GetLocale() ~= "koKR" then
    return
end

ET.L = ET.L or {}
local L = ET.L

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

-- New Configuration Keys (Translation needed)
-- General Configuration
L["General"] = "일반"
L["Features"] = "기능"
L["Enable EpicTip"] = "EpicTip 활성화"
L["Overall size of tooltips"] = "Overall size of tooltips" -- TODO: Translate
L["Competitive"] = "경쟁"
L["Mythic+ Display Format"] = "신화+ 표시 형식"
L["Mount Information"] = "탈것 정보"

-- Ring Configuration
L["Ring Configuration"] = "링 설정"
L["Cursor Glow Effects"] = "커서 발광 효과"
L["Tail Effects"] = "꼬리 효과"
L["Pulse Effects"] = "맥동 효과"
L["Click Effects"] = "클릭 효과"
L["Combat Settings"] = "전투 설정"

-- Appearance Configuration
L["Appearance"] = "외관"
L["Background"] = "배경"
L["Border"] = "테두리"
L["Text Filtering"] = "텍스트 필터링"
L["Font Configuration"] = "글꼴 설정"

-- TrueStat Configuration
L["Enhanced Item Analysis and True Stat Values"] = "Enhanced Item Analysis and True Stat Values" -- TODO: Translate
L["Item Information"] = "아이템 정보"
L["True Stat Values"] = "실제 능력치 값"
L["Advanced Options"] = "고급 옵션"

-- Player Info Configuration
L["Player Information Display"] = "플레이어 정보 표시"
L["Player Info Display Options"] = "플레이어 정보 표시 옵션"

-- Debug and Status Messages
L["Loading"] = "로딩 중"
L["Loaded"] = "로드됨"
L["Enabled"] = "활성화됨"
L["Disabled"] = "비활성화됨"
L["Error"] = "오류"
L["Warning"] = "경고"
L["Ready"] = "준비됨"

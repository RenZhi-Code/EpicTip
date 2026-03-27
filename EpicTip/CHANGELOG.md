# EpicTip Changelog

## v27.03.26.5f

### Fixed
- Mythic+ rating was never showing — `AddToTooltip` was not wired into the tooltip pipeline
- Mythic+ rating for self returned nil — was passing GUID instead of unit token `"player"` to `GetPlayerMythicPlusRatingSummary`
- M+ tooltip lines overlapping — duplicate `AddToTooltip` call removed, tier title switched from `AddDoubleLine` to `AddLine`

### Added
- StaticData now fully wired into the tooltip system
- Mythic+ player tooltip: score coloured by rating bracket via `StaticData.GetMythicRatingColor`
- Mythic+ player tooltip: tier title (`the Umbral` / `the Umbral Hero`) shown when rating threshold reached
- Mythic+ player tooltip: next reward milestone shown with points needed and reward name
- Mythic+ player tooltip: per-dungeon best key breakdown using `C_ChallengeMode.GetMapInfo`
- Keystone item tooltip: gear and vault ilvl rewards with track name e.g. `Hero 3/6`
- Keystone item tooltip: crest type and count
- Keystone item tooltip: dungeon mount drop name where applicable
- Affix spell tooltips: hovering Tyrannical, Fortified, Xal'atath's Bargain etc. now shows affix description from `StaticData.seasonalAffixes`
- Mount tooltip: drop rate percentage shown for known rare mounts
- PvP tooltip: per-bracket rating with rank name (Combatant through Gladiator) and colour
- PvP tooltip: win/loss record and win percentage per bracket
- PvP tooltip: next rank milestone with points needed
- PvP rank thresholds and colours added to StaticData (`GetPvPRank`, `GetNextPvPRank`)

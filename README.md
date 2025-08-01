# Just the Tip

![Version](https://img.shields.io/badge/version-01.08.25.10-blue) ![WoW](https://img.shields.io/badge/WoW-The%20War%20Within-orange) ![License](https://img.shields.io/badge/license-All%20Rights%20Reserved-red)

A comprehensive World of Warcraft addon that enhances tooltips with detailed player information, item comparisons, stat calculations, mount details, and includes a customizable cursor ring for improved visibility.

##  Features

###  **Enhanced Player Tooltips**
- **Class-Colored Names** - Player names displayed in their class colors
- **Class & Role Icons** - Visual indicators for class and role (Tank/Healer/DPS)
- **Specialization Display** - Shows current spec (e.g., "Unholy Death Knight")
- **Item Level** - Displays average equipped item level
- **Target Information** - Shows who the player is targeting
- **Guild Formatting** - Properly formatted guild names with `<brackets>`
- **Faction Colors** - Blue for Alliance, Red for Horde
- **Clean Display** - Removes clutter like "(Player)" text

###  **Smart Item Tooltips**
- **Item Level Comparison** - Compare with equipped gear
  - 🟢 **Green (+X)** for upgrades
  - 🔴 **Red (-X)** for downgrades  
  - 🟡 **Yellow (=)** for same level
- **Enhanced Item Details** - Type, subtype, and equipment slot info
- **Source Information** - Shows acquisition method (Drop, Quest, Vendor, etc.)
- **Multi-slot Support** - Handles rings, trinkets, and weapon combinations
- **Item Search** - Find items quickly with `/jttitem <name>`

###  **Advanced Stat Calculations**
- **True Stat Values** - Displays actual values after diminishing returns
- **Rating Breakpoints** - Shows rating needed for next percentage tier
- **Diminishing Returns** - Visual indicators for stat penalties
- **Complete Coverage** - All secondary and tertiary stats
- **TWW Compatible** - Updated for The War Within expansion


###  **Mount Recognition System**
- **Automatic Detection** - Identifies mounts on players
- **Detailed Information** - Name, type, and acquisition source
- **Collection Status** - Shows if you own the mount
- **Mount Categories** - Ground, Flying, Aquatic classification
- **Smart Conflict Avoidance** - Works alongside other mount addons

###  **Cursor Ring**
- **Visual Enhancement** - Colored ring follows your mouse cursor
- **Combat Awareness** - Different opacity in/out of combat
- **Class Color Integration** - Automatically matches your class
- **Multiple Styles** - Default, Thin, Thick, or Solid textures
- **Fully Customizable** - Size, colors, transparency, and behavior
- **High Visibility Mode** - Bright green option for accessibility

##  Installation

### Automatic (Recommended)
1. Install via **CurseForge App** or **WoWUp**
2. Launch World of Warcraft
3. Configure via `/jtt config`

### Manual
1. Download the latest release
2. Extract to `World of Warcraft\_retail_\Interface\AddOns\`
3. Ensure folder is named `JustTheTip`
4. Restart WoW or `/reload`

##  Configuration

### Quick Setup
```
/jtt config          # Open configuration panel
/jtt ring show       # Enable cursor ring
/jtt debug           # Toggle debug mode
```

### Main Settings

| Category | Setting | Default | Description |
|----------|---------|---------|-------------|
| **General** | Enable Tooltip | ✅ | Master switch for all features |
| **General** | Anchor to Mouse | ✅ | Tooltips follow cursor |
| **General** | Tooltip Scale | 1.0 | Size multiplier (0.5-2.0) |
| **Player Info** | Show Item Level | ✅ | Display player's average ilvl |
| **Player Info** | Show Specialization | ✅ | Current spec information |
| **Player Info** | Show Target | ✅ | What player is targeting |
| **Player Info** | Class Icons | ✅ | Visual class indicators |
| **Player Info** | Role Icons | ✅ | Tank/Healer/DPS icons |
| **Features** | Mythic+ Rating | ❌ | M+ score (optional) |
| **Features** | PvP Rating | ❌ | Arena/RBG rating (optional) |
| **Features** | Item Information | ✅ | Enhanced item tooltips |
| **Features** | Stat Values | ✅ | Calculated stat weights |
| **Features** | Mount Information | ✅ | Mount details on hover |
| **Ring** | Enable Ring | ❌ | Cursor ring visibility |
| **Ring** | Ring Texture | Default | Visual style |
| **Ring** | Use Class Color | ✅ | Match class colors |
| **Ring** | Combat Alpha | 0.7 | Opacity during combat |
| **Ring** | Out of Combat Alpha | 0.3 | Opacity when safe |

##  Commands

### Core Commands
```bash
/jtt config          # Open configuration panel
/jtt debug           # Toggle debug information
/jtt test            # Show addon status
/jtt save            # Force save settings
```

### Cursor Ring
```bash
/jtt ring show       # Enable and show ring
/jtt ring hide       # Hide ring (keep enabled)
/jtt ring toggle     # Toggle visibility
/jtt ring enable     # Enable ring system
/jtt ring disable    # Disable ring system
```

### Item Search
```bash
/jttitem <name>      # Search for items
/jttsearch <name>    # Alternative search
```

##  Advanced Features

### Tooltip Behavior
- **Mouse Anchoring**: Tooltips follow cursor or stay in fixed position
- **Combat Hiding**: Optional tooltip hiding during combat
- **Health Bar Control**: Show/hide unit health bars
- **Background Customization**: Custom colors and opacity
- **Scale Options**: Resize tooltips from 50% to 200%

### Performance Optimizations
- **Inspection Throttling**: Prevents API spam
- **Smart Caching**: Reduces repeated calculations
- **Event Optimization**: Minimal CPU usage
- **Memory Management**: ~2-3MB typical usage

### Compatibility
- **The War Within** (11.0+) fully supported
- **Dragonflight** (10.0+) compatible
- **Ace3 Framework** for stability
- **Modern APIs** with legacy fallbacks

##  Troubleshooting

### Common Issues

**Q: Tooltips not appearing**
A: Check `/jtt config` → General → Enable Tooltip

**Q: Ring not visible**
A: Use `/jtt ring show` and check visibility settings

**Q: Item comparisons incorrect**
A: Ensure you have gear equipped in compared slots

**Q: Mount info missing**
A: Feature works best on nearby players and yourself

### Debug Information
Enable debug mode for detailed troubleshooting:
```bash
/jtt debug           # Toggle debug output
/jtt test            # Show module status
```

### Reset Options
```bash
# Reset all settings to defaults
Delete WTF/Account/[Account]/SavedVariables/JustTheTip.lua
```

##  Technical Details

### System Requirements
- **World of Warcraft**: The War Within (11.0.7+)
- **Dependencies**: None (Ace3 libraries included)
- **Memory**: ~2-3MB typical usage
- **CPU**: Minimal impact, optimized event handling

### Database Structure
- **Saved Variables**: `JustTheTipSettings`
- **Profile System**: Per-character or account-wide
- **Backup**: Automatic settings preservation
- **Migration**: Seamless updates

### Module Architecture
```
JustTheTip/
├── Core.lua              # Main addon framework
├── Modules/
│   ├── Tooltip.lua       # Player tooltip enhancements
│   ├── ItemInfo.lua      # Item comparison system
│   ├── StatValues.lua    # Stat calculations
│   ├── MountInfo.lua     # Mount recognition
│   ├── Ring.lua          # Cursor ring system
│   └── Utils.lua         # Shared utilities
└── Media/                # Ring textures
```

##  Customization Examples

### Cursor Ring Setups

**High Visibility Gaming**
- Texture: Solid
- Color: High Visibility (Green)
- Combat Alpha: 1.0
- Size: 32px

**Minimal Class Theme**
- Texture: Thin
- Color: Class Color
- Combat Alpha: 0.8
- Out of Combat: 0.2
- Size: 24px

**Professional Streaming**
- Texture: Default
- Color: Custom (White)
- Combat Alpha: 0.6
- Size: 28px

##  Version History

### v01.08.25.10 (Current)
- ✅ Complete tooltip system overhaul
- ✅ Added cursor ring with combat awareness
- ✅ Enhanced mount recognition
- ✅ Improved stat calculations with diminishing returns
- ✅ Better item comparison system
- ✅ Full configuration interface
- ✅ Performance optimizations

### Previous Versions
- Enhanced player information display
- Basic item level comparisons
- Simple tooltip modifications

##  Development

### Author
**knutballs** - EU Ravencrest  
*Addon development since 2025*

### Credits
- **Stat Data**: SimulationCraft & Pawn addon methodologies
- **Framework**: Ace3 addon libraries
- **Testing**: Guild members and community feedback
- **Inspiration**: Various tooltip enhancement addons

### Contributing
This addon is currently in active development. For bug reports or feature requests:
1. Use `/jtt debug` for diagnostic information
2. Test with minimal addons to isolate issues
3. Provide specific reproduction steps








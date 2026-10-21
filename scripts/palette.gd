extends RefCounted
## Runtime theme tokens for Pulsebreak.
##
## Default theme "aerospace" is the 1.3.1 art direction: warm off-white type
## on graphite, ONE accent (signal orange, the color of the shots you steal),
## gold only for money, red only for danger, pale ice as a thin secondary line.
## Themes are static vars so Settings can swap the whole token set live; the
## HUD rebuilds itself after a swap. Hostile shot orange and sector identity
## colors are gameplay language and stay constant across themes.

const THEME_NAMES := {
	"aerospace": "AEROSPACE",
	"foundry": "FOUNDRY",
	"abyss": "ABYSS",
	"blueprint": "BLUEPRINT",
}

const THEMES := {
	"aerospace": {
		"INK": Color("0b0d0f"), "PANEL": Color("14181d"), "PANEL_LINE": Color("394048"),
		"SIGNAL": Color("ff7a1a"), "SIGNAL_SOFT": Color("ffa25e"), "GOLD": Color("e3b04b"),
		"CORAL": Color("e5484d"), "CORAL_SOFT": Color("ff7467"), "WHITE": Color("eae7de"),
		"MUTED": Color("9b978a"), "ICE": Color("c3d5e0"),
		"MINT": Color("ff7a1a"), "MINT_BRIGHT": Color("ffa25e"),
		"AMBER": Color("e3b04b"), "AMBER_HOT": Color("ffb35c"),
		"WEAPON_ICE": Color("d7e6ee"), "WEAPON_AMBER": Color("e8a33d"),
		"WEAPON_ELECTRIC": Color("7ea6c4"), "WEAPON_PLASMA": Color("ffd98a"),
		"PANEL_RAISED": Color("1c2129"), "PANEL_INSET": Color("10131a"), "HAIRLINE": Color("2a3038"),
		"FAM_HARVEST": Color("ff7a1a"), "FAM_ECHO": Color("c3d5e0"), "FAM_WAKE": Color("eae7de"),
	},
	"foundry": {
		"INK": Color("120c07"), "PANEL": Color("1d140d"), "PANEL_LINE": Color("4a3826"),
		"SIGNAL": Color("ff9a3c"), "SIGNAL_SOFT": Color("ffbe78"), "GOLD": Color("ffc85e"),
		"CORAL": Color("e5484d"), "CORAL_SOFT": Color("ff7467"), "WHITE": Color("f2e4c8"),
		"MUTED": Color("a98f6d"), "ICE": Color("cfe0d8"),
		"MINT": Color("ff9a3c"), "MINT_BRIGHT": Color("ffbe78"),
		"AMBER": Color("ffc85e"), "AMBER_HOT": Color("ffd98a"),
		"WEAPON_ICE": Color("e8dcc0"), "WEAPON_AMBER": Color("f0a83e"),
		"WEAPON_ELECTRIC": Color("c9a86a"), "WEAPON_PLASMA": Color("ffe2a0"),
		"PANEL_RAISED": Color("2a1d12"), "PANEL_INSET": Color("160f09"), "HAIRLINE": Color("3a2c1c"),
		"FAM_HARVEST": Color("ff9a3c"), "FAM_ECHO": Color("cfe0d8"), "FAM_WAKE": Color("f2e4c8"),
	},
	"abyss": {
		"INK": Color("05090c"), "PANEL": Color("0a161c"), "PANEL_LINE": Color("23424e"),
		"SIGNAL": Color("35c4b5"), "SIGNAL_SOFT": Color("7fe0d2"), "GOLD": Color("e3b04b"),
		"CORAL": Color("ff5a5f"), "CORAL_SOFT": Color("ff8577"), "WHITE": Color("e6f2ef"),
		"MUTED": Color("7d9a97"), "ICE": Color("bfe9ff"),
		"MINT": Color("35c4b5"), "MINT_BRIGHT": Color("7fe0d2"),
		"AMBER": Color("e3b04b"), "AMBER_HOT": Color("ffcf7a"),
		"WEAPON_ICE": Color("d9f4ff"), "WEAPON_AMBER": Color("e8c33d"),
		"WEAPON_ELECTRIC": Color("6fd3e7"), "WEAPON_PLASMA": Color("a8ffe9"),
		"PANEL_RAISED": Color("10222b"), "PANEL_INSET": Color("071118"), "HAIRLINE": Color("1a303c"),
		"FAM_HARVEST": Color("35c4b5"), "FAM_ECHO": Color("bfe9ff"), "FAM_WAKE": Color("e6f2ef"),
	},
	"blueprint": {
		"INK": Color("081120"), "PANEL": Color("0e1e33"), "PANEL_LINE": Color("3d6a99"),
		"SIGNAL": Color("ffb35c"), "SIGNAL_SOFT": Color("ffcf8a"), "GOLD": Color("ffd98a"),
		"CORAL": Color("ff6b6b"), "CORAL_SOFT": Color("ff9a8a"), "WHITE": Color("eaf4ff"),
		"MUTED": Color("8fb0d8"), "ICE": Color("9fd0ff"),
		"MINT": Color("ffb35c"), "MINT_BRIGHT": Color("ffcf8a"),
		"AMBER": Color("ffd98a"), "AMBER_HOT": Color("ffe6b0"),
		"WEAPON_ICE": Color("eaf4ff"), "WEAPON_AMBER": Color("ffb35c"),
		"WEAPON_ELECTRIC": Color("9fd0ff"), "WEAPON_PLASMA": Color("cfe8ff"),
		"PANEL_RAISED": Color("142a44"), "PANEL_INSET": Color("0a1828"), "HAIRLINE": Color("274a6e"),
		"FAM_HARVEST": Color("ffb35c"), "FAM_ECHO": Color("9fd0ff"), "FAM_WAKE": Color("eaf4ff"),
	},
}

static var active_id := "aerospace"

static var INK := Color("0b0d0f")
static var PANEL := Color("14181d")
static var PANEL_LINE := Color("394048")
static var SIGNAL := Color("ff7a1a")
static var SIGNAL_SOFT := Color("ffa25e")
static var GOLD := Color("e3b04b")
static var CORAL := Color("e5484d")
static var CORAL_SOFT := Color("ff7467")
static var WHITE := Color("eae7de")
static var MUTED := Color("9b978a")
static var ICE := Color("c3d5e0")
static var MINT := Color("ff7a1a")
static var MINT_BRIGHT := Color("ffa25e")
static var AMBER := Color("e3b04b")
static var AMBER_HOT := Color("ffb35c")
static var WEAPON_ICE := Color("d7e6ee")
static var WEAPON_AMBER := Color("e8a33d")
static var WEAPON_ELECTRIC := Color("7ea6c4")
static var WEAPON_PLASMA := Color("ffd98a")
static var PANEL_RAISED := Color("1c2129")
static var PANEL_INSET := Color("10131a")
static var HAIRLINE := Color("2a3038")
static var FAM_HARVEST := Color("ff7a1a")
static var FAM_ECHO := Color("c3d5e0")
static var FAM_WAKE := Color("eae7de")

const SHOT_ORANGE := Color("ff9a3c")
const SECTOR_SKYPORT := Color("c3d5e0")
const SECTOR_FOUNDRY := Color("e0a458")
const SECTOR_TEMPEST := Color("8fb0c9")

static func theme_ids() -> Array:
	return THEMES.keys()

static func set_theme(id: String) -> bool:
	if not THEMES.has(id):
		return false
	active_id = id
	var t: Dictionary = THEMES[id]
	INK = t.INK; PANEL = t.PANEL; PANEL_LINE = t.PANEL_LINE
	SIGNAL = t.SIGNAL; SIGNAL_SOFT = t.SIGNAL_SOFT; GOLD = t.GOLD
	CORAL = t.CORAL; CORAL_SOFT = t.CORAL_SOFT; WHITE = t.WHITE
	MUTED = t.MUTED; ICE = t.ICE
	MINT = t.MINT; MINT_BRIGHT = t.MINT_BRIGHT; AMBER = t.AMBER; AMBER_HOT = t.AMBER_HOT
	WEAPON_ICE = t.WEAPON_ICE; WEAPON_AMBER = t.WEAPON_AMBER
	WEAPON_ELECTRIC = t.WEAPON_ELECTRIC; WEAPON_PLASMA = t.WEAPON_PLASMA
	PANEL_RAISED = t.PANEL_RAISED; PANEL_INSET = t.PANEL_INSET; HAIRLINE = t.HAIRLINE
	FAM_HARVEST = t.FAM_HARVEST; FAM_ECHO = t.FAM_ECHO; FAM_WAKE = t.FAM_WAKE
	return true

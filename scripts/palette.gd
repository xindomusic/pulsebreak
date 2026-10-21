extends RefCounted
## The single color-token set for Pulsebreak (1.3.1 art direction).
##
## "Aerospace instrument": warm off-white type on graphite, ONE accent.
## Researched across reference game UIs (Destiny's white-on-graphite minimal
## panels, Hades' gold-on-near-black restraint, Dead Space's restrained
## hologram lines) and the classic palette rule: two neutrals dark, two
## neutrals light, one red for danger, one accent for everything else.
##
## The accent is SIGNAL ORANGE — the color of the shots you steal. Energy,
## focus and the primary action all speak orange; gold appears only for
## money (salvage cores, combo), red only for danger, pale ice only as a
## thin secondary line. No neon mint, no purple, no solid accent slabs:
## primary buttons are off-white with ink text.

const INK := Color("0b0d0f")
const PANEL := Color("14181d")
const PANEL_LINE := Color("394048")
const SIGNAL := Color("ff7a1a")
const SIGNAL_SOFT := Color("ffa25e")
const GOLD := Color("e3b04b")
const CORAL := Color("e5484d")
const CORAL_SOFT := Color("ff7467")
const WHITE := Color("eae7de")
const MUTED := Color("9b978a")
const ICE := Color("c3d5e0")

# Back-compat names (values follow the new direction).
const MINT := Color("ff7a1a")
const MINT_BRIGHT := Color("ffa25e")
const AMBER := Color("e3b04b")
const AMBER_HOT := Color("ffb35c")

const WEAPON_ICE := Color("d7e6ee")
const WEAPON_AMBER := Color("e8a33d")
const WEAPON_ELECTRIC := Color("7ea6c4")
const WEAPON_PLASMA := Color("ffd98a")

const PANEL_RAISED := Color("1c2129")
const PANEL_INSET := Color("10131a")
const HAIRLINE := Color("2a3038")
const FAM_HARVEST := Color("ff7a1a")
const FAM_ECHO := Color("c3d5e0")
const FAM_WAKE := Color("eae7de")

const SHOT_ORANGE := Color("ff9a3c")
const SECTOR_SKYPORT := Color("c3d5e0")
const SECTOR_FOUNDRY := Color("e0a458")
const SECTOR_TEMPEST := Color("8fb0c9")

extends RefCounted
## The single color-token set for Pulsebreak. HUD, FX, weapons and sector
## themes reference these values; art.gd's material palette uses the same hues.
## Language: mint = player/energy, amber = harvest economy, coral = threat.

const INK := Color("08131e")
const MINT := Color("76f7df")
const MINT_BRIGHT := Color("40edff")
const AMBER := Color("ffb477")
const AMBER_HOT := Color("ffc46b")
const CORAL := Color("ff5d5d")
const CORAL_SOFT := Color("ff7467")
const WHITE := Color("edf6f7")
const MUTED := Color("9eb5c5")

const WEAPON_ICE := Color("c8f4ff")
const WEAPON_AMBER := Color("ffca79")
const WEAPON_ELECTRIC := Color("4da6ff")
const WEAPON_PLASMA := Color("3dff9e")

const SHOT_ORANGE := Color("ffb465")
const SECTOR_SKYPORT := Color("76f7df")
const SECTOR_FOUNDRY := Color("ffd18a")
const SECTOR_TEMPEST := Color("7ac7ff")

extends RefCounted

# Single source of truth for the app palette. New UI must take colors from here.
# The static theme resource mirrors these values because Godot themes cannot
# reference script constants.

const BG := Color("#10131a")
const BG_DEEP := Color("#05070c")
const SURFACE := Color("#1b202f")
const SURFACE_ALT := Color("#232a3c")
const SURFACE_HOVER := Color("#2e3850")
const SURFACE_PRESSED := Color("#1a2131")
const SURFACE_DISABLED := Color("#191c23")

const TEXT := Color("#f4f6fb")
const MUTED := Color("#93a0b8")

const BLUE := Color("#4b7fd4")
const BLUE_DEEP := Color("#2e4f8f")
const BLUE_SOFT := Color("#6f9be0")

const GREEN := Color("#3fae7a")
const GREEN_BRIGHT := Color("#49c48b")
const GREEN_DARK := Color("#329166")

const GOLD := Color("#f2b134")
const GOLD_SOFT := Color("#ffd166")

const ERROR := Color("#e66673")
const ERROR_DARK := Color("#b04a55")

const MISSED := Color("#151a25")
const GRID := Color("#2a3348")
const TRANSPARENT := Color(0, 0, 0, 0)
const DIM := Color(0.0196, 0.0275, 0.0471, 0.86)

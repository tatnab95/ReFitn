extends RefCounted

# Single source of truth for the app palette. New UI must take colors from here.
# Two palettes (dark is the default); apply() switches the static values in place,
# so every script that reads ThemeColors.X gets the active palette.

const PALETTE_DARK := {
	"bg": "#0A0F1F", "bg_deep": "#060A16", "surface": "#111A33", "surface_raised": "#1A2750",
	"surface_hover": "#22325E", "surface_pressed": "#0E1630", "surface_disabled": "#0D1222",
	"border": "#26366B", "blue": "#1E3A8A", "blue_hover": "#2A4BB0", "blue_deep": "#142A66",
	"green": "#22C55E", "green_dark": "#15803D", "gold": "#FBBF24", "gold_soft": "#FDE68A",
	"text": "#EAF0FF", "text_muted": "#8C9AC0", "danger": "#E5484D", "danger_dark": "#B93238",
	"missed": "#151E38",
}

const PALETTE_LIGHT := {
	"bg": "#F3F6FD", "bg_deep": "#DDE4F5", "surface": "#FFFFFF", "surface_raised": "#E6ECFA",
	"surface_hover": "#D6DFF4", "surface_pressed": "#EEF2FB", "surface_disabled": "#EEF1F7",
	"border": "#C5D0EC", "blue": "#1E40AF", "blue_hover": "#2B52CC", "blue_deep": "#1E3A8A",
	"green": "#16A34A", "green_dark": "#15803D", "gold": "#B7791F", "gold_soft": "#D69E2E",
	"text": "#0A0F1F", "text_muted": "#55638A", "danger": "#D93036", "danger_dark": "#B42328",
	"missed": "#EEF2FA",
}

# Text drawn on green buttons is always dark, white is unreadable on #22C55E.
const ON_GREEN_HEX := "#052E16"

static var BG := Color("#0A0F1F")
static var BG_DEEP := Color("#060A16")
static var SURFACE := Color("#111A33")
static var SURFACE_ALT := Color("#1A2750")
static var SURFACE_HOVER := Color("#22325E")
static var SURFACE_PRESSED := Color("#0E1630")
static var SURFACE_DISABLED := Color("#0D1222")

static var TEXT := Color("#EAF0FF")
static var MUTED := Color("#8C9AC0")

static var BLUE := Color("#1E3A8A")
static var BLUE_DEEP := Color("#142A66")
static var BLUE_SOFT := Color("#2A4BB0")

static var GREEN := Color("#22C55E")
static var GREEN_BRIGHT := Color("#22C55E")
static var GREEN_DARK := Color("#15803D")

static var GOLD := Color("#FBBF24")
static var GOLD_SOFT := Color("#FDE68A")

static var ERROR := Color("#E5484D")
static var ERROR_DARK := Color("#B93238")

static var MISSED := Color("#151E38")
static var GRID := Color("#26366B")
static var GRID_FAINT := Color(0.149, 0.212, 0.420, 0.35)
static var ON_GREEN := Color(ON_GREEN_HEX)
static var TRANSPARENT := Color(0, 0, 0, 0)
static var DIM := Color(0.039, 0.059, 0.122, 0.86)


static func apply(dark: bool) -> void:
	var p: Dictionary = PALETTE_DARK if dark else PALETTE_LIGHT
	BG = _c(p, "bg")
	BG_DEEP = _c(p, "bg_deep")
	SURFACE = _c(p, "surface")
	SURFACE_ALT = _c(p, "surface_raised")
	SURFACE_HOVER = _c(p, "surface_hover")
	SURFACE_PRESSED = _c(p, "surface_pressed")
	SURFACE_DISABLED = _c(p, "surface_disabled")
	TEXT = _c(p, "text")
	MUTED = _c(p, "text_muted")
	BLUE = _c(p, "blue")
	BLUE_DEEP = _c(p, "blue_deep")
	BLUE_SOFT = _c(p, "blue_hover")
	GREEN = _c(p, "green")
	GREEN_BRIGHT = _c(p, "green")
	GREEN_DARK = _c(p, "green_dark")
	GOLD = _c(p, "gold")
	GOLD_SOFT = _c(p, "gold_soft")
	ERROR = _c(p, "danger")
	ERROR_DARK = _c(p, "danger_dark")
	MISSED = _c(p, "missed")
	GRID = _c(p, "border")
	GRID_FAINT = Color(GRID, 0.35)
	DIM = Color(BG, 0.86)


static func _c(p: Dictionary, key: String) -> Color:
	return Color(str(p[key]))

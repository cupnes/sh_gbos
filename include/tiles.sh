if [ "${INCLUDE_TILES_SH+is_defined}" ]; then
	return
fi
INCLUDE_TILES_SH=true

GBOS_TILE_BYTES=10	# 一つのタイルは16バイト(0x10)

GBOS_CTRL_CHR_NL=0a

GBOS_TILE_NUM_SPC=00
GBOS_TILE_NUM_BLACK=09
GBOS_TILE_NUM_LIGHT_GRAY=0a
GBOS_TILE_NUM_FUNC_BTN=0b
GBOS_TILE_NUM_MINI_BTN=0c
GBOS_TILE_NUM_MAXI_BTN=0d
GBOS_TILE_NUM_CSL=0e
GBOS_TILE_NUM_UP_ARROW=12
GBOS_TYPE_ICON_TILE_BASE=38
GBOS_NUM_ICON_TILES=04

GBOS_ICON_NUM_EXE=01
GBOS_ICON_NUM_TXT=02
GBOS_ICON_NUM_IMG=03

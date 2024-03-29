if [ "${INCLUDE_TILES_SH+is_defined}" ]; then
	return
fi
INCLUDE_TILES_SH=true

GBOS_TILE_BYTES=10	# 一つのタイルは16バイト(0x10)

GBOS_CTRL_CHR_NL=0a
GBOS_CTRL_CHR_NULL=ff

GBOS_TILE_NUM_SPC=00
GBOS_TILE_NUM_UPPER_BAR=02
GBOS_TILE_NUM_RIGHT_BAR=04
GBOS_TILE_NUM_LOWER_BAR=06
GBOS_TILE_NUM_LEFT_BAR=08
GBOS_TILE_NUM_BLACK=09
GBOS_TILE_NUM_LIGHT_GRAY=0a
GBOS_TILE_NUM_FUNC_BTN=0b
GBOS_TILE_NUM_MINI_BTN=0c
GBOS_TILE_NUM_MAXI_BTN=0d
GBOS_TILE_NUM_CSL=0e
GBOS_TILE_NUM_UP_ARROW=12
GBOS_TILE_NUM_NUM_BASE=14
GBOS_TILE_NUM_ALPHA_BASE=1E	# 大文字指定
GBOS_TILE_NUM_OPEN_BRACKET=48
GBOS_TILE_NUM_CLOSE_BRACKET=49
GBOS_TILE_NUM_DAKUTEN=4b
GBOS_TILE_NUM_HIRA_BASE=4C
GBOS_TILE_NUM_HIRA_A=4c
GBOS_TILE_NUM_HIRA_I=4d
GBOS_TILE_NUM_HIRA_U=4e
GBOS_TILE_NUM_HIRA_KA=51
GBOS_TILE_NUM_HIRA_KI=52
GBOS_TILE_NUM_HIRA_KU=53
GBOS_TILE_NUM_HIRA_KE=54
GBOS_TILE_NUM_HIRA_KO=55
GBOS_TILE_NUM_HIRA_SA=56
GBOS_TILE_NUM_HIRA_SHI=57
GBOS_TILE_NUM_HIRA_SU=58
GBOS_TILE_NUM_HIRA_SE=59
GBOS_TILE_NUM_HIRA_TA=5b
GBOS_TILE_NUM_HIRA_CHI=5c
GBOS_TILE_NUM_HIRA_TSU=5d
GBOS_TILE_NUM_HIRA_TE=5e
GBOS_TILE_NUM_HIRA_TO=5f
GBOS_TILE_NUM_HIRA_NA=60
GBOS_TILE_NUM_HIRA_NI=61
GBOS_TILE_NUM_HIRA_NO=64
GBOS_TILE_NUM_HIRA_FU=67
GBOS_TILE_NUM_HIRA_HA=65
GBOS_TILE_NUM_HIRA_HE=68
GBOS_TILE_NUM_HIRA_HO=69
GBOS_TILE_NUM_HIRA_MA=6a
GBOS_TILE_NUM_HIRA_MO=6e
GBOS_TILE_NUM_HIRA_YU=70
GBOS_TILE_NUM_HIRA_YO=71
GBOS_TILE_NUM_HIRA_RA=72
GBOS_TILE_NUM_HIRA_RI=73
GBOS_TILE_NUM_HIRA_RU=74
GBOS_TILE_NUM_HIRA_RE=75
GBOS_TILE_NUM_HIRA_WO=78
GBOS_TILE_NUM_HIRA_N=79
GBOS_TILE_NUM_TOUTEN=7b
GBOS_TILE_NUM_KUTEN=7c
GBOS_TILE_NUM_EXCLAMATION=7d
GBOS_TILE_NUM_QUESTION=7e
GBOS_TILE_NUM_DASH=7f
GBOS_TILE_NUM_RIGHT_ARROW=84
GBOS_TYPE_ICON_TILE_BASE=38
GBOS_NUM_ICON_TILES=04

GBOS_ICON_NUM_EXE=01
GBOS_ICON_NUM_TXT=02
GBOS_ICON_NUM_IMG=03

get_num_tile_num() {
	local n=$1
	echo "obase=16;ibase=16;$GBOS_TILE_NUM_NUM_BASE + $n" | bc
}

ASCII_A_HEX=41
get_alpha_tile_num() {
	local ch=$1
	local ascii_num_hex=$(echo -n $ch | hexdump -e '1/1 "%02X"')
	local ascii_ofs_hex=$(echo "obase=16;ibase=16;$ascii_num_hex - $ASCII_A_HEX" | bc)
	echo "obase=16;ibase=16;$GBOS_TILE_NUM_ALPHA_BASE + $ascii_ofs_hex" | bc
}

if [ "${INCLUDE_GB_SH+is_defined}" ]; then
	return
fi
INCLUDE_GB_SH=true

. include/lr35902.sh
. include/common.sh

# 10進数での計算用
GB_ROM_BANK_SIZE_NOHEAD=16048
GB_ROM_BANK_SIZE=16384
GB_ROM_SIZE=32768
GB_VECT_SIZE=256
GB_HEAD_SIZE=80

# 以降、基本的に数値は16進数で定義

GB_ROM_FREE_BASE=0150
GB_DISP_WIDTH=a0
GB_DISP_HEIGHT=90
GB_DISP_WIDTH_T=14
GB_DISP_HEIGHT_T=12
GB_NON_DISP_WIDTH_T=0c	# $GB_SC_WIDTH_T - $GB_DISP_WIDTH_T
GB_SC_WIDTH_T=20	# $GB_DISP_WIDTH_T + $GB_NON_DISP_WIDTH_T
GB_SC_HEIGHT_T=20
GB_TILE_WIDTH=08
GB_TILE_HEIGHT=08

GB_WRAM1_BASE=d000

GB_NUM_ALL_OBJS=28

GB_OAM_BASE=FE00
GB_OAM_SZ=04	# 4 bytes
GB_OAM_ATTR_Y_FLIP=40

# I/O Ports
GB_IO_JOYP=00
GB_IO_SB=01
GB_IO_SC=02
GB_IO_TIMA=05
GB_IO_TAC=07
GB_IO_NR10=10
GB_IO_NR11=11
GB_IO_NR12=12
GB_IO_NR13=13
GB_IO_NR14=14
GB_IO_NR21=16
GB_IO_NR22=17
GB_IO_NR23=18
GB_IO_NR24=19
GB_IO_NR30=1a
GB_IO_NR31=1b
GB_IO_NR32=1c
GB_IO_NR33=1d
GB_IO_NR34=1e
GB_IO_NR41=20
GB_IO_NR42=21
GB_IO_NR43=22
GB_IO_NR44=23
GB_IO_NR50=24
GB_IO_NR51=25
GB_IO_NR52=26
GB_IO_LCDC=40
GB_IO_STAT=41
GB_IO_SCY=42
GB_IO_SCX=43
GB_IO_LY=44
GB_IO_LYC=45
GB_IO_BGP=47
GB_IO_OBP0=48
GB_IO_OBP1=49
GB_IO_WY=4a
GB_IO_WX=4b
GBC_IO_BGPI=68
GBC_IO_BGPD=69
GBC_IO_BGPD=69
GBC_IO_OBPI=6a
GBC_IO_OBPD=6b
GB_IO_IE=ff

GB_TAC_BIT_START=04
GB_TAC_BIT_HZ_262144=01

GB_NR10_BIT_SWEEP_OFF=00

GB_NR12_BIT_NO_SOUND_STOP_ENV=00

GB_NR14_BIT_RESTART_SOUND=80

GB_NR21_BIT_DUTY_50PCT=80

GB_NR22_BIT_INIT_ENV_VOL_8=80
GB_NR22_BIT_ENV_SWEEP_NUM_STOP_ENV=00
GB_NR22_BITNUM_INIT_ENV_VOL=04

GB_NR23_BIT_FREQ_A4=d6

GB_NR24_BIT_RESTART_SOUND=80
GB_NR24_BIT_COUNT_CONSEC_SEL=40
GB_NR24_BIT_FREQ_A4=06

GB_NR30_BIT_SOUND_CH3_OFF=80

GB_NR32_BIT_MUTE=00

GB_NR34_BIT_RESTART_SOUND=80

GB_NR41_BIT_SOUND_LEN_00=00

GB_NR42_BIT_INIT_ENV_VOL_MUTE=00

GB_NR44_BIT_RESTART_SOUND=80

GB_NR50_BIT_VIN_SO2_EN=80
GB_NR50_BIT_S02_LV_4=40
GB_NR50_BIT_S02_LV_SHIFT=4
GB_NR50_BIT_VIN_SO1_EN=08
GB_NR50_BIT_S01_LV_4=04
GB_NR50_BIT_S01_LV_SHIFT=0

GB_NR51_BIT_SOUND2_TO_SO2=20
GB_NR51_BIT_SOUND2_TO_SO1=02

GB_NR52_BIT_ALL_OFF=00
GB_NR52_BIT_ALL_ON=80
GB_NR52_BITNUM_ALL_ONOFF=7

GB_LCDC_BIT_DE=80

GB_LCDC_BITNUM_OBJ_SIZE=2
GB_LCDC_BITNUM_OE=1

GB_WX_ORIG=07

GB_BGP_DEFAULT=e4		# %11100100
GB_OBP_DEFAULT=e0		# %11100000
GBC_PI_BIT_AI=80	# auto increment
GBC_PLT_WHITE=7fff
GBC_PLT_LIGHT_GRAY=3def
GBC_PLT_DARK_GRAY=2108
GBC_PLT_BLACK=0000

GB_MBC_RAM_EN_ADDR=0000
GB_MBC_RAM_EN_VAL=0a
GB_MBC_ROM_BANK_ADDR=2000
GB_MBC_ROMRAM_BANK_ADDR=4000
GB_MBC_SEL_ROM=00
GB_MBC_SEL_RAM=01
GB_MBC_ROMRAM_SEL_ADDR=6000

GB_CARTROM_BANK1_BASE=4000
GB_CARTRAM_BASE=a000

# Nintendoロゴデータ
gb_nintendo_logo() {
	echo -en '\xce\xed\x66\x66\xcc\x0d\x00\x0b'
	echo -en '\x03\x73\x00\x83\x00\x0c\x00\x0d'
	echo -en '\x00\x08\x11\x1f\x88\x89\x00\x0e'
	echo -en '\xdc\xcc\x6e\xe6\xdd\xdd\xd9\x99'
	echo -en '\xbb\xbb\x67\x63\x6e\x0e\xec\xcc'
	echo -en '\xdd\xdc\x99\x9f\xbb\xb9\x33\x3e'
}

# タイトル文字列無しのヘッダ
gb_cart_header_no_title() {
	local entry_addr=$(four_digits $1)

	# エントリアドレスへジャンプ
	echo -en '\x00\xc3'
	echo_2bytes $entry_addr

	# Nintendoロゴデータ
	gb_nintendo_logo

	# アドレス0x0134-0x014c(25バイト)のヘッダ情報はすべて0にする
	dd if=/dev/zero bs=1 count=25 2>/dev/null

	# ヘッダのチェックサム
	echo -en '\xe7'

	# グローバルチェックサム
	# (実機では見ない情報だし設定しない)
	echo -en '\x00\x00'
}

# タイトル文字列無しのヘッダ(カートリッジタイプ:MBC1)
gb_cart_header_no_title_mbc1() {
	local entry_addr=$(four_digits $1)

	# エントリアドレスへジャンプ
	echo -en '\x00\xc3'
	echo_2bytes $entry_addr

	# Nintendoロゴデータ
	gb_nintendo_logo

	# アドレス0x0134-0x0142(15バイト)のヘッダ情報はすべて0にする
	dd if=/dev/zero bs=1 count=15 2>/dev/null

	# 0x0143 - CGB Flag
	# 0x80 - Game supports CGB functions, but works on old gameboys also.
	echo -en '\x80'

	# 0x0144-0145 - New Licensee Code
	# 0x00 - none
	echo -en '\x00\x00'

	# 0x0146 - SGB Flag
	# 0x03 - Game supports SGB functions
	echo -en '\x03'

	# 0x0147 - Cartridge Type
	# echo -en '\x01'	# MBC1
	echo -en '\x03'	# MBC1+RAM+BATTERY

	# 0x0148 - ROM Size
	# 0x01 - 64 KByte(4 banks)
	echo -en '\x01'

	# 0x0149 - RAM Size
	# 0x00 - None
	# echo -en '\x00'
	# 0x03 - 32 KBytes (4 banks of 8KBytes each)
	echo -en '\x03'

	# 0x014A - Destination Code
	# 0x00 - Japanese
	echo -en '\x00'

	# 0x014B - Old Licensee Code
	# A value of 33h signalizes that the New License Code in header bytes 0144-0145 is used instead.
	# (Super Game Boy functions won't work if <> $33.)
	echo -en '\x33'

	# 014C - Mask ROM Version number
	# Specifies the version number of the game. That is usually 00h.
	echo -en '\x00'

	# 014D - Header Checksum
	# echo -en '\x2f'
	echo -en '\x2a'

	# グローバルチェックサム
	# (実機では見ない情報だし設定しない)
	echo -en '\x00\x00'
}

gb_all_nop_vector_table() {
	dd if=/dev/zero bs=1 count=256 2>/dev/null
}

# 割り込みは全てretiで返すベクタテーブル
gb_all_intr_reti_vector_table() {
	dd if=/dev/zero bs=1 count=64 2>/dev/null
	lr35902_ei_and_ret
	dd if=/dev/zero bs=1 count=7 2>/dev/null
	lr35902_ei_and_ret
	dd if=/dev/zero bs=1 count=7 2>/dev/null
	lr35902_ei_and_ret
	dd if=/dev/zero bs=1 count=7 2>/dev/null
	lr35902_ei_and_ret
	dd if=/dev/zero bs=1 count=7 2>/dev/null
	lr35902_ei_and_ret
	dd if=/dev/zero bs=1 count=159 2>/dev/null
}

gb_reset_scroll_pos() {
	# スクロールレジスタクリア
	lr35902_clear_reg regA
	lr35902_copy_to_ioport_from_regA $GB_IO_SCY
	lr35902_copy_to_ioport_from_regA $GB_IO_SCX
}

gb_set_window_pos() {
	local x=$1
	local y=$2
	lr35902_set_reg regA $(calc16_2 "${GB_WX_ORIG}+$x")
	lr35902_copy_to_ioport_from_regA $GB_IO_WX
	lr35902_set_reg regA $y
	lr35902_copy_to_ioport_from_regA $GB_IO_WY
}

gb_set_palette_to_default() {
	# パレット初期化
	lr35902_set_reg regA $GB_BGP_DEFAULT
	lr35902_copy_to_ioport_from_regA $GB_IO_BGP
	lr35902_set_reg regA $GB_OBP_DEFAULT
	lr35902_copy_to_ioport_from_regA $GB_IO_OBP0
	lr35902_copy_to_ioport_from_regA $GB_IO_OBP1

	## GBC用パレットも初期化
	### BG 0
	lr35902_set_reg regA $GBC_PI_BIT_AI
	lr35902_copy_to_ioport_from_regA $GBC_IO_BGPI
	for _i in $(seq 8); do
		#### Color 0
		lr35902_set_reg regA $(echo $GBC_PLT_WHITE | cut -c3-4)
		lr35902_copy_to_ioport_from_regA $GBC_IO_BGPD
		lr35902_set_reg regA $(echo $GBC_PLT_WHITE | cut -c1-2)
		lr35902_copy_to_ioport_from_regA $GBC_IO_BGPD
		#### Color 1
		lr35902_set_reg regA $(echo $GBC_PLT_LIGHT_GRAY | cut -c3-4)
		lr35902_copy_to_ioport_from_regA $GBC_IO_BGPD
		lr35902_set_reg regA $(echo $GBC_PLT_LIGHT_GRAY | cut -c1-2)
		lr35902_copy_to_ioport_from_regA $GBC_IO_BGPD
		#### Color 2
		lr35902_set_reg regA $(echo $GBC_PLT_DARK_GRAY | cut -c3-4)
		lr35902_copy_to_ioport_from_regA $GBC_IO_BGPD
		lr35902_set_reg regA $(echo $GBC_PLT_DARK_GRAY | cut -c1-2)
		lr35902_copy_to_ioport_from_regA $GBC_IO_BGPD
		#### Color 3
		lr35902_set_reg regA $(echo $GBC_PLT_BLACK | cut -c3-4)
		lr35902_copy_to_ioport_from_regA $GBC_IO_BGPD
		lr35902_set_reg regA $(echo $GBC_PLT_BLACK | cut -c1-2)
		lr35902_copy_to_ioport_from_regA $GBC_IO_BGPD
	done

	### OBJ 0
	lr35902_set_reg regA $GBC_PI_BIT_AI
	lr35902_copy_to_ioport_from_regA $GBC_IO_OBPI
	for _i in $(seq 8); do
		#### Color 0
		lr35902_set_reg regA $(echo $GBC_PLT_WHITE | cut -c3-4)
		lr35902_copy_to_ioport_from_regA $GBC_IO_OBPD
		lr35902_set_reg regA $(echo $GBC_PLT_WHITE | cut -c1-2)
		lr35902_copy_to_ioport_from_regA $GBC_IO_OBPD
		#### Color 1
		lr35902_set_reg regA $(echo $GBC_PLT_WHITE | cut -c3-4)
		lr35902_copy_to_ioport_from_regA $GBC_IO_OBPD
		lr35902_set_reg regA $(echo $GBC_PLT_WHITE | cut -c1-2)
		lr35902_copy_to_ioport_from_regA $GBC_IO_OBPD
		#### Color 2
		lr35902_set_reg regA $(echo $GBC_PLT_DARK_GRAY | cut -c3-4)
		lr35902_copy_to_ioport_from_regA $GBC_IO_OBPD
		lr35902_set_reg regA $(echo $GBC_PLT_DARK_GRAY | cut -c1-2)
		lr35902_copy_to_ioport_from_regA $GBC_IO_OBPD
		#### Color 3
		lr35902_set_reg regA $(echo $GBC_PLT_BLACK | cut -c3-4)
		lr35902_copy_to_ioport_from_regA $GBC_IO_OBPD
		lr35902_set_reg regA $(echo $GBC_PLT_BLACK | cut -c1-2)
		lr35902_copy_to_ioport_from_regA $GBC_IO_OBPD
	done
}

gb_wait_for_vblank_to_start() {
	# vblankの開始の瞬間(LY=147)を待つ
	lr35902_copy_to_regA_from_ioport $GB_IO_LY
	lr35902_compare_regA_and 93
	lr35902_rel_jump_with_cond NZ $(two_comp 06)
}

gb_infinity_halt() {
	# 無限ループで止める
	lr35902_halt
	lr35902_rel_jump $(two_comp 04)
}

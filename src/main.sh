if [ "${SRC_MAIN_SH+is_defined}" ]; then
	return
fi
SRC_MAIN_SH=true

. include/gb.sh

GBOS_ROM_TILE_DATA_START=$GB_ROM_START_ADDR
GBOS_TILE_DATA_START=8000
GBOS_BG_TILEMAP_START=9800

gbos_vec() {
	gb_all_intr_reti_vector_table
}

GBOS_NUM_ALL_TILES=31
GBOS_NUM_ALL_TILE_BYTES=0310
gbos_const() {
	### タイルデータ(計49タイル,784(310)バイト) ###
	# [文字コード]
	# - 記号(13文字,208(d0)バイト)
	# ' '
	echo -en '\x00\x00\x00\x00\x00\x00\x00\x00'
	echo -en '\x00\x00\x00\x00\x00\x00\x00\x00'
	# ┌
	echo -en '\xff\xff\x80\x80\x80\x80\x80\x80'
	echo -en '\x80\x80\x80\x80\x80\x80\x80\x80'
	# ─(上)
	echo -en '\xff\xff\x00\x00\x00\x00\x00\x00'
	echo -en '\x00\x00\x00\x00\x00\x00\x00\x00'
	# ┐
	echo -en '\xff\xff\x01\x01\x01\x01\x01\x01'
	echo -en '\x01\x01\x01\x01\x01\x01\x01\x01'
	# │(右)
	echo -en '\x01\x01\x01\x01\x01\x01\x01\x01'
	echo -en '\x01\x01\x01\x01\x01\x01\x01\x01'
	# ┘
	echo -en '\x01\x01\x01\x01\x01\x01\x01\x01'
	echo -en '\x01\x01\x01\x01\x01\x01\xff\xff'
	# ─(下)
	echo -en '\x00\x00\x00\x00\x00\x00\x00\x00'
	echo -en '\x00\x00\x00\x00\x00\x00\xff\xff'
	# └
	echo -en '\x80\x80\x80\x80\x80\x80\x80\x80'
	echo -en '\x80\x80\x80\x80\x80\x80\xff\xff'
	# │(左)
	echo -en '\x80\x80\x80\x80\x80\x80\x80\x80'
	echo -en '\x80\x80\x80\x80\x80\x80\x80\x80'
	# →
	echo -en '\x00\x00\x08\x08\x04\x04\x02\x02'
	echo -en '\x7f\x7f\x02\x02\x04\x04\x08\x08'
	# ←
	echo -en '\x00\x00\x08\x08\x10\x10\x20\x20'
	echo -en '\x7f\x7f\x20\x20\x10\x10\x08\x08'
	# ↑
	echo -en '\x00\x00\x08\x08\x1c\x1c\x2a\x2a'
	echo -en '\x49\x49\x08\x08\x08\x08\x08\x08'
	# ↓
	echo -en '\x00\x00\x08\x08\x08\x08\x08\x08'
	echo -en '\x49\x49\x2a\x2a\x1c\x1c\x08\x08'
	# - 数字(10文字,160(a0)バイト)
	# 0
	echo -en '\x00\x00\x3e\x3e\x43\x43\x45\x45'
	echo -en '\x49\x49\x51\x51\x61\x61\x3e\x3e'
	# 1
	echo -en '\x00\x00\x08\x08\x18\x18\x08\x08'
	echo -en '\x08\x08\x08\x08\x08\x08\x3e\x3e'
	# 2
	echo -en '\x00\x00\x3e\x3e\x41\x41\x02\x02'
	echo -en '\x0c\x0c\x10\x10\x20\x20\x7f\x7f'
	# 3
	echo -en '\x00\x00\x3e\x3e\x41\x41\x02\x02'
	echo -en '\x0c\x0c\x02\x02\x41\x41\x3e\x3e'
	# 4
	echo -en '\x00\x00\x04\x04\x0c\x0c\x14\x14'
	echo -en '\x24\x24\x7f\x7f\x04\x04\x04\x04'
	# 5
	echo -en '\x00\x00\x7f\x7f\x40\x40\x40\x40'
	echo -en '\x7e\x7e\x01\x01\x41\x41\x3e\x3e'
	# 6
	echo -en '\x00\x00\x3e\x3e\x41\x41\x40\x40'
	echo -en '\x7e\x7e\x41\x41\x41\x41\x3e\x3e'
	# 7
	echo -en '\x00\x00\x7f\x7f\x41\x41\x01\x01'
	echo -en '\x02\x02\x04\x04\x08\x08\x10\x10'
	# 8
	echo -en '\x00\x00\x3e\x3e\x41\x41\x41\x41'
	echo -en '\x3e\x3e\x41\x41\x41\x41\x3e\x3e'
	# 9
	echo -en '\x00\x00\x3e\x3e\x41\x41\x41\x41'
	echo -en '\x3f\x3f\x01\x01\x41\x41\x3e\x3e'
	# - アルファベット(26文字,416(1a0)バイト)
	# A
	echo -en '\x00\x00\x1c\x1c\x22\x22\x41\x41'
	echo -en '\x41\x41\x7f\x7f\x41\x41\x41\x41'
	# B
	echo -en '\x00\x00\x7e\x7e\x41\x41\x41\x41'
	echo -en '\x7e\x7e\x41\x41\x41\x41\x7e\x7e'
	# C
	echo -en '\x00\x00\x3e\x3e\x41\x41\x40\x40'
	echo -en '\x40\x40\x40\x40\x41\x41\x3e\x3e'
	# D
	echo -en '\x00\x00\x7c\x7c\x42\x42\x41\x41'
	echo -en '\x41\x41\x41\x41\x42\x42\x7c\x7c'
	# E
	echo -en '\x00\x00\x7f\x7f\x40\x40\x40\x40'
	echo -en '\x7f\x7f\x40\x40\x40\x40\x7f\x7f'
	# F
	echo -en '\x00\x00\x7f\x7f\x40\x40\x40\x40'
	echo -en '\x7e\x7e\x40\x40\x40\x40\x40\x40'
	# G
	echo -en '\x00\x00\x3e\x3e\x41\x41\x40\x40'
	echo -en '\x4f\x4f\x41\x41\x41\x41\x3e\x3e'
	# H
	echo -en '\x00\x00\x41\x41\x41\x41\x41\x41'
	echo -en '\x7f\x7f\x41\x41\x41\x41\x41\x41'
	# I
	echo -en '\x00\x00\x3e\x3e\x08\x08\x08\x08'
	echo -en '\x08\x08\x08\x08\x08\x08\x3e\x3e'
	# J
	echo -en '\x00\x00\x07\x07\x02\x02\x02\x02'
	echo -en '\x02\x02\x02\x02\x22\x22\x1c\x1c'
	# K
	echo -en '\x00\x00\x43\x43\x44\x44\x48\x48'
	echo -en '\x50\x50\x68\x68\x44\x44\x43\x43'
	# L
	echo -en '\x00\x00\x40\x40\x40\x40\x40\x40'
	echo -en '\x40\x40\x40\x40\x40\x40\x7f\x7f'
	# M
	echo -en '\x00\x00\x41\x41\x41\x41\x63\x63'
	echo -en '\x55\x55\x49\x49\x41\x41\x41\x41'
	# N
	echo -en '\x00\x00\x41\x41\x61\x61\x51\x51'
	echo -en '\x49\x49\x45\x45\x43\x43\x41\x41'
	# O
	echo -en '\x00\x00\x3e\x3e\x41\x41\x41\x41'
	echo -en '\x41\x41\x41\x41\x41\x41\x3e\x3e'
	# P
	echo -en '\x00\x00\x7e\x7e\x41\x41\x41\x41'
	echo -en '\x7e\x7e\x40\x40\x40\x40\x40\x40'
	# Q
	echo -en '\x00\x00\x3e\x3e\x41\x41\x41\x41'
	echo -en '\x41\x41\x4d\x4d\x43\x43\x3f\x3f'
	# R
	echo -en '\x00\x00\x7e\x7e\x41\x41\x41\x41'
	echo -en '\x7e\x7e\x41\x41\x41\x41\x41\x41'
	# S
	echo -en '\x00\x00\x3e\x3e\x41\x41\x40\x40'
	echo -en '\x3e\x3e\x01\x01\x41\x41\x3e\x3e'
	# T
	echo -en '\x00\x00\x7f\x7f\x08\x08\x08\x08'
	echo -en '\x08\x08\x08\x08\x08\x08\x08\x08'
	# U
	echo -en '\x00\x00\x41\x41\x41\x41\x41\x41'
	echo -en '\x41\x41\x41\x41\x41\x41\x3e\x3e'
	# V
	echo -en '\x00\x00\x41\x41\x41\x41\x41\x41'
	echo -en '\x41\x41\x22\x22\x14\x14\x08\x08'
	# W
	echo -en '\x00\x00\x41\x41\x41\x41\x49\x49'
	echo -en '\x49\x49\x55\x55\x55\x55\x22\x22'
	# X
	echo -en '\x00\x00\x41\x41\x22\x22\x14\x14'
	echo -en '\x08\x08\x14\x14\x22\x22\x41\x41'
	# Y
	echo -en '\x00\x00\x41\x41\x22\x22\x14\x14'
	echo -en '\x08\x08\x08\x08\x08\x08\x08\x08'
	# Z
	echo -en '\x00\x00\x7f\x7f\x02\x02\x04\x04'
	echo -en '\x08\x08\x10\x10\x20\x20\x7f\x7f'
}

load_all_tiles() {
	local rel_sz
	local bc_radix='obase=16;ibase=16;'
	local bc_form="${GBOS_TILE_DATA_START}+${GBOS_NUM_ALL_TILE_BYTES}"
	local end_addr=$(echo "${bc_radix}${bc_form}" | bc)
	local end_addr_th=$(echo $end_addr | cut -c-2)
	local end_addr_bh=$(echo $end_addr | cut -c3-)
	lr35902_set_reg regDE $GBOS_ROM_TILE_DATA_START
	lr35902_set_reg regHL $GBOS_TILE_DATA_START
	(
		lr35902_copy_to_from regA ptrDE
		lr35902_copyinc_to_ptrHL_from_regA
		lr35902_copy_to_from regA regH
		lr35902_compare_regA_and $end_addr_th
		(
			lr35902_copy_to_from regA regL
			lr35902_compare_regA_and $end_addr_bh
			lr35902_rel_jump_with_cond Z 03
		) >src/load_all_tiles.1.o
		rel_sz=$(stat -c '%s' src/load_all_tiles.1.o)
		lr35902_rel_jump_with_cond NZ $(two_digits_d $rel_sz)
		cat src/load_all_tiles.1.o
		lr35902_inc regDE
	) >src/load_all_tiles.2.o
	cat src/load_all_tiles.2.o
	rel_sz=$(stat -c '%s' src/load_all_tiles.2.o)
	lr35902_rel_jump $(two_comp_d $((rel_sz + 2)))
}

clear_bg() {
	lr35902_set_reg regHL $GBOS_BG_TILEMAP_START
	lr35902_set_reg regB 20
	lr35902_clear_reg regA
	# >>loopB
	lr35902_set_reg regC 20				# 2
	# >>loopA
	lr35902_copyinc_to_ptrHL_from_regA		# 1
	lr35902_dec regC				# 1
	lr35902_rel_jump_with_cond NZ $(two_comp 04)	# 2
	# <<loopA
	lr35902_dec regB				# 1
	lr35902_rel_jump_with_cond NZ $(two_comp 07)	# 2
	# <<loopB
}

dump_all_tiles() {
	local rel_sz
	lr35902_set_reg regHL $GBOS_BG_TILEMAP_START
	lr35902_set_reg regB $GBOS_NUM_ALL_TILES
	lr35902_set_reg regDE $(four_digits $GB_NON_DISP_WIDTH_TILES)
	lr35902_clear_reg regC
	(
		lr35902_copy_to_from regA regC
		lr35902_copyinc_to_ptrHL_from_regA
		lr35902_copy_to_from regA regL
		lr35902_and_to_regA 1f
		lr35902_compare_regA_and $GB_DISP_WIDTH_TILES
		(
			lr35902_add_to_regHL regDE
		) >src/dump_all_tiles.1.o
		rel_sz=$(stat -c '%s' src/dump_all_tiles.1.o)
		lr35902_rel_jump_with_cond NZ $(two_digits_d $rel_sz)
		cat src/dump_all_tiles.1.o
		lr35902_inc regC
		lr35902_dec regB
	) >src/dump_all_tiles.2.o
	cat src/dump_all_tiles.2.o
	rel_sz=$(stat -c '%s' src/dump_all_tiles.2.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((rel_sz + 2)))
}

# 変数
var_crr_cur_1=c000	# キータイルを次に配置する場所(下位)
var_crr_cur_2=c001	# キータイルを次に配置する場所(上位)
var_btn_stat=c002	# 現在のキー状態を示す変数

init() {
	# 割り込みは一旦無効にする
	lr35902_disable_interrupts

	# SPをFFFE(HMEMの末尾)に設定
	lr35902_set_regHL_and_SP fffe

	# スクロールレジスタクリア
	gb_reset_scroll_pos

	# パレット初期化
	gb_set_palette_to_default

	# V-Blankの開始を待つ
	gb_wait_for_vblank_to_start

	# LCDを停止する
	# - 停止の間はVRAMとOAMに自由にアクセスできる(vblankとか関係なく)
	# - Bit 7の他も明示的に設定

	# [LCD制御レジスタの設定値]
	# - Bit 7: LCD Display Enable (0=Off, 1=On)
	#   -> LCDを停止させるため0
	# - Bit 6: Window Tile Map Display Select (0=9800-9BFF, 1=9C00-9FFF)
	#   -> 9800-9BFFは背景に使うため、
	#      ウィンドウタイルマップには9C00-9FFFを設定
	# - Bit 5: Window Display Enable (0=Off, 1=On)
	#   -> ウィンドウは使わないので0
	# - Bit 4: BG & Window Tile Data Select (0=8800-97FF, 1=8000-8FFF)
	#   -> タイルデータの配置領域は8000-8FFFにする
	# - Bit 3: BG Tile Map Display Select (0=9800-9BFF, 1=9C00-9FFF)
	#   -> 背景用のタイルマップ領域に9800-9BFFを使う
	# - Bit 2: OBJ (Sprite) Size (0=8x8, 1=8x16)
	#   -> スプライトはまだ使わないので適当に8x8を設定
	# - Bit 1: OBJ (Sprite) Display Enable (0=Off, 1=On)
	#   -> スプライトはまだ使わないので0
	# - Bit 0: BG Display (0=Off, 1=On)
	#   -> 背景は使うので1

	lr35902_set_reg regA 51
	lr35902_copy_to_ioport_from_regA $GB_IO_LCDC

	# タイルデータをVRAMのタイルデータ領域へロード
	load_all_tiles

	# VRAMの背景用タイルマップ領域を白タイル(タイル番号0)で初期化
	clear_bg

	# 画面へ全タイルをダンプ
	dump_all_tiles

	# V-Blank(b0)の割り込みのみ有効化
	lr35902_set_reg regA 01
	lr35902_copy_to_ioport_from_regA $GB_IO_IE

	# 変数初期化
	# - キータイルを次に配置する背景マップのアドレスを初期化
	lr35902_set_reg regA 98
	lr35902_copy_to_addr_from_regA $var_crr_cur_2
	lr35902_clear_reg regA
	lr35902_copy_to_addr_from_regA $var_crr_cur_1
	# - 入力状態を示す変数をゼロクリア
	lr35902_copy_to_addr_from_regA $var_btn_stat

	# 割り込み有効化
	lr35902_enable_interrupts

	# LCD再開
	lr35902_set_reg regA d1
	lr35902_copy_to_ioport_from_regA $GB_IO_LCDC
}

gbos_main() {
	init >src/init.o
	cat src/init.o

	# 以降、割り込み駆動の処理部
	lr35902_halt					# 2

	# [VRAMタイルマップ更新]

	# V-Blank期間中であることを確認(おそらくこの処理は不要)
	# lr35902_copy_to_regA_from_ioport $GB_IO_STAT	# 2
	# echo -en '\xe6\x03'	# and $03		# 2
	# echo -en '\xfe\x01'	# cp $01		# 2
	# lr35902_rel_jump_with_cond NZ 02		# 2
	# lr35902_rel_jump $(two_comp 0c)	# 必ずこちらに入る	# 2
	# lr35902_rel_jump $(two_comp 0e)			# 2

	# 入力状態の変数値に応じてタイルを配置し配置場所更新
	## 同時押しがあればキーの数だけ実施する

	# 現在の入力状態と次のタイル配置アドレスをメモリから取得
	lr35902_copy_to_regA_from_addr $var_btn_stat	# 3
	lr35902_copy_to_from regC regA			# 1
	lr35902_copy_to_regA_from_addr $var_crr_cur_1	# 3
	lr35902_copy_to_from regL regA			# 1
	lr35902_copy_to_regA_from_addr $var_crr_cur_2	# 3
	lr35902_copy_to_from regH regA			# 1

	# - b7 スタートボタン の処理
	echo -en '\xcb\x79'	# bit 7,c		# 2
	lr35902_rel_jump_with_cond Z 05			# 2
	lr35902_set_reg regA 01				# 2
	echo -en '\xcb\xb9'	# res 7,c		# 2
	lr35902_copyinc_to_ptrHL_from_regA		# 1

	# 次のタイル配置アドレスをメモリへ格納
	lr35902_copy_to_from regA regL			# 1
	lr35902_copy_to_addr_from_regA $var_crr_cur_1	# 3
	lr35902_copy_to_from regA regH			# 1
	lr35902_copy_to_addr_from_regA $var_crr_cur_2	# 3



	# [キー入力処理]
	# チャタリング(あるのか？)等のノイズ除去は未実装

	# * ボタンキーの入力チェック *
	# ボタンキー側の入力を取得するように設定
	lr35902_copy_to_regA_from_ioport $GB_IO_JOYP	# 2
	echo -en '\xcb\xaf'	# res 5,a		# 2
	echo -en '\xcb\xe7'	# set 4,a		# 2
	lr35902_copy_to_ioport_from_regA $GB_IO_JOYP	# 2

	# 改めて入力取得
	lr35902_copy_to_regA_from_ioport $GB_IO_JOYP	# 2
	# ノイズ除去のため2回読む
	lr35902_copy_to_regA_from_ioport $GB_IO_JOYP	# 2
	lr35902_copy_to_from regB regA			# 1

	# スタートキーは押下中か？
	echo -en '\xcb\x58'	# bit 3,b		# 2
	lr35902_rel_jump_with_cond NZ 04		# 2
	# >>キー押下中の処理
	echo -en '\xcb\xf9'	# set 7,c		# 2
	lr35902_rel_jump 02				# 2
	# <<キー押下中の処理
	# >>キー押下が無かった場合の処理
	echo -en '\xcb\xb9'	# res 7,c		# 2
	# <<キー押下が無かった場合の処理

	# セレクトキーは押下中か？
	echo -en '\xcb\x50'	# bit 2,b		# 2
	lr35902_rel_jump_with_cond NZ 04		# 2
	# >>キー押下中の処理
	echo -en '\xcb\xf1'	# set 6,c		# 2
	lr35902_rel_jump 02				# 2
	# <<キー押下中の処理
	# >>キー押下が無かった場合の処理
	echo -en '\xcb\xb1'	# res 6,c		# 2
	# <<キー押下が無かった場合の処理

	# Bキーは押下中か？
	echo -en '\xcb\x48'	# bit 1,b		# 2
	lr35902_rel_jump_with_cond NZ 04		# 2
	# >>キー押下中の処理
	echo -en '\xcb\xe9'	# set 5,c		# 2
	lr35902_rel_jump 02				# 2
	# <<キー押下中の処理
	# >>キー押下が無かった場合の処理
	echo -en '\xcb\xa9'	# res 5,c		# 2
	# <<キー押下が無かった場合の処理

	# Aキーは押下中か？
	echo -en '\xcb\x40'	# bit 0,b		# 2
	lr35902_rel_jump_with_cond NZ 04		# 2
	# >>キー押下中の処理
	echo -en '\xcb\xe1'	# set 4,c		# 2
	lr35902_rel_jump 02				# 2
	# <<キー押下中の処理
	# >>キー押下が無かった場合の処理
	echo -en '\xcb\xa1'	# res 4,c		# 2
	# <<キー押下が無かった場合の処理

	# * 方向キーの入力チェック *
	# 方向キー側の入力を取得するように設定
	lr35902_copy_to_regA_from_ioport $GB_IO_JOYP	# 2
	echo -en '\xcb\xef'	# set 5,a		# 2
	echo -en '\xcb\xa7'	# res 4,a		# 2
	lr35902_copy_to_ioport_from_regA $GB_IO_JOYP	# 2

	# 改めて入力取得
	lr35902_copy_to_regA_from_ioport $GB_IO_JOYP	# 2
	# ノイズ除去のため2回読む
	lr35902_copy_to_regA_from_ioport $GB_IO_JOYP	# 2
	lr35902_copy_to_from regB regA			# 1

	# ↓キーは押下中か？
	echo -en '\xcb\x58'	# bit 3,b		# 2
	lr35902_rel_jump_with_cond NZ 04		# 2
	# >>キー押下中の処理
	echo -en '\xcb\xd9'	# set 3,c		# 2
	lr35902_rel_jump 02				# 2
	# <<キー押下中の処理
	# >>キー押下が無かった場合の処理
	echo -en '\xcb\x99'	# res 3,c		# 2
	# <<キー押下が無かった場合の処理

	# ↑キーは押下中か？
	echo -en '\xcb\x50'	# bit 2,b		# 2
	lr35902_rel_jump_with_cond NZ 04		# 2
	# >>キー押下中の処理
	echo -en '\xcb\xd1'	# set 2,c		# 2
	lr35902_rel_jump 02				# 2
	# <<キー押下中の処理
	# >>キー押下が無かった場合の処理
	echo -en '\xcb\x91'	# res 2,c		# 2
	# <<キー押下が無かった場合の処理

	# ←キーは押下中か？
	echo -en '\xcb\x48'	# bit 1,b		# 2
	lr35902_rel_jump_with_cond NZ 04		# 2
	# >>キー押下中の処理
	echo -en '\xcb\xc9'	# set 1,c		# 2
	lr35902_rel_jump 02				# 2
	# <<キー押下中の処理
	# >>キー押下が無かった場合の処理
	echo -en '\xcb\x89'	# res 1,c		# 2
	# <<キー押下が無かった場合の処理

	# →キーは押下中か？
	echo -en '\xcb\x40'	# bit 0,b		# 2
	lr35902_rel_jump_with_cond NZ 04		# 2
	# >>キー押下中の処理
	echo -en '\xcb\xc1'	# set 0,c		# 2
	lr35902_rel_jump 02				# 2
	# <<キー押下中の処理
	# >>キー押下が無かった場合の処理
	echo -en '\xcb\x81'	# res 0,c		# 2
	# <<キー押下が無かった場合の処理

	# 現在の入力状態をメモリ上の変数へ保存
	lr35902_copy_to_from regA regC			# 1
	lr35902_copy_to_addr_from_regA $var_btn_stat	# 3

	# 割り込み待ち(halt)へ戻る
	# lr35902_rel_jump $(two_comp 76)			# 2
	# (+ 2 4 (* 2 (+ 8 5 40)) 4 2)118
	gbos_const >src/gbos_const.o
	local const_bytes=$(stat -c '%s' src/gbos_const.o)
	local init_bytes=$(stat -c '%s' src/init.o)
	local bc_form="obase=16;${const_bytes}+${init_bytes}"
	local const_init=$(echo $bc_form | bc)
	bc_form="obase=16;ibase=16;${GB_ROM_START_ADDR}+${const_init}"
	local halt_addr=$(echo $bc_form | bc)
	echo -en "\xc3"
	echo_2bytes $(four_digits $halt_addr)	# jp $halt_addr
}

if [ "${SRC_MAIN_SH+is_defined}" ]; then
	return
fi
SRC_MAIN_SH=true

. include/gb.sh

gbos_vec() {
	gb_all_intr_reti_vector_table
}

gbos_const() {
	# ' '
	echo -en '\x00\x00\x00\x00\x00\x00\x00\x00'
	echo -en '\x00\x00\x00\x00\x00\x00\x00\x00'

	# S
	echo -en '\x00\x00\x3e\x3e\x41\x41\x40\x40'
	echo -en '\x3e\x3e\x01\x01\x41\x41\x3e\x3e'
	# L
	echo -en '\x00\x00\x40\x40\x40\x40\x40\x40'
	echo -en '\x40\x40\x40\x40\x40\x40\x7f\x7f'
	# B
	echo -en '\x00\x00\x7e\x7e\x41\x41\x41\x41'
	echo -en '\x7e\x7e\x41\x41\x41\x41\x7e\x7e'
	# A
	echo -en '\x00\x00\x1c\x1c\x22\x22\x41\x41'
	echo -en '\x41\x41\x7f\x7f\x41\x41\x41\x41'

	# Down
	echo -en '\x00\x00\x08\x08\x08\x08\x08\x08'
	echo -en '\x49\x49\x2a\x2a\x1c\x1c\x08\x08'
	# Up
	echo -en '\x00\x00\x08\x08\x1c\x1c\x2a\x2a'
	echo -en '\x49\x49\x08\x08\x08\x08\x08\x08'
	# Left
	echo -en '\x00\x00\x08\x08\x10\x10\x20\x20'
	echo -en '\x7f\x7f\x20\x20\x10\x10\x08\x08'
	# Right
	echo -en '\x00\x00\x08\x08\x04\x04\x02\x02'
	echo -en '\x7f\x7f\x02\x02\x04\x04\x08\x08'
}

clear_bg() {
	lr35902_set_reg regHL 9800
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
	lr35902_set_reg regDE 0150
	lr35902_set_reg regHL 8000
	lr35902_set_reg regB 90
	(
		lr35902_copy_to_from regA ptrDE
		lr35902_copy_to_from ptrHL regA
		lr35902_inc regDE
		lr35902_inc regHL
		lr35902_dec regB
	) >src/init.loop.o
	cat src/init.loop.o
	local loop_sz=$(stat -c '%s' src/init.loop.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((loop_sz + 2)))

	# VRAMの背景用タイルマップ領域を白タイル(タイル番号0)で初期化
	clear_bg

	# V-Blank(b0)の割り込みのみ有効化
	lr35902_set_reg regA 01
	lr35902_copy_to_ioport_from_regA $GB_IO_IE
}

gbos_main() {
	init

	# 変数
	local var_crr_cur_1=c000	# キータイルを次に配置する場所(下位)
	local var_crr_cur_2=c001	# キータイルを次に配置する場所(上位)
	local var_btn_stat=c002	# 現在のキー状態を示す変数

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
	echo -en '\xc3\x2b\x02'	# jp $022b
}

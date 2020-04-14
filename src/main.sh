if [ "${SRC_MAIN_SH+is_defined}" ]; then
	return
fi
SRC_MAIN_SH=true

. include/gb.sh
. src/tiles.sh

GBOS_WIN_DEF_X_T=00
GBOS_WIN_DEF_Y_T=00

# ウィンドウの見かけ上の幅/高さ
# (描画用の1タイル分の幅/高さは除く)
GBOS_WIN_WIDTH_T=$(calc16_2 "${GB_DISP_WIDTH_T}-2")
GBOS_WIN_HEIGHT_T=$(calc16_2 "${GB_DISP_HEIGHT_T}-2")
GBOS_WIN_DRAWABLE_WIDTH_T=$(calc16_2 "${GBOS_WIN_WIDTH_T}-2")
GBOS_WIN_DRAWABLE_HEIGHT_T=$(calc16_2 "${GBOS_WIN_HEIGHT_T}-3")
GBOS_WIN_DRAWABLE_BASE_XT=$(calc16_2 "${GBOS_WIN_DEF_X_T}+2")
GBOS_WIN_DRAWABLE_MAX_XT=$(calc16_2 "${GBOS_WIN_DRAWABLE_BASE_XT}+${GBOS_WIN_DRAWABLE_WIDTH_T}-1")

GBOS_WX_DEF=00
GBOS_WY_DEF=00
GBOS_ROM_TILE_DATA_START=$GB_ROM_START_ADDR
GBOS_TILE_DATA_START=8000
GBOS_BG_TILEMAP_START=9800
GBOS_WINDOW_TILEMAP_START=9c00
GBOS_FS_BASE=4000

# マウス座標
## TODO: ウィンドウを動かすようになったら
##       GBOS_WIN_DEF_{X,Y}_Tを使っている部分は直す
## ウィンドウのアイコン領域のベースアドレス
GBOS_ICON_BASE_X=$(
	calc16_2 "(${GBOS_WIN_DEF_X_T}*${GB_TILE_WIDTH})+(${GB_TILE_WIDTH}*2)"
		)
GBOS_ICON_BASE_Y=$(
	calc16_2 "(${GBOS_WIN_DEF_Y_T}*${GB_TILE_HEIGHT})+(${GB_TILE_HEIGHT}*3)"
		)
CLICK_WIDTH=$(calc16_2 "${GB_TILE_WIDTH}*2")
CLICK_HEIGHT=$(calc16_2 "${GB_TILE_HEIGHT}*2")

# [LCD制御レジスタのベース設定値]
# - Bit 7: LCD Display Enable (0=Off, 1=On)
#   -> LCDはOn/Offは変わるためベースでは0
# - Bit 6: Window Tile Map Display Select (0=9800-9BFF, 1=9C00-9FFF)
#   -> ウィンドウタイルマップには9C00-9FFF(1)を設定
# - Bit 5: Window Display Enable (0=Off, 1=On)
#   -> ウィンドウはまずは使わないので0
# - Bit 4: BG & Window Tile Data Select (0=8800-97FF, 1=8000-8FFF)
#   -> タイルデータの配置領域は8000-8FFF(1)にする
# - Bit 3: BG Tile Map Display Select (0=9800-9BFF, 1=9C00-9FFF)
#   -> 背景用のタイルマップ領域に9800-9BFF(0)を使う
# - Bit 2: OBJ (Sprite) Size (0=8x8, 1=8x16)
#   -> スプライトサイズは8x16(1)
# - Bit 1: OBJ (Sprite) Display Enable (0=Off, 1=On)
#   -> スプライト使うので1
# - Bit 0: BG Display (0=Off, 1=On)
#   -> 背景は使うので1
GBOS_LCDC_BASE=57	# %0101 0111($57)

GBOS_OBJ_WIDTH=08
GBOS_OBJ_HEIGHT=10
GBOS_OBJ_DEF_ATTR=00	# %0000 0000($00)

GBOS_OAM_BASE=fe00
GBOS_OAM_SZ=04	# 4 bytes
GBOS_OAM_NUM_CSL=00

GBOS_DIR_KEY_MASK=0f	# $var_btn_stat の十字キー入力のみ抽出するマスク
GBOS_DOWN_KEY_MASK=08
GBOS_UP_KEY_MASK=04
GBOS_LEFT_KEY_MASK=02
GBOS_RIGHT_KEY_MASK=01

GBOS_BTN_KEY_MASK=f0	# $var_btn_stat のボタン入力のみ抽出するマスク
GBOS_START_KEY_MASK=80
GBOS_SELECT_KEY_MASK=40
GBOS_B_KEY_MASK=20
GBOS_A_KEY_MASK=10

# 描画アクション(DA)ステータス用定数
GBOS_DA_BITNUM_CLR_WIN=0
GBOS_DA_BITNUM_VIEW_TXT=2

# 変数
var_mouse_x=c000	# マウスカーソルX座標
var_mouse_y=c001	# マウスカーソルY座標
var_btn_stat=c002	# 現在のキー状態を示す変数
var_win_xt=c003	# ウィンドウのX座標(タイル番目)
var_win_yt=c004	# ウィンドウのY座標(タイル番目)
var_prv_btn=c005	# 前回のキー状態を示す変数
var_draw_act_stat=c006	# 描画アクション(DA)ステータス
var_da_var1=c007	# DA用変数1
			# - view_txt: 残り文字数(下位8ビット)
var_da_var2=c008	# DA用変数2
			# - view_txt: 残り文字数(上位8ビット)
var_da_var3=c009	# DA用変数3
			# - view_txt: 次に配置する文字のアドレス下位8ビット
var_da_var4=c00a	# DA用変数4
			# - view_txt: 次に配置する文字のアドレス上位8ビット
var_da_var5=c00b	# DA用変数5
			# - view_txt: 次に配置するウィンドウタイル座標Y
var_da_var6=c00c	# DA用変数6
			# - view_txt: 次に配置するウィンドウタイル座標X
var_clr_win_nyt=c00d	# - clr_win: 次にクリアするウィンドウタイル座標Y

# タイル座標をアドレスへ変換
# in : regD  - タイル座標Y
#      regE  - タイル座標X
# out: regHL - 9800h〜のアドレスを格納
a_tcoord_to_addr=$GBOS_GFUNC_START
f_tcoord_to_addr() {
	local sz

	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE

	lr35902_set_reg regHL $GBOS_BG_TILEMAP_START
	lr35902_clear_reg regA
	lr35902_compare_regA_and regD
	(
		lr35902_set_reg regBC $(four_digits $GB_SC_WIDTH_T)
		(
			lr35902_add_to_regHL regBC
			lr35902_dec regD
		) >src/f_tcoord_to_addr.1.o
		cat src/f_tcoord_to_addr.1.o
		sz=$(stat -c '%s' src/f_tcoord_to_addr.1.o)
		lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz + 2)))
	) >src/f_tcoord_to_addr.2.o
	sz=$(stat -c '%s' src/f_tcoord_to_addr.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz)
	cat src/f_tcoord_to_addr.2.o
	lr35902_add_to_regHL regDE

	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

# ウィンドウタイル座標をタイル座標へ変換
# in : regD  - ウィンドウタイル座標Y
#      regE  - ウィンドウタイル座標X
# out: regD  - タイル座標Y
#      regE  - タイル座標X
f_tcoord_to_addr >src/f_tcoord_to_addr.o
fsz=$(to16 $(stat -c '%s' src/f_tcoord_to_addr.o))
a_wtcoord_to_tcoord=$(four_digits $(calc16 "${a_tcoord_to_addr}+${fsz}"))
f_wtcoord_to_tcoord() {
	lr35902_push_reg regAF

	lr35902_copy_to_regA_from_addr $var_win_yt
	lr35902_add_to_regA regD
	lr35902_copy_to_from regD regA
	lr35902_copy_to_regA_from_addr $var_win_xt
	lr35902_add_to_regA regE
	lr35902_copy_to_from regE regA

	lr35902_pop_reg regAF
	lr35902_return
}

# タイル座標の位置へ指定されたタイルを配置する
# in : regA  - 配置するタイル番号
#      regD  - タイル座標Y
#      regE  - タイル座標X
f_wtcoord_to_tcoord >src/f_wtcoord_to_tcoord.o
fsz=$(to16 $(stat -c '%s' src/f_wtcoord_to_tcoord.o))
fadr=$(calc16 "${a_wtcoord_to_tcoord}+${fsz}")
a_lay_tile_at_tcoord=$(four_digits $fadr)
f_lay_tile_at_tcoord() {
	lr35902_call $a_tcoord_to_addr
	lr35902_copy_to_ptrHL_from regA

	lr35902_return
}

# ウィンドウタイル座標の位置へ指定されたタイルを配置する
# in : regA  - 配置するタイル番号
#      regD  - ウィンドウタイル座標Y
#      regE  - ウィンドウタイル座標X
f_lay_tile_at_tcoord >src/f_lay_tile_at_tcoord.o
fsz=$(to16 $(stat -c '%s' src/f_lay_tile_at_tcoord.o))
fadr=$(calc16 "${a_lay_tile_at_tcoord}+${fsz}")
a_lay_tile_at_wtcoord=$(four_digits $fadr)
f_lay_tile_at_wtcoord() {
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	lr35902_call $a_wtcoord_to_tcoord
	lr35902_call $a_tcoord_to_addr
	lr35902_copy_to_ptrHL_from regA

	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_return
}

# タイル座標の位置から右へ指定されたタイルを並べる
# in : regA  - 並べるタイル番号
#      regC  - 並べる個数
#      regD  - タイル座標Y
#      regE  - タイル座標X
f_lay_tile_at_wtcoord >src/f_lay_tile_at_wtcoord.o
fsz=$(to16 $(stat -c '%s' src/f_lay_tile_at_wtcoord.o))
fadr=$(calc16 "${a_lay_tile_at_wtcoord}+${fsz}")
a_lay_tiles_at_tcoord_to_right=$(four_digits $fadr)
f_lay_tiles_at_tcoord_to_right() {
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	lr35902_call $a_tcoord_to_addr
	(
		lr35902_copyinc_to_ptrHL_from_regA
		lr35902_dec regC
	) >src/f_lay_tiles_at_tcoord_to_right.1.o
	cat src/f_lay_tiles_at_tcoord_to_right.1.o
	local sz=$(stat -c '%s' src/f_lay_tiles_at_tcoord_to_right.1.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz + 2)))

	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_return
}

# ウィンドウタイル座標の位置から右へ指定されたタイルを並べる
# in : regA  - 並べるタイル番号
#      regC  - 並べる個数
#      regD  - ウィンドウタイル座標Y
#      regE  - ウィンドウタイル座標X
f_lay_tiles_at_tcoord_to_right >src/f_lay_tiles_at_tcoord_to_right.o
fsz=$(to16 $(stat -c '%s' src/f_lay_tiles_at_tcoord_to_right.o))
fadr=$(calc16 "${a_lay_tiles_at_tcoord_to_right}+${fsz}")
a_lay_tiles_at_wtcoord_to_right=$(four_digits $fadr)
f_lay_tiles_at_wtcoord_to_right() {
	lr35902_push_reg regDE

	lr35902_call $a_wtcoord_to_tcoord
	lr35902_call $a_lay_tiles_at_tcoord_to_right

	lr35902_pop_reg regDE
	lr35902_return
}

# タイル座標の位置から下へ指定されたタイルを並べる
# in : regA  - 並べるタイル番号
#      regC  - 並べる個数
#      regD  - タイル座標Y
#      regE  - タイル座標X
f_lay_tiles_at_wtcoord_to_right >src/f_lay_tiles_at_wtcoord_to_right.o
fsz=$(to16 $(stat -c '%s' src/f_lay_tiles_at_wtcoord_to_right.o))
fadr=$(calc16 "${a_lay_tiles_at_wtcoord_to_right}+${fsz}")
a_lay_tiles_at_tcoord_to_low=$(four_digits $fadr)
f_lay_tiles_at_tcoord_to_low() {
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	lr35902_call $a_tcoord_to_addr
	lr35902_set_reg regDE $(four_digits $GB_SC_WIDTH_T)
	(
		lr35902_copy_to_ptrHL_from regA
		lr35902_add_to_regHL regDE
		lr35902_dec regC
	) >src/f_lay_tiles_at_tcoord_to_low.1.o
	cat src/f_lay_tiles_at_tcoord_to_low.1.o
	local sz=$(stat -c '%s' src/f_lay_tiles_at_tcoord_to_low.1.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz + 2)))

	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_return
}

# ウィンドウタイル座標の位置から下へ指定されたタイルを並べる
# in : regA  - 並べるタイル番号
#      regC  - 並べる個数
#      regD  - ウィンドウタイル座標Y
#      regE  - ウィンドウタイル座標X
f_lay_tiles_at_tcoord_to_low >src/f_lay_tiles_at_tcoord_to_low.o
fsz=$(to16 $(stat -c '%s' src/f_lay_tiles_at_tcoord_to_low.o))
fadr=$(calc16 "${a_lay_tiles_at_tcoord_to_low}+${fsz}")
a_lay_tiles_at_wtcoord_to_low=$(four_digits $fadr)
f_lay_tiles_at_wtcoord_to_low() {
	lr35902_push_reg regDE

	lr35902_call $a_wtcoord_to_tcoord
	lr35902_call $a_lay_tiles_at_tcoord_to_low

	lr35902_pop_reg regDE
	lr35902_return
}

# オブジェクト番号をOAMアドレスへ変換
# in : regC  - オブジェクト番号(00h〜27h)
# out: regHL - OAMアドレス(FE00h〜FE9Ch)
f_lay_tiles_at_wtcoord_to_low >src/f_lay_tiles_at_wtcoord_to_low.o
fsz=$(to16 $(stat -c '%s' src/f_lay_tiles_at_wtcoord_to_low.o))
fadr=$(calc16 "${a_lay_tiles_at_wtcoord_to_low}+${fsz}")
a_objnum_to_addr=$(four_digits $fadr)
f_objnum_to_addr() {
	lr35902_push_reg regBC

	lr35902_clear_reg regB
	lr35902_shift_left_arithmetic regC
	lr35902_shift_left_arithmetic regC
	lr35902_set_reg regHL $GB_OAM_BASE
	lr35902_add_to_regHL regBC

	lr35902_pop_reg regBC
	lr35902_return
}

# オブジェクトの座標を設定
# in : regC - オブジェクト番号
#      regA - 座標Y
#      regB - 座標X
f_objnum_to_addr >src/f_objnum_to_addr.o
fsz=$(to16 $(stat -c '%s' src/f_objnum_to_addr.o))
fadr=$(calc16 "${a_objnum_to_addr}+${fsz}")
a_set_objpos=$(four_digits $fadr)
f_set_objpos() {
	lr35902_push_reg regHL

	lr35902_call $a_objnum_to_addr
	lr35902_copyinc_to_ptrHL_from_regA
	lr35902_copy_to_ptrHL_from regB

	lr35902_pop_reg regHL
	lr35902_return
}

# アイコンをウィンドウ座標に配置
# in : regA - アイコン番号
#      regD - ウィンドウタイル座標Y
#      regE - ウィンドウタイル座標X
f_set_objpos >src/f_set_objpos.o
fsz=$(to16 $(stat -c '%s' src/f_set_objpos.o))
fadr=$(calc16 "${a_set_objpos}+${fsz}")
a_lay_icon=$(four_digits $fadr)
f_lay_icon() {
	lr35902_push_reg regAF
	lr35902_push_reg regDE

	# アイコン番号を、アイコンのベースタイル番号へ変換
	# (1アイコン辺りのタイル数が4なので、アイコン番号を4倍する)
	lr35902_shift_left_arithmetic regA
	lr35902_shift_left_arithmetic regA

	# 配置するアイコンの1つ目のタイル番号を算出
	lr35902_add_to_regA $GBOS_TYPE_ICON_TILE_BASE

	# 左上
	lr35902_call $a_lay_tile_at_wtcoord
	lr35902_inc regA

	# 右上
	lr35902_inc regE
	lr35902_call $a_lay_tile_at_wtcoord
	lr35902_inc regA

	# 右下
	lr35902_inc regD
	lr35902_call $a_lay_tile_at_wtcoord
	lr35902_inc regA

	# 左下
	lr35902_dec regE
	lr35902_call $a_lay_tile_at_wtcoord

	lr35902_pop_reg regDE
	lr35902_pop_reg regAF
	lr35902_return
}

# ウィンドウ内をクリア
f_lay_icon >src/f_lay_icon.o
fsz=$(to16 $(stat -c '%s' src/f_lay_icon.o))
fadr=$(calc16 "${a_lay_icon}+${fsz}")
a_clr_win=$(four_digits $fadr)
f_clr_win() {
	lr35902_push_reg regAF

	# DA用変数設定
	lr35902_set_reg regA 03
	lr35902_copy_to_addr_from_regA $var_clr_win_nyt

	# DASにclr_winのビットをセット
	lr35902_copy_to_regA_from_addr $var_draw_act_stat
	lr35902_set_bitN_of_reg $GBOS_DA_BITNUM_CLR_WIN regA
	lr35902_copy_to_addr_from_regA $var_draw_act_stat

	lr35902_pop_reg regAF
	lr35902_return
}
f_clr_win_old2() {
	# 計時(*clr_win.2): ここから(*clr_win.3)までで 1/4096 秒
	# (* (/ 1 4096.0) 1000)0.244140625 ms
	lr35902_push_reg regAF
	lr35902_push_reg regDE

	lr35902_set_reg regA $GBOS_TILE_NUM_SPC

	lr35902_set_reg regD 03
	lr35902_set_reg regE 02
	lr35902_call $a_lay_tile_at_tcoord

	lr35902_inc regE
	lr35902_call $a_lay_tile_at_tcoord

	lr35902_inc regD
	lr35902_call $a_lay_tile_at_tcoord

	lr35902_dec regE
	lr35902_call $a_lay_tile_at_tcoord

	lr35902_pop_reg regDE
	lr35902_pop_reg regAF
	# 計時(*clr_win.3)
	lr35902_return
}
f_clr_win_old() {
	# 計時(*f_clr_win.1): ここから(*f_clr_win.2)までで 14/4096 秒
	# (* (/ 14 4096.0) 1000) 3.41796875 ms
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE

	lr35902_set_reg regA $GBOS_TILE_NUM_SPC
	lr35902_set_reg regC $GBOS_WIN_DRAWABLE_WIDTH_T
	lr35902_set_reg regD 03
	lr35902_set_reg regE 02
	lr35902_set_reg regB $GBOS_WIN_DRAWABLE_HEIGHT_T

	(
		lr35902_call $a_lay_tiles_at_wtcoord_to_right
		lr35902_inc regD
		lr35902_dec regB
	) >src/f_clr_win.1.o
	cat src/f_clr_win.1.o
	local sz=$(stat -c '%s' src/f_clr_win.1.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz+2)))

	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	# 計時(*f_clr_win.2)
	lr35902_return
}

# テキストファイルを表示
# TODO 現状、ファイルは一つしか無いのでファイル番号などを引数で渡しはしない
f_clr_win >src/f_clr_win.o
fsz=$(to16 $(stat -c '%s' src/f_clr_win.o))
fadr=$(calc16 "${a_clr_win}+${fsz}")
a_view_txt=$(four_digits $fadr)
f_view_txt() {
	lr35902_push_reg regAF

	lr35902_call $a_clr_win

	# DA用変数設定

	# 残り文字数
	# 現状、ファイルは一つしか無い想定なので
	# 1つ目のファイルサイズが書かれている場所へのオフセットは
	# 0x000aで固定
	local file_sz_ofs=000a
	local file_sz_addr=$(calc16 "${GBOS_FS_BASE}+${file_sz_ofs}")
	lr35902_copy_to_regA_from_addr $file_sz_addr
	lr35902_copy_to_addr_from_regA $var_da_var1
	# TODO まずはファイルサイズは256バイト未満ということにする
	lr35902_clear_reg regA
	lr35902_copy_to_addr_from_regA $var_da_var2

	# 次に配置する文字のアドレス
	# 同様に1つ目のファイルデータへのオフセットは
	# 0x000cで固定
	local file_data_ofs=000c
	local file_data_addr=$(calc16 "${GBOS_FS_BASE}+${file_data_ofs}")
	lr35902_set_reg regA $(echo $file_data_addr | cut -c3-4)
	lr35902_copy_to_addr_from_regA $var_da_var3
	lr35902_set_reg regA $(echo $file_data_addr | cut -c1-2)
	lr35902_copy_to_addr_from_regA $var_da_var4

	# 次に配置するウィンドウタイル座標
	lr35902_set_reg regA 03	# Y座標
	lr35902_copy_to_addr_from_regA $var_da_var5
	lr35902_set_reg regA 02	# X座標
	lr35902_copy_to_addr_from_regA $var_da_var6

	# DASにview_txtのフラグ設定
	lr35902_copy_to_regA_from_addr $var_draw_act_stat
	lr35902_set_bitN_of_reg $GBOS_DA_BITNUM_VIEW_TXT regA
	lr35902_copy_to_addr_from_regA $var_draw_act_stat

	lr35902_pop_reg regAF
	lr35902_return
}

# view_txt用周期ハンドラ
# TODO 現状、文字数は255文字まで(1バイト以内)
f_view_txt >src/f_view_txt.o
fsz=$(to16 $(stat -c '%s' src/f_view_txt.o))
fadr=$(calc16 "${a_view_txt}+${fsz}")
a_view_txt_cyc=$(four_digits $fadr)
f_view_txt_cyc() {
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	# 次に配置する文字をregBへ取得
	lr35902_copy_to_regA_from_addr $var_da_var3
	lr35902_copy_to_from regL regA
	lr35902_copy_to_regA_from_addr $var_da_var4
	lr35902_copy_to_from regH regA
	lr35902_copyinc_to_regA_from_ptrHL
	lr35902_copy_to_from regB regA

	# 次に配置するウィンドウタイル座標を (X, Y) = (regE, regD) へ取得
	lr35902_copy_to_regA_from_addr $var_da_var5
	lr35902_copy_to_from regD regA
	lr35902_copy_to_regA_from_addr $var_da_var6
	lr35902_copy_to_from regE regA

	# regBが改行文字か否か
	lr35902_copy_to_from regA regB
	lr35902_compare_regA_and $GBOS_CTRL_CHR_NL
	(
		# 改行文字である場合

		# 次に配置するX座標を描画領域の開始座標にする
		lr35902_set_reg regA $GBOS_WIN_DRAWABLE_BASE_XT
		lr35902_copy_to_addr_from_regA $var_da_var6
		# 次に配置するY座標をインクリメントする
		lr35902_inc regD
		lr35902_copy_to_from regA regD
		lr35902_copy_to_addr_from_regA $var_da_var5
		## TODO 1画面を超える場合の対処は未実装
	) >src/f_view_txt_cyc.1.o
	(
		# 改行文字でない場合

		# 配置する文字をregAへ設定
		lr35902_copy_to_from regA regB

		# タイル配置の関数を呼び出す
		lr35902_call $a_lay_tile_at_wtcoord

		# 次に配置する座標更新
		## 現在のX座標は描画領域右端であるか
		lr35902_copy_to_from regA regE
		lr35902_compare_regA_and $GBOS_WIN_DRAWABLE_MAX_XT
		(
			# 右端である場合

			# 次に配置するX座標を描画領域の開始座標にする
			lr35902_set_reg regA $GBOS_WIN_DRAWABLE_BASE_XT
			lr35902_copy_to_addr_from_regA $var_da_var6
			# 次に配置するY座標をインクリメントする
			lr35902_inc regD
			lr35902_copy_to_from regA regD
			lr35902_copy_to_addr_from_regA $var_da_var5
			## TODO 1画面を超える場合の対処は未実装
		) >src/f_view_txt_cyc.3.o
		(
			# 右端でない場合

			# X座標をインクリメントして変数へ書き戻す
			lr35902_inc regA
			lr35902_copy_to_addr_from_regA $var_da_var6

			# 右端である場合の処理を飛ばす
			local sz_3=$(stat -c '%s' src/f_view_txt_cyc.3.o)
			lr35902_rel_jump $(two_digits_d $sz_3)
		) >src/f_view_txt_cyc.4.o
		local sz_4=$(stat -c '%s' src/f_view_txt_cyc.4.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_4)
		# 右端でない場合
		cat src/f_view_txt_cyc.4.o
		# 右端である場合
		cat src/f_view_txt_cyc.3.o

		# 改行文字である場合の処理を飛ばす
		local sz_1=$(stat -c '%s' src/f_view_txt_cyc.1.o)
		lr35902_rel_jump $(two_digits_d $sz_1)
	) >src/f_view_txt_cyc.2.o
	local sz_2=$(stat -c '%s' src/f_view_txt_cyc.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	# 改行文字でない場合
	cat src/f_view_txt_cyc.2.o
	# 改行文字である場合
	cat src/f_view_txt_cyc.1.o

	# 残り文字数更新
	## TODO 上位8ビットの対処
	##      (そのため現状は255文字までしか対応していない)
	lr35902_copy_to_regA_from_addr $var_da_var1
	lr35902_dec regA
	(
		# 残り文字数が0になった場合

		# DASのview_txtのビットを下ろす
		lr35902_copy_to_regA_from_addr $var_draw_act_stat
		lr35902_res_bitN_of_reg $GBOS_DA_BITNUM_VIEW_TXT regA
		lr35902_copy_to_addr_from_regA $var_draw_act_stat
	) >src/f_view_txt_cyc.5.o
	(
		# 残り文字数が0にならなかった場合

		# 残り文字数を変数へ書き戻す
		lr35902_copy_to_addr_from_regA $var_da_var1

		# 次に配置する文字のアドレス更新
		lr35902_copy_to_from regA regL
		lr35902_copy_to_addr_from_regA $var_da_var3
		lr35902_copy_to_from regA regH
		lr35902_copy_to_addr_from_regA $var_da_var4

		# 残り文字数が0になった場合の処理を飛ばす
		local sz_5=$(stat -c '%s' src/f_view_txt_cyc.5.o)
		lr35902_rel_jump $(two_digits_d $sz_5)
	) >src/f_view_txt_cyc.6.o
	local sz_6=$(stat -c '%s' src/f_view_txt_cyc.6.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_6)
	# 残り文字数が0にならなかった場合
	cat src/f_view_txt_cyc.6.o
	# 残り文字数が0になった場合
	cat src/f_view_txt_cyc.5.o

	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

# clr_win用周期ハンドラ
f_view_txt_cyc >src/f_view_txt_cyc.o
fsz=$(to16 $(stat -c '%s' src/f_view_txt_cyc.o))
fadr=$(calc16 "${a_view_txt_cyc}+${fsz}")
a_clr_win_cyc=$(four_digits $fadr)
f_clr_win_cyc() {
	lr35902_push_reg regAF
	lr35902_push_reg regDE

	# 次にクリアするウィンドウタイルY行を取得
	lr35902_copy_to_regA_from_addr $var_clr_win_nyt
	lr35902_copy_to_from regD regA

	# クリア開始X座標を設定
	lr35902_set_reg regE 02

	# クリアに使う文字を設定
	lr35902_set_reg regA $GBOS_TILE_NUM_SPC

	# 並べる個数(描画幅)を設定
	lr35902_set_reg regC $GBOS_WIN_DRAWABLE_WIDTH_T

	# タイル配置の関数を呼び出す
	lr35902_call $a_lay_tiles_at_wtcoord_to_right

	# 終端判定
	lr35902_copy_to_from regA regD
	lr35902_compare_regA_and $(calc16_2 "2+${GBOS_WIN_DRAWABLE_HEIGHT_T}")
	(
		# Y座標が描画最終行と等しい

		# DASのclr_winのビットを下ろす
		lr35902_copy_to_regA_from_addr $var_draw_act_stat
		lr35902_res_bitN_of_reg $GBOS_DA_BITNUM_CLR_WIN regA
		lr35902_copy_to_addr_from_regA $var_draw_act_stat

		# pop & return
		lr35902_pop_reg regDE
		lr35902_pop_reg regAF
		lr35902_return
	) >src/f_clr_win_cyc.1.o
	local sz_1=$(stat -c '%s' src/f_clr_win_cyc.1.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $sz_1)
	cat src/f_clr_win_cyc.1.o

	# 次にクリアする行更新
	lr35902_inc regD
	lr35902_copy_to_from regA regD
	lr35902_copy_to_addr_from_regA $var_clr_win_nyt

	lr35902_pop_reg regDE
	lr35902_pop_reg regAF
	lr35902_return
}

# V-Blankハンドラ
# f_vblank_hdlr() {
	# V-Blank/H-Blank時の処理は、
	# mainのHaltループ内でその他の処理と直列に実施する
	# ∵ 割り込み時にフラグレジスタをスタックへプッシュしない上に
	#    手動でプッシュする命令も無いため
	#    任意のタイミングで割り込みハンドラが実施される設計にするには
	#    割り込まれる可能性のある処理全てで
	#    「フラグレジスタへ影響を与える命令〜条件付きジャンプ」
	#    をdi〜eiで保護する必要が出てくる
	#    また、現状の分量であれば全てV-Blank期間に収まる

	# lr35902_ei_and_ret
# }

# 0500h〜の領域に配置される
global_functions() {
	f_tcoord_to_addr
	f_wtcoord_to_tcoord
	f_lay_tile_at_tcoord
	f_lay_tile_at_wtcoord
	f_lay_tiles_at_tcoord_to_right
	f_lay_tiles_at_wtcoord_to_right
	f_lay_tiles_at_tcoord_to_low
	f_lay_tiles_at_wtcoord_to_low
	f_objnum_to_addr
	f_set_objpos
	f_lay_icon
	f_clr_win
	f_view_txt
	f_view_txt_cyc
	f_clr_win_cyc
}

gbos_vec() {
	dd if=/dev/zero bs=1 count=64 2>/dev/null

	# V-Blank (INT 40h)
	# lr35902_abs_jump $a_vblank_hdlr
	# dd if=/dev/zero bs=1 count=$((8 - 3)) 2>/dev/null
	lr35902_ei_and_ret
	dd if=/dev/zero bs=1 count=7 2>/dev/null

	# LCD STAT (INT 48h)
	lr35902_ei_and_ret
	dd if=/dev/zero bs=1 count=7 2>/dev/null

	# Timer (INT 50h)
	lr35902_ei_and_ret
	dd if=/dev/zero bs=1 count=7 2>/dev/null

	# Serial (INT 58h)
	lr35902_ei_and_ret
	dd if=/dev/zero bs=1 count=7 2>/dev/null

	# Joypad (INT 60h)
	lr35902_ei_and_ret
	dd if=/dev/zero bs=1 count=159 2>/dev/null
}

gbos_const() {
	char_tiles
	dd if=/dev/zero bs=1 count=$GBOS_TILERSV_AREA_BYTES 2>/dev/null
	global_functions
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
	local sz
	lr35902_set_reg regHL $GBOS_BG_TILEMAP_START
	lr35902_set_reg regB $GB_SC_HEIGHT_T
	lr35902_clear_reg regA
	(
		lr35902_set_reg regC $GB_SC_WIDTH_T
		(
			lr35902_copyinc_to_ptrHL_from_regA
			lr35902_dec regC
		) >src/clear_bg.1.o
		cat src/clear_bg.1.o
		sz=$(stat -c '%s' src/clear_bg.1.o)
		lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz+2)))
		lr35902_dec regB
	) >src/clear_bg.2.o
	cat src/clear_bg.2.o
	sz=$(stat -c '%s' src/clear_bg.2.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz+2)))
}

lay_tiles_in_grid() {
	lr35902_set_reg regHL 9800
	lr35902_set_reg regB 20
	lr35902_clear_reg regA
	# (
		lr35902_set_reg regC 20
		echo -en '\xee\x01'	# xor 1
		# (
			lr35902_copyinc_to_ptrHL_from_regA
			echo -en '\xee\x01'	# xor 1
			lr35902_dec regC
			lr35902_rel_jump_with_cond NZ $(two_comp 06)
		# )
		lr35902_dec regB
		lr35902_rel_jump_with_cond NZ $(two_comp 0d)
	# )
}

dump_all_tiles() {
	local rel_sz
	lr35902_set_reg regHL $GBOS_BG_TILEMAP_START
	lr35902_set_reg regB $GBOS_NUM_ALL_TILES
	lr35902_set_reg regDE $(four_digits $GB_NON_DISP_WIDTH_T)
	lr35902_clear_reg regC
	(
		lr35902_copy_to_from regA regC
		lr35902_copyinc_to_ptrHL_from_regA
		lr35902_copy_to_from regA regL
		lr35902_and_to_regA 1f
		lr35902_compare_regA_and $GB_DISP_WIDTH_T
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

hide_all_objs() {
	lr35902_clear_reg regA
	lr35902_set_reg regC $GB_NUM_ALL_OBJS
	(
		lr35902_dec regC
		lr35902_call $a_set_objpos
		lr35902_compare_regA_and regC
	) >src/hide_all_objs.1.o
	cat src/hide_all_objs.1.o
	local sz=$(stat -c '%s' src/hide_all_objs.1.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz+2)))
}

set_win_coord() {
	local xt=$1
	local yt=$2
	lr35902_set_reg regA $xt
	lr35902_copy_to_addr_from_regA $var_win_xt
	lr35902_set_reg regA $yt
	lr35902_copy_to_addr_from_regA $var_win_yt
}

draw_blank_window() {
	# local sz

	# タイトルバーを描画

	lr35902_set_reg regA 06	# _
	lr35902_set_reg regC $GBOS_WIN_WIDTH_T
	lr35902_set_reg regD 00
	lr35902_set_reg regE 01
	lr35902_call $a_lay_tiles_at_wtcoord_to_right

	lr35902_set_reg regD $GBOS_WIN_HEIGHT_T
	lr35902_call $a_lay_tiles_at_wtcoord_to_right

	lr35902_set_reg regA 02	# -(上付き)
	lr35902_set_reg regD 02
	lr35902_call $a_lay_tiles_at_wtcoord_to_right

	lr35902_set_reg regA $GBOS_TILE_NUM_LIGHT_GRAY
	lr35902_set_reg regC $(calc16 "${GBOS_WIN_WIDTH_T}-3")
	lr35902_set_reg regD 01
	lr35902_set_reg regE 02
	lr35902_call $a_lay_tiles_at_wtcoord_to_right

	lr35902_set_reg regA 04	# |(右付き)
	lr35902_set_reg regC $GBOS_WIN_HEIGHT_T
	lr35902_set_reg regD 01
	lr35902_set_reg regE 00
	lr35902_call $a_lay_tiles_at_wtcoord_to_low

	lr35902_set_reg regA 08	# |(左付き)
	lr35902_set_reg regE $(calc16 "${GBOS_WIN_WIDTH_T}+1")
	lr35902_call $a_lay_tiles_at_wtcoord_to_low

	lr35902_set_reg regA $GBOS_TILE_NUM_FUNC_BTN
	lr35902_set_reg regC 01
	lr35902_set_reg regE 01
	lr35902_call $a_lay_tiles_at_wtcoord_to_low

	lr35902_set_reg regA $GBOS_TILE_NUM_MINI_BTN
	lr35902_set_reg regC 01
	lr35902_set_reg regE $(calc16 "${GBOS_WIN_WIDTH_T}-1")
	lr35902_call $a_lay_tiles_at_wtcoord_to_low

	lr35902_set_reg regA $GBOS_TILE_NUM_MAXI_BTN
	lr35902_set_reg regC 01
	lr35902_set_reg regE ${GBOS_WIN_WIDTH_T}
	lr35902_call $a_lay_tiles_at_wtcoord_to_low
}

# 初期アイコン描画
draw_init_icons() {
	lr35902_set_reg regA $GBOS_ICON_NUM_IMG
	lr35902_set_reg regD 03
	lr35902_set_reg regE 02
	lr35902_call $a_lay_icon
}

# TODO グローバル関数化
obj_init() {
	local oam_num=$1
	local y=$2
	local x=$3
	local tile_num=$4
	local attr=$5

	local oam_addr=$(calc16 "${GBOS_OAM_BASE}+(${oam_num}*${GBOS_OAM_SZ})")
	lr35902_set_reg regHL $oam_addr

	lr35902_set_reg regA $y
	lr35902_copyinc_to_ptrHL_from_regA

	lr35902_set_reg regA $x
	lr35902_copyinc_to_ptrHL_from_regA

	lr35902_set_reg regA $tile_num
	lr35902_copyinc_to_ptrHL_from_regA

	lr35902_set_reg regA $attr
	lr35902_copyinc_to_ptrHL_from_regA
}

init() {
	# 割り込みは一旦無効にする
	lr35902_disable_interrupts

	# SPをFFFE(HMEMの末尾)に設定
	lr35902_set_regHL_and_SP fffe

	# スクロールレジスタクリア
	gb_reset_scroll_pos

	# ウィンドウ座標レジスタへ初期値設定
	gb_set_window_pos $GBOS_WX_DEF $GBOS_WY_DEF

	# パレット初期化
	gb_set_palette_to_default

	# V-Blankの開始を待つ
	gb_wait_for_vblank_to_start

	# LCDを停止する
	# - 停止の間はVRAMとOAMに自由にアクセスできる(vblankとか関係なく)
	lr35902_set_reg regA ${GBOS_LCDC_BASE}
	lr35902_copy_to_ioport_from_regA $GB_IO_LCDC

	# タイルデータをVRAMのタイルデータ領域へロード
	load_all_tiles

	# 背景タイルマップを白タイル(タイル番号0)で初期化
	clear_bg

	# OAMを初期化(全て非表示にする)
	hide_all_objs

	# ウィンドウ座標(タイル番目)の変数へデフォルト値設定
	set_win_coord $GBOS_WIN_DEF_X_T $GBOS_WIN_DEF_Y_T

	# タイトル・中身空のウィンドウを描画
	draw_blank_window

	# 初期アイコンを配置
	draw_init_icons

	# マウスカーソルを描画
	obj_init $GBOS_OAM_NUM_CSL $GBOS_OBJ_HEIGHT $GBOS_OBJ_WIDTH \
		 $GBOS_TILE_NUM_CSL $GBOS_OBJ_DEF_ATTR
	# 別途 obj_move とかの関数も作る
	# TODO グローバル関数化

	# V-Blank(b0)の割り込みのみ有効化
	lr35902_set_reg regA 01
	lr35902_copy_to_ioport_from_regA $GB_IO_IE

	# 変数初期化
	# - マウスカーソルX,Y座標を画面左上で初期化
	lr35902_set_reg regA $GBOS_OBJ_WIDTH
	lr35902_copy_to_addr_from_regA $var_mouse_x
	lr35902_set_reg regA $GBOS_OBJ_HEIGHT
	lr35902_copy_to_addr_from_regA $var_mouse_y
	# - 入力状態を示す変数をゼロクリア
	lr35902_clear_reg regA
	lr35902_copy_to_addr_from_regA $var_btn_stat
	lr35902_copy_to_addr_from_regA $var_prv_btn
	# - DASをゼロクリア
	lr35902_copy_to_addr_from_regA $var_draw_act_stat

	# LCD再開
	lr35902_set_reg regA $(calc16 "${GBOS_LCDC_BASE}+${GB_LCDC_BIT_DE}")
	lr35902_copy_to_ioport_from_regA $GB_IO_LCDC

	# 割り込み有効化
	lr35902_enable_interrupts
}

# マウスカーソル座標更新
# in : regD - 現在のキーの状態
update_mouse_cursor() {
	local sz

	# マウスカーソル座標を変数から取得
	## regB ← X座標
	lr35902_copy_to_regA_from_addr $var_mouse_x
	lr35902_copy_to_from regB regA
	## regC ← Y座標
	lr35902_copy_to_regA_from_addr $var_mouse_y
	lr35902_copy_to_from regC regA

	# ↓の押下状態確認
	lr35902_copy_to_from regA regD
	lr35902_and_to_regA $GBOS_DOWN_KEY_MASK
	(
		lr35902_inc regC
	) >src/update_mouse_cursor.1.o
	sz=$(stat -c '%s' src/update_mouse_cursor.1.o)
	lr35902_rel_jump_with_cond Z $(two_digits $sz)
	cat src/update_mouse_cursor.1.o

	# ↑の押下状態確認
	lr35902_copy_to_from regA regD
	lr35902_and_to_regA $GBOS_UP_KEY_MASK
	(
		lr35902_dec regC
	) >src/update_mouse_cursor.2.o
	sz=$(stat -c '%s' src/update_mouse_cursor.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits $sz)
	cat src/update_mouse_cursor.2.o

	# ←の押下状態確認
	lr35902_copy_to_from regA regD
	lr35902_and_to_regA $GBOS_LEFT_KEY_MASK
	(
		lr35902_dec regB
	) >src/update_mouse_cursor.3.o
	sz=$(stat -c '%s' src/update_mouse_cursor.3.o)
	lr35902_rel_jump_with_cond Z $(two_digits $sz)
	cat src/update_mouse_cursor.3.o

	# →の押下状態確認
	lr35902_copy_to_from regA regD
	lr35902_and_to_regA $GBOS_RIGHT_KEY_MASK
	(
		lr35902_inc regB
	) >src/update_mouse_cursor.4.o
	sz=$(stat -c '%s' src/update_mouse_cursor.4.o)
	lr35902_rel_jump_with_cond Z $(two_digits $sz)
	cat src/update_mouse_cursor.4.o

	# OAM更新
	lr35902_copy_to_from regA regC
	lr35902_set_reg regC $GBOS_OAM_NUM_CSL
	lr35902_call $a_set_objpos

	# 変数へ反映
	lr35902_copy_to_addr_from_regA $var_mouse_y
	lr35902_copy_to_from regA regB
	lr35902_copy_to_addr_from_regA $var_mouse_x
}

# クリックイベント処理
click_event() {
	local sz
	local sx=$(calc16_2 "${GBOS_ICON_BASE_X}+${GBOS_OBJ_WIDTH}")
	local sy=$(calc16_2 "${GBOS_ICON_BASE_Y}+${GBOS_OBJ_HEIGHT}")
	local ex=$(calc16_2 "${GBOS_ICON_BASE_X}+${CLICK_WIDTH}+${GBOS_OBJ_WIDTH}")
	local ey=$(calc16_2 "${GBOS_ICON_BASE_Y}+${CLICK_HEIGHT}+${GBOS_OBJ_HEIGHT}")

	lr35902_copy_to_regA_from_addr $var_mouse_x
	lr35902_compare_regA_and $ex
	(
		lr35902_compare_regA_and $sx
		(
			lr35902_copy_to_regA_from_addr $var_mouse_y
			lr35902_compare_regA_and $ey
			(
				lr35902_compare_regA_and $sy
				(
					# lr35902_call $a_clr_win
					lr35902_call $a_view_txt
				) >src/click_event.4.o
				sz=$(stat -c '%s' src/click_event.4.o)
				lr35902_rel_jump_with_cond C $(two_digits_d $sz)
				cat src/click_event.4.o
			) >src/click_event.3.o
			sz=$(stat -c '%s' src/click_event.3.o)
			lr35902_rel_jump_with_cond NC $(two_digits_d $sz)
			cat src/click_event.3.o
		) >src/click_event.2.o
		sz=$(stat -c '%s' src/click_event.2.o)
		lr35902_rel_jump_with_cond C $(two_digits_d $sz)
		cat src/click_event.2.o
	) >src/click_event.1.o
	sz=$(stat -c '%s' src/click_event.1.o)
	lr35902_rel_jump_with_cond NC $(two_digits_d $sz)
	cat src/click_event.1.o
}

# ボタンリリースに応じた処理
# in : regA - リリースされたボタン(上位4ビット)
btn_release_handler() {
	lr35902_and_to_regA $GBOS_B_KEY_MASK
	(
		click_event
	) >src/btn_release_handler.1.o
	local sz=$(stat -c '%s' src/btn_release_handler.1.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz)
	cat src/btn_release_handler.1.o
}

# DASのビットに応じた処理を呼び出す
# in : regA - DAS
das_handler() {
	# clr_winのチェック
	lr35902_test_bitN_of_reg $GBOS_DA_BITNUM_CLR_WIN regA
	(
		# clr_winがセットされていなかった場合

		# view_txtのチェック
		lr35902_test_bitN_of_reg $GBOS_DA_BITNUM_VIEW_TXT regA
		(
			# view_txtがセットされていた場合
			lr35902_call $a_view_txt_cyc
		) >src/das_handler.3.o
		local sz_3=$(stat -c '%s' src/das_handler.3.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_3)
		cat src/das_handler.3.o
	) >src/das_handler.1.o
	(
		# clr_winがセットされていた場合
		lr35902_call $a_clr_win_cyc

		# clr_winがセットされていなかった場合の処理を飛ばす
		local sz_1=$(stat -c '%s' src/das_handler.1.o)
		lr35902_rel_jump $(two_digits_d $sz_1)
	) >src/das_handler.2.o
	local sz_2=$(stat -c '%s' src/das_handler.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	# clr_winがセットされていた場合
	cat src/das_handler.2.o
	# clr_winがセットされていなかった場合
	cat src/das_handler.1.o
}

# 2020-03-05 19時現在
# 処理時間: 1/4096 秒
# (* (/ 1 4096.0) 1000.0)0.244140625 ms
# (/ 1000000 4096.0)244.140625 us
#
# 1496サイクル(計上していないものもある)
# 4.19MHz -> (/ 1000 4.19)238.6634844868735 ns/cyc
# (* 238 1496)356048 ns -> 356.048 us
# これは本来は通らない条件も全て含んでいる
# より正確なのは↑の244 usで、概ね同じ数値が出ているので
# ↑の244usは妥当そうだと言える
event_driven() {
	local sz

	lr35902_halt



	# [マウスカーソル更新]

	# 現在の入力状態を変数から取得
	# 計時(*0): ここから(*1)までで 1/4096 秒
	# (* (/ 1 4096.0) 1000)0.244140625 ms
	lr35902_copy_to_regA_from_addr $var_btn_stat
	lr35902_copy_to_from regD regA

	# 十字キー入力の有無確認
	lr35902_and_to_regA $GBOS_DIR_KEY_MASK
	(
		# 十字キー入力があればマウスカーソル座標更新
		update_mouse_cursor
	) >src/event_driven.1.o
	sz=$(stat -c '%s' src/event_driven.1.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz)
	cat src/event_driven.1.o

	# DASに何らかのビットがセットされているか
	lr35902_copy_to_regA_from_addr $var_draw_act_stat
	lr35902_compare_regA_and 00
	(
		# DASに何らかのビットがセットされていた場合の処理
		das_handler
	) >src/event_driven.4.o
	(
		# DASにビットが何もセットされていなかった場合の処理
		# (ボタンリリースに応じた処理を実施)

		# 前回の入力状態を変数から取得
		lr35902_copy_to_regA_from_addr $var_prv_btn
		lr35902_copy_to_from regE regA

		# リリースのみ抽出(1->0の変化があったビットのみregAへ格納)
		# 1. 現在と前回でxor
		lr35902_xor_to_regA regD
		# 2. 1.と前回でand
		lr35902_and_to_regA regE

		# ボタンのリリースがあった場合それに応じた処理を実施
		lr35902_and_to_regA $GBOS_BTN_KEY_MASK
		(
			# ボタンリリースがあれば応じた処理を実施
			btn_release_handler
		) >src/event_driven.2.o
		sz=$(stat -c '%s' src/event_driven.2.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz)
		cat src/event_driven.2.o

		# DAS用の処理は飛ばす
		local sz2=$(stat -c '%s' src/event_driven.4.o)
		lr35902_rel_jump $(two_digits_d $sz2)
	) >src/event_driven.3.o
	sz=$(stat -c '%s' src/event_driven.3.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz)
	# DASにビットが何もセットされていなかった場合の処理
	# (ボタンリリースに応じた処理を実施)
	cat src/event_driven.3.o
	# DASにビットがセットされていた場合の処理
	cat src/event_driven.4.o

	# 前回の入力状態更新
	lr35902_copy_to_from regA regD
	lr35902_copy_to_addr_from_regA $var_prv_btn



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



	# [割り込み待ち(halt)へ戻る]
	# lr35902_rel_jump $(two_comp 76)			# 2
	# (+ 2 4 (* 2 (+ 8 5 40)) 4 2)118
	gbos_const >src/gbos_const.o
	local const_bytes=$(stat -c '%s' src/gbos_const.o)
	local init_bytes=$(stat -c '%s' src/init.o)
	local bc_form="obase=16;${const_bytes}+${init_bytes}"
	local const_init=$(echo $bc_form | bc)
	bc_form="obase=16;ibase=16;${GB_ROM_START_ADDR}+${const_init}"
	local halt_addr=$(echo $bc_form | bc)
	# 計時(*3)
	lr35902_abs_jump $(four_digits $halt_addr)
}

gbos_main() {
	init >src/init.o
	cat src/init.o

	# 以降、割り込み駆動の処理部
	event_driven
}

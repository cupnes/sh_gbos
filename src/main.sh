# (TODO) f_view_{txt,img,dir} では GBOS_WST_NUM_{TXT,IMG,DIR}を使って
#        対象ビットのみを設定するようにする

if [ "${SRC_MAIN_SH+is_defined}" ]; then
	return
fi
SRC_MAIN_SH=true

. include/gb.sh
. include/vars.sh
. include/tiles.sh
. include/gbos.sh
. include/tdq.sh
. src/tiles.sh

rm -f $MAP_FILE_NAME

debug_mode=false

GBOS_ROM_TILE_DATA_START=$GB_ROM_FREE_BASE
GBOS_TILE_DATA_START=8000
GBOS_BG_TILEMAP_START=9800
GBOS_WINDOW_TILEMAP_START=9c00
GBOS_FS_BASE=4000
GBOS_FS_FILE_ATTR_SZ=07

GBOS_APP_MEM_BASE=$GB_WRAM1_BASE

# マウス座標
## TODO: ウィンドウを動かすようになったら
##       GBOS_WIN_DEF_{X,Y}_Tを使っている部分は直す
## ウィンドウのアイコン領域のベースアドレス
GBOS_ICON_BASE_X=$(
	calc16_2 "(${GBOS_WX_DEF}*${GB_TILE_WIDTH})+(${GB_TILE_WIDTH}*2)"
		)
GBOS_ICON_BASE_Y=$(
	calc16_2 "(${GBOS_WY_DEF}*${GB_TILE_HEIGHT})+(${GB_TILE_HEIGHT}*3)"
		)
CLICK_WIDTH=$(calc16_2 "${GB_TILE_WIDTH}*4")
CLICK_HEIGHT=$(calc16_2 "${GB_TILE_HEIGHT}*3")

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
GBOS_OAM_NUM_PCB=27

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

GBOS_JOYP_BITNUM_RIGHT=0
GBOS_JOYP_BITNUM_LEFT=1
GBOS_JOYP_BITNUM_UP=2
GBOS_JOYP_BITNUM_DOWN=3
GBOS_JOYP_BITNUM_A=4
GBOS_JOYP_BITNUM_B=5
GBOS_JOYP_BITNUM_SELECT=6
GBOS_JOYP_BITNUM_START=7

# ウィンドウステータス用定数
GBOS_WST_BITNUM_DIR=0	# ディレクトリ表示中
GBOS_WST_BITNUM_EXE=1	# 実行ファイル実行中
GBOS_WST_BITNUM_TXT=2	# テキストファイル表示中
GBOS_WST_BITNUM_IMG=3	# 画像ファイル表示中
GBOS_WST_NUM_DIR=01	# ディレクトリ表示中
GBOS_WST_NUM_EXE=02	# 実行ファイル実行中
GBOS_WST_NUM_TXT=04	# テキストファイル表示中
GBOS_WST_NUM_IMG=08	# 画像ファイル表示中

# タイルミラー領域
GBOS_TMRR_BASE=dc00	# タイルミラー領域ベースアドレス
GBOS_TMRR_BASE_BH=00	# タイルミラー領域ベースアドレス(下位8ビット)
GBOS_TMRR_BASE_TH=dc	# タイルミラー領域ベースアドレス(上位8ビット)
GBOS_TOFS_MASK_TH=03	# タイルアドレスオフセット部マスク(上位8ビット)

# タイル座標をアドレスへ変換
# in : regD  - タイル座標Y
#      regE  - タイル座標X
# out: regHL - 9800h〜のアドレスを格納
a_tcoord_to_addr=$GBOS_GFUNC_START
echo -e "a_tcoord_to_addr=$a_tcoord_to_addr" >>$MAP_FILE_NAME
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
echo -e "a_wtcoord_to_tcoord=$a_wtcoord_to_tcoord" >>$MAP_FILE_NAME
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

# タイル座標をミラーアドレスへ変換
# in : regD  - タイル座標Y
#      regE  - タイル座標X
# out: regHL - dc00h〜のアドレスを格納
f_wtcoord_to_tcoord >src/f_wtcoord_to_tcoord.o
fsz=$(to16 $(stat -c '%s' src/f_wtcoord_to_tcoord.o))
a_tcoord_to_mrraddr=$(four_digits $(calc16 "${a_wtcoord_to_tcoord}+${fsz}"))
echo -e "a_tcoord_to_mrraddr=$a_tcoord_to_mrraddr" >>$MAP_FILE_NAME
f_tcoord_to_mrraddr() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE

	local sz
	lr35902_set_reg regHL $GBOS_TMRR_BASE
	lr35902_clear_reg regA
	lr35902_compare_regA_and regD
	(
		lr35902_set_reg regBC $(four_digits $GB_SC_WIDTH_T)
		(
			lr35902_add_to_regHL regBC
			lr35902_dec regD
		) >src/f_tcoord_to_mrraddr.1.o
		cat src/f_tcoord_to_mrraddr.1.o
		sz=$(stat -c '%s' src/f_tcoord_to_mrraddr.1.o)
		lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz + 2)))
	) >src/f_tcoord_to_mrraddr.2.o
	sz=$(stat -c '%s' src/f_tcoord_to_mrraddr.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz)
	cat src/f_tcoord_to_mrraddr.2.o
	lr35902_add_to_regHL regDE

	# pop & return
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

# タイル座標の位置へ指定されたタイルを配置する
# in : regA  - 配置するタイル番号
#      regD  - タイル座標Y
#      regE  - タイル座標X
f_tcoord_to_mrraddr >src/f_tcoord_to_mrraddr.o
fsz=$(to16 $(stat -c '%s' src/f_tcoord_to_mrraddr.o))
fadr=$(calc16 "${a_tcoord_to_mrraddr}+${fsz}")
a_lay_tile_at_tcoord=$(four_digits $fadr)
echo -e "a_lay_tile_at_tcoord=$a_lay_tile_at_tcoord" >>$MAP_FILE_NAME
f_lay_tile_at_tcoord() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regHL

	lr35902_call $a_tcoord_to_addr
	lr35902_copy_to_ptrHL_from regA

	# pop & return
	lr35902_pop_reg regHL
	lr35902_pop_reg regAF
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
echo -e "a_lay_tile_at_wtcoord=$a_lay_tile_at_wtcoord" >>$MAP_FILE_NAME
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
echo -e "a_lay_tiles_at_tcoord_to_right=$a_lay_tiles_at_tcoord_to_right" >>$MAP_FILE_NAME
f_lay_tiles_at_tcoord_to_right() {
	local sz

	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	lr35902_copy_to_from regB regC

	lr35902_call $a_tcoord_to_addr
	(
		lr35902_copyinc_to_ptrHL_from_regA
		lr35902_dec regC
	) >src/f_lay_tiles_at_tcoord_to_right.1.o
	cat src/f_lay_tiles_at_tcoord_to_right.1.o
	sz=$(stat -c '%s' src/f_lay_tiles_at_tcoord_to_right.1.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz + 2)))

	lr35902_copy_to_from regC regB

	lr35902_call $a_tcoord_to_mrraddr
	(
		lr35902_copyinc_to_ptrHL_from_regA
		lr35902_dec regC
	) >src/f_lay_tiles_at_tcoord_to_right.2.o
	cat src/f_lay_tiles_at_tcoord_to_right.2.o
	sz=$(stat -c '%s' src/f_lay_tiles_at_tcoord_to_right.2.o)
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
echo -e "a_lay_tiles_at_wtcoord_to_right=$a_lay_tiles_at_wtcoord_to_right" >>$MAP_FILE_NAME
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
echo -e "a_lay_tiles_at_tcoord_to_low=$a_lay_tiles_at_tcoord_to_low" >>$MAP_FILE_NAME
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
echo -e "a_lay_tiles_at_wtcoord_to_low=$a_lay_tiles_at_wtcoord_to_low" >>$MAP_FILE_NAME
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
echo -e "a_objnum_to_addr=$a_objnum_to_addr" >>$MAP_FILE_NAME
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
echo -e "a_set_objpos=$a_set_objpos" >>$MAP_FILE_NAME
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
echo -e "a_lay_icon=$a_lay_icon" >>$MAP_FILE_NAME
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
echo -e "a_clr_win=$a_clr_win" >>$MAP_FILE_NAME
f_clr_win() {
	lr35902_push_reg regAF

	# DA用変数設定
	lr35902_set_reg regA 03
	lr35902_copy_to_addr_from_regA $var_clr_win_nyt

	# DASにclr_winのビットをセット
	lr35902_copy_to_regA_from_addr $var_draw_act_stat
	lr35902_set_bitN_of_reg $GBOS_DA_BITNUM_CLR_WIN regA
	lr35902_copy_to_addr_from_regA $var_draw_act_stat

	# ウィンドウステータスのview系/run系ビットをクリア
	lr35902_copy_to_regA_from_addr $var_win_stat
	lr35902_res_bitN_of_reg $GBOS_WST_BITNUM_TXT regA
	lr35902_res_bitN_of_reg $GBOS_WST_BITNUM_IMG regA
	lr35902_res_bitN_of_reg $GBOS_WST_BITNUM_EXE regA
	lr35902_copy_to_addr_from_regA $var_win_stat

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
# in : regA  - ファイル番号
#      regHL - ファイル先頭アドレス
f_clr_win >src/f_clr_win.o
fsz=$(to16 $(stat -c '%s' src/f_clr_win.o))
fadr=$(calc16 "${a_clr_win}+${fsz}")
a_view_txt=$(four_digits $fadr)
echo -e "a_view_txt=$a_view_txt" >>$MAP_FILE_NAME
f_view_txt() {
	lr35902_push_reg regAF
	lr35902_push_reg regHL

	lr35902_call $a_clr_win

	# DA用変数設定

	# 残り文字数
	lr35902_copyinc_to_regA_from_ptrHL
	lr35902_copy_to_addr_from_regA $var_da_var1
	lr35902_copyinc_to_regA_from_ptrHL
	lr35902_copy_to_addr_from_regA $var_da_var2

	# 次に配置する文字のアドレス
	lr35902_copy_to_from regA regL
	lr35902_copy_to_addr_from_regA $var_da_var3
	lr35902_copy_to_from regA regH
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

	# ウィンドウステータスに「テキストファイル表示中」を設定
	lr35902_copy_to_regA_from_addr $var_win_stat
	## 「ディレクトリ表示中」はクリア
	lr35902_res_bitN_of_reg $GBOS_WST_BITNUM_DIR regA
	## 「テキストファイル表示中」を設定
	lr35902_set_bitN_of_reg $GBOS_WST_BITNUM_TXT regA
	lr35902_copy_to_addr_from_regA $var_win_stat

	lr35902_pop_reg regHL
	lr35902_pop_reg regAF
	lr35902_return
}

# view_txt用周期ハンドラ
# TODO 現状、文字数は255文字まで(1バイト以内)
f_view_txt >src/f_view_txt.o
fsz=$(to16 $(stat -c '%s' src/f_view_txt.o))
fadr=$(calc16 "${a_view_txt}+${fsz}")
a_view_txt_cyc=$(four_digits $fadr)
echo -e "a_view_txt_cyc=$a_view_txt_cyc" >>$MAP_FILE_NAME
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
echo -e "a_clr_win_cyc=$a_clr_win_cyc" >>$MAP_FILE_NAME
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

# タイル番号をアドレスへ変換
# in : regA  - タイル番号
# out: regHL - 8000h〜のアドレスを格納
f_clr_win_cyc >src/f_clr_win_cyc.o
fsz=$(to16 $(stat -c '%s' src/f_clr_win_cyc.o))
fadr=$(calc16 "${a_clr_win_cyc}+${fsz}")
a_tn_to_addr=$(four_digits $fadr)
echo -e "a_tn_to_addr=$a_tn_to_addr" >>$MAP_FILE_NAME
f_tn_to_addr() {
	local sz

	# HLへ0x8000を設定
	# 計時(1)ここから(2)までで 5/16384 秒
	# (* (/ 5 16384.0) 1000)0.30517578125 ms
	lr35902_set_reg regHL $GBOS_TILE_DATA_START

	# A == 0x00 の場合、そのままreturn
	lr35902_compare_regA_and 00
	(
		lr35902_return
	) >src/f_tn_to_addr.1.o
	sz=$(stat -c '%s' src/f_tn_to_addr.1.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz)
	cat src/f_tn_to_addr.1.o

	# 関数内で変更する戻り値以外のレジスタをpush
	lr35902_push_reg regAF
	lr35902_push_reg regDE

	# DEへ1タイル当たりのバイト数(16)を設定
	lr35902_clear_reg regD
	lr35902_set_reg regE $GBOS_TILE_BYTES

	# タイル番号の数だけHLへDEを加算
	(
		lr35902_add_to_regHL regDE
		lr35902_dec regA
	) >src/f_tn_to_addr.2.o
	cat src/f_tn_to_addr.2.o
	sz=$(stat -c '%s' src/f_tn_to_addr.2.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz+2)))

	# 関数内で変更した戻り値以外のレジスタをpop
	lr35902_pop_reg regDE
	lr35902_pop_reg regAF

	# return
	# 計時(2)
	lr35902_return
}

# 画像ファイルを表示
# in : regA - 表示するファイル番目(0始まり)
f_tn_to_addr >src/f_tn_to_addr.o
fsz=$(to16 $(stat -c '%s' src/f_tn_to_addr.o))
fadr=$(calc16 "${a_tn_to_addr}+${fsz}")
a_view_img=$(four_digits $fadr)
echo -e "a_view_img=$a_view_img" >>$MAP_FILE_NAME
f_view_img() {
	# 画像解像度は16x13タイル(128x104ピクセル)固定
	# なので、ファイルサイズは0x0d00固定

	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	# ファイル番目をBへコピー
	lr35902_copy_to_from regB regA

	# 次に描画するタイル番号を0x30で初期化
	lr35902_set_reg regA 30
	lr35902_copy_to_addr_from_regA $var_view_img_nt

	# 次に使用するタイルアドレスを設定
	local ntadr=$(calc16 "${GBOS_TILE_DATA_START}+300")
	lr35902_set_reg regA $(echo $ntadr | cut -c3-4)
	lr35902_copy_to_addr_from_regA $var_view_img_ntadr_bh
	lr35902_set_reg regA $(echo $ntadr | cut -c1-2)
	lr35902_copy_to_addr_from_regA $var_view_img_ntadr_th

	# 次に描画するタイルデータアドレスを設定
	local file_ofs_1st_ofs=0008
	local file_ofs_1st_addr=$(calc16 "${GBOS_FS_BASE}+${file_ofs_1st_ofs}")
	lr35902_set_reg regHL $file_ofs_1st_addr
	lr35902_copy_to_from regA regB
	lr35902_compare_regA_and 00
	(
		# 描画するファイル番目が0以外の場合

		lr35902_set_reg regDE $(four_digits $GBOS_FS_FILE_ATTR_SZ)

		(
			lr35902_add_to_regHL regDE
			lr35902_dec regA
		) >src/f_view_img.1.o
		cat src/f_view_img.1.o
		local sz_1=$(stat -c '%s' src/f_view_img.1.o)
		lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_1 + 2)))
	) >src/f_view_img.2.o
	local sz_2=$(stat -c '%s' src/f_view_img.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	cat src/f_view_img.2.o
	## ファイルデータ領域へのオフセット取得
	lr35902_copyinc_to_regA_from_ptrHL
	lr35902_copy_to_from regE regA
	lr35902_copy_to_from regA ptrHL
	lr35902_copy_to_from regD regA
	## ファイルサイズ(2バイト)を飛ばす
	lr35902_inc regDE
	lr35902_inc regDE
	## FSベースアドレスと足してファイルデータ先頭アドレス取得
	lr35902_set_reg regHL $GBOS_FS_BASE
	lr35902_add_to_regHL regDE
	## ファイルデータ領域のアドレスを変数へ設定
	lr35902_copy_to_from regA regL
	lr35902_copy_to_addr_from_regA $var_view_img_dtadr_bh
	lr35902_copy_to_from regA regH
	lr35902_copy_to_addr_from_regA $var_view_img_dtadr_th

	# 次に描画するウィンドウタイル座標を設定
	lr35902_set_reg regA 03
	lr35902_copy_to_addr_from_regA $var_view_img_nyt
	lr35902_set_reg regA 02
	lr35902_copy_to_addr_from_regA $var_view_img_nxt

	# DASのview_imgビットを立てる
	lr35902_copy_to_regA_from_addr $var_draw_act_stat
	lr35902_set_bitN_of_reg $GBOS_DA_BITNUM_VIEW_IMG regA
	lr35902_copy_to_addr_from_regA $var_draw_act_stat

	# ウィンドウステータスに「画像ファイル表示中」を設定
	lr35902_copy_to_regA_from_addr $var_win_stat
	## 「ディレクトリ表示中」はクリア
	lr35902_res_bitN_of_reg $GBOS_WST_BITNUM_DIR regA
	## 「画像ファイル表示中」を設定
	lr35902_set_bitN_of_reg $GBOS_WST_BITNUM_IMG regA
	lr35902_copy_to_addr_from_regA $var_win_stat

	# pop & return
	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

# 画像ファイルを表示する周期関数
f_view_img >src/f_view_img.o
fsz=$(to16 $(stat -c '%s' src/f_view_img.o))
fadr=$(calc16 "${a_view_img}+${fsz}")
a_view_img_cyc=$(four_digits $fadr)
echo -e "a_view_img_cyc=$a_view_img_cyc" >>$MAP_FILE_NAME
f_view_img_cyc() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	# 次に描画するタイル番号をBへロード
	lr35902_copy_to_regA_from_addr $var_view_img_nt
	lr35902_copy_to_from regB regA

	# 次に使用するタイルアドレスをHLへロード
	lr35902_copy_to_regA_from_addr $var_view_img_ntadr_bh
	lr35902_copy_to_from regL regA
	lr35902_copy_to_regA_from_addr $var_view_img_ntadr_th
	lr35902_copy_to_from regH regA

	# 退避する必要の有無確認
	# (タイル番号 + 1 <= タイル数 なら退避必要
	#  タイル番号 + 1 > タイル数 なら退避不要
	#  タイル番号(regB) > (タイル数 - 1)(regA) なら退避不要)
	local save_base_tn=$(calc16_2 "${GBOS_NUM_ALL_TILES}-1")
	lr35902_set_reg regA $save_base_tn
	lr35902_compare_regA_and regB
	(
		# 退避処理

		# HLをpush
		lr35902_push_reg regHL

		# 退避するタイルのアドレスをDEへ設定
		lr35902_copy_to_from regD regH
		lr35902_copy_to_from regE regL

		# HLへ退避先のメモリアドレスを設定
		## DE+5000hを設定する(D300h-)
		lr35902_copy_to_from regA regB
		lr35902_set_reg regBC 5000
		lr35902_add_to_regHL regBC
		lr35902_copy_to_from regB regA

		# Cへ16を設定(ループ用カウンタ。16バイト)
		# 計時(1)ここから(2)まで 2/16384 秒
		# (* (/ 2 16384.0) 1000)0.1220703125 ms
		lr35902_set_reg regC 10

		# Cの数だけ1バイトずつ[DE]->[HL]へコピー
		(
			lr35902_copy_to_from regA ptrDE
			lr35902_copyinc_to_ptrHL_from_regA
			lr35902_inc regDE
			lr35902_dec regC
		) >src/f_view_img_cyc.2.o
		cat src/f_view_img_cyc.2.o
		local sz_2=$(stat -c '%s' src/f_view_img_cyc.2.o)
		lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_2+2)))

		# HLをpop
		lr35902_pop_reg regHL
	) >src/f_view_img_cyc.1.o
	local sz_1=$(stat -c '%s' src/f_view_img_cyc.1.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $sz_1)
	cat src/f_view_img_cyc.1.o

	# ファイルにかかれているタイルデータを30以降のタイル領域へロード
	## 次に描画するタイルデータアドレスをDEへ設定
	lr35902_copy_to_regA_from_addr $var_view_img_dtadr_bh
	lr35902_copy_to_from regE regA
	lr35902_copy_to_regA_from_addr $var_view_img_dtadr_th
	lr35902_copy_to_from regD regA

	## Cへ16を設定(ループ用カウンタ。16バイト)
	lr35902_set_reg regC 10

	## Cの数だけ1バイトずつ[DE]->[HL]へコピー
	(
		lr35902_copy_to_from regA ptrDE
		lr35902_copyinc_to_ptrHL_from_regA
		lr35902_inc regDE
		lr35902_dec regC
	) >src/f_view_img_cyc.3.o
	cat src/f_view_img_cyc.3.o
	local sz_3=$(stat -c '%s' src/f_view_img_cyc.3.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_3+2)))

	## 次に描画するタイルデータアドレス更新
	lr35902_copy_to_from regA regE
	lr35902_copy_to_addr_from_regA $var_view_img_dtadr_bh
	lr35902_copy_to_from regA regD
	lr35902_copy_to_addr_from_regA $var_view_img_dtadr_th

	# 30〜ffのタイルを(xt,yt)=(02,03)のdrawable領域へ配置
	## 1サイクルで1タイル

	## 次に描画するウィンドウタイル座標を(X,Y)=(E,D)へ取得
	lr35902_copy_to_regA_from_addr $var_view_img_nyt
	lr35902_copy_to_from regD regA
	lr35902_copy_to_regA_from_addr $var_view_img_nxt
	lr35902_copy_to_from regE regA

	## 次に描画するタイル番号をAへ設定
	lr35902_copy_to_from regA regB

	## タイルを描画
	lr35902_call $a_lay_tile_at_wtcoord

	# 終了判定
	## 今描画したタイルは最後(0xff)のタイルか?
	lr35902_compare_regA_and ff
	(
		# 最後のタイルである場合

		# 終わったらDASのview_imgのビットを下ろす
		lr35902_copy_to_regA_from_addr $var_draw_act_stat
		lr35902_res_bitN_of_reg $GBOS_DA_BITNUM_VIEW_IMG regA
		lr35902_copy_to_addr_from_regA $var_draw_act_stat
	) >src/f_view_img_cyc.4.o
	(
		# 最後のタイルでない場合

		# 次に描画するタイル番号を更新
		lr35902_inc regA
		lr35902_copy_to_addr_from_regA $var_view_img_nt

		# 次に使用するタイルアドレスを更新
		## HLがインクリメント済みの状態
		lr35902_copy_to_from regA regL
		lr35902_copy_to_addr_from_regA $var_view_img_ntadr_bh
		lr35902_copy_to_from regA regH
		lr35902_copy_to_addr_from_regA $var_view_img_ntadr_th

		# 次に描画するウィンドウタイル座標更新
		## 今描画したX座標はウィンドウ右端か?
		lr35902_copy_to_from regA regE
		lr35902_compare_regA_and $(calc16_2 "${GBOS_WIN_DRAWABLE_WIDTH_T}+1")
		(
			# 右端である場合

			# X座標を左端座標へ更新
			lr35902_set_reg regA 02
			lr35902_copy_to_addr_from_regA $var_view_img_nxt

			# Y座標をインクリメント
			lr35902_copy_to_from regA regD
			lr35902_inc regA
			lr35902_copy_to_addr_from_regA $var_view_img_nyt
		) >src/f_view_img_cyc.6.o
		(
			# 右端でない場合

			# X座標をインクリメント
			lr35902_copy_to_from regA regE
			lr35902_inc regA
			lr35902_copy_to_addr_from_regA $var_view_img_nxt

			# 右端である場合の処理を飛ばす
			local sz_6=$(stat -c '%s' src/f_view_img_cyc.6.o)
			lr35902_rel_jump $(two_digits_d $sz_6)
		) >src/f_view_img_cyc.7.o
		local sz_7=$(stat -c '%s' src/f_view_img_cyc.7.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_7)
		## 右端でない場合
		cat src/f_view_img_cyc.7.o
		## 右端である場合
		cat src/f_view_img_cyc.6.o

		## 最後のタイルである場合の処理を飛ばす
		local sz_4=$(stat -c '%s' src/f_view_img_cyc.4.o)
		lr35902_rel_jump $(two_digits_d $sz_4)
	) >src/f_view_img_cyc.5.o
	local sz_5=$(stat -c '%s' src/f_view_img_cyc.5.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_5)
	## 最後のタイルでない場合
	cat src/f_view_img_cyc.5.o
	## 最後のタイルである場合
	cat src/f_view_img_cyc.4.o

	# pop & return
	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

# タイルデータを復帰する周期ハンドラを登録する関数
f_view_img_cyc >src/f_view_img_cyc.o
fsz=$(to16 $(stat -c '%s' src/f_view_img_cyc.o))
fadr=$(calc16 "${a_view_img_cyc}+${fsz}")
a_rstr_tiles=$(four_digits $fadr)
echo -e "a_rstr_tiles=$a_rstr_tiles" >>$MAP_FILE_NAME
f_rstr_tiles() {
	# push
	lr35902_push_reg regAF

	# TODO rstr_tiles_cycで使用する変数設定
	local ntadr=$(calc16 "${GBOS_TILE_DATA_START}+300")
	lr35902_set_reg regA $(echo $ntadr | cut -c3-4)
	lr35902_copy_to_addr_from_regA $var_view_img_ntadr_bh
	lr35902_set_reg regA $(echo $ntadr | cut -c1-2)
	lr35902_copy_to_addr_from_regA $var_view_img_ntadr_th

	# DASへタイルデータ復帰のビットをセット
	lr35902_copy_to_regA_from_addr $var_draw_act_stat
	lr35902_set_bitN_of_reg $GBOS_DA_BITNUM_RSTR_TILES regA
	lr35902_copy_to_addr_from_regA $var_draw_act_stat

	# pop & return
	lr35902_pop_reg regAF
	lr35902_return
}

# タイルデータを復帰する周期関数
f_rstr_tiles >src/f_rstr_tiles.o
fsz=$(to16 $(stat -c '%s' src/f_rstr_tiles.o))
fadr=$(calc16 "${a_rstr_tiles}+${fsz}")
a_rstr_tiles_cyc=$(four_digits $fadr)
echo -e "a_rstr_tiles_cyc=$a_rstr_tiles_cyc" >>$MAP_FILE_NAME
f_rstr_tiles_cyc() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	# 復帰するタイルのアドレスをHLへ設定
	## var_view_img_ntadr変数を流用する
	lr35902_copy_to_regA_from_addr $var_view_img_ntadr_bh
	lr35902_copy_to_from regL regA
	lr35902_copy_to_regA_from_addr $var_view_img_ntadr_th
	lr35902_copy_to_from regH regA

	# 退避場所のメモリアドレスをDEへ設定
	## HL+5000hを設定する(D300h-)
	lr35902_push_reg regHL
	lr35902_set_reg regBC 5000
	lr35902_add_to_regHL regBC
	lr35902_copy_to_from regD regH
	lr35902_copy_to_from regE regL
	lr35902_pop_reg regHL

	# Cへ16を設定(ループ用カウンタ。16バイト)
	lr35902_set_reg regC 10

	# Cの数だけ1バイトずつ[DE]->[HL]へコピー
	(
		lr35902_copy_to_from regA ptrDE
		lr35902_copyinc_to_ptrHL_from_regA
		lr35902_inc regDE
		lr35902_dec regC
	) >src/f_rstr_tiles_cyc.1.o
	cat src/f_rstr_tiles_cyc.1.o
	local sz_1=$(stat -c '%s' src/f_rstr_tiles_cyc.1.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_1+2)))

	# この周期処理の終了判定
	local ntlast=$(calc16 "${GBOS_TILE_DATA_START}+${GBOS_NUM_ALL_TILE_BYTES}")
	local ntlast_th=$(echo $ntlast | cut -c1-2)
	local ntlast_bh=$(echo $ntlast | cut -c3-4)
	lr35902_copy_to_from regA regH
	lr35902_compare_regA_and $ntlast_th
	(
		# A != $ntlast_th の場合

		# HLを変数へ保存
		lr35902_copy_to_from regA regL
		lr35902_copy_to_addr_from_regA $var_view_img_ntadr_bh
		lr35902_copy_to_from regA regH
		lr35902_copy_to_addr_from_regA $var_view_img_ntadr_th
	) >src/f_rstr_tiles_cyc.2.o
	(
		# A == $ntlast_th の場合

		lr35902_copy_to_from regA regL
		lr35902_compare_regA_and $ntlast_bh
		(
			# A == $ntlast_bh の場合

			# DAのGBOS_DA_BITNUM_RSTR_TILESのビットを下ろす
			lr35902_copy_to_regA_from_addr $var_draw_act_stat
			lr35902_res_bitN_of_reg $GBOS_DA_BITNUM_RSTR_TILES regA
			lr35902_copy_to_addr_from_regA $var_draw_act_stat

			# 続く A != $ntlast_th の場合の処理を飛ばす
			local sz_2=$(stat -c '%s' src/f_rstr_tiles_cyc.2.o)
			lr35902_rel_jump $(two_digits_d $sz_2)
		) >src/f_rstr_tiles_cyc.3.o
		local sz_3=$(stat -c '%s' src/f_rstr_tiles_cyc.3.o)
		lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_3)
		## A == $ntlast_bh の場合
		cat src/f_rstr_tiles_cyc.3.o
	) >src/f_rstr_tiles_cyc.4.o
	local sz_4=$(stat -c '%s' src/f_rstr_tiles_cyc.4.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_4)
	## A == $ntlast_th の場合
	cat src/f_rstr_tiles_cyc.4.o
	## A != $ntlast_th の場合
	cat src/f_rstr_tiles_cyc.2.o

	# pop & return
	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

# ディレクトリを表示
## TODO 今の所ルートディレクトリ固定
## TODO 今の所ファイルは1つで固定
f_rstr_tiles_cyc >src/f_rstr_tiles_cyc.o
fsz=$(to16 $(stat -c '%s' src/f_rstr_tiles_cyc.o))
fadr=$(calc16 "${a_rstr_tiles_cyc}+${fsz}")
a_view_dir=$(four_digits $fadr)
echo -e "a_view_dir=$a_view_dir" >>$MAP_FILE_NAME
f_view_dir() {
	# push
	lr35902_push_reg regAF

	# 0番目のファイルから表示する
	lr35902_clear_reg regA
	lr35902_copy_to_addr_from_regA $var_view_dir_file_th

	# DASへディレクトリ表示のビットをセット
	lr35902_copy_to_regA_from_addr $var_draw_act_stat
	lr35902_set_bitN_of_reg $GBOS_DA_BITNUM_VIEW_DIR regA
	lr35902_copy_to_addr_from_regA $var_draw_act_stat

	# ウィンドウステータスにディレクトリ表示中のビットをセット
	lr35902_copy_to_regA_from_addr $var_win_stat
	lr35902_set_bitN_of_reg $GBOS_WST_BITNUM_DIR regA
	lr35902_copy_to_addr_from_regA $var_win_stat

	# 隠しコマンドステートをクリア
	lr35902_clear_reg regA
	lr35902_copy_to_addr_from_regA $var_hidden_com_stat

	# pop & return
	lr35902_pop_reg regAF
	lr35902_return
}

# ディレクトリを表示する周期関数
## TODO 今の所ルートディレクトリのみ
## TODO 今の所ファイルは1つで固定
f_view_dir >src/f_view_dir.o
fsz=$(to16 $(stat -c '%s' src/f_view_dir.o))
fadr=$(calc16 "${a_view_dir}+${fsz}")
a_view_dir_cyc=$(four_digits $fadr)
echo -e "a_view_dir_cyc=$a_view_dir_cyc" >>$MAP_FILE_NAME
# アイコンを配置するウィンドウY座標を
# レジスタAに格納されたファイル番目で算出し
# レジスタDへ設定
set_icon_wy_to_regD_calc_from_regA() {
	# ファイル番目のビット3-2を抽出
	lr35902_and_to_regA 0c
	(
		# ファイル番目[3:2] == 01 or 10 or 11
		lr35902_compare_regA_and 04
		(
			# ファイル番目[3:2] == 10 or 11
			lr35902_compare_regA_and 08
			(
				# ファイル番目[3:2] == 11
				lr35902_set_reg regD 0c
			) >src/set_icon_wy_to_regD_calc_from_regA.6.o
			(
				# ファイル番目[3:2] == 10
				lr35902_set_reg regD 09

				# 「ファイル番目[3:2] == 11」の処理を飛ばす
				local sz_6=$(stat -c '%s' src/set_icon_wy_to_regD_calc_from_regA.6.o)
				lr35902_rel_jump $(two_digits_d $sz_6)
			) >src/set_icon_wy_to_regD_calc_from_regA.5.o
			local sz_5=$(stat -c '%s' src/set_icon_wy_to_regD_calc_from_regA.5.o)
			lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_5)
			cat src/set_icon_wy_to_regD_calc_from_regA.5.o
			cat src/set_icon_wy_to_regD_calc_from_regA.6.o
		) >src/set_icon_wy_to_regD_calc_from_regA.4.o
		(
			# ファイル番目[3:2] == 01
			lr35902_set_reg regD 06

			# 「ファイル番目[3:2] == 10 or 11」の処理を飛ばす
			local sz_4=$(stat -c '%s' src/set_icon_wy_to_regD_calc_from_regA.4.o)
			lr35902_rel_jump $(two_digits_d $sz_4)
		) >src/set_icon_wy_to_regD_calc_from_regA.3.o
		local sz_3=$(stat -c '%s' src/set_icon_wy_to_regD_calc_from_regA.3.o)
		lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_3)
		cat src/set_icon_wy_to_regD_calc_from_regA.3.o
		cat src/set_icon_wy_to_regD_calc_from_regA.4.o
	) >src/set_icon_wy_to_regD_calc_from_regA.2.o
	(
		# ファイル番目[3:2] == 00
		lr35902_set_reg regD 03

		# 「ファイル番目[3:2] == 01 or 10 or 11」の処理を飛ばす
		local sz_2=$(stat -c '%s' src/set_icon_wy_to_regD_calc_from_regA.2.o)
		lr35902_rel_jump $(two_digits_d $sz_2)
	) >src/set_icon_wy_to_regD_calc_from_regA.1.o
	local sz_1=$(stat -c '%s' src/set_icon_wy_to_regD_calc_from_regA.1.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_1)
	cat src/set_icon_wy_to_regD_calc_from_regA.1.o
	cat src/set_icon_wy_to_regD_calc_from_regA.2.o
}
# アイコンを配置するウィンドウX座標を
# レジスタAに格納されたファイル番目で算出し
# レジスタEへ設定
set_icon_wx_to_regE_calc_from_regA() {
	# ファイル番目のビット1-0を抽出
	lr35902_and_to_regA 03
	(
		# ファイル番目[1:0] == 01 or 10 or 11
		lr35902_compare_regA_and 01
		(
			# ファイル番目[1:0] == 10 or 11
			lr35902_compare_regA_and 02
			(
				# ファイル番目[1:0] == 11
				lr35902_set_reg regE 0f
			) >src/set_icon_wx_to_regE_calc_from_regA.6.o
			(
				# ファイル番目[1:0] == 10
				lr35902_set_reg regE 0b

				# 「ファイル番目[1:0] == 11」の処理を飛ばす
				local sz_6=$(stat -c '%s' src/set_icon_wx_to_regE_calc_from_regA.6.o)
				lr35902_rel_jump $(two_digits_d $sz_6)
			) >src/set_icon_wx_to_regE_calc_from_regA.5.o
			local sz_5=$(stat -c '%s' src/set_icon_wx_to_regE_calc_from_regA.5.o)
			lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_5)
			cat src/set_icon_wx_to_regE_calc_from_regA.5.o
			cat src/set_icon_wx_to_regE_calc_from_regA.6.o
		) >src/set_icon_wx_to_regE_calc_from_regA.4.o
		(
			# ファイル番目[1:0] == 01
			lr35902_set_reg regE 07

			# 「ファイル番目[1:0] == 10 or 11」の処理を飛ばす
			local sz_4=$(stat -c '%s' src/set_icon_wx_to_regE_calc_from_regA.4.o)
			lr35902_rel_jump $(two_digits_d $sz_4)
		) >src/set_icon_wx_to_regE_calc_from_regA.3.o
		local sz_3=$(stat -c '%s' src/set_icon_wx_to_regE_calc_from_regA.3.o)
		lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_3)
		cat src/set_icon_wx_to_regE_calc_from_regA.3.o
		cat src/set_icon_wx_to_regE_calc_from_regA.4.o
	) >src/set_icon_wx_to_regE_calc_from_regA.2.o
	(
		# ファイル番目[1:0] == 00
		lr35902_set_reg regE 03

		# 「ファイル番目[1:0] == 01 or 10 or 11」の処理を飛ばす
		local sz_2=$(stat -c '%s' src/set_icon_wx_to_regE_calc_from_regA.2.o)
		lr35902_rel_jump $(two_digits_d $sz_2)
	) >src/set_icon_wx_to_regE_calc_from_regA.1.o
	local sz_1=$(stat -c '%s' src/set_icon_wx_to_regE_calc_from_regA.1.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_1)
	cat src/set_icon_wx_to_regE_calc_from_regA.1.o
	cat src/set_icon_wx_to_regE_calc_from_regA.2.o
}
f_view_dir_cyc() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	# 表示するファイル番目を変数からBへ取得
	lr35902_copy_to_regA_from_addr $var_view_dir_file_th
	lr35902_copy_to_from regB regA

	# アイコンを置くウィンドウ座標(X,Y)を(E,D)へ設定
	set_icon_wy_to_regD_calc_from_regA
	lr35902_copy_to_from regA regB
	set_icon_wx_to_regE_calc_from_regA

	# アイコン番号をAへ設定
	## TODO ルートディレクトリ固定なので
	##      1つ目のファイルのファイルタイプへのオフセットは0x0007固定
	local file_type_ofs=0007
	local file_type_addr=$(calc16 "${GBOS_FS_BASE}+${file_type_ofs}")
	## 0番目のファイルであるか否か
	lr35902_copy_to_from regA regB
	lr35902_compare_regA_and 00
	(
		# 0番目のファイルの場合
		lr35902_copy_to_regA_from_addr $file_type_addr
	) >src/f_view_dir_cyc.1.o
	(
		# 1番目以降のファイルの場合

		# DEを使うのでpush
		lr35902_push_reg regDE

		# 1つ目のファイルタイプアドレスをHLへ格納
		lr35902_set_reg regHL $file_type_addr

		# 次のファイルタイプアドレスへのオフセットをDEへ格納
		lr35902_set_reg regDE $(four_digits $GBOS_FS_FILE_ATTR_SZ)

		# 表示するファイル番目をCへコピー
		lr35902_copy_to_from regC regB

		# 現在のファイル番目のファイルタイプのアドレス取得
		(
			lr35902_add_to_regHL regDE
			lr35902_dec regC
		) >src/f_view_dir_cyc.3.o
		cat src/f_view_dir_cyc.3.o
		local sz_3=$(stat -c '%s' src/f_view_dir_cyc.3.o)
		lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_3 + 2)))

		# ファイルタイプをAへ格納
		lr35902_copy_to_from regA ptrHL

		# DEを元に戻す(pop)
		lr35902_pop_reg regDE

		# 0番目の場合の処理を飛ばす
		local sz_1=$(stat -c '%s' src/f_view_dir_cyc.1.o)
		lr35902_rel_jump $(two_digits_d $sz_1)
	) >src/f_view_dir_cyc.2.o
	local sz_2=$(stat -c '%s' src/f_view_dir_cyc.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	## 1番目以降のファイルの場合
	cat src/f_view_dir_cyc.2.o
	## 0番目のファイルの場合
	cat src/f_view_dir_cyc.1.o

	# アイコンを描画
	lr35902_call $a_lay_icon

	# ファイル番目をインクリメント
	lr35902_inc regB

	# ディレクトリのファイル数取得
	## TODO ルートディレクトリ固定なのでオフセットは0x0000固定
	local num_files_ofs=0000
	local num_files_addr=$(calc16 "${GBOS_FS_BASE}+${num_files_ofs}")
	lr35902_copy_to_regA_from_addr $num_files_addr

	# 終了判定
	## ファイル数(A) == 次に表示するファイル番目(B) だったら終了
	lr35902_compare_regA_and regB
	(
		# ファイル数(A) == 次に表示するファイル番目(B) の場合

		# DAのGBOS_DA_BITNUM_VIEW_DIRのビットを下ろす
		lr35902_copy_to_regA_from_addr $var_draw_act_stat
		lr35902_res_bitN_of_reg $GBOS_DA_BITNUM_VIEW_DIR regA
		lr35902_copy_to_addr_from_regA $var_draw_act_stat
	) >src/f_view_dir_cyc.4.o
	(
		# ファイル数(A) != 次に表示するファイル番目(B) の場合

		# 表示するファイル番目の変数を更新
		lr35902_copy_to_from regA regB
		lr35902_copy_to_addr_from_regA $var_view_dir_file_th

		# ファイル数(A) == 次に表示するファイル番目(B) の場合の処理を飛ばす
		local sz_4=$(stat -c '%s' src/f_view_dir_cyc.4.o)
		lr35902_rel_jump $(two_digits_d $sz_4)
	) >src/f_view_dir_cyc.5.o
	local sz_5=$(stat -c '%s' src/f_view_dir_cyc.5.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_5)
	## ファイル数(A) != 次に表示するファイル番目(B) の場合
	cat src/f_view_dir_cyc.5.o
	## ファイル数(A) == 次に表示するファイル番目(B) の場合
	cat src/f_view_dir_cyc.4.o

	# pop & return
	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

# アイコン領域のクリック確認(X軸)
# in : var_mouse_x変数
# out: regA - クリック位置のファイル番号の下位2ビットをbit[1:0]に設定
#             クリック位置がアイコン領域外の場合 $80 を設定
#             ※ bit[1:0]はビットセットのみ行うので、予めクリアしておくこと
# ※ OBJ座標系は右下原点なのでマウスX座標はカーソル先端(左上)から+8ピクセル
f_view_dir_cyc >src/f_view_dir_cyc.o
fsz=$(to16 $(stat -c '%s' src/f_view_dir_cyc.o))
fadr=$(calc16 "${a_view_dir_cyc}+${fsz}")
a_check_click_icon_area_x=$(four_digits $fadr)
echo -e "a_check_click_icon_area_x=$a_check_click_icon_area_x" >>$MAP_FILE_NAME
f_check_click_icon_area_x() {
	# push
	lr35902_push_reg regAF

	# マウス座標(X)を取得
	lr35902_copy_to_regA_from_addr $var_mouse_x

	# A >= 16 ?
	lr35902_compare_regA_and 18
	(
		# A >= 16 の場合

		# A < 48 ?
		lr35902_compare_regA_and 38
		(
			# A < 48 の場合

			# pop & return
			lr35902_pop_reg regAF
			## bit[1:0] = %00
			lr35902_return
		) >src/f_check_click_icon_area_x.1.o
		local sz_1=$(stat -c '%s' src/f_check_click_icon_area_x.1.o)
		lr35902_rel_jump_with_cond NC $(two_digits_d $sz_1)
		cat src/f_check_click_icon_area_x.1.o
	) >src/f_check_click_icon_area_x.2.o
	local sz_2=$(stat -c '%s' src/f_check_click_icon_area_x.2.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $sz_2)
	cat src/f_check_click_icon_area_x.2.o

	# A >= 48 ?
	lr35902_compare_regA_and 38
	(
		# A >= 48 の場合

		# A < 80 ?
		lr35902_compare_regA_and 58
		(
			# A < 80 の場合

			# pop & return
			lr35902_pop_reg regAF
			## bit[1:0] = %01
			lr35902_add_to_regA 01
			lr35902_return
		) >src/f_check_click_icon_area_x.3.o
		local sz_3=$(stat -c '%s' src/f_check_click_icon_area_x.3.o)
		lr35902_rel_jump_with_cond NC $(two_digits_d $sz_3)
		cat src/f_check_click_icon_area_x.3.o
	) >src/f_check_click_icon_area_x.4.o
	local sz_4=$(stat -c '%s' src/f_check_click_icon_area_x.4.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $sz_4)
	cat src/f_check_click_icon_area_x.4.o

	# A >= 80 ?
	lr35902_compare_regA_and 58
	(
		# A >= 80 の場合

		# A < 112 ?
		lr35902_compare_regA_and 78
		(
			# A < 112 の場合

			# pop & return
			lr35902_pop_reg regAF
			## bit[1:0] = %10
			lr35902_add_to_regA 02
			lr35902_return
		) >src/f_check_click_icon_area_x.5.o
		local sz_5=$(stat -c '%s' src/f_check_click_icon_area_x.5.o)
		lr35902_rel_jump_with_cond NC $(two_digits_d $sz_5)
		cat src/f_check_click_icon_area_x.5.o
	) >src/f_check_click_icon_area_x.6.o
	local sz_6=$(stat -c '%s' src/f_check_click_icon_area_x.6.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $sz_6)
	cat src/f_check_click_icon_area_x.6.o

	# A >= 112 ?
	lr35902_compare_regA_and 78
	(
		# A >= 112 の場合

		# A < 144 ?
		lr35902_compare_regA_and 98
		(
			# A < 144 の場合

			# pop & return
			lr35902_pop_reg regAF
			## bit[1:0] = %11
			lr35902_add_to_regA 03
			lr35902_return
		) >src/f_check_click_icon_area_x.7.o
		local sz_7=$(stat -c '%s' src/f_check_click_icon_area_x.7.o)
		lr35902_rel_jump_with_cond NC $(two_digits_d $sz_7)
		cat src/f_check_click_icon_area_x.7.o
	) >src/f_check_click_icon_area_x.8.o
	local sz_8=$(stat -c '%s' src/f_check_click_icon_area_x.8.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $sz_8)
	cat src/f_check_click_icon_area_x.8.o

	# pop & return
	lr35902_pop_reg regAF
	lr35902_set_reg regA 80	# アイコン領域外
	lr35902_return
}

# アイコン領域のクリック確認(Y軸)
# in : var_mouse_y変数
# out: regA - クリック位置のファイル番号のbit[3:2]をAレジスタのbit[3:2]に設定
#             クリック位置がアイコン領域外の場合 $80 を設定
#             ※ bit[3:2]はビットセットのみ行うので、予めクリアしておくこと
# ※ OBJ座標系は右下原点なのでマウスY座標はカーソル先端(左上)から+16ピクセル
f_check_click_icon_area_x >src/f_check_click_icon_area_x.o
fsz=$(to16 $(stat -c '%s' src/f_check_click_icon_area_x.o))
fadr=$(calc16 "${a_check_click_icon_area_x}+${fsz}")
a_check_click_icon_area_y=$(four_digits $fadr)
echo -e "a_check_click_icon_area_y=$a_check_click_icon_area_y" >>$MAP_FILE_NAME
f_check_click_icon_area_y() {
	# push
	lr35902_push_reg regAF

	# マウス座標(Y)を取得
	lr35902_copy_to_regA_from_addr $var_mouse_y

	# A >= 24 ?
	lr35902_compare_regA_and 28
	(
		# A >= 24 の場合

		# A < 48 ?
		lr35902_compare_regA_and 40
		(
			# A < 48 の場合

			# pop & return
			lr35902_pop_reg regAF
			## bit[3:2] = %00
			lr35902_return
		) >src/f_check_click_icon_area_y.1.o
		local sz_1=$(stat -c '%s' src/f_check_click_icon_area_y.1.o)
		lr35902_rel_jump_with_cond NC $(two_digits_d $sz_1)
		cat src/f_check_click_icon_area_y.1.o
	) >src/f_check_click_icon_area_y.2.o
	local sz_2=$(stat -c '%s' src/f_check_click_icon_area_y.2.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $sz_2)
	cat src/f_check_click_icon_area_y.2.o

	# A >= 48 ?
	lr35902_compare_regA_and 40
	(
		# A >= 48 の場合

		# A < 72 ?
		lr35902_compare_regA_and 58
		(
			# A < 72 の場合

			# pop & return
			lr35902_pop_reg regAF
			## bit[3:2] = %01
			lr35902_add_to_regA 04
			lr35902_return
		) >src/f_check_click_icon_area_y.3.o
		local sz_3=$(stat -c '%s' src/f_check_click_icon_area_y.3.o)
		lr35902_rel_jump_with_cond NC $(two_digits_d $sz_3)
		cat src/f_check_click_icon_area_y.3.o
	) >src/f_check_click_icon_area_y.4.o
	local sz_4=$(stat -c '%s' src/f_check_click_icon_area_y.4.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $sz_4)
	cat src/f_check_click_icon_area_y.4.o

	# A >= 72 ?
	lr35902_compare_regA_and 58
	(
		# A >= 72 の場合

		# A < 96 ?
		lr35902_compare_regA_and 70
		(
			# A < 96 の場合

			# pop & return
			lr35902_pop_reg regAF
			## bit[3:2] = %10
			lr35902_add_to_regA 08
			lr35902_return
		) >src/f_check_click_icon_area_y.5.o
		local sz_5=$(stat -c '%s' src/f_check_click_icon_area_y.5.o)
		lr35902_rel_jump_with_cond NC $(two_digits_d $sz_5)
		cat src/f_check_click_icon_area_y.5.o
	) >src/f_check_click_icon_area_y.6.o
	local sz_6=$(stat -c '%s' src/f_check_click_icon_area_y.6.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $sz_6)
	cat src/f_check_click_icon_area_y.6.o

	# A >= 96 ?
	lr35902_compare_regA_and 70
	(
		# A >= 96 の場合

		# A < 120 ?
		lr35902_compare_regA_and 88
		(
			# A < 120 の場合

			# pop & return
			lr35902_pop_reg regAF
			## bit[3:2] = %11
			lr35902_add_to_regA 0c
			lr35902_return
		) >src/f_check_click_icon_area_y.7.o
		local sz_7=$(stat -c '%s' src/f_check_click_icon_area_y.7.o)
		lr35902_rel_jump_with_cond NC $(two_digits_d $sz_7)
		cat src/f_check_click_icon_area_y.7.o
	) >src/f_check_click_icon_area_y.8.o
	local sz_8=$(stat -c '%s' src/f_check_click_icon_area_y.8.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $sz_8)
	cat src/f_check_click_icon_area_y.8.o

	# pop & return
	lr35902_pop_reg regAF
	lr35902_set_reg regA 80	# アイコン領域外
	lr35902_return
}

# 実行ファイル実行開始関数
# in : regHL - ファイル先頭アドレス
#              (ファイルサイズ(2バイト)以降の領域の先頭アドレス)
f_check_click_icon_area_y >src/f_check_click_icon_area_y.o
fsz=$(to16 $(stat -c '%s' src/f_check_click_icon_area_y.o))
fadr=$(calc16 "${a_check_click_icon_area_y}+${fsz}")
a_run_exe=$(four_digits $fadr)
echo -e "a_run_exe=$a_run_exe" >>$MAP_FILE_NAME
f_run_exe() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	# 画面クリアをDAへ登録
	lr35902_call $a_clr_win

	# RAM(0xD000-)へロード
	lr35902_copyinc_to_regA_from_ptrHL
	lr35902_copy_to_from regC regA
	lr35902_copyinc_to_regA_from_ptrHL
	lr35902_copy_to_from regB regA
	lr35902_set_reg regDE $GBOS_APP_MEM_BASE
	lr35902_push_reg regHL
	lr35902_copy_to_from regL regE
	lr35902_copy_to_from regH regD
	lr35902_add_to_regHL regBC
	lr35902_copy_to_from regC regL
	lr35902_copy_to_from regB regH
	lr35902_pop_reg regHL
	(
		(
			lr35902_copyinc_to_regA_from_ptrHL
			lr35902_copy_to_from ptrDE regA
			lr35902_inc regDE

			# DE != BC の間ループする

			# D == B ?
			lr35902_copy_to_from regA regD
			lr35902_compare_regA_and regB
		) >src/f_run_exe.1.o
		cat src/f_run_exe.1.o
		local sz_1=$(stat -c '%s' src/f_run_exe.1.o)
		lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_1 + 2)))

		# E == C ?
		lr35902_copy_to_from regA regE
		lr35902_compare_regA_and regC
	) >src/f_run_exe.2.o
	cat src/f_run_exe.2.o
	local sz_2=$(stat -c '%s' src/f_run_exe.2.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_2 + 2)))

	# DASにrun_exeのビットをセット
	lr35902_copy_to_regA_from_addr $var_draw_act_stat
	lr35902_set_bitN_of_reg $GBOS_DA_BITNUM_RUN_EXE regA
	lr35902_copy_to_addr_from_regA $var_draw_act_stat

	# ウィンドウステータスに「実行ファイル実行中」のみを設定
	lr35902_set_reg regA $GBOS_WST_NUM_EXE
	lr35902_copy_to_addr_from_regA $var_win_stat

	# pop & return
	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

# 実行ファイル周期実行関数
f_run_exe >src/f_run_exe.o
fsz=$(to16 $(stat -c '%s' src/f_run_exe.o))
fadr=$(calc16 "${a_run_exe}+${fsz}")
a_run_exe_cyc=$(four_digits $fadr)
echo -e "a_run_exe_cyc=$a_run_exe_cyc" >>$MAP_FILE_NAME
f_run_exe_cyc() {
	# push
	lr35902_push_reg regAF

	# $GBOS_APP_MEM_BASE をcall
	lr35902_call $GBOS_APP_MEM_BASE

	# pop & return
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

# 1000h〜の領域に配置される
global_functions() {
	f_tcoord_to_addr
	f_wtcoord_to_tcoord
	f_tcoord_to_mrraddr
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
	f_tn_to_addr
	f_view_img
	f_view_img_cyc
	f_rstr_tiles
	f_rstr_tiles_cyc
	f_view_dir
	f_view_dir_cyc
	f_check_click_icon_area_x
	f_check_click_icon_area_y
	f_run_exe
	f_run_exe_cyc
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

# レジスタAをシェル引数で指定されたオブジェクト番号のY座標に設定
obj_set_y() {
	local oam_num=$1
	local oam_addr=$(calc16 "${GBOS_OAM_BASE}+(${oam_num}*${GBOS_OAM_SZ})")
	lr35902_set_reg regHL $oam_addr
	lr35902_copy_to_ptrHL_from regA
}

# シェル引数で指定されたオブジェクト番号のY座標をレジスタAに取得
obj_get_y() {
	local oam_num=$1
	local oam_addr=$(calc16 "${GBOS_OAM_BASE}+(${oam_num}*${GBOS_OAM_SZ})")
	lr35902_set_reg regHL $oam_addr
	lr35902_copy_to_from regA ptrHL
}

# 処理棒の初期化
proc_bar_init() {
	if [ "${debug_mode}" = "true" ]; then
		# 処理棒を描画
		obj_init $GBOS_OAM_NUM_PCB $GB_DISP_HEIGHT $GB_DISP_WIDTH \
			 $GBOS_TILE_NUM_UP_ARROW $GBOS_OBJ_DEF_ATTR

		# 関連する変数の初期化
		lr35902_clear_reg regA
		lr35902_copy_to_addr_from_regA $var_dbg_over_vblank
	fi
}

# 処理棒の開始時点設定
proc_bar_begin() {
	if [ "${debug_mode}" = "true" ]; then
		# 前回vblank期間を超えていたかチェック
		obj_get_y $GBOS_OAM_NUM_PCB
		lr35902_compare_regA_and $GBOS_OBJ_HEIGHT
		(
			lr35902_set_reg regA 01
			lr35902_copy_to_addr_from_regA $var_dbg_over_vblank
		) >src/proc_bar_begin.1.o
		local sz_1=$(stat -c '%s' src/proc_bar_begin.1.o)
		lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_1)
		cat src/proc_bar_begin.1.o

		# 処理棒をMAX設定
		# 一番高い位置に処理棒OBJのY座標を設定する
		# ループ処理末尾でその時のLYに応じて設定し直すが
		# 末尾に至るまでの間にVブランクを終えた場合、
		# 処理棒は一番高い位置で残ることになる
		# (それにより、Vブランク期間内にループ処理を終えられなかった事がわかる)
		lr35902_set_reg regA $GBOS_OBJ_HEIGHT
		obj_set_y $GBOS_OAM_NUM_PCB
	fi
}

# 処理棒の終了時点設定
proc_bar_end() {
	if [ "${debug_mode}" = "true" ]; then
		# [処理棒をLYに応じて設定]
		lr35902_copy_to_regA_from_ioport $GB_IO_LY
		lr35902_sub_to_regA $GB_DISP_HEIGHT
		lr35902_compare_regA_and 00
		(
			# A == 0 の場合
			lr35902_set_reg regA $GB_DISP_HEIGHT
		) >src/proc_bar_end.3.o
		(
			# A != 0 の場合
			lr35902_copy_to_from regC regA
			lr35902_set_reg regA $GB_DISP_HEIGHT
			(
				lr35902_sub_to_regA 0e
				lr35902_dec regC
			) >src/proc_bar_end.1.o
			cat src/proc_bar_end.1.o
			local sz_1=$(stat -c '%s' src/proc_bar_end.1.o)
			lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_1 + 2)))

			# A == 0の場合の処理を飛ばす
			local sz_3=$(stat -c '%s' src/proc_bar_end.3.o)
			lr35902_rel_jump $(two_digits_d $sz_3)
		) >src/proc_bar_end.2.o
		local sz_2=$(stat -c '%s' src/proc_bar_end.2.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
		cat src/proc_bar_end.2.o
		cat src/proc_bar_end.3.o

		obj_set_y $GBOS_OAM_NUM_PCB
	fi
}

# タイルミラー領域を空白タイルで初期化
init_tmrr() {
	lr35902_set_reg regL $GBOS_TMRR_BASE_BH
	lr35902_set_reg regH $GBOS_TMRR_BASE_TH

	(
		lr35902_set_reg regA $GBOS_TILE_NUM_SPC
		lr35902_copyinc_to_ptrHL_from_regA

		lr35902_copy_to_from regA regH
		lr35902_compare_regA_and e0
	) >src/init_tmrr.1.o
	cat src/init_tmrr.1.o
	local sz_1=$(stat -c '%s' src/init_tmrr.1.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_1 + 2)))
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
	set_win_coord $GBOS_WX_DEF $GBOS_WY_DEF

	# タイトル・中身空のウィンドウを描画
	draw_blank_window

	# 初期アイコンを配置
	lr35902_call $a_view_dir
	(
		lr35902_call $a_view_dir_cyc
		lr35902_copy_to_regA_from_addr $var_draw_act_stat
		lr35902_test_bitN_of_reg $GBOS_DA_BITNUM_VIEW_DIR regA
	) >src/init.1.o
	cat src/init.1.o
	local sz_1=$(stat -c '%s' src/init.1.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_1 + 2)))

	# マウスカーソルを描画
	obj_init $GBOS_OAM_NUM_CSL $GBOS_OBJ_HEIGHT $GBOS_OBJ_WIDTH \
		 $GBOS_TILE_NUM_CSL $GBOS_OBJ_DEF_ATTR
	# 別途 obj_move とかの関数も作る
	# TODO グローバル関数化

	# 処理棒の初期化
	proc_bar_init

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
	# - アプリ用ボタンリリースフラグをゼロクリア
	lr35902_copy_to_addr_from_regA $var_app_release_btn
	# - ウィンドウステータスをディレクトリ表示中で初期化
	lr35902_set_bitN_of_reg $GBOS_WST_BITNUM_DIR regA
	lr35902_copy_to_addr_from_regA $var_win_stat
	# - tdq.head = tdq.tail = TDQ_FIRST
	lr35902_set_reg regA $(echo $GBOS_TDQ_FIRST | cut -c3-4)
	lr35902_copy_to_addr_from_regA $var_tdq_head_bh
	lr35902_copy_to_addr_from_regA $var_tdq_tail_bh
	lr35902_set_reg regA $(echo $GBOS_TDQ_FIRST | cut -c1-2)
	lr35902_copy_to_addr_from_regA $var_tdq_head_th
	lr35902_copy_to_addr_from_regA $var_tdq_tail_th
	# - tdq.stat = is_empty
	lr35902_set_reg regA 01
	lr35902_copy_to_addr_from_regA $var_tdq_stat

	# タイルミラー領域の初期化
	init_tmrr

	# タイマー設定&開始
	lr35902_copy_to_regA_from_ioport $GB_IO_TAC
	lr35902_or_to_regA $(calc16_2 "$GB_TAC_BIT_START+$GB_TAC_BIT_HZ_262144")
	lr35902_copy_to_ioport_from_regA $GB_IO_TAC

	# サウンドの初期化
	# - サウンド無効化(使う時にONにする)
	lr35902_copy_to_regA_from_ioport $GB_IO_NR52
	lr35902_res_bitN_of_reg $GB_NR52_BITNUM_ALL_ONOFF regA
	lr35902_copy_to_ioport_from_regA $GB_IO_NR52

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

# ファイルを閲覧
# in : regA - ファイル番号
## TODO 関数化
## TODO regA == 80 の時、直ちにret
## TODO regA >= ファイル数 の時、直ちにret
view_file() {
	# DEは呼び出し元で使っているので予め退避
	lr35902_push_reg regDE

	# Aは作業にも使うのでファイル番号はBへコピー
	lr35902_copy_to_from regB regA

	# ファイルタイプ取得
	local file_type_1st_ofs=0007
	local file_type_1st_addr=$(calc16 "${GBOS_FS_BASE}+${file_type_1st_ofs}")
	lr35902_set_reg regHL $file_type_1st_addr
	lr35902_compare_regA_and 00
	(
		# ファイル番号 != 0 の場合

		lr35902_set_reg regDE $(four_digits $GBOS_FS_FILE_ATTR_SZ)

		(
			lr35902_add_to_regHL regDE
			lr35902_dec regA
		) >src/view_file.3.o
		cat src/view_file.3.o
		local sz_3=$(stat -c '%s' src/view_file.3.o)
		lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_3 + 2)))
	) >src/view_file.4.o
	local sz_4=$(stat -c '%s' src/view_file.4.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_4)
	cat src/view_file.4.o
	## ファイルタイプをAへ取得
	lr35902_copy_to_from regA ptrHL

	# Aは作業に使うのでCへコピー
	lr35902_copy_to_from regC regA

	# HLへファイル先頭アドレスを設定
	## ファイルへのオフセットが格納されたアドレスを設定
	lr35902_inc regHL
	## ファイルへのオフセット取得
	lr35902_copyinc_to_regA_from_ptrHL
	lr35902_copy_to_from regE regA
	lr35902_copy_to_from regA ptrHL
	lr35902_copy_to_from regD regA
	## FSベースアドレスと足してファイルデータ先頭アドレス取得
	lr35902_set_reg regHL $GBOS_FS_BASE
	lr35902_add_to_regHL regDE

	# ファイルタイプをAへ復帰
	lr35902_copy_to_from regA regC

	lr35902_compare_regA_and $GBOS_ICON_NUM_EXE
	(
		# 実行ファイルの場合
		lr35902_copy_to_from regA regB
		lr35902_call $a_run_exe

		# Aがこの後何にもヒットしないようにする
		lr35902_clear_reg regA
	) >src/view_file.5.o
	local sz_5=$(stat -c '%s' src/view_file.5.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_5)
	cat src/view_file.5.o

	lr35902_compare_regA_and $GBOS_ICON_NUM_TXT
	(
		# テキストファイルの場合
		lr35902_copy_to_from regA regB
		lr35902_call $a_view_txt

		# Aがこの後何にもヒットしないようにする
		lr35902_clear_reg regA
	) >src/view_file.1.o
	local sz_1=$(stat -c '%s' src/view_file.1.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_1)
	cat src/view_file.1.o

	lr35902_compare_regA_and $GBOS_ICON_NUM_IMG
	(
		# 画像ファイルの場合
		lr35902_copy_to_from regA regB
		lr35902_call $a_view_img
	) >src/view_file.2.o
	local sz_2=$(stat -c '%s' src/view_file.2.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_2)
	cat src/view_file.2.o

	# DEを復帰
	lr35902_pop_reg regDE
}

# クリックイベント処理
click_event() {
	lr35902_push_reg regAF

	# ウィンドウステータスが「ディレクトリ表示中」であるか確認
	lr35902_copy_to_regA_from_addr $var_win_stat
	lr35902_test_bitN_of_reg $GBOS_WST_BITNUM_DIR regA
	(
		# 「ディレクトリ表示中」の場合

		lr35902_clear_reg regA
		lr35902_call $a_check_click_icon_area_x
		lr35902_call $a_check_click_icon_area_y

		view_file
	) >src/click_event.1.o
	local sz_1=$(stat -c '%s' src/click_event.1.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_1)
	cat src/click_event.1.o

	lr35902_pop_reg regAF
}

# 右クリックイベント処理
# in : regA - リリースされたボタン(上位4ビット)
right_click_event() {
	# 呼び出し元へ戻る際に復帰できるようにpush
	lr35902_push_reg regAF

	# ウィンドウステータスをAへ取得
	lr35902_copy_to_regA_from_addr $var_win_stat

	# 画像ファイル表示中か確認
	lr35902_test_bitN_of_reg $GBOS_WST_BITNUM_IMG regA
	(
		# 画像ファイル表示中の場合
		lr35902_call $a_rstr_tiles
	) >src/right_click_event.1.o
	local sz_1=$(stat -c '%s' src/right_click_event.1.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_1)
	## 画像ファイル表示中の場合
	cat src/right_click_event.1.o

	# clr_win設定
	lr35902_call $a_clr_win

	# view_dir設定
	lr35902_call $a_view_dir

	lr35902_pop_reg regAF
}

# ボタンリリースに応じた処理
# in : regA - リリースされたボタン(上位4ビット)
btn_release_handler() {
	local sz

	# Bボタンの確認
	lr35902_test_bitN_of_reg $GBOS_B_KEY_BITNUM regA
	(
		click_event
	) >src/btn_release_handler.1.o
	sz=$(stat -c '%s' src/btn_release_handler.1.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz)
	cat src/btn_release_handler.1.o

	# Aボタンの確認
	lr35902_test_bitN_of_reg $GBOS_A_KEY_BITNUM regA
	(
		right_click_event
	) >src/btn_release_handler.2.o
	sz=$(stat -c '%s' src/btn_release_handler.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz)
	cat src/btn_release_handler.2.o
}

# タイル描画キュー処理
# 書き換え不可レジスタ: regD
# (変更する場合はpush/popすること)
tdq_handler() {
	lr35902_copy_to_regA_from_addr $var_tdq_stat
	lr35902_test_bitN_of_reg $GBOS_TDQ_STAT_BITNUM_EMPTY regA
	(
		# tdq is not empty

		# push
		lr35902_push_reg regDE

		# HL = tdq.head
		lr35902_copy_to_regA_from_addr $var_tdq_head_bh
		lr35902_copy_to_from regL regA
		lr35902_copy_to_regA_from_addr $var_tdq_head_th
		lr35902_copy_to_from regH regA

		# 1周期の最大描画タイル数をCへ設定
		lr35902_set_reg regC $GBOS_TDQ_MAX_DRAW_TILES

		(
			# E = (HL++)
			lr35902_copyinc_to_regA_from_ptrHL
			lr35902_copy_to_from regE regA
			# D = (HL++)
			lr35902_copyinc_to_regA_from_ptrHL
			lr35902_copy_to_from regD regA
			# A = (HL++)
			lr35902_copyinc_to_regA_from_ptrHL

			# (DE) = A
			lr35902_copy_to_from ptrDE regA

			# タイルミラー領域(0xDC00-)更新
			lr35902_copy_to_from regB regA
			lr35902_copy_to_from regA regD
			lr35902_and_to_regA $GBOS_TOFS_MASK_TH
			lr35902_add_to_regA $GBOS_TMRR_BASE_TH
			lr35902_copy_to_from regD regA
			lr35902_copy_to_from regA regB
			lr35902_copy_to_from ptrDE regA

			# L == TDQ_END[7:0] ?
			lr35902_copy_to_from regA regL
			lr35902_compare_regA_and $(echo $GBOS_TDQ_END | cut -c3-4)
			(
				# L == TDQ_END[7:0]

				# H == TDQ_END[15:8] ?
				lr35902_copy_to_from regA regH
				lr35902_compare_regA_and $(echo $GBOS_TDQ_END | cut -c1-2)
				(
					# H == TDQ_END[15:8]

					# HL = TDQ_FIRST
					lr35902_set_reg regL $(echo $GBOS_TDQ_FIRST | cut -c3-4)
					lr35902_set_reg regH $(echo $GBOS_TDQ_FIRST | cut -c1-2)
				) >src/tdq_handler.5.o
				local sz_5=$(stat -c '%s' src/tdq_handler.5.o)
				lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_5)
				cat src/tdq_handler.5.o
			) >src/tdq_handler.4.o
			local sz_4=$(stat -c '%s' src/tdq_handler.4.o)
			lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_4)
			cat src/tdq_handler.4.o

			# tdq.head = HL
			lr35902_copy_to_from regA regL
			lr35902_copy_to_addr_from_regA $var_tdq_head_bh
			lr35902_copy_to_from regA regH
			lr35902_copy_to_addr_from_regA $var_tdq_head_th

			# tdq.head[7:0] == tdq.tail[7:0] ?
			lr35902_copy_to_regA_from_addr $var_tdq_tail_bh
			lr35902_compare_regA_and regL
			(
				# tdq.head[7:0] == tdq.tail[7:0]

				# tdq.head[15:8] == tdq.tail[15:8] ?
				lr35902_copy_to_regA_from_addr $var_tdq_tail_th
				lr35902_compare_regA_and regH
				(
					# tdq.head[15:8] == tdq.tail[15:8]

					# tdq.stat = empty
					lr35902_set_reg regA 01
					lr35902_copy_to_addr_from_regA $var_tdq_stat

					# popまでジャンプ
					# デクリメント命令サイズ(1)+相対ジャンプ命令サイズ(2)
					# +レジスタAクリアサイズ(1)+tdq.stat設定サイズ(3)=7
					lr35902_rel_jump 07
				) >src/tdq_handler.3.o
				local sz_3=$(stat -c '%s' src/tdq_handler.3.o)
				lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_3)
				cat src/tdq_handler.3.o
			) >src/tdq_handler.2.o
			local sz_2=$(stat -c '%s' src/tdq_handler.2.o)
			lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_2)
			cat src/tdq_handler.2.o
		) >src/tdq_handler.6.o
		cat src/tdq_handler.6.o
		local sz_6=$(stat -c '%s' src/tdq_handler.6.o)

		# Cをデクリメント
		lr35902_dec regC

		# C != 0 なら繰り返す
		# tdq_handler.6.oのサイズに
		# デクリメント命令サイズと相対ジャンプ命令サイズを足す
		lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_6+3)))

		# tdq.stat = 0
		lr35902_clear_reg regA
		lr35902_copy_to_addr_from_regA $var_tdq_stat

		# pop
		lr35902_pop_reg regDE
	) >src/tdq_handler.1.o
	local sz_1=$(stat -c '%s' src/tdq_handler.1.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_1)
	cat src/tdq_handler.1.o
}

# DASのビットに応じた処理を呼び出す
# in : regA - DAS
das_handler() {
	# rstr_tilesのチェック
	lr35902_test_bitN_of_reg $GBOS_DA_BITNUM_RSTR_TILES regA
	(
		# rstr_tilesがセットされていた場合
		lr35902_call $a_rstr_tiles_cyc

		# この周期ではVIEW系の処理は実施しない
		lr35902_res_bitN_of_reg $GBOS_DA_BITNUM_VIEW_DIR regA
		lr35902_res_bitN_of_reg $GBOS_DA_BITNUM_VIEW_TXT regA
		lr35902_res_bitN_of_reg $GBOS_DA_BITNUM_VIEW_IMG regA
	) >src/das_handler.5.o
	local sz_5=$(stat -c '%s' src/das_handler.5.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_5)
	# rstr_tilesがセットされていた場合
	cat src/das_handler.5.o

	# clr_winのチェック
	lr35902_test_bitN_of_reg $GBOS_DA_BITNUM_CLR_WIN regA
	(
		# clr_winがセットされていなかった場合

		# view_dirのチェック
		lr35902_test_bitN_of_reg $GBOS_DA_BITNUM_VIEW_DIR regA
		(
			# view_dirがセットされていた場合
			lr35902_call $a_view_dir_cyc
		) >src/das_handler.6.o
		local sz_6=$(stat -c '%s' src/das_handler.6.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_6)
		# view_dirがセットされていた場合
		cat src/das_handler.6.o

		# run_exeのチェック
		lr35902_test_bitN_of_reg $GBOS_DA_BITNUM_RUN_EXE regA
		(
			# run_exeがセットされていた場合
			# TIMA = 01
			lr35902_call $a_run_exe_cyc
			# TIMA = 02
			# (* (/ 1 16384.0) 1000)0.06103515625 ms
		) >src/das_handler.7.o
		local sz_7=$(stat -c '%s' src/das_handler.7.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_7)
		# run_exeがセットされていた場合
		cat src/das_handler.7.o

		# view_txtのチェック
		lr35902_test_bitN_of_reg $GBOS_DA_BITNUM_VIEW_TXT regA
		(
			# view_txtがセットされていた場合
			lr35902_call $a_view_txt_cyc
		) >src/das_handler.3.o
		local sz_3=$(stat -c '%s' src/das_handler.3.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_3)
		# view_txtがセットされていた場合
		cat src/das_handler.3.o

		# view_imgのチェック
		lr35902_test_bitN_of_reg $GBOS_DA_BITNUM_VIEW_IMG regA
		(
			# view_imgがセットされていた場合
			lr35902_call $a_view_img_cyc
		) >src/das_handler.4.o
		local sz_4=$(stat -c '%s' src/das_handler.4.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_4)
		# view_imgがセットされていた場合
		cat src/das_handler.4.o
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


	# [処理棒の開始時点設定]
	proc_bar_begin


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

	# [タイル描画キュー処理]
	tdq_handler


	# [ボタンリリースフラグ更新]

	# 前回の入力状態を変数から取得
	lr35902_copy_to_regA_from_addr $var_prv_btn
	lr35902_copy_to_from regE regA

	# リリースのみ抽出(1->0の変化があったビットのみregAへ格納)
	# 1. 現在と前回でxor
	lr35902_xor_to_regA regD
	# 2. 1.と前回でand
	lr35902_and_to_regA regE

	# リリースされたボタンをBへコピー
	lr35902_copy_to_from regB regA

	# ウィンドウステータスがディレクトリ表示中であるか否か
	lr35902_copy_to_regA_from_addr $var_win_stat
	lr35902_test_bitN_of_reg $GBOS_WST_BITNUM_DIR regA
	(
		# ディレクトリ表示中以外の場合

		# アプリ用ボタンリリースフラグ更新
		lr35902_copy_to_regA_from_addr $var_app_release_btn
		lr35902_or_to_regA regB
		lr35902_copy_to_addr_from_regA $var_app_release_btn
	) >src/event_driven.5.o
	(
		# ディレクトリ表示中の場合

		# 隠しコマンドステートをAへロード
		lr35902_copy_to_regA_from_addr $var_hidden_com_stat

		# 隠しコマンド入力判定状態遷移
		## ↑のリリースチェック
		lr35902_test_bitN_of_reg $GBOS_JOYP_BITNUM_UP regB
		(
			# ↑のリリース有り

			# stat は 0 or 1 か ? (stat < 2 ?)
			lr35902_compare_regA_and 02
			(
				# stat != 0 or 1

				# stat = 1
				lr35902_set_reg regA 01
				lr35902_copy_to_addr_from_regA $var_hidden_com_stat
			) >src/hidden_com_stat_up.2.o
			(
				# stat == 0 or 1

				# stat++
				lr35902_inc regA
				lr35902_copy_to_addr_from_regA $var_hidden_com_stat

				# stat != 0 or 1 の場合の処理を飛ばす
				local sz_hcs_up_2=$(stat -c '%s' src/hidden_com_stat_up.2.o)
				lr35902_rel_jump $(two_digits_d $sz_hcs_up_2)
			) >src/hidden_com_stat_up.1.o
			local sz_hcs_up_1=$(stat -c '%s' src/hidden_com_stat_up.1.o)
			lr35902_rel_jump_with_cond NC $(two_digits_d $sz_hcs_up_1)
			cat src/hidden_com_stat_up.1.o
			cat src/hidden_com_stat_up.2.o
		) >src/hidden_com_stat_up.o
		local sz_hcs_up=$(stat -c '%s' src/hidden_com_stat_up.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_hcs_up)
		cat src/hidden_com_stat_up.o

		## ↓のリリースチェック
		lr35902_test_bitN_of_reg $GBOS_JOYP_BITNUM_DOWN regB
		(
			# ↓のリリース有り

			# stat は 2 or 3 か ?
			# (2を引いた後、0xfeとの&を取ると0になるか?)

			## CへAを退避
			lr35902_copy_to_from regC regA

			## 2を引いた後、0xfeとの&を取ると0になるか?
			lr35902_sub_to_regA 02
			lr35902_and_to_regA fe
			(
				# stat != 2 or 3 (A != 0)

				# stat = 0
				lr35902_clear_reg regA
				lr35902_copy_to_addr_from_regA $var_hidden_com_stat
			) >src/hidden_com_stat_down.2.o
			(
				# stat == 2 or 3 (A == 0)

				# AへCを復帰
				lr35902_copy_to_from regA regC

				# stat++
				lr35902_inc regA
				lr35902_copy_to_addr_from_regA $var_hidden_com_stat

				# stat != 2 or 3 の場合の処理を飛ばす
				local sz_hcs_down_2=$(stat -c '%s' src/hidden_com_stat_down.2.o)
				lr35902_rel_jump $(two_digits_d $sz_hcs_down_2)
			) >src/hidden_com_stat_down.1.o
			local sz_hcs_down_1=$(stat -c '%s' src/hidden_com_stat_down.1.o)
			lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_hcs_down_1)
			cat src/hidden_com_stat_down.1.o
			cat src/hidden_com_stat_down.2.o
		) >src/hidden_com_stat_down.o
		local sz_hcs_down=$(stat -c '%s' src/hidden_com_stat_down.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_hcs_down)
		cat src/hidden_com_stat_down.o

		## ←のリリースチェック
		lr35902_test_bitN_of_reg $GBOS_JOYP_BITNUM_LEFT regB
		(
			# ←のリリース有り

			# stat は 4 or 6 か ?
			# (4を引いた後、0xfdとの&を取ると0になるか?)

			## CへAを退避
			lr35902_copy_to_from regC regA

			## 4を引いた後、0xfdとの&を取ると0になるか?
			lr35902_sub_to_regA 04
			lr35902_and_to_regA fd
			(
				# stat != 4 or 6 (A != 0)

				# stat = 0
				lr35902_clear_reg regA
				lr35902_copy_to_addr_from_regA $var_hidden_com_stat
			) >src/hidden_com_stat_left.2.o
			(
				# stat == 4 or 6 (A == 0)

				# AへCを復帰
				lr35902_copy_to_from regA regC

				# stat++
				lr35902_inc regA
				lr35902_copy_to_addr_from_regA $var_hidden_com_stat

				# stat != 4 or 6 の場合の処理を飛ばす
				local sz_hcs_left_2=$(stat -c '%s' src/hidden_com_stat_left.2.o)
				lr35902_rel_jump $(two_digits_d $sz_hcs_left_2)
			) >src/hidden_com_stat_left.1.o
			local sz_hcs_left_1=$(stat -c '%s' src/hidden_com_stat_left.1.o)
			lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_hcs_left_1)
			cat src/hidden_com_stat_left.1.o
			cat src/hidden_com_stat_left.2.o
		) >src/hidden_com_stat_left.o
		local sz_hcs_left=$(stat -c '%s' src/hidden_com_stat_left.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_hcs_left)
		cat src/hidden_com_stat_left.o

		## →のリリースチェック
		lr35902_test_bitN_of_reg $GBOS_JOYP_BITNUM_RIGHT regB
		(
			# →のリリース有り

			# stat は 5 or 7 か ?
			# (5を引いた後、0xfdとの&を取ると0になるか?)

			## CへAを退避
			lr35902_copy_to_from regC regA

			## 5を引いた後、0xfdとの&を取ると0になるか?
			lr35902_sub_to_regA 05
			lr35902_and_to_regA fd
			(
				# stat != 5 or 7 (A != 0)

				# stat = 0
				lr35902_clear_reg regA
				lr35902_copy_to_addr_from_regA $var_hidden_com_stat
			) >src/hidden_com_stat_right.2.o
			(
				# stat == 5 or 7 (A == 0)

				# AへCを復帰
				lr35902_copy_to_from regA regC

				# stat++
				lr35902_inc regA
				lr35902_copy_to_addr_from_regA $var_hidden_com_stat

				# stat != 5 or 7 の場合の処理を飛ばす
				local sz_hcs_right_2=$(stat -c '%s' src/hidden_com_stat_right.2.o)
				lr35902_rel_jump $(two_digits_d $sz_hcs_right_2)
			) >src/hidden_com_stat_right.1.o
			local sz_hcs_right_1=$(stat -c '%s' src/hidden_com_stat_right.1.o)
			lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_hcs_right_1)
			cat src/hidden_com_stat_right.1.o
			cat src/hidden_com_stat_right.2.o
		) >src/hidden_com_stat_right.o
		local sz_hcs_right=$(stat -c '%s' src/hidden_com_stat_right.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_hcs_right)
		cat src/hidden_com_stat_right.o

		## Bのリリースチェック
		lr35902_test_bitN_of_reg $GBOS_JOYP_BITNUM_B regB
		(
			# Bのリリース有り

			# stat は 8 か ?
			lr35902_compare_regA_and 08
			(
				# stat != 8

				# stat = 0
				lr35902_clear_reg regA
				lr35902_copy_to_addr_from_regA $var_hidden_com_stat
			) >src/hidden_com_stat_b.2.o
			(
				# stat == 8

				# stat++
				lr35902_inc regA
				lr35902_copy_to_addr_from_regA $var_hidden_com_stat

				# stat != 8 の場合の処理を飛ばす
				local sz_hcs_b_2=$(stat -c '%s' src/hidden_com_stat_b.2.o)
				lr35902_rel_jump $(two_digits_d $sz_hcs_b_2)
			) >src/hidden_com_stat_b.1.o
			local sz_hcs_b_1=$(stat -c '%s' src/hidden_com_stat_b.1.o)
			lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_hcs_b_1)
			cat src/hidden_com_stat_b.1.o
			cat src/hidden_com_stat_b.2.o
		) >src/hidden_com_stat_b.o
		local sz_hcs_b=$(stat -c '%s' src/hidden_com_stat_b.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_hcs_b)
		cat src/hidden_com_stat_b.o

		## Aのリリースチェック
		lr35902_test_bitN_of_reg $GBOS_JOYP_BITNUM_A regB
		(
			# Aのリリース有り

			# stat は 9 か ?
			lr35902_compare_regA_and 09
			(
				# stat != 9

				# stat = 0
				lr35902_clear_reg regA
				lr35902_copy_to_addr_from_regA $var_hidden_com_stat
			) >src/hidden_com_stat_a.2.o
			(
				# stat == 9

				# stat++
				lr35902_inc regA
				lr35902_copy_to_addr_from_regA $var_hidden_com_stat

				# stat != 9 の場合の処理を飛ばす
				local sz_hcs_a_2=$(stat -c '%s' src/hidden_com_stat_a.2.o)
				lr35902_rel_jump $(two_digits_d $sz_hcs_a_2)
			) >src/hidden_com_stat_a.1.o
			local sz_hcs_a_1=$(stat -c '%s' src/hidden_com_stat_a.1.o)
			lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_hcs_a_1)
			cat src/hidden_com_stat_a.1.o
			cat src/hidden_com_stat_a.2.o
		) >src/hidden_com_stat_a.o
		local sz_hcs_a=$(stat -c '%s' src/hidden_com_stat_a.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_hcs_a)
		cat src/hidden_com_stat_a.o

		## stat >= 10 ?
		lr35902_compare_regA_and 0a
		(
			local cursor_oam_tile_num_addr=fe02
			local tile_num=10	# →←
			lr35902_set_reg regA $tile_num
			lr35902_copy_to_addr_from_regA $cursor_oam_tile_num_addr
		) >src/hidden_com_stat_goal.o
		local sz_hcs_goal=$(stat -c '%s' src/hidden_com_stat_goal.o)
		lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_hcs_goal)
		cat src/hidden_com_stat_goal.o

		# ディレクトリ表示中以外の場合の処理を飛ばす
		local sz5=$(stat -c '%s' src/event_driven.5.o)
		lr35902_rel_jump $(two_digits_d $sz5)
	) >src/event_driven.6.o
	local sz6=$(stat -c '%s' src/event_driven.6.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz6)
	cat src/event_driven.6.o
	cat src/event_driven.5.o


	# [描画アクション(DA)あるいはボタンリリース処理]

	# DASに何らかのビットがセットされているか
	lr35902_copy_to_regA_from_addr $var_draw_act_stat
	lr35902_compare_regA_and 00
	# TIMA = 01
	(
		# DASに何らかのビットがセットされていた場合の処理
		das_handler
	) >src/event_driven.4.o
	(
		# DASにビットが何もセットされていなかった場合の処理
		# (ボタンリリースに応じた処理を実施)

		# ボタンのリリースがあった場合それに応じた処理を実施
		lr35902_copy_to_from regA regB
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


	# [処理棒の終了時点設定]
	proc_bar_end


	# [割り込み待ち(halt)へ戻る]
	# lr35902_rel_jump $(two_comp 76)			# 2
	# (+ 2 4 (* 2 (+ 8 5 40)) 4 2)118
	gbos_const >src/gbos_const.o
	local const_bytes=$(stat -c '%s' src/gbos_const.o)
	local init_bytes=$(stat -c '%s' src/init.o)
	local bc_form="obase=16;${const_bytes}+${init_bytes}"
	local const_init=$(echo $bc_form | bc)
	bc_form="obase=16;ibase=16;${GB_ROM_FREE_BASE}+${const_init}"
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

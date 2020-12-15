#!/bin/bash

# set -uex
set -ue

. include/gb.sh
. include/map.sh
. include/vars.sh
. include/tiles.sh
. include/gbos.sh
. include/tdq.sh

# アプリのメモリマップ
APP_MAIN_SZ=0200
APP_VARS_SZ=0200
APP_FUNCS_SZ=0800
APP_MAIN_BASE=$GB_WRAM1_BASE
APP_VARS_BASE=$(calc16 "$APP_MAIN_BASE+$APP_MAIN_SZ")
APP_FUNCS_BASE=$(calc16 "$APP_VARS_BASE+$APP_VARS_SZ")

# 汎用フラグ変数
CF_GFLG_BITNUM_INITED=0	# 初期化済みフラグのビット番号

# RAM0オリジナルデータ用ROMバンク番号
CF_CARTROM_BANK_NUM=02

map_file=map.sh
rm -f $map_file

vars() {
	# 汎用フラグ変数
	var_general_flgs=$APP_VARS_BASE
	echo -e "var_general_flgs=$var_general_flgs" >>$map_file
	echo -en '\x00'	# 全て0
}
# 変数設定のために空実行
vars >/dev/null
rm -f $map_file

# 初期配置のタイルをtdqへ積む
# ※ この関数内で使うレジスタは事前のpushと事後のpopをしていない
f_draw_init_tiles() {
	# 1行目(0x9862-)
	# 「かーとりつし゛のRAMを」
	lr35902_set_reg regDE 9862
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_KA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_DASH
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_TO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_RI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_TSU
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SHI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_DAKUTEN
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_NO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $(get_alpha_tile_num R)
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $(get_alpha_tile_num A)
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $(get_alpha_tile_num M)
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_WO
	lr35902_call $a_enq_tdq

	# 2行目(0x9882-)
	# 「しよきかしますか?」
	lr35902_set_reg regDE 9882
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SHI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_YO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_KI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_KA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SHI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_MA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SU
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_KA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_QUESTION
	lr35902_call $a_enq_tdq

	# 4行目(0x98c2-)
	# 「しよきかすると、」
	lr35902_set_reg regDE 98c2
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SHI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_YO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_KI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_KA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SU
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_RU
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_TO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_TOUTEN
	lr35902_call $a_enq_tdq

	# 5行目(0x98e2-)
	# 「かーとりつし゛のRAMか゛」
	lr35902_set_reg regDE 98e2
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_KA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_DASH
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_TO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_RI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_TSU
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SHI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_DAKUTEN
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_NO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $(get_alpha_tile_num R)
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $(get_alpha_tile_num A)
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $(get_alpha_tile_num M)
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_KA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_DAKUTEN
	lr35902_call $a_enq_tdq

	# 6行目(0x9902-)
	# 「さいしよのし゛ようたいに」
	lr35902_set_reg regDE 9902
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_I
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SHI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_YO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_NO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SHI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_DAKUTEN
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_YO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_U
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_TA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_I
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_NI
	lr35902_call $a_enq_tdq

	# 7行目(0x9922-)
	# 「もと゛ります。」
	lr35902_set_reg regDE 9922
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_MO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_TO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_DAKUTEN
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_RI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_MA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SU
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_KUTEN
	lr35902_call $a_enq_tdq

	# 8行目(0x9942-)
	# 「(ふあいるも、さいしよの」
	lr35902_set_reg regDE 9942
	lr35902_set_reg regB $GBOS_TILE_NUM_OPEN_BRACKET
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_FU
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_A
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_I
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_RU
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_MO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_TOUTEN
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_I
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SHI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_YO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_NO
	lr35902_call $a_enq_tdq

	# 9行目(0x9962-)
	# 「し゛ようたいにもと゛ります。)」
	lr35902_set_reg regDE 9962
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SHI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_DAKUTEN
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_YO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_U
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_TA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_I
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_NI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_MO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_TO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_DAKUTEN
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_RI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_MA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SU
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_KUTEN
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_CLOSE_BRACKET
	lr35902_call $a_enq_tdq

	# 11行目(0x99a2-)
	# 「すたーとほ゛たん→しよきかする」
	lr35902_set_reg regDE 99a2
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SU
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_TA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_DASH
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_TO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_HO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_DAKUTEN
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_TA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_N
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_RIGHT_ARROW
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SHI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_YO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_KI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_KA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SU
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_RU
	lr35902_call $a_enq_tdq

	# 12行目(0x99c2-)
	# 「Aほ゛たん→ふあいるいちらんへ」
	lr35902_set_reg regDE 99c2
	lr35902_set_reg regB $(get_alpha_tile_num A)
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_HO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_DAKUTEN
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_TA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_N
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_RIGHT_ARROW
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_FU
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_A
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_I
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_RU
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_I
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_CHI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_RA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_N
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_HE
	lr35902_call $a_enq_tdq

	# 13行目(0x99e8-)
	# 「もと゛る」
	lr35902_set_reg regDE 99e8
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_MO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_TO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_DAKUTEN
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_RU
	lr35902_call $a_enq_tdq

	# return
	lr35902_return
}

# 「しよきかちゆう」の文字列を描画し、下部のその他の領域はクリアする
# ※ この関数内で使うレジスタは事前のpushと事後のpopをしていない
# ※ regCは書き換えないこと
f_draw_initializing_tiles() {
	# 11行目(0x99a2-)
	# 「しよきかちゆう」
	lr35902_set_reg regDE 99A2
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SHI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_YO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_KI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_KA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_CHI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_YU
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_U
	lr35902_call $a_enq_tdq

	# 8個のスペース文字を入れてクリア
	lr35902_set_reg regA 08
	lr35902_set_reg regB $GBOS_TILE_NUM_SPC
	(
		lr35902_inc regE
		lr35902_call $a_enq_tdq
		lr35902_dec regA
	) >f_draw_initializing_tiles.1.o
	cat f_draw_initializing_tiles.1.o
	local sz_1=$(stat -c '%s' f_draw_initializing_tiles.1.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_1 + 2)))

	# 12行目(0x99c2-)
	# 15個のスペース文字を入れてクリア
	lr35902_set_reg regA 0f
	lr35902_set_reg regDE 99c2
	(
		lr35902_call $a_enq_tdq
		lr35902_inc regE
		lr35902_dec regA
	) >f_draw_initializing_tiles.2.o
	cat f_draw_initializing_tiles.2.o
	local sz_2=$(stat -c '%s' f_draw_initializing_tiles.2.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_2 + 2)))

	# 13行目(0x99e8-)
	# 4個のスペース文字を入れてクリア
	lr35902_set_reg regA 04
	lr35902_set_reg regDE 99e8
	cat f_draw_initializing_tiles.2.o
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_2 + 2)))

	# return
	lr35902_return
}

# 0x4000(ROM)〜8KB分を、0xa000(RAM)〜へコピー
# ※ この関数内で使うレジスタは事前のpushと事後のpopをしていない
# ※ regCは書き換えないこと
f_copy_rom_to_ram() {
	# push
	lr35902_push_reg regBC

	# regHLにSRCアドレス(0x4000)をロード
	lr35902_set_reg regHL $GB_CARTROM_BANK1_BASE

	# regDEにDSTアドレス(0xa000)をロード
	lr35902_set_reg regDE $GB_CARTRAM_BASE

	# regBCに8192(0x2000)をロード
	lr35902_set_reg regBC 2000

	(
		# SRCをインクリメントしながら1バイト読み出す
		lr35902_copyinc_to_regA_from_ptrHL

		# SRCをスタックへ退避
		lr35902_push_reg regHL

		# DSTをregHLへ設定
		lr35902_copy_to_from regL regE
		lr35902_copy_to_from regH regD

		# DSTをインクリメントしながら1バイト書き込む
		lr35902_copyinc_to_ptrHL_from_regA

		# DSTをregDEへ退避
		lr35902_copy_to_from regE regL
		lr35902_copy_to_from regD regH

		# SRCをスタックから復帰
		lr35902_pop_reg regHL

		# regBCをデクリメント
		lr35902_dec regBC

		# regBCが0か確認
		lr35902_copy_to_from regA regC
		lr35902_or_to_regA regB
	) >f_copy_rom_to_ram.1.o
	cat f_copy_rom_to_ram.1.o
	local sz_1=$(stat -c '%s' f_copy_rom_to_ram.1.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_1 + 2)))

	# pop & return
	lr35902_pop_reg regBC
	lr35902_return
}

# 「しよきかかんりよう!」の文字列を描画
# ※ この関数内で使うレジスタは事前のpushと事後のpopをしていない
# ※ regCは書き換えないこと
f_draw_initialized_tiles() {
	# 11行目(0x99a2-)
	# 「しよきかかんりよう」
	lr35902_set_reg regDE 99A2
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SHI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_YO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_KI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_KA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_KA
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_N
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_RI
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_YO
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_U
	lr35902_call $a_enq_tdq

	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_EXCLAMATION
	lr35902_call $a_enq_tdq

	# 5個のスペース文字を入れてクリア
	lr35902_set_reg regA 05
	lr35902_set_reg regB $GBOS_TILE_NUM_SPC
	(
		lr35902_inc regE
		lr35902_call $a_enq_tdq
		lr35902_dec regA
	) >f_draw_initialized_tiles.1.o
	cat f_draw_initialized_tiles.1.o
	local sz_1=$(stat -c '%s' f_draw_initialized_tiles.1.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_1 + 2)))

	# return
	lr35902_return
}

funcs() {
	local fsz

	# 初期配置のタイルをtdqへ積む
	a_draw_init_tiles=$APP_FUNCS_BASE
	echo -e "a_draw_init_tiles=$a_draw_init_tiles" >>$map_file
	f_draw_init_tiles

	# 「しよきかちゆう」の文字列を描画し、下部のその他の領域はクリアする
	f_draw_init_tiles >f_draw_init_tiles.o
	fsz=$(to16 $(stat -c '%s' f_draw_init_tiles.o))
	a_draw_initializing_tiles=$(four_digits $(calc16 "${a_draw_init_tiles}+${fsz}"))
	echo -e "a_draw_initializing_tiles=$a_draw_initializing_tiles" >>$map_file
	f_draw_initializing_tiles

	# 0x4000(ROM)〜8KB分を、0xa000(RAM)〜へコピー
	f_draw_initializing_tiles >f_draw_initializing_tiles.o
	fsz=$(to16 $(stat -c '%s' f_draw_initializing_tiles.o))
	a_copy_rom_to_ram=$(four_digits $(calc16 "${a_draw_initializing_tiles}+${fsz}"))
	echo -e "a_copy_rom_to_ram=$a_copy_rom_to_ram" >>$map_file
	f_copy_rom_to_ram

	# 「しよきかかんりよう!」の文字列を描画
	f_copy_rom_to_ram >f_copy_rom_to_ram.o
	fsz=$(to16 $(stat -c '%s' f_copy_rom_to_ram.o))
	a_draw_initialized_tiles=$(four_digits $(calc16 "${a_copy_rom_to_ram}+${fsz}"))
	echo -e "a_draw_initialized_tiles=$a_draw_initialized_tiles" >>$map_file
	f_draw_initialized_tiles
}
# 変数設定のために空実行
funcs >/dev/null
rm -f $map_file

main() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	# 初期化処理
	(
		# アプリ用ボタンリリースフラグをクリア
		lr35902_clear_reg regA
		lr35902_copy_to_addr_from_regA $var_app_release_btn

		# 初期画面描画のエントリをTDQへ積む
		lr35902_call $a_draw_init_tiles

		# カートリッジRAM enable
		lr35902_set_reg regA $GB_MBC_RAM_EN_VAL
		lr35902_copy_to_addr_from_regA $GB_MBC_RAM_EN_ADDR

		# 初期化済みフラグをセット
		lr35902_copy_to_regA_from_addr $var_general_flgs
		lr35902_set_bitN_of_reg $CF_GFLG_BITNUM_INITED regA
		lr35902_copy_to_addr_from_regA $var_general_flgs

		# pop & return
		lr35902_pop_reg regHL
		lr35902_pop_reg regDE
		lr35902_pop_reg regBC
		lr35902_pop_reg regAF
		lr35902_return
	) >main.1.o

	# フラグ変数の初期化済みフラグチェック
	lr35902_copy_to_regA_from_addr $var_general_flgs
	lr35902_test_bitN_of_reg $CF_GFLG_BITNUM_INITED regA

	# フラグがセットされていたら(初期化済みだったら)、
	# 初期化処理をスキップ
	local sz_1=$(stat -c '%s' main.1.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_1)
	cat main.1.o

	# 定常処理

	# アプリ用ボタンリリースフラグをregAへ取得
	lr35902_copy_to_regA_from_addr $var_app_release_btn

	# Aボタン(右クリック): 終了
	lr35902_test_bitN_of_reg $GBOS_A_KEY_BITNUM regA
	(
		# Aボタン(右クリック)のリリースがあった場合

		# カートリッジRAM disable
		lr35902_clear_reg regA
		lr35902_copy_to_addr_from_regA $GB_MBC_RAM_EN_ADDR

		# run_exe_cycを終了させる
		lr35902_call $a_exit_exe

		# pop & return
		lr35902_pop_reg regHL
		lr35902_pop_reg regDE
		lr35902_pop_reg regBC
		lr35902_pop_reg regAF
		lr35902_return
	) >main.2.o
	local sz_2=$(stat -c '%s' main.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	cat main.2.o

	# スタートボタン: 初期化実施
	lr35902_test_bitN_of_reg $GBOS_START_KEY_BITNUM regA
	(
		# スタートボタンのリリースがあった場合

		# ボタンリリース状態をregCへ取っておく
		lr35902_copy_to_from regC regA

		# カートリッジROMのバンクを
		# RAM0オリジナルデータのバンクへ切り替える
		lr35902_set_reg regA $CF_CARTROM_BANK_NUM
		lr35902_copy_to_addr_from_regA $GB_MBC_ROM_BANK_ADDR

		# 0x4000(ROM)〜8KB分を、0xa000(RAM)〜へコピー
		lr35902_call $a_copy_rom_to_ram

		# カートリッジROMのバンクを
		# ファイルシステムのバンクへ戻す
		lr35902_set_reg regA $GBOS_CARTROM_BANK_SYS
		lr35902_copy_to_addr_from_regA $GB_MBC_ROM_BANK_ADDR

		# 「しよきかかんりよう!」の文字列を描画
		lr35902_call $a_draw_initialized_tiles

		# アプリ用ボタンリリースフラグのスタートボタンをクリア
		lr35902_copy_to_from regA regC
		lr35902_res_bitN_of_reg $GBOS_START_KEY_BITNUM regA
		lr35902_copy_to_addr_from_regA $var_app_release_btn
	) >main.3.o
	local sz_3=$(stat -c '%s' main.3.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_3)
	cat main.3.o

	# pop & return
	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

make_bin() {
	local file_sz
	local area_sz
	local pad_sz

	# メインプログラム領域
	main >main.o
	cat main.o
	file_sz=$(stat -c '%s' main.o)
	area_sz=$(echo "ibase=16;$APP_MAIN_SZ" | bc)
	pad_sz=$((area_sz - file_sz))
	dd if=/dev/zero bs=1 count=$pad_sz

	# 変数領域
	vars >vars.o
	cat vars.o
	file_sz=$(stat -c '%s' vars.o)
	area_sz=$(echo "ibase=16;$APP_VARS_SZ" | bc)
	pad_sz=$((area_sz - file_sz))
	dd if=/dev/zero bs=1 count=$pad_sz

	# 関数領域
	funcs >funcs.o
	cat funcs.o
	file_sz=$(stat -c '%s' funcs.o)
	area_sz=$(echo "ibase=16;$APP_FUNCS_SZ" | bc)
	pad_sz=$((area_sz - file_sz))
	dd if=/dev/zero bs=1 count=$pad_sz
}

make_bin

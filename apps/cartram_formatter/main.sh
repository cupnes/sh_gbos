#!/bin/bash

set -uex
# set -ue

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

funcs() {
	local fsz

	# 初期配置のタイルをtdqへ積む
	a_draw_init_tiles=$APP_FUNCS_BASE
	echo -e "a_draw_init_tiles=$a_draw_init_tiles" >>$map_file
	f_draw_init_tiles
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

		# カートリッジROMのバンクを
		# ファイルシステムのバンクへ戻す
		lr35902_set_reg regA $GBOS_CARTROM_BANK_SYS
		lr35902_copy_to_addr_from_regA $GB_MBC_ROM_BANK_ADDR

		# DAS: run_exeをクリア
		lr35902_copy_to_regA_from_addr $var_draw_act_stat
		lr35902_res_bitN_of_reg $GBOS_DA_BITNUM_RUN_EXE regA
		lr35902_copy_to_addr_from_regA $var_draw_act_stat

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

		# カートリッジROMのバンクを
		# RAM0オリジナルデータのバンクへ切り替える
		lr35902_set_reg regA $CF_CARTROM_BANK_NUM
		lr35902_copy_to_addr_from_regA $GB_MBC_ROM_BANK_ADDR
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

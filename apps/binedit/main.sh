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
APP_MAIN_SZ=0500
APP_VARS_SZ=0200
APP_FUNCS_SZ=0500
APP_MAIN_BASE=$GB_WRAM1_BASE
APP_VARS_BASE=$(calc16 "$APP_MAIN_BASE+$APP_MAIN_SZ")
APP_FUNCS_BASE=$(calc16 "$APP_VARS_BASE+$APP_VARS_SZ")

BE_OAM_BASE_CSL=$(calc16 "$GB_OAM_BASE+$GB_OAM_SZ")
BE_OAM_CSL_Y_ADDR=$(calc16 "$BE_OAM_BASE_CSL")
BE_OAM_CSL_X_ADDR=$(calc16 "$BE_OAM_BASE_CSL+1")
BE_OAM_BASE_WIN_TITLE=$(calc16 "$GB_OAM_BASE+($GB_OAM_SZ*2)")

BE_OBJX_DAREA_BASE=40
BE_OBJX_DAREA_LAST=90
BE_OBJY_DAREA_BASE=30	# 0行目のobjY座標
BE_OBJY_DAREA_LAST=88	# 12行目のobjY座標

# 押下判定のしきい値
BE_KEY_PRESS_TH=05

# カーソル移動補助変数
BE_CSL_ATTR_BITNUM_IS_UPPER=2

map_file=map.sh
rm -f $map_file

# RAM
RAM_BKUP_NEXT_ADDR_TH=a000
RAM_BKUP_NEXT_ADDR_BH=a001

vars() {
	# 汎用フラグ変数
	var_general_flgs=$APP_VARS_BASE
	echo -e "var_general_flgs=$var_general_flgs" >>$map_file
	echo -en '\x00'	# 全て0

	# 対象ファイルサイズ
	## 下位8ビット
	var_file_size_bh=$(calc16 "$var_general_flgs+1")
	echo -e "var_file_size_bh=$var_file_size_bh" >>$map_file
	echo -en '\x00'
	## 上位8ビット
	var_file_size_th=$(calc16 "$var_file_size_bh+1")
	echo -e "var_file_size_th=$var_file_size_th" >>$map_file
	echo -en '\x00'

	# 表示位置管理用カウンタ
	# - 未表示である残バイト数
	# - ファイルサイズが1画面分(4バイト * 12行 = 48バイト以下)の場合:
	#   1画面表示した時点でこのカウンタは0になる
	# - ファイルサイズが2画面分以上の場合:
	#   例えばファイルサイズが49であるとすると
	#   1画面目を表示した時点ではこのカウンタは残り1
	#   次のページへ進み、2画面目で、残る1バイトを表示して
	#   このカウンタは0になる
	#   また、1画面目へ戻ると、このカウンタは1に戻る
	## 下位8ビット
	var_remain_bytes_bh=$(calc16 "$var_file_size_th+1")
	echo -e "var_remain_bytes_bh=$var_remain_bytes_bh" >>$map_file
	echo -en '\x00'
	## 上位8ビット
	var_remain_bytes_th=$(calc16 "$var_remain_bytes_bh+1")
	echo -e "var_remain_bytes_th=$var_remain_bytes_th" >>$map_file
	echo -en '\x00'

	# □カーソル座標(左上原点)
	# TODO 今や初期化のときしか使ってない
	#      初期化のときも使わないようにして消す
	## Y座標
	var_csl_y=$(calc16 "$var_remain_bytes_th+1")
	echo -e "var_csl_y=$var_csl_y" >>$map_file
	echo -en '\x20'
	## X座標
	var_csl_x=$(calc16 "$var_csl_y+1")
	echo -e "var_csl_x=$var_csl_x" >>$map_file
	echo -en '\x38'

	# 方向キー入力判定用
	## 前回の入力
	var_prev_dir_input=$(calc16 "$var_csl_x+1")
	echo -e "var_prev_dir_input=$var_prev_dir_input" >>$map_file
	echo -en '\x00'
	## 連続押下カウンタ
	var_press_counter=$(calc16 "$var_prev_dir_input+1")
	echo -e "var_press_counter=$var_press_counter" >>$map_file
	echo -en '\x00'

	# カーソル位置のデータアドレス
	## 下位8ビット
	var_csl_dadr_bh=$(calc16 "$var_press_counter+1")
	echo -e "var_csl_dadr_bh=$var_csl_dadr_bh" >>$map_file
	echo -en '\x00'
	## 上位8ビット
	var_csl_dadr_th=$(calc16 "$var_csl_dadr_bh+1")
	echo -e "var_csl_dadr_th=$var_csl_dadr_th" >>$map_file
	echo -en '\x00'

	# カーソル位置のタイルアドレス
	## 下位8ビット
	var_csl_tadr_bh=$(calc16 "$var_csl_dadr_th+1")
	echo -e "var_csl_tadr_bh=$var_csl_tadr_bh" >>$map_file
	echo -en '\x87'
	## 上位8ビット
	var_csl_tadr_th=$(calc16 "$var_csl_tadr_bh+1")
	echo -e "var_csl_tadr_th=$var_csl_tadr_th" >>$map_file
	echo -en '\x98'

	# カーソル移動の補助変数
	## b2   : 上位4ビット(=1)/下位4ビット(=0)
	## b1-b0: 1行の何バイト目か(0〜3)
	var_csl_attr=$(calc16 "$var_csl_tadr_th+1")
	echo -e "var_csl_attr=$var_csl_attr" >>$map_file
	echo -en '\x04'
}
# 変数設定のために空実行
vars >/dev/null
rm -f $map_file

# 初期配置のタイルをtdqへ積む
# ※ この関数内で使うレジスタは事前のpushと事後のpopをしていない
f_draw_init_tiles() {
	# オブジェクト
	## マウスカーソルを非表示にする
	lr35902_clear_reg regB
	lr35902_set_reg regDE $GBOS_OAM_BASE_CSL
	lr35902_call $a_enq_tdq

	## □カーソルの設定
	### Y座標
	lr35902_set_reg regDE $BE_OAM_BASE_CSL
	lr35902_copy_to_regA_from_addr $var_csl_y
	lr35902_add_to_regA 10
	lr35902_copy_to_from regB regA
	lr35902_call $a_enq_tdq
	### X座標
	lr35902_inc regE
	lr35902_copy_to_regA_from_addr $var_csl_x
	lr35902_add_to_regA 08
	lr35902_copy_to_from regB regA
	lr35902_call $a_enq_tdq
	### タイル番号
	lr35902_inc regE
	lr35902_set_reg regB 06
	lr35902_call $a_enq_tdq
	### 属性
	lr35902_inc regE
	lr35902_clear_reg regB
	lr35902_call $a_enq_tdq

	# ## ウィンドウタイトル
	# ### 1文字目「ふ」
	# #### Y座標
	# lr35902_set_reg regDE $BE_OAM_BASE_WIN_TITLE
	# lr35902_set_reg regB 18
	# lr35902_call $a_enq_tdq
	# #### X座標
	# lr35902_inc regE
	# lr35902_call $a_enq_tdq
	# #### タイル番号
	# lr35902_inc regE
	# lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_FU
	# lr35902_call $a_enq_tdq
	# #### 属性
	# lr35902_inc regE
	# lr35902_clear_reg regB
	# lr35902_call $a_enq_tdq
	# ### 2文字目「あ」
	# #### Y座標
	# lr35902_inc regE
	# lr35902_set_reg regB 18
	# lr35902_call $a_enq_tdq
	# #### X座標
	# lr35902_inc regE
	# lr35902_set_reg regB 20
	# lr35902_call $a_enq_tdq
	# #### タイル番号
	# lr35902_inc regE
	# lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_A
	# lr35902_call $a_enq_tdq
	# #### 属性
	# lr35902_inc regE
	# lr35902_clear_reg regB
	# lr35902_call $a_enq_tdq
	# ### 3文字目「い」
	# #### Y座標
	# lr35902_inc regE
	# lr35902_set_reg regB 18
	# lr35902_call $a_enq_tdq
	# #### X座標
	# lr35902_inc regE
	# lr35902_set_reg regB 28
	# lr35902_call $a_enq_tdq
	# #### タイル番号
	# lr35902_inc regE
	# lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_I
	# lr35902_call $a_enq_tdq
	# #### 属性
	# lr35902_inc regE
	# lr35902_clear_reg regB
	# lr35902_call $a_enq_tdq
	# ### 4文字目「る」
	# #### Y座標
	# lr35902_inc regE
	# lr35902_set_reg regB 18
	# lr35902_call $a_enq_tdq
	# #### X座標
	# lr35902_inc regE
	# lr35902_set_reg regB 30
	# lr35902_call $a_enq_tdq
	# #### タイル番号
	# lr35902_inc regE
	# lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_RU
	# lr35902_call $a_enq_tdq
	# #### 属性
	# lr35902_inc regE
	# lr35902_clear_reg regB
	# lr35902_call $a_enq_tdq

	# メモリダンプ部
	## 「あ」
	lr35902_set_reg regDE 9862
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_A
	lr35902_call $a_enq_tdq
	## 「と」
	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_TO
	lr35902_call $a_enq_tdq
	## 「゛」
	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_DAKUTEN
	lr35902_call $a_enq_tdq
	## 「れ」
	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_RE
	lr35902_call $a_enq_tdq
	## 「す」
	lr35902_inc regE
	lr35902_set_reg regB $GBOS_TILE_NUM_HIRA_SU
	lr35902_call $a_enq_tdq

	## 「0」
	lr35902_set_reg regE 68
	lr35902_set_reg regB $(get_num_tile_num 00)
	lr35902_call $a_enq_tdq
	## 「1」
	lr35902_set_reg regE 6b
	lr35902_set_reg regB $(get_num_tile_num 01)
	lr35902_call $a_enq_tdq
	## 「2」
	lr35902_set_reg regE 6e
	lr35902_set_reg regB $(get_num_tile_num 02)
	lr35902_call $a_enq_tdq
	## 「3」
	lr35902_set_reg regE 71
	lr35902_set_reg regB $(get_num_tile_num 03)
	lr35902_call $a_enq_tdq

	# return
	lr35902_return
}

# 指定したアドレスから最大4バイトダンプ
# データが4バイトに満たない場合、EOFを返す
# in : regHL - ダンプ開始アドレス
#    : regDE - 描画先アドレス
# out: regHL - ダンプしたバイト数分だけインクリメントされて返る
#    : regDE - 描画した最終アドレスが返る
#    : regA  - ダンプしたバイト数([0:4])
# ※ regEだけインクリメントして1行分を書いていく実装
#    (regEが繰り上がる事は想定していない)
f_dump_addr_and_data_4bytes() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC

	# アドレスをダンプ
	## アドレス[15:12]
	lr35902_copy_to_from regA regH
	lr35902_swap_nibbles regA
	lr35902_call $a_byte_to_tile
	lr35902_call $a_enq_tdq
	## アドレス[11:8]
	lr35902_copy_to_from regA regH
	lr35902_call $a_byte_to_tile
	lr35902_inc regE
	lr35902_call $a_enq_tdq
	## アドレス[7:4]
	lr35902_copy_to_from regA regL
	lr35902_swap_nibbles regA
	lr35902_call $a_byte_to_tile
	lr35902_inc regE
	lr35902_call $a_enq_tdq
	## アドレス[3:0]
	lr35902_copy_to_from regA regL
	lr35902_call $a_byte_to_tile
	lr35902_inc regE
	lr35902_call $a_enq_tdq

	## 表示位置管理用カウンタを確認
	lr35902_push_reg regHL
	lr35902_copy_to_regA_from_addr $var_remain_bytes_bh
	lr35902_copy_to_from regL regA
	lr35902_copy_to_regA_from_addr $var_remain_bytes_th
	lr35902_copy_to_from regH regA
	lr35902_clear_reg regA
	lr35902_or_to_regA regL
	lr35902_or_to_regA regH
	(
		# カウンタが0の場合

		# pop & return
		lr35902_pop_reg regHL
		lr35902_pop_reg regBC
		lr35902_pop_reg regAF
		## ダンプしたバイト数は0を返す
		lr35902_clear_reg regA
		lr35902_return
	) >f_dump_addr_and_data_4bytes.0.o
	local sz_0=$(stat -c '%s' f_dump_addr_and_data_4bytes.0.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_0)
	cat f_dump_addr_and_data_4bytes.0.o
	lr35902_pop_reg regHL

	# 空白の分1タイル飛ばす
	lr35902_inc regE

	# データをダンプ
	## 1バイト目
	lr35902_copyinc_to_regA_from_ptrHL
	lr35902_copy_to_from regC regA
	### [7:4]
	lr35902_swap_nibbles regA
	lr35902_call $a_byte_to_tile
	lr35902_inc regE
	lr35902_call $a_enq_tdq
	### [3:0]
	lr35902_copy_to_from regA regC
	lr35902_call $a_byte_to_tile
	lr35902_inc regE
	lr35902_call $a_enq_tdq

	## 表示位置管理用カウンタをデクリメント
	lr35902_push_reg regHL
	lr35902_copy_to_regA_from_addr $var_remain_bytes_bh
	lr35902_copy_to_from regL regA
	lr35902_copy_to_regA_from_addr $var_remain_bytes_th
	lr35902_copy_to_from regH regA
	lr35902_dec regHL
	lr35902_copy_to_from regA regL
	lr35902_copy_to_addr_from_regA $var_remain_bytes_bh
	lr35902_copy_to_from regA regH
	lr35902_copy_to_addr_from_regA $var_remain_bytes_th
	lr35902_clear_reg regA
	lr35902_or_to_regA regL
	lr35902_or_to_regA regH
	(
		# カウンタが0になった場合

		# pop & return
		lr35902_pop_reg regHL
		lr35902_pop_reg regBC
		lr35902_pop_reg regAF
		## ダンプしたバイト数は1を返す
		lr35902_set_reg regA 01
		lr35902_return
	) >f_dump_addr_and_data_4bytes.1.o
	local sz_1=$(stat -c '%s' f_dump_addr_and_data_4bytes.1.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_1)
	cat f_dump_addr_and_data_4bytes.1.o
	lr35902_pop_reg regHL

	## 空白の分1タイル飛ばす
	lr35902_inc regE

	## 2バイト目
	lr35902_copyinc_to_regA_from_ptrHL
	lr35902_copy_to_from regC regA
	### [7:4]
	lr35902_swap_nibbles regA
	lr35902_call $a_byte_to_tile
	lr35902_inc regE
	lr35902_call $a_enq_tdq
	### [3:0]
	lr35902_copy_to_from regA regC
	lr35902_call $a_byte_to_tile
	lr35902_inc regE
	lr35902_call $a_enq_tdq

	## 表示位置管理用カウンタをデクリメント
	lr35902_push_reg regHL
	lr35902_copy_to_regA_from_addr $var_remain_bytes_bh
	lr35902_copy_to_from regL regA
	lr35902_copy_to_regA_from_addr $var_remain_bytes_th
	lr35902_copy_to_from regH regA
	lr35902_dec regHL
	lr35902_copy_to_from regA regL
	lr35902_copy_to_addr_from_regA $var_remain_bytes_bh
	lr35902_copy_to_from regA regH
	lr35902_copy_to_addr_from_regA $var_remain_bytes_th
	lr35902_clear_reg regA
	lr35902_or_to_regA regL
	lr35902_or_to_regA regH
	(
		# カウンタが0になった場合

		# pop & return
		lr35902_pop_reg regHL
		lr35902_pop_reg regBC
		lr35902_pop_reg regAF
		## ダンプしたバイト数は2を返す
		lr35902_set_reg regA 02
		lr35902_return
	) >f_dump_addr_and_data_4bytes.2.o
	local sz_2=$(stat -c '%s' f_dump_addr_and_data_4bytes.2.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_2)
	cat f_dump_addr_and_data_4bytes.2.o
	lr35902_pop_reg regHL

	## 空白の分1タイル飛ばす
	lr35902_inc regE

	## 3バイト目
	lr35902_copyinc_to_regA_from_ptrHL
	lr35902_copy_to_from regC regA
	### [7:4]
	lr35902_swap_nibbles regA
	lr35902_call $a_byte_to_tile
	lr35902_inc regE
	lr35902_call $a_enq_tdq
	### [3:0]
	lr35902_copy_to_from regA regC
	lr35902_call $a_byte_to_tile
	lr35902_inc regE
	lr35902_call $a_enq_tdq

	## 表示位置管理用カウンタをデクリメント
	lr35902_push_reg regHL
	lr35902_copy_to_regA_from_addr $var_remain_bytes_bh
	lr35902_copy_to_from regL regA
	lr35902_copy_to_regA_from_addr $var_remain_bytes_th
	lr35902_copy_to_from regH regA
	lr35902_dec regHL
	lr35902_copy_to_from regA regL
	lr35902_copy_to_addr_from_regA $var_remain_bytes_bh
	lr35902_copy_to_from regA regH
	lr35902_copy_to_addr_from_regA $var_remain_bytes_th
	lr35902_clear_reg regA
	lr35902_or_to_regA regL
	lr35902_or_to_regA regH
	(
		# カウンタが0になった場合

		# pop & return
		lr35902_pop_reg regHL
		lr35902_pop_reg regBC
		lr35902_pop_reg regAF
		## ダンプしたバイト数は3を返す
		lr35902_set_reg regA 03
		lr35902_return
	) >f_dump_addr_and_data_4bytes.3.o
	local sz_3=$(stat -c '%s' f_dump_addr_and_data_4bytes.3.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_3)
	cat f_dump_addr_and_data_4bytes.3.o
	lr35902_pop_reg regHL

	## 空白の分1タイル飛ばす
	lr35902_inc regE

	## 4バイト目
	lr35902_copyinc_to_regA_from_ptrHL
	lr35902_copy_to_from regC regA
	### [7:4]
	lr35902_swap_nibbles regA
	lr35902_call $a_byte_to_tile
	lr35902_inc regE
	lr35902_call $a_enq_tdq
	### [3:0]
	lr35902_copy_to_from regA regC
	lr35902_call $a_byte_to_tile
	lr35902_inc regE
	lr35902_call $a_enq_tdq

	## 表示位置管理用カウンタをデクリメント
	lr35902_push_reg regHL
	lr35902_copy_to_regA_from_addr $var_remain_bytes_bh
	lr35902_copy_to_from regL regA
	lr35902_copy_to_regA_from_addr $var_remain_bytes_th
	lr35902_copy_to_from regH regA
	lr35902_dec regHL
	lr35902_copy_to_from regA regL
	lr35902_copy_to_addr_from_regA $var_remain_bytes_bh
	lr35902_copy_to_from regA regH
	lr35902_copy_to_addr_from_regA $var_remain_bytes_th
	lr35902_pop_reg regHL

	# pop & return
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	## ダンプしたバイト数は4を返す
	lr35902_set_reg regA 04
	lr35902_return
}

# (主にobjを)元に戻すエントリをtdqへ積む
f_draw_restore_tiles() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE

	# オブジェクト
	## □カーソルを非表示にする
	lr35902_clear_reg regB
	lr35902_set_reg regDE $BE_OAM_BASE_CSL
	lr35902_call $a_enq_tdq

	## TODO マウスカーソルを表示する

	## TODO ウィンドウタイトルを非表示にする

	# pop & return
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

# カーソルを一つ前へ進める関数
# カーソル位置下位側3バイト目の処理
# ※ 使用するレジスタのpush/popはしていない
f_forward_cursor_bh_3() {
	# 現在12行目か否か
	## 現在のカーソルのobjY座標取得
	lr35902_copy_to_regA_from_addr $BE_OAM_CSL_Y_ADDR
	## 12行目のobjY座標値と比較
	lr35902_compare_regA_and $BE_OBJY_DAREA_LAST
	(
		# 12行目未満の場合

		# □カーソルOAM更新
		## 1タイル分増やす
		lr35902_add_to_regA 08
		## □カーソルのOAMのX座標を更新するエントリをtdqへ積む
		lr35902_copy_to_from regB regA
		lr35902_set_reg regDE $BE_OAM_CSL_Y_ADDR
		lr35902_call $a_enq_tdq
		## 現在のカーソルのobjX座標取得
		lr35902_copy_to_regA_from_addr $BE_OAM_CSL_X_ADDR
		## 行頭のobjアドレスを設定
		lr35902_set_reg regA $BE_OBJX_DAREA_BASE
		## □カーソルのOAMのX座標を更新するエントリをtdqへ積む
		lr35902_copy_to_from regB regA
		lr35902_set_reg regDE $BE_OAM_CSL_X_ADDR
		lr35902_call $a_enq_tdq

		# カーソル位置のデータアドレス変数更新
		## 変数をregDEへ取得
		lr35902_copy_to_regA_from_addr $var_csl_dadr_bh
		lr35902_copy_to_from regE regA
		lr35902_copy_to_regA_from_addr $var_csl_dadr_th
		lr35902_copy_to_from regD regA
		## regDEをインクリメント
		lr35902_inc regDE
		## regDEを変数へ書き戻す
		lr35902_copy_to_from regA regE
		lr35902_copy_to_addr_from_regA $var_csl_dadr_bh
		lr35902_copy_to_from regA regD
		lr35902_copy_to_addr_from_regA $var_csl_dadr_th

		# カーソル位置のタイルアドレス変数更新
		## 変数をregDEへ取得
		lr35902_copy_to_regA_from_addr $var_csl_tadr_bh
		lr35902_copy_to_from regE regA
		lr35902_copy_to_regA_from_addr $var_csl_tadr_th
		lr35902_copy_to_from regD regA
		## regDEを0x16増やす
		lr35902_push_reg regHL
		lr35902_set_reg regHL 0016
		lr35902_add_to_regHL regDE
		lr35902_copy_to_from regE regL
		lr35902_copy_to_from regD regH
		lr35902_pop_reg regHL
		## regDEを変数へ書き戻す
		lr35902_copy_to_from regA regE
		lr35902_copy_to_addr_from_regA $var_csl_tadr_bh
		lr35902_copy_to_from regA regD
		lr35902_copy_to_addr_from_regA $var_csl_tadr_th

		# カーソル移動の補助変数更新
		## b2に1を、b0-b1に0を設定(0x04)
		lr35902_set_reg regA 04
		lr35902_copy_to_addr_from_regA $var_csl_attr
	) >f_forward_cursor_bh_3.1.o
	local sz_1=$(stat -c '%s' f_forward_cursor_bh_3.1.o)
	## 現在12行目以上のカーソル位置だったら処理を飛ばす
	lr35902_rel_jump_with_cond NC $(two_digits_d $sz_1)
	cat f_forward_cursor_bh_3.1.o

	# return
	lr35902_return
}

# カーソルを一つ前へ進める
f_forward_cursor() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE

	# カーソル移動の補助変数をregCへ取得
	lr35902_copy_to_regA_from_addr $var_csl_attr
	lr35902_copy_to_from regC regA

	# 現在のカーソル位置は上位側か下位側か
	lr35902_test_bitN_of_reg $BE_CSL_ATTR_BITNUM_IS_UPPER regC
	(
		# 下位側

		# 3バイト目か否か?
		lr35902_compare_regA_and 03
		(
			# regA < 3 (0〜2バイト目)

			# □カーソルOAM更新
			## 現在のカーソルのobjX座標取得
			lr35902_copy_to_regA_from_addr $BE_OAM_CSL_X_ADDR
			## 2タイル分進める
			lr35902_add_to_regA 10
			## □カーソルのOAMのX座標を更新するエントリをtdqへ積む
			lr35902_copy_to_from regB regA
			lr35902_set_reg regDE $BE_OAM_CSL_X_ADDR
			lr35902_call $a_enq_tdq

			# カーソル位置のデータアドレス変数更新
			## 変数をregDEへ取得
			lr35902_copy_to_regA_from_addr $var_csl_dadr_bh
			lr35902_copy_to_from regE regA
			lr35902_copy_to_regA_from_addr $var_csl_dadr_th
			lr35902_copy_to_from regD regA
			## regDEをインクリメント
			lr35902_inc regDE
			## regDEを変数へ書き戻す
			lr35902_copy_to_from regA regE
			lr35902_copy_to_addr_from_regA $var_csl_dadr_bh
			lr35902_copy_to_from regA regD
			lr35902_copy_to_addr_from_regA $var_csl_dadr_th

			# カーソル位置のタイルアドレス変数更新
			## 変数をregDEへ取得
			lr35902_copy_to_regA_from_addr $var_csl_tadr_bh
			lr35902_copy_to_from regE regA
			lr35902_copy_to_regA_from_addr $var_csl_tadr_th
			lr35902_copy_to_from regD regA
			## regDEを2増やす
			lr35902_inc regDE
			lr35902_inc regDE
			## regDEを変数へ書き戻す
			lr35902_copy_to_from regA regE
			lr35902_copy_to_addr_from_regA $var_csl_tadr_bh
			lr35902_copy_to_from regA regD
			lr35902_copy_to_addr_from_regA $var_csl_tadr_th

			# カーソル移動の補助変数更新
			## b2(is_upper)は0なので、そのままインクリメント
			lr35902_inc regC
			## b2(is_upper)をセット
			lr35902_set_bitN_of_reg $BE_CSL_ATTR_BITNUM_IS_UPPER regC
			## 変数へ書き戻す
			lr35902_copy_to_from regA regC
			lr35902_copy_to_addr_from_regA $var_csl_attr
		) >f_forward_cursor.3.o
		(
			# regA >= 3 (3バイト目)

			# □カーソルOAM更新
			# カーソル位置のデータアドレス変数更新
			# カーソル位置のタイルアドレス変数更新
			# カーソル移動の補助変数更新
			lr35902_call $a_forward_cursor_bh_3

			# regA < 3 の場合の処理を飛ばす
			local sz_3=$(stat -c '%s' f_forward_cursor.3.o)
			lr35902_rel_jump $(two_digits_d $sz_3)
		) >f_forward_cursor.4.o
		local sz_4=$(stat -c '%s' f_forward_cursor.4.o)
		lr35902_rel_jump_with_cond C $(two_digits_d $sz_4)
		cat f_forward_cursor.4.o	# regA >= 3
		cat f_forward_cursor.3.o	# regA < 3
	) >f_forward_cursor.1.o
	(
		# 上位側

		# □カーソルOAM更新
		## 現在のカーソルのobjX座標取得
		lr35902_copy_to_regA_from_addr $BE_OAM_CSL_X_ADDR
		## 1タイル分進める
		lr35902_add_to_regA 08
		## □カーソルのOAMのX座標を更新するエントリをtdqへ積む
		lr35902_copy_to_from regB regA
		lr35902_set_reg regDE $BE_OAM_CSL_X_ADDR
		lr35902_call $a_enq_tdq

		# カーソル位置のデータアドレス変数更新
		## 何もしない

		# カーソル位置のタイルアドレス変数更新
		## 変数をregDEへ取得
		lr35902_copy_to_regA_from_addr $var_csl_tadr_bh
		lr35902_copy_to_from regE regA
		lr35902_copy_to_regA_from_addr $var_csl_tadr_th
		lr35902_copy_to_from regD regA
		## regDEを1増やす
		lr35902_inc regDE
		## regDEを変数へ書き戻す
		lr35902_copy_to_from regA regE
		lr35902_copy_to_addr_from_regA $var_csl_tadr_bh
		lr35902_copy_to_from regA regD
		lr35902_copy_to_addr_from_regA $var_csl_tadr_th

		# カーソル移動の補助変数更新
		## b2(is_upper)をリセット
		lr35902_res_bitN_of_reg $BE_CSL_ATTR_BITNUM_IS_UPPER regC
		## 変数へ書き戻す
		lr35902_copy_to_from regA regC
		lr35902_copy_to_addr_from_regA $var_csl_attr

		# 下位側の処理を飛ばす
		local sz_1=$(stat -c '%s' f_forward_cursor.1.o)
		lr35902_rel_jump $(two_digits_d $sz_1)
	) >f_forward_cursor.2.o
	local sz_2=$(stat -c '%s' f_forward_cursor.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	cat f_forward_cursor.2.o	# b2(is_upper) == 1 (上位側)
	cat f_forward_cursor.1.o	# b2(is_upper) == 0 (下位側)

	# pop & return
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

# カーソルを一つ後ろへ進める関数
# カーソル位置上位側0バイト目の処理
# ※ 使用するレジスタのpush/popはしていない
f_backward_cursor_th_0() {
	# 現在1行目か否か
	## 現在のカーソルのobjY座標取得
	lr35902_copy_to_regA_from_addr $BE_OAM_CSL_Y_ADDR
	## 1行目のobjY座標値と比較
	lr35902_compare_regA_and $BE_OBJY_DAREA_BASE
	(
		# 1行目ではない場合

		# □カーソルOAM更新
		## 1タイル分減らす
		lr35902_sub_to_regA 08
		## □カーソルのOAMのX座標を更新するエントリをtdqへ積む
		lr35902_copy_to_from regB regA
		lr35902_set_reg regDE $BE_OAM_CSL_Y_ADDR
		lr35902_call $a_enq_tdq
		## 現在のカーソルのobjX座標取得
		lr35902_copy_to_regA_from_addr $BE_OAM_CSL_X_ADDR
		## 行末のobjアドレスを設定
		lr35902_set_reg regA $BE_OBJX_DAREA_LAST
		## □カーソルのOAMのX座標を更新するエントリをtdqへ積む
		lr35902_copy_to_from regB regA
		lr35902_set_reg regDE $BE_OAM_CSL_X_ADDR
		lr35902_call $a_enq_tdq

		# カーソル位置のデータアドレス変数更新
		## 変数をregDEへ取得
		lr35902_copy_to_regA_from_addr $var_csl_dadr_bh
		lr35902_copy_to_from regE regA
		lr35902_copy_to_regA_from_addr $var_csl_dadr_th
		lr35902_copy_to_from regD regA
		## regDEをデクリメント
		lr35902_dec regDE
		## regDEを変数へ書き戻す
		lr35902_copy_to_from regA regE
		lr35902_copy_to_addr_from_regA $var_csl_dadr_bh
		lr35902_copy_to_from regA regD
		lr35902_copy_to_addr_from_regA $var_csl_dadr_th

		# カーソル位置のタイルアドレス変数更新
		## 変数をregDEへ取得
		lr35902_copy_to_regA_from_addr $var_csl_tadr_bh
		lr35902_copy_to_from regE regA
		lr35902_copy_to_regA_from_addr $var_csl_tadr_th
		lr35902_copy_to_from regD regA
		## regDEを0x16減らす
		## 0x0016の2の補数0xffeaを足す
		lr35902_push_reg regHL
		lr35902_set_reg regHL ffea
		lr35902_add_to_regHL regDE
		lr35902_copy_to_from regE regL
		lr35902_copy_to_from regD regH
		lr35902_pop_reg regHL
		## regDEを変数へ書き戻す
		lr35902_copy_to_from regA regE
		lr35902_copy_to_addr_from_regA $var_csl_tadr_bh
		lr35902_copy_to_from regA regD
		lr35902_copy_to_addr_from_regA $var_csl_tadr_th

		# カーソル移動の補助変数更新
		## b2に0を、b0-b1に3を設定(0x03)
		lr35902_set_reg regA 03
		lr35902_copy_to_addr_from_regA $var_csl_attr
	) >f_backward_cursor_th_0.1.o
	local sz_1=$(stat -c '%s' f_backward_cursor_th_0.1.o)
	## 現在1行目のカーソル位置だったら処理を飛ばす
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_1)
	cat f_backward_cursor_th_0.1.o

	# return
	lr35902_return
}

# カーソルを一つ後ろへ進める
f_backward_cursor() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE

	# カーソル移動の補助変数をregCへ取得
	lr35902_copy_to_regA_from_addr $var_csl_attr
	lr35902_copy_to_from regC regA

	# 現在のカーソル位置は上位側か下位側か
	lr35902_test_bitN_of_reg $BE_CSL_ATTR_BITNUM_IS_UPPER regC
	(
		# 下位側

		# □カーソルOAM更新
		## 現在のカーソルのobjX座標取得
		lr35902_copy_to_regA_from_addr $BE_OAM_CSL_X_ADDR
		## 1タイル分戻す
		lr35902_sub_to_regA 08
		## □カーソルのOAMのX座標を更新するエントリをtdqへ積む
		lr35902_copy_to_from regB regA
		lr35902_set_reg regDE $BE_OAM_CSL_X_ADDR
		lr35902_call $a_enq_tdq

		# カーソル位置のデータアドレス変数更新
		## 何もしない

		# カーソル位置のタイルアドレス変数更新
		## 変数をregDEへ取得
		lr35902_copy_to_regA_from_addr $var_csl_tadr_bh
		lr35902_copy_to_from regE regA
		lr35902_copy_to_regA_from_addr $var_csl_tadr_th
		lr35902_copy_to_from regD regA
		## regDEを1減らす
		lr35902_dec regDE
		## regDEを変数へ書き戻す
		lr35902_copy_to_from regA regE
		lr35902_copy_to_addr_from_regA $var_csl_tadr_bh
		lr35902_copy_to_from regA regD
		lr35902_copy_to_addr_from_regA $var_csl_tadr_th

		# カーソル移動の補助変数更新
		## b2(is_upper)をセット
		lr35902_set_bitN_of_reg $BE_CSL_ATTR_BITNUM_IS_UPPER regC
		## 変数へ書き戻す
		lr35902_copy_to_from regA regC
		lr35902_copy_to_addr_from_regA $var_csl_attr
	) >f_backward_cursor.1.o
	(
		# 上位側

		# 0バイト目か否か?
		lr35902_compare_regA_and 04
		## b2(is_upper)が立っているので
		## b1-b0が0b00の場合、0x04になる
		(
			# regA == 0x04 (0バイト目)

			# □カーソルOAM更新
			# カーソル位置のデータアドレス変数更新
			# カーソル位置のタイルアドレス変数更新
			# カーソル移動の補助変数更新
			lr35902_call $a_backward_cursor_th_0
		) >f_backward_cursor.3.o
		(
			# regA != 0x04 (1〜3バイト目)

			# □カーソルOAM更新
			## 現在のカーソルのobjX座標取得
			lr35902_copy_to_regA_from_addr $BE_OAM_CSL_X_ADDR
			## 2タイル分戻す
			lr35902_sub_to_regA 10
			## □カーソルのOAMのX座標を更新するエントリをtdqへ積む
			lr35902_copy_to_from regB regA
			lr35902_set_reg regDE $BE_OAM_CSL_X_ADDR
			lr35902_call $a_enq_tdq

			# カーソル位置のデータアドレス変数更新
			## 変数をregDEへ取得
			lr35902_copy_to_regA_from_addr $var_csl_dadr_bh
			lr35902_copy_to_from regE regA
			lr35902_copy_to_regA_from_addr $var_csl_dadr_th
			lr35902_copy_to_from regD regA
			## regDEをデクリメント
			lr35902_dec regDE
			## regDEを変数へ書き戻す
			lr35902_copy_to_from regA regE
			lr35902_copy_to_addr_from_regA $var_csl_dadr_bh
			lr35902_copy_to_from regA regD
			lr35902_copy_to_addr_from_regA $var_csl_dadr_th

			# カーソル位置のタイルアドレス変数更新
			## 変数をregDEへ取得
			lr35902_copy_to_regA_from_addr $var_csl_tadr_bh
			lr35902_copy_to_from regE regA
			lr35902_copy_to_regA_from_addr $var_csl_tadr_th
			lr35902_copy_to_from regD regA
			## regDEを2減らす
			lr35902_dec regDE
			lr35902_dec regDE
			## regDEを変数へ書き戻す
			lr35902_copy_to_from regA regE
			lr35902_copy_to_addr_from_regA $var_csl_tadr_bh
			lr35902_copy_to_from regA regD
			lr35902_copy_to_addr_from_regA $var_csl_tadr_th

			# カーソル移動の補助変数更新
			## b2(is_upper)をリセット
			lr35902_res_bitN_of_reg $BE_CSL_ATTR_BITNUM_IS_UPPER regC
			## b2(is_upper)は0なので、そのままデクリメント
			lr35902_dec regC
			## 変数へ書き戻す
			lr35902_copy_to_from regA regC
			lr35902_copy_to_addr_from_regA $var_csl_attr

			# regA == 0x04 (0バイト目) の処理を飛ばす
			local sz_3=$(stat -c '%s' f_backward_cursor.3.o)
			lr35902_rel_jump $(two_digits_d $sz_3)
		) >f_backward_cursor.4.o
		local sz_4=$(stat -c '%s' f_backward_cursor.4.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_4)
		cat f_backward_cursor.4.o	# regA != 0x04 (1〜3バイト目)
		cat f_backward_cursor.3.o	# regA == 0x04 (0バイト目)

		# 下位側の処理を飛ばす
		local sz_1=$(stat -c '%s' f_backward_cursor.1.o)
		lr35902_rel_jump $(two_digits_d $sz_1)
	) >f_backward_cursor.2.o
	local sz_2=$(stat -c '%s' f_backward_cursor.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	cat f_backward_cursor.2.o	# b2(is_upper) == 1 (上位側)
	cat f_backward_cursor.1.o	# b2(is_upper) == 0 (下位側)

	# pop & return
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

# カーソル位置の値をインクリメント
f_inc_cursor() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	# カーソル移動の補助変数をregCへ取得
	lr35902_copy_to_regA_from_addr $var_csl_attr
	lr35902_copy_to_from regC regA

	# 現在のカーソル位置は上位側か下位側か
	lr35902_test_bitN_of_reg $BE_CSL_ATTR_BITNUM_IS_UPPER regC
	(
		# 下位側

		# RAM上の値更新
		## カーソル位置の値取得
		lr35902_copy_to_regA_from_addr $var_csl_dadr_bh
		lr35902_copy_to_from regL regA
		lr35902_copy_to_regA_from_addr $var_csl_dadr_th
		lr35902_copy_to_from regH regA
		lr35902_copy_to_from regA ptrHL
		## regBには上位4ビットのみ設定
		lr35902_and_to_regA f0
		lr35902_copy_to_from regB regA
		## regAにはそのまま設定
		lr35902_copy_to_from regA ptrHL
		## regAをインクリメント
		lr35902_inc regA
		## regAの下位4ビットだけ抽出
		lr35902_and_to_regA 0f
		## regB(上位4ビット)と結合
		lr35902_or_to_regA regB
		## カーソル位置のRAMへ書き戻す
		lr35902_copy_to_from ptrHL regA

		# カーソル位置のタイル更新
		## regAの下位4ビットを抽出
		lr35902_and_to_regA 0f
		## 0x0a以上か否かに応じてタイル番号取得
		lr35902_compare_regA_and 0a
		(
			# regA < 0x0a

			# 番号タイルのベース番号を足し合わせる
			lr35902_add_to_regA $GBOS_TILE_NUM_NUM_BASE
		) >f_inc_cursor.3.o
		(
			# regA >= 0x0a

			# 0x0aを引く
			lr35902_sub_to_regA 0a

			# アルファベットタイルのベース番号を足し合わせる
			lr35902_add_to_regA $GBOS_TILE_NUM_ALPHA_BASE

			# regA < 0x0a の処理を飛ばす
			local sz_3=$(stat -c '%s' f_inc_cursor.3.o)
			lr35902_rel_jump $(two_digits_d $sz_3)
		) >f_inc_cursor.4.o
		local sz_4=$(stat -c '%s' f_inc_cursor.4.o)
		lr35902_rel_jump_with_cond C $(two_digits_d $sz_4)
		cat f_inc_cursor.4.o	# regA >= 0x0a の場合
		cat f_inc_cursor.3.o	# regA < 0x0a の場合
		## タイル番号をregBに設定
		lr35902_copy_to_from regB regA
		## カーソル位置のタイルアドレスをregDEに取得
		lr35902_copy_to_regA_from_addr $var_csl_tadr_bh
		lr35902_copy_to_from regE regA
		lr35902_copy_to_regA_from_addr $var_csl_tadr_th
		lr35902_copy_to_from regD regA
		## tdqに積む
		lr35902_call $a_enq_tdq
	) >f_inc_cursor.1.o
	(
		# 上位側

		# RAM上の値更新
		## カーソル位置の値取得
		lr35902_copy_to_regA_from_addr $var_csl_dadr_bh
		lr35902_copy_to_from regL regA
		lr35902_copy_to_regA_from_addr $var_csl_dadr_th
		lr35902_copy_to_from regH regA
		lr35902_copy_to_from regA ptrHL
		## regBに下位4ビットのみ設定
		lr35902_and_to_regA 0f
		lr35902_copy_to_from regB regA
		## regAにはそのまま設定
		lr35902_copy_to_from regA ptrHL
		## regAの上位4ビットを下位4ビットへ持ってくる
		lr35902_swap_nibbles regA
		## regAをインクリメント
		lr35902_inc regA
		## regAの下位4ビットを上位4ビットへ持ってくる
		lr35902_swap_nibbles regA
		## regAの上位4ビットのみ抽出
		lr35902_and_to_regA f0
		## regB(下位4ビット)と結合
		lr35902_or_to_regA regB
		## カーソル位置のRAMへ書き戻す
		lr35902_copy_to_from ptrHL regA

		# カーソル位置のタイル更新
		## regAの上位4ビットを下位4ビットへ持ってくる
		lr35902_swap_nibbles regA
		## regAの下位4ビットを抽出
		lr35902_and_to_regA 0f
		## 0x0a以上か否かに応じてタイル番号取得
		lr35902_compare_regA_and 0a
		(
			# regA < 0x0a

			# 番号タイルのベース番号を足し合わせる
			lr35902_add_to_regA $GBOS_TILE_NUM_NUM_BASE
		) >f_inc_cursor.5.o
		(
			# regA >= 0x0a

			# 0x0aを引く
			lr35902_sub_to_regA 0a

			# アルファベットタイルのベース番号を足し合わせる
			lr35902_add_to_regA $GBOS_TILE_NUM_ALPHA_BASE

			# regA < 0x0a の処理を飛ばす
			local sz_5=$(stat -c '%s' f_inc_cursor.5.o)
			lr35902_rel_jump $(two_digits_d $sz_5)
		) >f_inc_cursor.6.o
		local sz_6=$(stat -c '%s' f_inc_cursor.6.o)
		lr35902_rel_jump_with_cond C $(two_digits_d $sz_6)
		cat f_inc_cursor.6.o	# regA >= 0x0a の場合
		cat f_inc_cursor.5.o	# regA < 0x0a の場合
		## タイル番号をregBに設定
		lr35902_copy_to_from regB regA
		## カーソル位置のタイルアドレスをregDEに取得
		lr35902_copy_to_regA_from_addr $var_csl_tadr_bh
		lr35902_copy_to_from regE regA
		lr35902_copy_to_regA_from_addr $var_csl_tadr_th
		lr35902_copy_to_from regD regA
		## tdqに積む
		lr35902_call $a_enq_tdq

		# 下位側の処理を飛ばす
		local sz_1=$(stat -c '%s' f_inc_cursor.1.o)
		lr35902_rel_jump $(two_digits_d $sz_1)
	) >f_inc_cursor.2.o
	local sz_2=$(stat -c '%s' f_inc_cursor.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	cat f_inc_cursor.2.o	# b2(is_upper) == 1 (上位側)
	cat f_inc_cursor.1.o	# b2(is_upper) == 0 (下位側)

	# pop & return
	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

# カーソル位置の値をデクリメント
f_dec_cursor() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	# カーソル移動の補助変数をregCへ取得
	lr35902_copy_to_regA_from_addr $var_csl_attr
	lr35902_copy_to_from regC regA

	# 現在のカーソル位置は上位側か下位側か
	lr35902_test_bitN_of_reg $BE_CSL_ATTR_BITNUM_IS_UPPER regC
	(
		# 下位側

		# RAM上の値更新
		## カーソル位置の値取得
		lr35902_copy_to_regA_from_addr $var_csl_dadr_bh
		lr35902_copy_to_from regL regA
		lr35902_copy_to_regA_from_addr $var_csl_dadr_th
		lr35902_copy_to_from regH regA
		lr35902_copy_to_from regA ptrHL
		## regBには上位4ビットのみ設定
		lr35902_and_to_regA f0
		lr35902_copy_to_from regB regA
		## regAにはそのまま設定
		lr35902_copy_to_from regA ptrHL
		## regAをデクリメント
		lr35902_dec regA
		## regAの下位4ビットだけ抽出
		lr35902_and_to_regA 0f
		## regB(上位4ビット)と結合
		lr35902_or_to_regA regB
		## カーソル位置のRAMへ書き戻す
		lr35902_copy_to_from ptrHL regA

		# カーソル位置のタイル更新
		## regAの下位4ビットを抽出
		lr35902_and_to_regA 0f
		## 0x0a以上か否かに応じてタイル番号取得
		lr35902_compare_regA_and 0a
		(
			# regA < 0x0a

			# 番号タイルのベース番号を足し合わせる
			lr35902_add_to_regA $GBOS_TILE_NUM_NUM_BASE
		) >f_dec_cursor.3.o
		(
			# regA >= 0x0a

			# 0x0aを引く
			lr35902_sub_to_regA 0a

			# アルファベットタイルのベース番号を足し合わせる
			lr35902_add_to_regA $GBOS_TILE_NUM_ALPHA_BASE

			# regA < 0x0a の処理を飛ばす
			local sz_3=$(stat -c '%s' f_dec_cursor.3.o)
			lr35902_rel_jump $(two_digits_d $sz_3)
		) >f_dec_cursor.4.o
		local sz_4=$(stat -c '%s' f_dec_cursor.4.o)
		lr35902_rel_jump_with_cond C $(two_digits_d $sz_4)
		cat f_dec_cursor.4.o	# regA >= 0x0a の場合
		cat f_dec_cursor.3.o	# regA < 0x0a の場合
		## タイル番号をregBに設定
		lr35902_copy_to_from regB regA
		## カーソル位置のタイルアドレスをregDEに取得
		lr35902_copy_to_regA_from_addr $var_csl_tadr_bh
		lr35902_copy_to_from regE regA
		lr35902_copy_to_regA_from_addr $var_csl_tadr_th
		lr35902_copy_to_from regD regA
		## tdqに積む
		lr35902_call $a_enq_tdq
	) >f_dec_cursor.1.o
	(
		# 上位側

		# RAM上の値更新
		## カーソル位置の値取得
		lr35902_copy_to_regA_from_addr $var_csl_dadr_bh
		lr35902_copy_to_from regL regA
		lr35902_copy_to_regA_from_addr $var_csl_dadr_th
		lr35902_copy_to_from regH regA
		lr35902_copy_to_from regA ptrHL
		## regBに下位4ビットのみ設定
		lr35902_and_to_regA 0f
		lr35902_copy_to_from regB regA
		## regAにはそのまま設定
		lr35902_copy_to_from regA ptrHL
		## regAの上位4ビットを下位4ビットへ持ってくる
		lr35902_swap_nibbles regA
		## regAをデクリメント
		lr35902_dec regA
		## regAの下位4ビットを上位4ビットへ持ってくる
		lr35902_swap_nibbles regA
		## regAの上位4ビットのみ抽出
		lr35902_and_to_regA f0
		## regB(下位4ビット)と結合
		lr35902_or_to_regA regB
		## カーソル位置のRAMへ書き戻す
		lr35902_copy_to_from ptrHL regA

		# カーソル位置のタイル更新
		## regAの上位4ビットを下位4ビットへ持ってくる
		lr35902_swap_nibbles regA
		## regAの下位4ビットを抽出
		lr35902_and_to_regA 0f
		## 0x0a以上か否かに応じてタイル番号取得
		lr35902_compare_regA_and 0a
		(
			# regA < 0x0a

			# 番号タイルのベース番号を足し合わせる
			lr35902_add_to_regA $GBOS_TILE_NUM_NUM_BASE
		) >f_dec_cursor.5.o
		(
			# regA >= 0x0a

			# 0x0aを引く
			lr35902_sub_to_regA 0a

			# アルファベットタイルのベース番号を足し合わせる
			lr35902_add_to_regA $GBOS_TILE_NUM_ALPHA_BASE

			# regA < 0x0a の処理を飛ばす
			local sz_5=$(stat -c '%s' f_dec_cursor.5.o)
			lr35902_rel_jump $(two_digits_d $sz_5)
		) >f_dec_cursor.6.o
		local sz_6=$(stat -c '%s' f_dec_cursor.6.o)
		lr35902_rel_jump_with_cond C $(two_digits_d $sz_6)
		cat f_dec_cursor.6.o	# regA >= 0x0a の場合
		cat f_dec_cursor.5.o	# regA < 0x0a の場合
		## タイル番号をregBに設定
		lr35902_copy_to_from regB regA
		## カーソル位置のタイルアドレスをregDEに取得
		lr35902_copy_to_regA_from_addr $var_csl_tadr_bh
		lr35902_copy_to_from regE regA
		lr35902_copy_to_regA_from_addr $var_csl_tadr_th
		lr35902_copy_to_from regD regA
		## tdqに積む
		lr35902_call $a_enq_tdq

		# 下位側の処理を飛ばす
		local sz_1=$(stat -c '%s' f_dec_cursor.1.o)
		lr35902_rel_jump $(two_digits_d $sz_1)
	) >f_dec_cursor.2.o
	local sz_2=$(stat -c '%s' f_dec_cursor.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	cat f_dec_cursor.2.o	# b2(is_upper) == 1 (上位側)
	cat f_dec_cursor.1.o	# b2(is_upper) == 0 (下位側)

	# pop & return
	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

funcs() {
	local fsz

	# 初期配置のタイルをtdqへ積む
	a_draw_init_tiles=$APP_FUNCS_BASE
	echo -e "a_draw_init_tiles=$a_draw_init_tiles" >>$map_file
	f_draw_init_tiles

	# 指定したアドレスから4バイトダンプ
	f_draw_init_tiles >f_draw_init_tiles.o
	fsz=$(to16 $(stat -c '%s' f_draw_init_tiles.o))
	a_dump_addr_and_data_4bytes=$(four_digits $(calc16 "${a_draw_init_tiles}+${fsz}"))
	echo -e "a_dump_addr_and_data_4bytes=$a_dump_addr_and_data_4bytes" >>$map_file
	f_dump_addr_and_data_4bytes

	# (主にobjを)元に戻すエントリをtdqへ積む
	f_dump_addr_and_data_4bytes >f_dump_addr_and_data_4bytes.o
	fsz=$(to16 $(stat -c '%s' f_dump_addr_and_data_4bytes.o))
	a_draw_restore_tiles=$(four_digits $(calc16 "${a_dump_addr_and_data_4bytes}+${fsz}"))
	echo -e "a_draw_restore_tiles=$a_draw_restore_tiles" >>$map_file
	f_draw_restore_tiles

	# カーソルを一つ前へ進める関数
	# カーソル位置下位側3バイト目の処理
	f_draw_restore_tiles >f_draw_restore_tiles.o
	fsz=$(to16 $(stat -c '%s' f_draw_restore_tiles.o))
	a_forward_cursor_bh_3=$(four_digits $(calc16 "${a_draw_restore_tiles}+${fsz}"))
	echo -e "a_forward_cursor_bh_3=$a_forward_cursor_bh_3" >>$map_file
	f_forward_cursor_bh_3

	# カーソルを一つ前へ進める
	f_forward_cursor_bh_3 >f_forward_cursor_bh_3.o
	fsz=$(to16 $(stat -c '%s' f_forward_cursor_bh_3.o))
	a_forward_cursor=$(four_digits $(calc16 "${a_forward_cursor_bh_3}+${fsz}"))
	echo -e "a_forward_cursor=$a_forward_cursor" >>$map_file
	f_forward_cursor

	# カーソルを一つ後ろへ進める関数
	# カーソル位置上位側0バイト目の処理
	f_forward_cursor >f_forward_cursor.o
	fsz=$(to16 $(stat -c '%s' f_forward_cursor.o))
	a_backward_cursor_th_0=$(four_digits $(calc16 "${a_forward_cursor}+${fsz}"))
	echo -e "a_backward_cursor_th_0=$a_backward_cursor_th_0" >>$map_file
	f_backward_cursor_th_0

	# カーソルを一つ後ろへ進める
	f_backward_cursor_th_0 >f_backward_cursor_th_0.o
	fsz=$(to16 $(stat -c '%s' f_backward_cursor_th_0.o))
	a_backward_cursor=$(four_digits $(calc16 "${a_backward_cursor_th_0}+${fsz}"))
	echo -e "a_backward_cursor=$a_backward_cursor" >>$map_file
	f_backward_cursor

	# カーソル位置の値をインクリメント
	f_backward_cursor >f_backward_cursor.o
	fsz=$(to16 $(stat -c '%s' f_backward_cursor.o))
	a_inc_cursor=$(four_digits $(calc16 "${a_backward_cursor}+${fsz}"))
	echo -e "a_inc_cursor=$a_inc_cursor" >>$map_file
	f_inc_cursor

	# カーソル位置の値をデクリメント
	f_inc_cursor >f_inc_cursor.o
	fsz=$(to16 $(stat -c '%s' f_inc_cursor.o))
	a_dec_cursor=$(four_digits $(calc16 "${a_inc_cursor}+${fsz}"))
	echo -e "a_dec_cursor=$a_dec_cursor" >>$map_file
	f_dec_cursor
}
# 変数設定のために空実行
funcs >/dev/null
rm -f $map_file

main() {
	local flg_bitnum_inited=0

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

		# OBJサイズを8x8へ変更する
		lr35902_copy_to_regA_from_ioport $GB_IO_LCDC
		lr35902_res_bitN_of_reg $GB_LCDC_BITNUM_OBJ_SIZE regA
		lr35902_copy_to_ioport_from_regA $GB_IO_LCDC

		# カーネル側でマウスカーソルの更新をしないように専用の変数を設定
		lr35902_clear_reg regA
		lr35902_copy_to_addr_from_regA $var_mouse_enable

		# 初期画面描画のエントリをTDQへ積む
		lr35902_call $a_draw_init_tiles

		# 描画先アドレスの初期値設定
		lr35902_set_reg regD 98
		lr35902_set_reg regE 82

		# 初期表示として、
		# var_exe_1(下位),var_exe_2(上位)のデータをダンプする
		## var_exe_{1,2}をregHLへロード
		lr35902_copy_to_regA_from_addr $var_exe_1
		lr35902_copy_to_from regL regA
		lr35902_copy_to_regA_from_addr $var_exe_2
		lr35902_copy_to_from regH regA

		## サイズをregBCへロード
		## 併せて変数へ保存
		lr35902_copyinc_to_regA_from_ptrHL
		lr35902_copy_to_from regC regA
		lr35902_copy_to_addr_from_regA $var_file_size_bh
		lr35902_copy_to_addr_from_regA $var_remain_bytes_bh
		lr35902_copyinc_to_regA_from_ptrHL
		lr35902_copy_to_from regB regA
		lr35902_copy_to_addr_from_regA $var_file_size_th
		lr35902_copy_to_addr_from_regA $var_remain_bytes_th

		## この時点のptrHLはデータ部分の先頭アドレス
		## カーソル位置のデータアドレス変数をこのregHLで初期化
		lr35902_copy_to_from regA regL
		lr35902_copy_to_addr_from_regA $var_csl_dadr_bh
		lr35902_copy_to_from regA regH
		lr35902_copy_to_addr_from_regA $var_csl_dadr_th

		## 1画面分(12行)を表示し終えたかの判断に使うカウンタを
		## 初期化
		lr35902_set_reg regC 0c

		## アドレスとデータをダンプ
		(
			# 1行分ダンプ
			lr35902_call $a_dump_addr_and_data_4bytes

			# 戻り値をチェックし4未満ならループを脱出
			lr35902_compare_regA_and 04
			lr35902_rel_jump_with_cond C $(two_digits_d $((8 + 1 + 2)))

			# 描画先アドレスを次の行頭へ移動(+0x11)(8バイト)
			lr35902_push_reg regHL		# 1
			lr35902_set_reg regHL 0011	# 3
			lr35902_add_to_regHL regDE	# 1
			lr35902_copy_to_from regD regH	# 1
			lr35902_copy_to_from regE regL	# 1
			lr35902_pop_reg regHL		# 1

			# 行数カウンタをデクリメント(1バイト)
			lr35902_dec regC
		) >main.2.o
		cat main.2.o
		## regCを使った12回分のループ(2バイト)
		local sz_2=$(stat -c '%s' main.2.o)
		lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_2 + 2)))

		# 初期化済みフラグをセット
		lr35902_copy_to_regA_from_addr $APP_VARS_BASE
		lr35902_set_bitN_of_reg $flg_bitnum_inited regA
		lr35902_copy_to_addr_from_regA $APP_VARS_BASE

		# pop & return
		lr35902_pop_reg regHL
		lr35902_pop_reg regDE
		lr35902_pop_reg regBC
		lr35902_pop_reg regAF
		lr35902_return
	) >main.1.o

	# フラグ変数の初期化済みフラグチェック
	lr35902_copy_to_regA_from_addr $APP_VARS_BASE
	lr35902_test_bitN_of_reg $flg_bitnum_inited regA

	# フラグがセットされていたら(初期化済みだったら)、
	# 初期化処理をスキップ
	local sz_1=$(stat -c '%s' main.1.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_1)
	cat main.1.o

	# 定常処理

	# 方向キーに応じた処理
	## 現在の十字キー入力状態をregBへ取得
	lr35902_copy_to_regA_from_addr $var_btn_stat
	lr35902_and_to_regA $GBOS_DIR_KEY_MASK
	lr35902_copy_to_from regB regA

	## 前回の十字キー入力状態をregAへ取得
	lr35902_copy_to_regA_from_addr $var_prev_dir_input

	## 前回と現在の入力状態を比較
	lr35902_compare_regA_and regB
	(
		# 前回 == 現在 の場合

		# いずれかの入力があるか？
		lr35902_or_to_regA regA
		(
			# いずれの入力も無し

			# regAをクリア
			lr35902_clear_reg regA
		) >main.5.o
		(
			# いずれかの入力有り

			# カウンタ値をregAへ取得しインクリメント
			lr35902_copy_to_regA_from_addr $var_press_counter
			lr35902_inc regA

			# いずれの入力も無しの処理を飛ばす
			local sz_5=$(stat -c '%s' main.5.o)
			lr35902_rel_jump $(two_digits_d $sz_5)
		) >main.7.o
		local sz_7=$(stat -c '%s' main.7.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_7)
		cat main.7.o	# いずれかの入力有り
		cat main.5.o	# いずれの入力も無し
	) >main.3.o
	(
		# 前回 != 現在 の場合

		# regAをクリア
		lr35902_clear_reg regA

		# 前回 == 現在 の場合の処理を飛ばす
		local sz_3=$(stat -c '%s' main.3.o)
		lr35902_rel_jump $(two_digits_d $sz_3)
	) >main.4.o
	local sz_4=$(stat -c '%s' main.4.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_4)
	cat main.4.o
	cat main.3.o

	## 現在のカウンタ値をregCへ保存
	lr35902_copy_to_from regC regA

	## カウンタ値のしきい値チェック(押下判定)
	lr35902_compare_regA_and $BE_KEY_PRESS_TH
	(
		# 押下有り

		# →か?
		lr35902_test_bitN_of_reg $GBOS_JOYP_BITNUM_RIGHT regB
		(
			# →の場合

			# カーソルを一つ進める関数を呼び出す
			lr35902_call $a_forward_cursor
		) >main.9.o
		local sz_9=$(stat -c '%s' main.9.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_9)
		cat main.9.o

		# ←か?
		lr35902_test_bitN_of_reg $GBOS_JOYP_BITNUM_LEFT regB
		(
			# ←の場合

			# カーソルを一つ戻る関数を呼び出す
			lr35902_call $a_backward_cursor
		) >main.10.o
		local sz_10=$(stat -c '%s' main.10.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_10)
		cat main.10.o

		# ↑か?
		lr35902_test_bitN_of_reg $GBOS_JOYP_BITNUM_UP regB
		(
			# ↑の場合

			# カーソル位置の値を一つ増やす関数を呼び出す
			lr35902_call $a_inc_cursor
		) >main.11.o
		local sz_11=$(stat -c '%s' main.11.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_11)
		cat main.11.o

		# ↓か?
		lr35902_test_bitN_of_reg $GBOS_JOYP_BITNUM_DOWN regB
		(
			# ↓の場合

			# カーソル位置の値を一つ減らす関数を呼び出す
			lr35902_call $a_dec_cursor
		) >main.12.o
		local sz_12=$(stat -c '%s' main.12.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_12)
		cat main.12.o

		# カウンタ値をゼロクリア
		lr35902_clear_reg regC
	) >main.8.o
	local sz_8=$(stat -c '%s' main.8.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $sz_8)
	cat main.8.o

	## カウンタ値更新
	lr35902_copy_to_from regA regC
	lr35902_copy_to_addr_from_regA $var_press_counter

	## 前回の入力状態更新
	lr35902_copy_to_from regA regB
	lr35902_copy_to_addr_from_regA $var_prev_dir_input

	# アプリ用ボタンリリースフラグをregAへ取得
	lr35902_copy_to_regA_from_addr $var_app_release_btn

	# Aボタン(右クリック): 終了
	lr35902_test_bitN_of_reg $GBOS_A_KEY_BITNUM regA
	(
		# Aボタン(右クリック)のリリースがあった場合

		# マウスカーソル表示・その他使用したOBJを非表示 のOAM変更をtdqへ積む
		lr35902_call $a_draw_restore_tiles

		# OBJサイズ設定を8x16へ戻す
		lr35902_copy_to_regA_from_ioport $GB_IO_LCDC
		lr35902_set_bitN_of_reg $GB_LCDC_BITNUM_OBJ_SIZE regA
		lr35902_copy_to_ioport_from_regA $GB_IO_LCDC

		# カーネル側でマウスカーソルの更新を再開するように専用の変数を設定
		lr35902_set_reg regA 01
		lr35902_copy_to_addr_from_regA $var_mouse_enable

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
	) >main.6.o
	local sz_6=$(stat -c '%s' main.6.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_6)
	cat main.6.o

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

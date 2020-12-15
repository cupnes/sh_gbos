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

BE_OAM_BASE_CSL=$(calc16 "$GB_OAM_BASE+$GB_OAM_SZ")
BE_OAM_CSL_Y_ADDR=$(calc16 "$BE_OAM_BASE_CSL")
BE_OAM_CSL_X_ADDR=$(calc16 "$BE_OAM_BASE_CSL+1")
BE_OAM_BASE_WIN_TITLE=$(calc16 "$GB_OAM_BASE+($GB_OAM_SZ*2)")

BE_OBJX_DAREA_BASE=40
BE_OBJX_DAREA_LAST=90
BE_OBJY_DAREA_BASE=30	# 1行目のobjY座標
BE_OBJY_DAREA_LAST=88	# 12行目のobjY座標
BE_TADR_AAREA_BASE=9882	# アドレス領域最初の1文字のタイルアドレス
BE_TADR_DAREA_BASE=9887	# データ領域1バイト目上位のタイルアドレス
BE_TADR_DAREA_LAST=99f1	# データ領域48バイト目下位のタイルアドレス

# 汎用フラグ変数
BE_GFLG_BITNUM_INITED=0	# 初期化済みフラグのビット番号
BE_GFLG_BITNUM_CSL_EXPECTED=7	# DEBUG カーソル期待値が設定済み
## カーソル期待値が部分的に適用されている間はこのフラグで判断する

# 押下判定のしきい値
BE_KEY_PRESS_TH=05

# カーソル移動補助変数
BE_CSL_ATTR_BITNUM_IS_UPPER=2

# カーソルに使うタイルのタイル番号
BE_TILE_NUM_CSL=$GBOS_TILE_NUM_LOWER_BAR

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

	# □カーソル座標期待値
	# OAMの更新が完了したかどうかの確認に使う
	# TODO 今や使っていないので消す
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
	echo -en "\x$(echo $BE_TADR_DAREA_BASE | cut -c3-4)"
	## 上位8ビット
	var_csl_tadr_th=$(calc16 "$var_csl_tadr_bh+1")
	echo -e "var_csl_tadr_th=$var_csl_tadr_th" >>$map_file
	echo -en "\x$(echo $BE_TADR_DAREA_BASE | cut -c1-2)"

	# カーソル移動の補助変数
	## b2   : 上位4ビット(=1)/下位4ビット(=0)
	## b1-b0: 1行の何バイト目か(0〜3)
	var_csl_attr=$(calc16 "$var_csl_tadr_th+1")
	echo -e "var_csl_attr=$var_csl_attr" >>$map_file
	echo -en '\x04'

	# データ最終アドレスを保持する変数
	## 現在のカーソル位置がこのアドレスと等しく
	## かつ、下位4ビットである場合、
	## それ以上→に移動しない
	## 下位8ビット
	var_dadr_last_bh=$(calc16 "$var_csl_attr+1")
	echo -e "var_dadr_last_bh=$var_dadr_last_bh" >>$map_file
	echo -en '\x00'
	## 上位8ビット
	var_dadr_last_th=$(calc16 "$var_dadr_last_bh+1")
	echo -e "var_dadr_last_th=$var_dadr_last_th" >>$map_file
	echo -en '\x00'

	# 現在の画面にダンプしたバイト数
	# ※ 2ページ目以降ではf_dump_addr_and_data()により設定される
	var_dumped_bytes_this_page=$(calc16 "$var_dadr_last_th+1")
	echo -e "var_dumped_bytes_this_page=$var_dumped_bytes_this_page" >>$map_file
	echo -en '\x00'

	# 画面更新中フラグ
	# ページ移動時、予めこの変数に1をセットした上で、
	# この変数へ0をセットするエントリをtdqに積む
	# 方向キーに応じた処理では、この変数が1の間は何もしない
	var_drawing_flag=$(calc16 "$var_dumped_bytes_this_page+1")
	echo -e "var_drawing_flag=$var_drawing_flag" >>$map_file
	echo -en '\x00'

	# 表示アドレスオフセット
	# f_dump_addr_and_data_4bytesは
	# このアドレスを足した値をアドレス列へダンプする
	## 下位8ビット
	var_disp_dadr_ofs_bh=$(calc16 "$var_drawing_flag+1")
	echo -e "var_disp_dadr_ofs_bh=$var_disp_dadr_ofs_bh" >>$map_file
	echo -en '\x00'
	## 上位8ビット
	var_disp_dadr_ofs_th=$(calc16 "$var_disp_dadr_ofs_bh+1")
	echo -e "var_disp_dadr_ofs_th=$var_disp_dadr_ofs_th" >>$map_file
	echo -en '\x00'
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
	## Y座標
	lr35902_set_reg regB $BE_OBJY_DAREA_BASE
	lr35902_set_reg regDE $BE_OAM_CSL_Y_ADDR
	lr35902_call $a_enq_tdq
	## X座標
	lr35902_set_reg regB $BE_OBJX_DAREA_BASE
	lr35902_set_reg regDE $BE_OAM_CSL_X_ADDR
	lr35902_call $a_enq_tdq
	### タイル番号
	lr35902_inc regE
	lr35902_set_reg regB $BE_TILE_NUM_CSL
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

	# regHLにvar_disp_dadr_ofs_{th,bh}を足したアドレスをダンプ
	## regHLをスタックへ退避
	lr35902_push_reg regHL
	## var_disp_dadr_ofs_{th,bh}をregBCへ設定
	lr35902_copy_to_regA_from_addr $var_disp_dadr_ofs_bh
	lr35902_copy_to_from regC regA
	lr35902_copy_to_regA_from_addr $var_disp_dadr_ofs_th
	lr35902_copy_to_from regB regA
	## regHLにregBCを足す
	lr35902_add_to_regHL regBC
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
	## regHLをスタックから復帰
	lr35902_pop_reg regHL

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

# 指定されたアドレスから1画面分ダンプ
# in : regHL - ダンプするデータ開始アドレス
# out: var_dumped_bytes_this_page
#      ※ 1ページ目の時だけ0x00をセットする
f_dump_addr_and_data() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	# 描画先アドレスの初期値設定
	lr35902_set_reg regD $(echo $BE_TADR_AAREA_BASE | cut -c1-2)
	lr35902_set_reg regE $(echo $BE_TADR_AAREA_BASE | cut -c3-4)

	# 1画面分(12行)を表示し終えたかの判断に使うカウンタを
	# 初期化
	lr35902_set_reg regC 0c

	# アドレスとデータをダンプ
	(
		# 1行分ダンプ
		lr35902_call $a_dump_addr_and_data_4bytes

		# regA(戻り値)をregBへ保存
		lr35902_copy_to_from regB regA

		# 行数カウンタをデクリメント
		lr35902_dec regC

		# 戻り値をチェックし4未満ならループを脱出
		lr35902_compare_regA_and 04
		lr35902_rel_jump_with_cond C $(two_digits_d $((8 + 2 + 2)))

		# 描画先アドレスを次の行頭へ移動(+0x11)(8バイト)
		lr35902_push_reg regHL		# 1
		lr35902_set_reg regHL 0011	# 3
		lr35902_add_to_regHL regDE	# 1
		lr35902_copy_to_from regD regH	# 1
		lr35902_copy_to_from regE regL	# 1
		lr35902_pop_reg regHL		# 1

		# regCが0か否か確認(2バイト)
		lr35902_copy_to_from regA regC	# 1
		lr35902_or_to_regA regA		# 1
	) >f_dump_addr_and_data.1.o
	cat f_dump_addr_and_data.1.o
	## regCを使った12回分のループ(2バイト)
	local sz_1=$(stat -c '%s' f_dump_addr_and_data.1.o)
	lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_1 + 2)))

	# f_dump_addr_and_data_4bytes()の最後の戻り値(regB)をregHへ保存
	lr35902_copy_to_from regH regB

	# 初期化済みフラグがセットされているかどうかを確認
	lr35902_copy_to_regA_from_addr $var_general_flgs
	lr35902_test_bitN_of_reg $BE_GFLG_BITNUM_INITED regA
	(
		# セットされていなければこの時点でpop & return
		# ※ 初期化時の1ページ目に関しては、ダンプしたバイト数は返さない
		lr35902_pop_reg regHL
		lr35902_pop_reg regDE
		lr35902_pop_reg regBC
		lr35902_pop_reg regAF
		lr35902_return
	) >f_dump_addr_and_data.2.o
	local sz_2=$(stat -c '%s' f_dump_addr_and_data.2.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_2)
	cat f_dump_addr_and_data.2.o

	# 今描画しているのが1ページ目か否かを確認
	# 1ページ目なら、
	# $var_remain_bytes_{th,bh} + 1ページのバイト数(0x0030)
	#   == $var_file_size_{th,bh}
	lr35902_push_reg regHL
	lr35902_push_reg regBC
	lr35902_copy_to_regA_from_addr $var_remain_bytes_bh
	lr35902_copy_to_from regL regA
	lr35902_copy_to_regA_from_addr $var_remain_bytes_th
	lr35902_copy_to_from regH regA
	lr35902_set_reg regBC 0030
	lr35902_add_to_regHL regBC
	lr35902_copy_to_regA_from_addr $var_file_size_bh
	lr35902_xor_to_regA regL
	lr35902_copy_to_from regL regA
	lr35902_copy_to_regA_from_addr $var_file_size_th
	lr35902_xor_to_regA regH
	lr35902_or_to_regA regL
	lr35902_pop_reg regBC
	lr35902_pop_reg regHL
	lr35902_or_to_regA regA
	(
		# 1ページ目の場合

		# 現在の画面のバイト数に0x00を設定
		lr35902_copy_to_addr_from_regA $var_dumped_bytes_this_page
	) >f_dump_addr_and_data.6.o
	(
		# 1ページ目でない場合

		# regHとregCを使ってダンプしたバイト数を取得
		# ダンプしたバイト数 = (12 - regC) * 4 - (4 - regH)
		#                    = (12 - regC) * 4 - 4 + regH
		lr35902_set_reg regA 0c
		lr35902_sub_to_regA regC
		lr35902_shift_left_arithmetic regA
		lr35902_shift_left_arithmetic regA
		lr35902_sub_to_regA 04
		lr35902_add_to_regA regH

		# 現在の画面のバイト数を変数へ設定
		lr35902_copy_to_addr_from_regA $var_dumped_bytes_this_page

		# 1ページ目の場合の処理を飛ばす
		local sz_6=$(stat -c '%s' f_dump_addr_and_data.6.o)
		lr35902_rel_jump $(two_digits_d $sz_6)
	) >f_dump_addr_and_data.7.o
	local sz_7=$(stat -c '%s' f_dump_addr_and_data.7.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_7)
	cat f_dump_addr_and_data.7.o	# 1ページ目でない場合
	cat f_dump_addr_and_data.6.o	# 1ページ目の場合

	# TODO ダンプしたバイト数が(* 4 12)48ならこの時点でpop&return

	# 画面途中で描画が終わった時、残りを空白文字でクリア
	## 現在の行の残りを空白文字でクリア
	### 残りバイト数(4 - regH)を取得
	lr35902_set_reg regA 04
	lr35902_sub_to_regA regH
	### 残りバイト数だけクリア処理を実施
	lr35902_set_reg regB $GBOS_TILE_NUM_SPC
	#### 残りバイト数(regA)が1以上の間繰り返す
	lr35902_compare_regA_and 01	# 2
	(
		# 空白の分1タイル飛ばす
		lr35902_inc regE

		# 2文字分のクリアを実施
		lr35902_inc regE
		lr35902_call $a_enq_tdq
		lr35902_inc regE
		lr35902_call $a_enq_tdq

		# 残りバイト数(regA)をデクリメント
		lr35902_dec regA
	) >f_dump_addr_and_data.4.o
	local sz_4=$(stat -c '%s' f_dump_addr_and_data.4.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $((sz_4 + 2)))	# 2
	cat f_dump_addr_and_data.4.o	# sz_4
	lr35902_rel_jump $(two_comp_d $((2 + 2 + sz_4 + 2)))	# 2

	## TODO regC == 0ならこの時点でpop&return

	## regC行分をクリア
	## ※ この時点でregBには$GBOS_TILE_NUM_SPCが設定されていること
	lr35902_copy_to_from regA regC
	### 残り行数が1以上の間繰り返す
	lr35902_compare_regA_and 01	# 2
	(
		# 1行分のクリア処理

		# クリアする行の行頭へ移動
		# (regDEに0x0011を足す)
		lr35902_set_reg regHL 0011
		lr35902_add_to_regHL regDE
		lr35902_copy_to_from regE regL
		lr35902_copy_to_from regD regH

		# アドレス領域をクリア
		lr35902_call $a_enq_tdq
		lr35902_inc regE
		lr35902_call $a_enq_tdq
		lr35902_inc regE
		lr35902_call $a_enq_tdq
		lr35902_inc regE
		lr35902_call $a_enq_tdq

		# 空白の分1タイル飛ばす
		lr35902_inc regE

		# データ領域をクリア
		lr35902_inc regE
		lr35902_call $a_enq_tdq
		lr35902_inc regE
		lr35902_call $a_enq_tdq
		lr35902_inc regE
		lr35902_inc regE
		lr35902_call $a_enq_tdq
		lr35902_inc regE
		lr35902_call $a_enq_tdq
		lr35902_inc regE
		lr35902_inc regE
		lr35902_call $a_enq_tdq
		lr35902_inc regE
		lr35902_call $a_enq_tdq
		lr35902_inc regE
		lr35902_inc regE
		lr35902_call $a_enq_tdq
		lr35902_inc regE
		lr35902_call $a_enq_tdq

		# 残り行数(regA)をデクリメント
		lr35902_dec regA
	) >f_dump_addr_and_data.5.o
	local sz_5=$(stat -c '%s' f_dump_addr_and_data.5.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $((sz_5 + 2)))	# 2
	cat f_dump_addr_and_data.5.o	# sz_5
	lr35902_rel_jump $(two_comp_d $((2 + 2 + sz_5 + 2)))	# 2

	# pop & return
	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
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

	## マウスカーソルを表示する
	lr35902_copy_to_regA_from_addr $var_mouse_y
	lr35902_copy_to_from regB regA
	lr35902_set_reg regDE $GBOS_OAM_BASE_CSL
	lr35902_call $a_enq_tdq

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
	# 現在データ最終バイトか否か
	## 「現在のカーソルのデータアドレス」と「データ最終アドレス取得」を比較
	## XORをとって0になるか否かを確認
	### 下位8ビットのXORをregEへ取得
	lr35902_copy_to_regA_from_addr $var_csl_dadr_bh
	lr35902_copy_to_from regE regA
	lr35902_copy_to_regA_from_addr $var_dadr_last_bh
	lr35902_xor_to_regA regE
	lr35902_copy_to_from regE regA
	### 上位8ビットのXORをregAへ取得
	lr35902_copy_to_regA_from_addr $var_csl_dadr_th
	lr35902_copy_to_from regD regA
	lr35902_copy_to_regA_from_addr $var_dadr_last_th
	lr35902_xor_to_regA regD
	### regEとregAのORをregAへ取得
	lr35902_or_to_regA regE
	## 結果が0か否か
	(
		# 現在のカーソル位置がデータ最終アドレスである場合

		# 何もせずreturn
		lr35902_return
	) >f_forward_cursor_bh_3.2.o
	local sz_2=$(stat -c '%s' f_forward_cursor_bh_3.2.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_2)
	cat f_forward_cursor_bh_3.2.o

	# 現在12行目か否か
	## 現在のカーソルのobjY座標取得
	lr35902_copy_to_regA_from_addr $BE_OAM_CSL_Y_ADDR
	## 12行目のobjY座標値と比較
	lr35902_compare_regA_and $BE_OBJY_DAREA_LAST
	(
		# 12行目以上の場合

		# 画面更新中フラグをセット
		lr35902_set_reg regA 01
		lr35902_copy_to_addr_from_regA $var_drawing_flag

		# □カーソルOAM更新
		## □カーソルのOAMのY座標を1行目へ更新するエントリをtdqへ積む
		lr35902_set_reg regB $BE_OBJY_DAREA_BASE
		lr35902_set_reg regDE $BE_OAM_CSL_Y_ADDR
		lr35902_call $a_enq_tdq
		## □カーソルのOAMのX座標を行頭へ更新するエントリをtdqへ積む
		lr35902_set_reg regB $BE_OBJX_DAREA_BASE
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
		## $BE_TADR_DAREA_BASEを設定する
		lr35902_set_reg regA $(echo $BE_TADR_DAREA_BASE | cut -c3-4)
		lr35902_copy_to_addr_from_regA $var_csl_tadr_bh
		lr35902_set_reg regA $(echo $BE_TADR_DAREA_BASE | cut -c1-2)
		lr35902_copy_to_addr_from_regA $var_csl_tadr_th

		# カーソル移動の補助変数更新
		## b2に1を、b0-b1に0を設定(0x04)
		lr35902_set_reg regA 04
		lr35902_copy_to_addr_from_regA $var_csl_attr

		# 画面描画
		## 描画開始データアドレスをregHLへ設定
		## ※ この時点で描画開始データアドレスはregDEに設定されている
		lr35902_copy_to_from regL regE
		lr35902_copy_to_from regH regD
		## 指定されたアドレスから1画面分ダンプ
		lr35902_call $a_dump_addr_and_data

		# 画面更新中フラグをリセットするエントリをtdqへ積む
		lr35902_clear_reg regB
		lr35902_set_reg regDE $var_drawing_flag
		lr35902_call $a_enq_tdq
	) >f_forward_cursor_bh_3.3.o
	(
		# 12行目未満の場合

		# □カーソルOAM更新
		## 1タイル分増やす
		lr35902_add_to_regA 08
		## □カーソルのOAMのY座標を更新するエントリをtdqへ積む
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

		# 12行目以上の場合の処理を飛ばす
		local sz_3=$(stat -c '%s' f_forward_cursor_bh_3.3.o)
		lr35902_rel_jump $(two_digits_d $sz_3)
	) >f_forward_cursor_bh_3.1.o
	local sz_1=$(stat -c '%s' f_forward_cursor_bh_3.1.o)
	lr35902_rel_jump_with_cond NC $(two_digits_d $sz_1)
	cat f_forward_cursor_bh_3.1.o	# regA < objY_darea_last
	cat f_forward_cursor_bh_3.3.o	# regA >= objY_darea_last

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

			# 現在のカーソル位置がデータ最終アドレスだったら何もしない
			## 「現在のカーソルのデータアドレス」と「データ最終アドレス取得」を比較
			## XORをとって0になるか否かを確認
			### 下位8ビットのXORをregEへ取得
			lr35902_copy_to_regA_from_addr $var_csl_dadr_bh
			lr35902_copy_to_from regE regA
			lr35902_copy_to_regA_from_addr $var_dadr_last_bh
			lr35902_xor_to_regA regE
			lr35902_copy_to_from regE regA
			### 上位8ビットのXORをregAへ取得
			lr35902_copy_to_regA_from_addr $var_csl_dadr_th
			lr35902_copy_to_from regD regA
			lr35902_copy_to_regA_from_addr $var_dadr_last_th
			lr35902_xor_to_regA regD
			### regEとregAのORをregAへ取得
			lr35902_or_to_regA regE
			## 結果が0か否か
			(
				# 現在のカーソル位置がデータ最終アドレスでない場合

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
			) >f_forward_cursor.5.o
			local sz_5=$(stat -c '%s' f_forward_cursor.5.o)
			lr35902_rel_jump_with_cond Z $(two_digits_d $sz_5)
			cat f_forward_cursor.5.o
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
		# 1行目の場合

		# 現在のページのバイト数取得
		lr35902_copy_to_regA_from_addr $var_dumped_bytes_this_page

		# 現在1ページ目か否か?
		# ※ 1ページ目ならvar_dumped_bytes_this_pageは00
		lr35902_compare_regA_and 00
		(
			# 1ページ目の場合

			# return
			lr35902_return
		) >f_backward_cursor_th_0.3.o
		local sz_3=$(stat -c '%s' f_backward_cursor_th_0.3.o)
		lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_3)
		cat f_backward_cursor_th_0.3.o

		# 1ページ目でない場合

		# 現在のページのバイト数(regA)をregCへ保存
		lr35902_copy_to_from regC regA

		# 画面更新中フラグをセット
		lr35902_set_reg regA 01
		lr35902_copy_to_addr_from_regA $var_drawing_flag

		# □カーソルOAM更新
		## □カーソルのOAMのY座標を12行目へ更新するエントリをtdqへ積む
		lr35902_set_reg regB $BE_OBJY_DAREA_LAST
		lr35902_set_reg regDE $BE_OAM_CSL_Y_ADDR
		lr35902_call $a_enq_tdq
		## □カーソルのOAMのX座標を行末へ更新するエントリをtdqへ積む
		lr35902_set_reg regB $BE_OBJX_DAREA_LAST
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
		## $BE_TADR_DAREA_LASTを設定する
		lr35902_set_reg regA $(echo $BE_TADR_DAREA_LAST | cut -c3-4)
		lr35902_copy_to_addr_from_regA $var_csl_tadr_bh
		lr35902_set_reg regA $(echo $BE_TADR_DAREA_LAST | cut -c1-2)
		lr35902_copy_to_addr_from_regA $var_csl_tadr_th

		# カーソル移動の補助変数更新
		## b2に0を、b0-b1に3を設定(0x03)
		lr35902_set_reg regA 03
		lr35902_copy_to_addr_from_regA $var_csl_attr

		# 画面描画
		## 表示位置管理用カウンタに
		## 現在のページのバイト数(regC)と
		## 前ページのバイト数(48(0x30))を足す
		lr35902_copy_to_regA_from_addr $var_remain_bytes_bh
		lr35902_copy_to_from regL regA
		lr35902_copy_to_regA_from_addr $var_remain_bytes_th
		lr35902_copy_to_from regH regA
		lr35902_clear_reg regB
		lr35902_add_to_regHL regBC
		lr35902_set_reg regBC 0030
		lr35902_add_to_regHL regBC
		lr35902_copy_to_from regA regL
		lr35902_copy_to_addr_from_regA $var_remain_bytes_bh
		lr35902_copy_to_from regA regH
		lr35902_copy_to_addr_from_regA $var_remain_bytes_th
		## 描画開始データアドレスをregHLへ設定
		## ※ この時点でregDEは、
		##    前ページ(これから描画するページ)の最終バイトを指している
		##    なので、この時点のregDEから47(0x2f)を引いた値が
		##    描画開始データアドレス
		##    16ビットの引き算命令は無いので
		##    0x002fの2の補数0xffd1を足す
		lr35902_copy_to_from regL regE
		lr35902_copy_to_from regH regD
		lr35902_set_reg regBC ffd1
		lr35902_add_to_regHL regBC
		## 指定されたアドレスから1画面分ダンプ
		lr35902_call $a_dump_addr_and_data

		# 画面更新中フラグをリセットするエントリをtdqへ積む
		lr35902_clear_reg regB
		lr35902_set_reg regDE $var_drawing_flag
		lr35902_call $a_enq_tdq
	) >f_backward_cursor_th_0.2.o
	(
		# 1行目ではない場合

		# □カーソルOAM更新
		## 1タイル分減らす
		lr35902_sub_to_regA 08
		## □カーソルのOAMのY座標を更新するエントリをtdqへ積む
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

		# 1行目の場合の処理を飛ばす
		local sz_2=$(stat -c '%s' f_backward_cursor_th_0.2.o)
		lr35902_rel_jump $(two_digits_d $sz_2)
	) >f_backward_cursor_th_0.1.o
	local sz_1=$(stat -c '%s' f_backward_cursor_th_0.1.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_1)
	cat f_backward_cursor_th_0.1.o	# 1行目ではない場合
	cat f_backward_cursor_th_0.2.o	# 1行目の場合

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

# 方向キーに応じた処理
# ※ カーソル期待値が設定済みで、OAMの値が期待値でない場合、
#    何もせずreturnする
# ※ 使用するレジスタのpush/popをしていない
f_proc_dir_keys() {
	# 画面更新中フラグがセットされているか否か?
	lr35902_copy_to_regA_from_addr $var_drawing_flag
	lr35902_compare_regA_and 01
	(
		# 画面更新中フラグがセットされている

		# return
		lr35902_return
	) >f_proc_dir_keys.10.o
	local sz_10=$(stat -c '%s' f_proc_dir_keys.10.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_10)
	cat f_proc_dir_keys.10.o

	# 現在の十字キー入力状態をregBへ取得
	lr35902_copy_to_regA_from_addr $var_btn_stat
	lr35902_and_to_regA $GBOS_DIR_KEY_MASK
	lr35902_copy_to_from regB regA

	# 前回の十字キー入力状態をregAへ取得
	lr35902_copy_to_regA_from_addr $var_prev_dir_input

	# 前回と現在の入力状態を比較
	lr35902_compare_regA_and regB
	(
		# 前回 == 現在 の場合

		# いずれかの入力があるか？
		lr35902_or_to_regA regA
		(
			# いずれの入力も無し

			# regAをクリア
			lr35902_clear_reg regA
		) >f_proc_dir_keys.1.o
		(
			# いずれかの入力有り

			# カウンタ値をregAへ取得しインクリメント
			lr35902_copy_to_regA_from_addr $var_press_counter
			lr35902_inc regA

			# いずれの入力も無しの処理を飛ばす
			local sz_1=$(stat -c '%s' f_proc_dir_keys.1.o)
			lr35902_rel_jump $(two_digits_d $sz_1)
		) >f_proc_dir_keys.2.o
		local sz_2=$(stat -c '%s' f_proc_dir_keys.2.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
		cat f_proc_dir_keys.2.o	# いずれかの入力有り
		cat f_proc_dir_keys.1.o	# いずれの入力も無し
	) >f_proc_dir_keys.3.o
	(
		# 前回 != 現在 の場合

		# regAをクリア
		lr35902_clear_reg regA

		# 前回 == 現在 の場合の処理を飛ばす
		local sz_3=$(stat -c '%s' f_proc_dir_keys.3.o)
		lr35902_rel_jump $(two_digits_d $sz_3)
	) >f_proc_dir_keys.4.o
	local sz_4=$(stat -c '%s' f_proc_dir_keys.4.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_4)
	cat f_proc_dir_keys.4.o
	cat f_proc_dir_keys.3.o

	# カウンタ値のしきい値チェック(押下判定)
	lr35902_compare_regA_and $BE_KEY_PRESS_TH
	(
		# 押下有り

		# →か?
		lr35902_test_bitN_of_reg $GBOS_JOYP_BITNUM_RIGHT regB
		(
			# →の場合

			# カーソルを一つ進める関数を呼び出す
			lr35902_call $a_forward_cursor

			# カウンタ値をゼロクリア
			lr35902_clear_reg regA
			lr35902_copy_to_addr_from_regA $var_press_counter

			# 前回の入力状態更新
			lr35902_copy_to_from regA regB
			lr35902_copy_to_addr_from_regA $var_prev_dir_input

			# return
			lr35902_return
		) >f_proc_dir_keys.5.o
		local sz_5=$(stat -c '%s' f_proc_dir_keys.5.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_5)
		cat f_proc_dir_keys.5.o

		# ←か?
		lr35902_test_bitN_of_reg $GBOS_JOYP_BITNUM_LEFT regB
		(
			# ←の場合

			# カーソルを一つ戻る関数を呼び出す
			lr35902_call $a_backward_cursor

			# カウンタ値をゼロクリア
			lr35902_clear_reg regA
			lr35902_copy_to_addr_from_regA $var_press_counter

			# 前回の入力状態更新
			lr35902_copy_to_from regA regB
			lr35902_copy_to_addr_from_regA $var_prev_dir_input

			# return
			lr35902_return
		) >f_proc_dir_keys.6.o
		local sz_6=$(stat -c '%s' f_proc_dir_keys.6.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_6)
		cat f_proc_dir_keys.6.o

		# 現在のファイルシステムはRAM上か?
		## ※ ここでreturnしない(RAM上である)としても、
		##    regAは結局ゼロクリアされるだけなので、
		##    regAはここで破壊して構わない
		## ファイルシステム先頭アドレスの上位8ビットを取得
		lr35902_copy_to_regA_from_addr $var_fs_base_th
		## カートリッジRAMアドレス上位8ビットと等しいか?
		lr35902_compare_regA_and $(echo $GB_CARTRAM_BASE | cut -c1-2)
		(
			# 等しくない場合
			# (現在のファイルシステムはROM上)

			# カウンタ値をゼロクリア
			lr35902_clear_reg regA
			lr35902_copy_to_addr_from_regA $var_press_counter

			# 前回の入力状態更新
			lr35902_copy_to_from regA regB
			lr35902_copy_to_addr_from_regA $var_prev_dir_input

			# return
			lr35902_return
		) >f_proc_dir_keys.11.o
		local sz_11=$(stat -c '%s' f_proc_dir_keys.11.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_11)
		cat f_proc_dir_keys.11.o

		# ↑か?
		lr35902_test_bitN_of_reg $GBOS_JOYP_BITNUM_UP regB
		(
			# ↑の場合

			# カーソル位置の値を一つ増やす関数を呼び出す
			lr35902_call $a_inc_cursor

			# カウンタ値をゼロクリア
			lr35902_clear_reg regA
			lr35902_copy_to_addr_from_regA $var_press_counter

			# 前回の入力状態更新
			lr35902_copy_to_from regA regB
			lr35902_copy_to_addr_from_regA $var_prev_dir_input

			# return
			lr35902_return
		) >f_proc_dir_keys.7.o
		local sz_7=$(stat -c '%s' f_proc_dir_keys.7.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_7)
		cat f_proc_dir_keys.7.o

		# ↓か?
		lr35902_test_bitN_of_reg $GBOS_JOYP_BITNUM_DOWN regB
		(
			# ↓の場合

			# カーソル位置の値を一つ減らす関数を呼び出す
			lr35902_call $a_dec_cursor

			# カウンタ値をゼロクリア
			lr35902_clear_reg regA
			lr35902_copy_to_addr_from_regA $var_press_counter

			# 前回の入力状態更新
			lr35902_copy_to_from regA regB
			lr35902_copy_to_addr_from_regA $var_prev_dir_input

			# return
			lr35902_return
		) >f_proc_dir_keys.8.o
		local sz_8=$(stat -c '%s' f_proc_dir_keys.8.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_8)
		cat f_proc_dir_keys.8.o
	) >f_proc_dir_keys.9.o
	local sz_9=$(stat -c '%s' f_proc_dir_keys.9.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $sz_9)
	cat f_proc_dir_keys.9.o

	# カウンタ値更新
	lr35902_copy_to_addr_from_regA $var_press_counter

	# 前回の入力状態更新
	lr35902_copy_to_from regA regB
	lr35902_copy_to_addr_from_regA $var_prev_dir_input

	# return
	lr35902_return
}

# 初期化処理
# ※ 使用するレジスタのpush/popをしていない
f_proc_init() {
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

	# 画面更新中フラグをセット
	lr35902_set_reg regA 01
	lr35902_copy_to_addr_from_regA $var_drawing_flag

	# 初期画面描画のエントリをTDQへ積む
	lr35902_call $a_draw_init_tiles

	# 初期表示として、
	# var_exe_1(下位),var_exe_2(上位)のデータをダンプする
	## var_exe_{1,2}をregHLへロード
	lr35902_copy_to_regA_from_addr $var_exe_1
	lr35902_copy_to_from regL regA
	lr35902_copy_to_regA_from_addr $var_exe_2
	lr35902_copy_to_from regH regA

	# ファイル右クリックで呼び出されたか直接起動されたかを判定
	# (var_exe_2(上位)が0x00か否かで判定)
	lr35902_or_to_regA regA
	(
		# var_exe_2 == 0x00
		# (直接起動された)

		# カートリッジRAM enable
		lr35902_set_reg regA $GB_MBC_RAM_EN_VAL
		lr35902_copy_to_addr_from_regA $GB_MBC_RAM_EN_ADDR

		# サイズを0xffffでregBCへ設定
		# 併せて変数へ保存
		lr35902_set_reg regBC ffff
		lr35902_set_reg regA ff
		lr35902_copy_to_addr_from_regA $var_file_size_bh
		lr35902_copy_to_addr_from_regA $var_file_size_th
		lr35902_copy_to_addr_from_regA $var_remain_bytes_bh
		lr35902_copy_to_addr_from_regA $var_remain_bytes_th

		# データ最終アドレスにも0xffffを設定
		lr35902_copy_to_addr_from_regA $var_dadr_last_bh
		lr35902_copy_to_addr_from_regA $var_dadr_last_th

		# この時点のregHLを
		# カーソル位置のデータアドレス変数に設定
		lr35902_copy_to_from regA regL
		lr35902_copy_to_addr_from_regA $var_csl_dadr_bh
		lr35902_copy_to_from regA regH
		lr35902_copy_to_addr_from_regA $var_csl_dadr_th
	) >f_proc_init.1.o
	(
		# var_exe_2 != 0x00
		# (右クリックで呼び出された)

		# サイズをregBCへロード
		# 併せて変数へ保存
		lr35902_copyinc_to_regA_from_ptrHL
		lr35902_copy_to_from regC regA
		lr35902_copy_to_addr_from_regA $var_file_size_bh
		lr35902_copy_to_addr_from_regA $var_remain_bytes_bh
		lr35902_copyinc_to_regA_from_ptrHL
		lr35902_copy_to_from regB regA
		lr35902_copy_to_addr_from_regA $var_file_size_th
		lr35902_copy_to_addr_from_regA $var_remain_bytes_th

		# この時点のregHLはデータ部分の先頭アドレス
		# カーソル位置のデータアドレス変数をこのregHLで初期化
		lr35902_copy_to_from regA regL
		lr35902_copy_to_addr_from_regA $var_csl_dadr_bh
		lr35902_copy_to_from regA regH
		lr35902_copy_to_addr_from_regA $var_csl_dadr_th

		# この時点のregHL(データ先頭アドレス)に
		# データサイズ - 1 を足して、
		# データ最終アドレスを得る
		lr35902_push_reg regHL
		lr35902_add_to_regHL regBC
		## -1の2の補数(0xffff)をregHLへ足す
		lr35902_set_reg regBC ffff
		lr35902_add_to_regHL regBC
		# それを変数へ保存
		lr35902_copy_to_from regA regL
		lr35902_copy_to_addr_from_regA $var_dadr_last_bh
		lr35902_copy_to_from regA regH
		lr35902_copy_to_addr_from_regA $var_dadr_last_th
		lr35902_pop_reg regHL

		# var_exe_3に設定されたファイルタイプを確認
		lr35902_copy_to_regA_from_addr $var_exe_3
		lr35902_compare_regA_and $GBOS_ICON_NUM_EXE
		(
			# 実行ファイル

			# var_disp_dadr_ofs_{th,bh}を設定
			## regHLをregDEへ退避
			lr35902_copy_to_from regE regL
			lr35902_copy_to_from regD regH
			## regHLへregHLの2の補数を設定
			lr35902_copy_to_from regA regL
			lr35902_complement_regA
			lr35902_copy_to_from regL regA
			lr35902_copy_to_from regA regH
			lr35902_complement_regA
			lr35902_copy_to_from regH regA
			lr35902_inc regHL
			## regBCへEXEのロード先アドレスを設定
			lr35902_set_reg regBC $GBOS_APP_MEM_BASE
			## regHL + regBCをregHLへ設定
			lr35902_add_to_regHL regBC
			## regHLをvar_disp_dadr_ofs_{th,bh}へ設定
			lr35902_copy_to_from regA regL
			lr35902_copy_to_addr_from_regA $var_disp_dadr_ofs_bh
			lr35902_copy_to_from regA regH
			lr35902_copy_to_addr_from_regA $var_disp_dadr_ofs_th
			## regHLをregDEから復帰
			lr35902_copy_to_from regL regE
			lr35902_copy_to_from regH regD
		) >f_proc_init.3.o
		local sz_3=$(stat -c '%s' f_proc_init.3.o)
		lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_3)
		cat f_proc_init.3.o

		# var_exe_2 == 0x00 の処理を飛ばす
		local sz_1=$(stat -c '%s' f_proc_init.1.o)
		lr35902_rel_jump $(two_digits_d $sz_1)
	) >f_proc_init.2.o
	local sz_2=$(stat -c '%s' f_proc_init.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	cat f_proc_init.2.o	# var_exe_2 != 0x00
	cat f_proc_init.1.o	# var_exe_2 == 0x00

	# 1画面分ダンプ
	lr35902_call $a_dump_addr_and_data

	# 画面更新中フラグをリセットするエントリをtdqへ積む
	lr35902_clear_reg regB
	lr35902_set_reg regDE $var_drawing_flag
	lr35902_call $a_enq_tdq

	# 初期化済みフラグをセット
	lr35902_copy_to_regA_from_addr $var_general_flgs
	lr35902_set_bitN_of_reg $BE_GFLG_BITNUM_INITED regA
	lr35902_copy_to_addr_from_regA $var_general_flgs

	# return
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

	# 指定されたアドレスから1画面分ダンプ
	f_dump_addr_and_data_4bytes >f_dump_addr_and_data_4bytes.o
	fsz=$(to16 $(stat -c '%s' f_dump_addr_and_data_4bytes.o))
	a_dump_addr_and_data=$(four_digits $(calc16 "${a_dump_addr_and_data_4bytes}+${fsz}"))
	echo -e "a_dump_addr_and_data=$a_dump_addr_and_data" >>$map_file
	f_dump_addr_and_data

	# (主にobjを)元に戻すエントリをtdqへ積む
	f_dump_addr_and_data >f_dump_addr_and_data.o
	fsz=$(to16 $(stat -c '%s' f_dump_addr_and_data.o))
	a_draw_restore_tiles=$(four_digits $(calc16 "${a_dump_addr_and_data}+${fsz}"))
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

	# 方向キーに応じた処理
	f_dec_cursor >f_dec_cursor.o
	fsz=$(to16 $(stat -c '%s' f_dec_cursor.o))
	a_proc_dir_keys=$(four_digits $(calc16 "${a_dec_cursor}+${fsz}"))
	echo -e "a_proc_dir_keys=$a_proc_dir_keys" >>$map_file
	f_proc_dir_keys

	# 初期化処理
	f_proc_dir_keys >f_proc_dir_keys.o
	fsz=$(to16 $(stat -c '%s' f_proc_dir_keys.o))
	a_proc_init=$(four_digits $(calc16 "${a_proc_dir_keys}+${fsz}"))
	echo -e "a_proc_init=$a_proc_init" >>$map_file
	f_proc_init
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
		# 初期化処理を呼び出す
		lr35902_call $a_proc_init

		# pop & return
		lr35902_pop_reg regHL
		lr35902_pop_reg regDE
		lr35902_pop_reg regBC
		lr35902_pop_reg regAF
		lr35902_return
	) >main.1.o

	# フラグ変数の初期化済みフラグチェック
	lr35902_copy_to_regA_from_addr $var_general_flgs
	lr35902_test_bitN_of_reg $BE_GFLG_BITNUM_INITED regA

	# フラグがセットされていたら(初期化済みだったら)、
	# 初期化処理をスキップ
	local sz_1=$(stat -c '%s' main.1.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_1)
	cat main.1.o

	# 定常処理

	# 方向キーに応じた処理
	# ※ 使用するレジスタのpush/popは無し
	lr35902_call $a_proc_dir_keys

	# アプリ用ボタンリリースフラグをregAへ取得
	lr35902_copy_to_regA_from_addr $var_app_release_btn

	# Aボタン(右クリック): 終了
	lr35902_test_bitN_of_reg $GBOS_A_KEY_BITNUM regA
	(
		# Aボタン(右クリック)のリリースがあった場合

		# カートリッジRAM disable
		lr35902_clear_reg regA
		lr35902_copy_to_addr_from_regA $GB_MBC_RAM_EN_ADDR

		# マウスカーソル表示・その他使用したOBJを非表示 のOAM変更をtdqへ積む
		lr35902_call $a_draw_restore_tiles

		# OBJサイズ設定を8x16へ戻す
		lr35902_copy_to_regA_from_ioport $GB_IO_LCDC
		lr35902_set_bitN_of_reg $GB_LCDC_BITNUM_OBJ_SIZE regA
		lr35902_copy_to_ioport_from_regA $GB_IO_LCDC

		# カーネル側でマウスカーソルの更新を再開するように専用の変数を設定
		lr35902_set_reg regA 01
		lr35902_copy_to_addr_from_regA $var_mouse_enable

		# run_exe_cycを終了させる
		lr35902_call $a_exit_exe

		# 実行ファイル用変数をゼロクリア
		lr35902_clear_reg regA
		lr35902_copy_to_addr_from_regA $var_exe_1
		lr35902_copy_to_addr_from_regA $var_exe_2
		lr35902_copy_to_addr_from_regA $var_exe_3

		# 現在のファイルシステムはRAM上か?
		lr35902_copy_to_regA_from_addr $var_fs_base_th
		## カートリッジRAMアドレス上位8ビットと等しいか?
		lr35902_compare_regA_and $(echo $GB_CARTRAM_BASE | cut -c1-2)
		(
			# 等しい(現在RAM上)

			# 安全のため(?)にnopを10個くらい入れておく
			for i in $(seq 10); do
				lr35902_nop
			done

			# カートリッジRAM enable
			lr35902_set_reg regA $GB_MBC_RAM_EN_VAL
			lr35902_copy_to_addr_from_regA $GB_MBC_RAM_EN_ADDR

			# 安全のため(?)にnopを10個くらい入れておく
			for i in $(seq 10); do
				lr35902_nop
			done
		) >main.2.o
		local sz_2=$(stat -c '%s' main.2.o)
		lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_2)
		cat main.2.o

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

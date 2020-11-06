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
}
# 変数設定のために空実行
vars >/dev/null
rm -f $map_file

# 初期配置のタイルをtdqへ積む
# ※ この関数内で使うレジスタは事前のpushと事後のpopをしていない
f_draw_init_tiles() {
	# 操作パネル部
	## 外枠
	### 上部
	#### TODO UPPER_LOWER_BARをデフォのタイルセットへ追加
	# lr35902_set_reg regB $GBOS_TILE_NUM_UPPER_LOWER_BAR
	# lr35902_set_reg regD 98

	# lr35902_set_reg regE 42
	# lr35902_call $a_enq_tdq
	# lr35902_set_reg regE 43
	# lr35902_call $a_enq_tdq

	lr35902_set_reg regB $GBOS_TILE_NUM_UPPER_BAR
	lr35902_set_reg regD 98

	lr35902_set_reg regE 82
	lr35902_call $a_enq_tdq
	lr35902_set_reg regE 83
	lr35902_call $a_enq_tdq

	### 右部
	lr35902_set_reg regB $GBOS_TILE_NUM_LEFT_BAR

	lr35902_set_reg regD 98

	lr35902_set_reg regE 64
	lr35902_call $a_enq_tdq
	lr35902_set_reg regE 84
	lr35902_call $a_enq_tdq
	lr35902_set_reg regE a4
	lr35902_call $a_enq_tdq
	lr35902_set_reg regE c4
	lr35902_call $a_enq_tdq
	lr35902_set_reg regE e4
	lr35902_call $a_enq_tdq

	lr35902_set_reg regD 99

	lr35902_set_reg regE 04
	lr35902_call $a_enq_tdq
	lr35902_set_reg regE 24
	lr35902_call $a_enq_tdq
	lr35902_set_reg regE 44
	lr35902_call $a_enq_tdq
	lr35902_set_reg regE 64
	lr35902_call $a_enq_tdq
	lr35902_set_reg regE 84
	lr35902_call $a_enq_tdq
	lr35902_set_reg regE a4
	lr35902_call $a_enq_tdq
	lr35902_set_reg regE c4
	lr35902_call $a_enq_tdq
	lr35902_set_reg regE e4
	lr35902_call $a_enq_tdq

	### 下部
	lr35902_set_reg regB $GBOS_TILE_NUM_LOWER_BAR

	lr35902_set_reg regE c3
	lr35902_call $a_enq_tdq
	lr35902_set_reg regE c2
	lr35902_call $a_enq_tdq

	#### TODO UPPER_LOWER_BARをデフォのタイルセットへ追加
	# lr35902_set_reg regB $GBOS_TILE_NUM_UPPER_LOWER_BAR
	# lr35902_set_reg regD 9a

	# lr35902_set_reg regE 03
	# lr35902_call $a_enq_tdq
	# lr35902_set_reg regE 02
	# lr35902_call $a_enq_tdq

	### 左部
	#### TODO LEFT_RIGHT_BARをデフォのタイルセットへ追加

	### パネル部
	lr35902_set_reg regD 98

	lr35902_set_reg regB $(get_num_tile_num 00)
	lr35902_set_reg regE a2
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_num_tile_num 01)
	lr35902_set_reg regE a3
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_num_tile_num 02)
	lr35902_set_reg regE c2
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_num_tile_num 03)
	lr35902_set_reg regE c3
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_num_tile_num 04)
	lr35902_set_reg regE e2
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_num_tile_num 05)
	lr35902_set_reg regE e3
	lr35902_call $a_enq_tdq

	lr35902_set_reg regD 99

	lr35902_set_reg regB $(get_num_tile_num 06)
	lr35902_set_reg regE 02
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_num_tile_num 07)
	lr35902_set_reg regE 03
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_num_tile_num 08)
	lr35902_set_reg regE 22
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_num_tile_num 09)
	lr35902_set_reg regE 23
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_alpha_tile_num A)
	lr35902_set_reg regE 42
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_alpha_tile_num B)
	lr35902_set_reg regE 43
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_alpha_tile_num C)
	lr35902_set_reg regE 62
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_alpha_tile_num D)
	lr35902_set_reg regE 63
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_alpha_tile_num E)
	lr35902_set_reg regE 82
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_alpha_tile_num F)
	lr35902_set_reg regE 83
	lr35902_call $a_enq_tdq

	# メモリダンプ部
	lr35902_set_reg regD 98

	lr35902_set_reg regB $(get_alpha_tile_num A)
	lr35902_set_reg regE 65
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_alpha_tile_num D)
	lr35902_set_reg regE 66
	lr35902_call $a_enq_tdq
	lr35902_set_reg regE 67
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_alpha_tile_num R)
	lr35902_set_reg regE 68
	lr35902_call $a_enq_tdq

	lr35902_set_reg regB $(get_num_tile_num 00)
	lr35902_set_reg regE 6B
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_num_tile_num 01)
	lr35902_set_reg regE 6D
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_num_tile_num 02)
	lr35902_set_reg regE 6F
	lr35902_call $a_enq_tdq
	lr35902_set_reg regB $(get_num_tile_num 03)
	lr35902_set_reg regE 71
	lr35902_call $a_enq_tdq

	# return
	lr35902_return
}

# 指定したアドレスから4バイトダンプ
# in : regH - ダンプするアドレス[15:8]
#    : regL - ダンプするアドレス[7:0]
#    : regD - 描画先アドレス[15:8]
#    : regE - 描画先アドレス[7:0]
# out: regHL- +4されて戻る
#    : regDE- +0x0cされて戻る
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

	# pop & return
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

		# 初期画面描画のエントリをTDQへ積む
		lr35902_call $a_draw_init_tiles

		# TODO ウィンドウの▲▼を使ってページ移動できるように

		# var_exe_1(下位),var_exe_2(上位)のアドレスをダンプする
		## var_exe_{1,2}をregHLへロード
		lr35902_copy_to_regA_from_addr $var_exe_1
		lr35902_copy_to_from regL regA
		lr35902_copy_to_regA_from_addr $var_exe_2
		lr35902_copy_to_from regH regA
		## サイズをregBCへロード
		lr35902_copyinc_to_regA_from_ptrHL
		lr35902_copy_to_from regC regA
		lr35902_copyinc_to_regA_from_ptrHL
		lr35902_copy_to_from regB regA
		## 描画先アドレスの初期値設定
		lr35902_set_reg regD 98
		lr35902_set_reg regE 85
		### ただし、今は12行分のデータ出力固定
		### TODO サイズに応じた分だけダンプするように
		lr35902_set_reg regC 0c
		## 12行分のループ処理
		(
			# 1行ダンプ
			lr35902_call $a_dump_addr_and_data_4bytes

			# regDE(描画先アドレス)に0x14を加算
			lr35902_push_reg regHL
			lr35902_clear_reg regH
			lr35902_set_reg regL 14
			lr35902_add_to_regHL regDE
			lr35902_copy_to_from regD regH
			lr35902_copy_to_from regE regL
			lr35902_pop_reg regHL

			# カウンタをデクリメント
			lr35902_dec regC
		) >main.10.o
		cat main.10.o
		local sz_10=$(stat -c '%s' main.10.o)
		lr35902_rel_jump_with_cond NZ $(two_comp_d $((sz_10 + 2)))

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

	# アプリ用ボタンリリースフラグをregAへ取得
	lr35902_copy_to_regA_from_addr $var_app_release_btn

	# Aボタン(右クリック): 終了
	lr35902_test_bitN_of_reg $GBOS_A_KEY_BITNUM regA
	(
		# Aボタン(右クリック)のリリースがあった場合

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

	# Bボタン(左クリック): マウスカーソルの座標へ黒タイル配置
	lr35902_test_bitN_of_reg $GBOS_B_KEY_BITNUM regA
	(
		# Bボタン(左クリック)のリリースがあった場合

		# ボタンリリース状態をregCへ取っておく
		lr35902_copy_to_from regC regA

		# マウスカーソルの座標を取得
		## タイル座標Y -> regD
		### マウスカーソルY座標 -> regA
		lr35902_copy_to_regA_from_addr $var_mouse_y
		### regA - 16 -> regA
		lr35902_set_reg regB 10
		lr35902_sub_to_regA regB
		### regAを3ビット右シフト
		lr35902_set_carry
		lr35902_comp_carry
		lr35902_rot_regA_right_th_carry
		lr35902_set_carry
		lr35902_comp_carry
		lr35902_rot_regA_right_th_carry
		lr35902_set_carry
		lr35902_comp_carry
		lr35902_rot_regA_right_th_carry
		### regA -> regD
		lr35902_copy_to_from regD regA

		## タイル座標X -> regE
		### マウスカーソルX座標 -> regA
		lr35902_copy_to_regA_from_addr $var_mouse_x
		### regA - 8 -> regA
		lr35902_set_reg regB 08
		lr35902_sub_to_regA regB
		### regAを3ビット右シフト
		lr35902_set_carry
		lr35902_comp_carry
		lr35902_rot_regA_right_th_carry
		lr35902_set_carry
		lr35902_comp_carry
		lr35902_rot_regA_right_th_carry
		lr35902_set_carry
		lr35902_comp_carry
		lr35902_rot_regA_right_th_carry
		### regA -> regE
		lr35902_copy_to_from regE regA

		# 黒タイル配置
		lr35902_call $a_tcoord_to_addr
		lr35902_copy_to_from regD regH
		lr35902_copy_to_from regE regL
		lr35902_set_reg regB $GBOS_TILE_NUM_BLACK
		lr35902_call $a_enq_tdq

		# アプリ用ボタンリリースフラグのBボタン(左クリック)をクリア
		lr35902_copy_to_from regA regC
		lr35902_res_bitN_of_reg $GBOS_B_KEY_BITNUM regA
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

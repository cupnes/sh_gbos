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

vars() {
	# 汎用フラグ変数
	var_general_flgs=$APP_VARS_BASE
	echo -e "var_general_flgs=$var_general_flgs" >>$map_file
	echo -en '\x00'	# 全て0
}

# 指定したセルの生死を取得
# in : regD  - タイル座標Y
#      regE  - タイル座標X
# out: regA  - 生(=1)死(=0)
f_get_cell_is_alive() {
	# D < $GBOS_WIN_DRAWABLE_BASE_YT だったらreturn
}

funcs() {
	# 指定したセルの生死を取得
	a_get_cell_is_alive=$APP_FUNCS_BASE
	echo -e "a_get_cell_is_alive=$a_get_cell_is_alive" >>$map_file
	f_get_cell_is_alive
}

init_glider() {
	local base_x=$GBOS_WIN_DRAWABLE_BASE_XT
	local base_y=$GBOS_WIN_DRAWABLE_BASE_YT

	lr35902_set_reg regA $GBOS_TILE_NUM_BLACK

	lr35902_set_reg regD $base_y
	lr35902_set_reg regE $(calc16_2 "$base_x+1")
	lr35902_call $a_lay_tile_at_wtcoord

	lr35902_set_reg regD $(calc16_2 "$base_y+1")
	lr35902_set_reg regE $(calc16_2 "$base_x+2")
	lr35902_call $a_lay_tile_at_wtcoord

	lr35902_set_reg regC 03
	lr35902_set_reg regD $(calc16_2 "$base_y+2")
	lr35902_set_reg regE $base_x
	lr35902_call $a_lay_tiles_at_wtcoord_to_right
}

# tdqへエントリを追加するマクロ
# in : regB  - 配置するタイル番号
#      regD  - VRAMアドレス[15:8]
#      regE  - VRAMアドレス[7:0]
tdq_enqueue() {
	# TODO tdq.stat に is_full がセットされていたら以降の処理をスキップ
	lr35902_copy_to_regA_from_addr $var_tdq_stat
	lr35902_test_bitN_of_reg $GBOS_TDQ_STAT_BITNUM_FULL regA
	(
		# Aへロードしたtdq.statをCへコピー
		lr35902_copy_to_from regC regA

		# tdq.tailが指す位置に追加
		lr35902_copy_to_regA_from_addr $var_tdq_tail_bh
		lr35902_copy_to_from regL regA
		lr35902_copy_to_regA_from_addr $var_tdq_tail_th
		lr35902_copy_to_from regH regA

		lr35902_copy_to_from regA regE
		lr35902_copyinc_to_ptrHL_from_regA
		lr35902_copy_to_from regA regD
		lr35902_copyinc_to_ptrHL_from_regA
		lr35902_copy_to_from regA regB
		lr35902_copyinc_to_ptrHL_from_regA

		# HL == TDQ_END だったら HL = TDQ_FIRST
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
			) >tdq_enqueue.1.o
			local sz_1=$(stat -c '%s' tdq_enqueue.1.o)
			lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_1)
			cat tdq_enqueue.1.o
		) >tdq_enqueue.2.o
		local sz_2=$(stat -c '%s' tdq_enqueue.2.o)
		lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_2)
		cat tdq_enqueue.2.o

		lr35902_copy_to_from regA regL
		lr35902_copy_to_addr_from_regA $var_tdq_tail_bh
		lr35902_copy_to_from regA regH
		lr35902_copy_to_addr_from_regA $var_tdq_tail_th

		# HL == tdq.head だったら tdq.stat に is_full ビットをセット
		# tdq.head[7:0] == tdq.tail[7:0] ?
		lr35902_copy_to_regA_from_addr $var_tdq_head_bh
		lr35902_compare_regA_and regL
		(
			# tdq.head[7:0] == tdq.tail[7:0]

			# tdq.head[15:8] == tdq.tail[15:8] ?
			lr35902_copy_to_regA_from_addr $var_tdq_head_th
			lr35902_compare_regA_and regH
			(
				# tdq.head[15:8] == tdq.tail[15:8]

				# C に full ビットをセット
				lr35902_set_bitN_of_reg $GBOS_TDQ_STAT_BITNUM_FULL regC
			) >tdq_enqueue.3.o
			local sz_3=$(stat -c '%s' tdq_enqueue.3.o)
			lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_3)
			cat tdq_enqueue.3.o
		) >tdq_enqueue.4.o
		local sz_4=$(stat -c '%s' tdq_enqueue.4.o)
		lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_4)
		cat tdq_enqueue.4.o

		# C の empty フラグをクリア
		lr35902_res_bitN_of_reg $GBOS_TDQ_STAT_BITNUM_EMPTY regC

		# tdq.stat = C
		lr35902_copy_to_from regA regC
		lr35902_copy_to_addr_from_regA $var_tdq_stat
	) >tdq_enqueue.5.o
	local sz_5=$(stat -c '%s' tdq_enqueue.5.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_5)
	cat tdq_enqueue.5.o
}

# 指定した座標のセルを更新
# in : regD  - タイル座標Y
#      regE  - タイル座標X
update_cell() {
	lr35902_call $a_tcoord_to_mrraddr
}

main() {
	local flg_bitnum_inited=0

	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	# フラグ変数の初期化済みフラグチェック
	lr35902_copy_to_regA_from_addr $VARS_BASE
	lr35902_test_bitN_of_reg $flg_bitnum_inited regA

	# フラグがセットされていたら(初期化済みだったら)、
	# 初期化処理をスキップ

	(
		# 定常処理
		lr35902_set_reg regD 03
		lr35902_set_reg regE 02
		update_cell
	) >main.2.o

	(
		# 初期化処理
		init_glider

		# 初期化済みフラグをセット
		lr35902_copy_to_regA_from_addr $VARS_BASE
		lr35902_set_bitN_of_reg $flg_bitnum_inited regA
		lr35902_copy_to_addr_from_regA $VARS_BASE

		# 定常処理をスキップ
		local sz_2=$(stat -c '%s' main.2.o)
		lr35902_rel_jump $(two_digits_d $sz_2)
	) >main.1.o

	local sz_1=$(stat -c '%s' main.1.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_1)
	cat main.1.o
	cat main.2.o

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
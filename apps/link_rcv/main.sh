#!/bin/bash

set -uex
# set -ue

# TODO シリアル通信プログラム

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

# 死んでいるセルのタイル番号は0である前提で作られている
LG_DEAD_TILE_NO=$GBOS_TILE_NUM_SPC	# =0
LG_LIVE_TILE_NO=$GBOS_TILE_NUM_BLACK

vars() {
	# 汎用フラグ変数
	var_debug=$APP_VARS_BASE
	echo -e "var_debug=$var_debug" >>$map_file
	echo -en '\x00'	# 全て0
}
# 変数設定のために空実行
vars >/dev/null
rm -f $map_file

# 指定したセルの生死を取得
# in : regD  - タイル座標Y
#      regE  - タイル座標X
# out: regA  - 生(=1)死(=0)
f_get_cell_is_alive() {
	# push
	lr35902_set_reg regA 00	# 戻り値は死(0)で初期化
	lr35902_push_reg regAF

	lr35902_copy_to_from regA regD

	# D < $GBOS_WIN_DRAWABLE_BASE_YT ならreturn
	# (D >= $GBOS_WIN_DRAWABLE_BASE_YT ならreturn処理をスキップ)
	lr35902_compare_regA_and $GBOS_WIN_DRAWABLE_BASE_YT
	(
		# pop & return
		lr35902_pop_reg regAF
		lr35902_return
	) >f_get_cell_is_alive.1.o
	local sz_1=$(stat -c '%s' f_get_cell_is_alive.1.o)
	lr35902_rel_jump_with_cond NC $(two_digits_d $sz_1)
	cat f_get_cell_is_alive.1.o

	# D >= ($GBOS_WIN_DRAWABLE_BASE_YT + $GBOS_WIN_DRAWABLE_HEIGHT_T) ならreturn
	# (D < ($GBOS_WIN_DRAWABLE_BASE_YT + $GBOS_WIN_DRAWABLE_HEIGHT_T) ならreturn処理をスキップ)
	lr35902_compare_regA_and $(calc16 "$GBOS_WIN_DRAWABLE_BASE_YT+$GBOS_WIN_DRAWABLE_HEIGHT_T")
	(
		# pop & return
		lr35902_pop_reg regAF
		lr35902_return
	) >f_get_cell_is_alive.2.o
	local sz_2=$(stat -c '%s' f_get_cell_is_alive.2.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $sz_2)
	cat f_get_cell_is_alive.2.o

	lr35902_copy_to_from regA regE

	# E < $GBOS_WIN_DRAWABLE_BASE_XT だったらreturn
	# (E >= $GBOS_WIN_DRAWABLE_BASE_XT ならreturn処理をスキップ)
	lr35902_compare_regA_and $GBOS_WIN_DRAWABLE_BASE_XT
	(
		# pop & return
		lr35902_pop_reg regAF
		lr35902_return
	) >f_get_cell_is_alive.3.o
	local sz_3=$(stat -c '%s' f_get_cell_is_alive.3.o)
	lr35902_rel_jump_with_cond NC $(two_digits_d $sz_3)
	cat f_get_cell_is_alive.3.o

	# E >= ($GBOS_WIN_DRAWABLE_BASE_XT + $GBOS_WIN_DRAWABLE_WIDTH_T) ならreturn
	# (E < ($GBOS_WIN_DRAWABLE_BASE_XT + $GBOS_WIN_DRAWABLE_WIDTH_T) ならreturn処理をスキップ)
	lr35902_compare_regA_and $(calc16 "$GBOS_WIN_DRAWABLE_BASE_XT+$GBOS_WIN_DRAWABLE_WIDTH_T")
	(
		# pop & return
		lr35902_pop_reg regAF
		lr35902_return
	) >f_get_cell_is_alive.4.o
	local sz_4=$(stat -c '%s' f_get_cell_is_alive.4.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $sz_4)
	cat f_get_cell_is_alive.4.o

	# push
	lr35902_push_reg regHL

	# (E, D) のミラータイル値を取得
	lr35902_call $a_tcoord_to_mrraddr
	lr35902_copy_to_from regA ptrHL

	# 生死判定
	lr35902_compare_regA_and $GBOS_TILE_NUM_SPC
	(
		# A != $GBOS_TILE_NUM_SPC (生)
		lr35902_pop_reg regHL
		lr35902_pop_reg regAF
		lr35902_set_reg regA 01
		lr35902_return
	) >f_get_cell_is_alive.5.o
	local sz_5=$(stat -c '%s' f_get_cell_is_alive.5.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_5)
	cat f_get_cell_is_alive.5.o

	# A == $GBOS_TILE_NUM_SPC (死)
	# pop & return
	lr35902_pop_reg regHL
	lr35902_pop_reg regAF
	lr35902_set_reg regA 00
	lr35902_return
}

# tdqへエントリを追加する
# in : regB  - 配置するタイル番号
#      regD  - VRAMアドレス[15:8]
#      regE  - VRAMアドレス[7:0]
f_tdq_enq() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

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

	# pop & return
	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

# 指定したセルの8近傍の生きているセルの数を返す
# in : regD  - タイル座標Y
#      regE  - タイル座標X
# out: regA  - 8近傍の生きているセルの数
get_num_live_cells_8_neighbors() {
	# カウンタクリア
	lr35902_clear_reg regC

	# get (X - 1, Y - 1)
	lr35902_dec regD
	lr35902_dec regE
	lr35902_call $a_get_cell_is_alive
	lr35902_copy_to_from regC regA

	# get (X, Y - 1)
	lr35902_inc regE
	lr35902_call $a_get_cell_is_alive
	lr35902_add_to_regA regC
	lr35902_copy_to_from regC regA

	# get (X + 1, Y - 1)
	lr35902_inc regE
	lr35902_call $a_get_cell_is_alive
	lr35902_add_to_regA regC
	lr35902_copy_to_from regC regA

	# get (X + 1, Y)
	lr35902_inc regD
	lr35902_call $a_get_cell_is_alive
	lr35902_add_to_regA regC
	lr35902_copy_to_from regC regA

	# get (X + 1, Y + 1)
	lr35902_inc regD
	lr35902_call $a_get_cell_is_alive
	lr35902_add_to_regA regC
	lr35902_copy_to_from regC regA

	# get (X, Y + 1)
	lr35902_dec regE
	lr35902_call $a_get_cell_is_alive
	lr35902_add_to_regA regC
	lr35902_copy_to_from regC regA

	# get (X - 1, Y + 1)
	lr35902_dec regE
	lr35902_call $a_get_cell_is_alive
	lr35902_add_to_regA regC
	lr35902_copy_to_from regC regA

	# get (X - 1, Y)
	lr35902_dec regD
	lr35902_call $a_get_cell_is_alive
	lr35902_add_to_regA regC

	# (X, Y) へ戻す
	lr35902_inc regE
}

# 指定した座標のセルを更新
# in : regD  - タイル座標Y
#      regE  - タイル座標X
f_update_cell() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	# 8近傍の生きているセルの数をCへ取得
	get_num_live_cells_8_neighbors
	lr35902_copy_to_from regC regA

	# 指定された座標のVRAMアドレスをHLへ取得
	lr35902_call $a_tcoord_to_addr

	# 指定されたセルの生死を確認
	lr35902_call $a_get_cell_is_alive
	lr35902_compare_regA_and 00
	(
		# 指定されたセルが死んでいる場合

		# C == 3 ?
		lr35902_copy_to_from regA regC
		lr35902_compare_regA_and 03
		(
			# C == 3

			# tdq.enq($LG_LIVE_TILE_NO, H, L)
			lr35902_set_reg regB $LG_LIVE_TILE_NO
			lr35902_copy_to_from regD regH
			lr35902_copy_to_from regE regL
			lr35902_call $a_tdq_enq
		) >update_cell.3.o
		local sz_3=$(stat -c '%s' update_cell.3.o)
		lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_3)
		cat update_cell.3.o
	) >update_cell.1.o
	(
		# 指定されたセルが生きている場合

		lr35902_copy_to_from regA regC

		# C < 2 ?
		lr35902_compare_regA_and 02
		(
			# C < 2

			# tdq.enq($LG_DEAD_TILE_NO, H, L)
			lr35902_set_reg regB $LG_DEAD_TILE_NO
			lr35902_copy_to_from regD regH
			lr35902_copy_to_from regE regL
			lr35902_call $a_tdq_enq
		) >update_cell.4.o
		local sz_4=$(stat -c '%s' update_cell.4.o)
		lr35902_rel_jump_with_cond NC $(two_digits_d $sz_4)
		cat update_cell.4.o

		# C >= 4 ?
		lr35902_compare_regA_and 04
		(
			# C >= 4

			# tdq.enq($LG_DEAD_TILE_NO, H, L)
			lr35902_set_reg regB $LG_DEAD_TILE_NO
			lr35902_copy_to_from regD regH
			lr35902_copy_to_from regE regL
			lr35902_call $a_tdq_enq
		) >update_cell.5.o
		local sz_5=$(stat -c '%s' update_cell.5.o)
		lr35902_rel_jump_with_cond C $(two_digits_d $sz_5)
		cat update_cell.5.o

		# 死んでいる場合の処理を飛ばす
		local sz_1=$(stat -c '%s' update_cell.1.o)
		lr35902_rel_jump $(two_digits_d $sz_1)
	) >update_cell.2.o
	local sz_2=$(stat -c '%s' update_cell.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	cat update_cell.2.o
	cat update_cell.1.o

	# pop & return
	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
	lr35902_return
}

funcs() {
	local fsz

	# 指定したセルの生死を取得
	a_get_cell_is_alive=$APP_FUNCS_BASE
	echo -e "a_get_cell_is_alive=$a_get_cell_is_alive" >>$map_file
	f_get_cell_is_alive

	# tdqへエントリを追加する
	f_get_cell_is_alive >f_get_cell_is_alive.o
	fsz=$(to16 $(stat -c '%s' f_get_cell_is_alive.o))
	a_tdq_enq=$(four_digits $(calc16 "${a_get_cell_is_alive}+${fsz}"))
	echo -e "a_tdq_enq=$a_tdq_enq" >>$map_file
	f_tdq_enq

	# 指定した座標のセルを更新
	f_tdq_enq >f_tdq_enq.o
	fsz=$(to16 $(stat -c '%s' f_tdq_enq.o))
	a_update_cell=$(four_digits $(calc16 "${a_tdq_enq}+${fsz}"))
	echo -e "a_update_cell=$a_update_cell" >>$map_file
	f_update_cell
}
# 変数設定のために空実行
funcs >/dev/null
rm -f $map_file

init_rnd() {
	lr35902_set_reg regB $GBOS_TILE_NUM_BLACK
	lr35902_set_reg regD $GBOS_WIN_DRAWABLE_BASE_YT
	(
		lr35902_set_reg regE $GBOS_WIN_DRAWABLE_BASE_XT
		(
			lr35902_copy_to_regA_from_ioport $GB_IO_TIMA
			lr35902_test_bitN_of_reg 0 regA
			(
				lr35902_push_reg regDE

				lr35902_call $a_tcoord_to_addr
				lr35902_copy_to_from regD regH
				lr35902_copy_to_from regE regL
				lr35902_call $a_tdq_enq

				lr35902_pop_reg regDE
			) >init_rnd.1.o
			local sz_1=$(stat -c '%s' init_rnd.1.o)
			lr35902_rel_jump_with_cond Z $(two_digits_d $sz_1)
			cat init_rnd.1.o

			lr35902_inc regE
			lr35902_copy_to_from regA regE
			lr35902_compare_regA_and $(calc16_2 "$GBOS_WIN_DRAWABLE_BASE_XT+$GBOS_WIN_DRAWABLE_WIDTH_T")
		) >init_rnd.2.o
		cat init_rnd.2.o
		local sz_2=$(stat -c '%s' init_rnd.2.o)
		lr35902_rel_jump_with_cond C $(two_comp_d $((sz_2 + 2)))

		lr35902_inc regD
		lr35902_copy_to_from regA regD
		lr35902_compare_regA_and $(calc16_2 "$GBOS_WIN_DRAWABLE_BASE_YT+$GBOS_WIN_DRAWABLE_HEIGHT_T")
	) >init_rnd.3.o
	cat init_rnd.3.o
	local sz_3=$(stat -c '%s' init_rnd.3.o)
	lr35902_rel_jump_with_cond C $(two_comp_d $((sz_3 + 2)))

	# var_draw_cycを1にするエントリを積む
	lr35902_set_reg regB 01
	lr35902_set_reg regD $(echo $var_draw_cyc | cut -c1-2)
	lr35902_set_reg regE $(echo $var_draw_cyc | cut -c3-4)
	lr35902_call $a_tdq_enq
}



main() {
	# push
	lr35902_push_reg regAF

	lr35902_clear_reg regA
	lr35902_copy_to_ioport_from_regA $GB_IO_SC

	(
		lr35902_copy_to_regA_from_ioport $GB_IO_SB
		lr35902_compare_regA_and 00
		(
			lr35902_copy_to_addr_from_regA $var_debug
		) >main.1.o
		local sz_1=$(stat -c '%s' main.1.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_1)
		cat main.1.o
	) >main.2.o
	cat main.2.o
	local sz_2=$(stat -c '%s' main.2.o)
	lr35902_rel_jump $(two_comp_d $((sz_2 + 2)))

	# pop & return
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

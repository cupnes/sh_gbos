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
# 変数設定のために空実行
vars >/dev/null
rm -f $map_file

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
	local flg_bitnum_inited=0

	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	# フラグ変数の初期化済みフラグチェック
	lr35902_copy_to_regA_from_addr $APP_VARS_BASE
	lr35902_test_bitN_of_reg $flg_bitnum_inited regA

	# フラグがセットされていたら(初期化済みだったら)、
	# 初期化処理をスキップ

	(
		# 定常処理

		# Aボタン(右クリック)で終了
		lr35902_copy_to_regA_from_addr $var_app_release_btn
		lr35902_test_bitN_of_reg $GBOS_A_KEY_BITNUM regA
		(
			# Aボタン(右クリック)のリリースがあった場合

			# DAS: run_exeをクリア
			lr35902_copy_to_regA_from_addr $var_draw_act_stat
			lr35902_res_bitN_of_reg $GBOS_DA_BITNUM_RUN_EXE regA
			lr35902_copy_to_addr_from_regA $var_draw_act_stat

			# tdq初期化
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

			# LCDCへOBJ表示設定
			lr35902_copy_to_regA_from_ioport $GB_IO_LCDC
			lr35902_set_bitN_of_reg $GB_LCDC_BITNUM_OE regA
			lr35902_copy_to_ioport_from_regA $GB_IO_LCDC

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

		# 処理中周期(A) < 描画中周期(B) だったらreturn処理をスキップ
		lr35902_copy_to_regA_from_addr $var_draw_cyc
		lr35902_copy_to_from regB regA
		lr35902_copy_to_regA_from_addr $var_proc_cyc
		lr35902_compare_regA_and regB
		(
			# pop & return
			lr35902_pop_reg regHL
			lr35902_pop_reg regDE
			lr35902_pop_reg regBC
			lr35902_pop_reg regAF
			lr35902_return
		) >main.3.o
		local sz_3=$(stat -c '%s' main.3.o)
		lr35902_rel_jump_with_cond C $(two_digits_d $sz_3)
		cat main.3.o

		# 更新処理
		# Y(regD)= 03 - 0f, X(regE)= 02 - 11 で update_cell() を呼び出す
		lr35902_set_reg regD $GBOS_WIN_DRAWABLE_BASE_YT
		(
			lr35902_set_reg regE $GBOS_WIN_DRAWABLE_BASE_XT

			(
				lr35902_call $a_update_cell

				lr35902_inc regE
				lr35902_copy_to_from regA regE
				lr35902_compare_regA_and $(calc16_2 "$GBOS_WIN_DRAWABLE_BASE_XT+$GBOS_WIN_DRAWABLE_WIDTH_T")
			) >main.4.o
			cat main.4.o
			local sz_4=$(stat -c '%s' main.4.o)
			lr35902_rel_jump_with_cond C $(two_comp_d $((sz_4 + 2)))

			lr35902_inc regD
			lr35902_copy_to_from regA regD
			lr35902_compare_regA_and $(calc16_2 "$GBOS_WIN_DRAWABLE_BASE_YT+$GBOS_WIN_DRAWABLE_HEIGHT_T")
		) >main.5.o
		cat main.5.o
		local sz_5=$(stat -c '%s' main.5.o)
		lr35902_rel_jump_with_cond C $(two_comp_d $((sz_5 + 2)))

		# var_draw_cycをインクリメントするエントリを積む
		lr35902_copy_to_regA_from_addr $var_draw_cyc
		lr35902_inc regA
		lr35902_copy_to_from regB regA
		lr35902_set_reg regD $(echo $var_draw_cyc | cut -c1-2)
		lr35902_set_reg regE $(echo $var_draw_cyc | cut -c3-4)
		lr35902_call $a_tdq_enq

		# var_proc_cycをインクリメント
		lr35902_copy_to_regA_from_addr $var_proc_cyc
		lr35902_inc regA
		lr35902_copy_to_addr_from_regA $var_proc_cyc
	) >main.2.o

	(
		# LCDCへOBJ非表示設定
		lr35902_copy_to_regA_from_ioport $GB_IO_LCDC
		lr35902_res_bitN_of_reg $GB_LCDC_BITNUM_OE regA
		lr35902_copy_to_ioport_from_regA $GB_IO_LCDC

		# アプリ用リリースボタンフラグをクリア
		lr35902_clear_reg regA
		lr35902_copy_to_addr_from_regA $var_app_release_btn

		# 初期パターン配置
		init_rnd

		# 初期化済みフラグをセット
		lr35902_copy_to_regA_from_addr $APP_VARS_BASE
		lr35902_set_bitN_of_reg $flg_bitnum_inited regA
		lr35902_copy_to_addr_from_regA $APP_VARS_BASE

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

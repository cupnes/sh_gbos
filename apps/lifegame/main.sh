#!/bin/bash

set -uex
# set -ue

. include/gb.sh
. include/map.sh
. include/vars.sh
. include/tiles.sh
. include/gbos.sh
. include/tdq.sh

VARS_BASE=$GB_WRAM1_BASE	# make_bin()で更新する

vars() {
	# 汎用フラグ変数
	echo -en '\x00'	# 全て0
	echo -en '\x00'
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

main() {
	local flg_bitnum_inited=0

	# push
	lr35902_push_reg regAF

	# フラグ変数の初期化済みフラグチェック
	lr35902_copy_to_regA_from_addr $VARS_BASE
	lr35902_test_bitN_of_reg $flg_bitnum_inited regA

	# フラグがセットされていたら(初期化済みだったら)、
	# 初期化処理をスキップ

	(
		# 定常処理

		local var_blink_tile_flg=$(calc16 "$VARS_BASE+1")
		lr35902_copy_to_regA_from_addr $var_blink_tile_flg
		lr35902_xor_to_regA 01
		(
			# A == 0
			lr35902_set_reg regB $GBOS_TILE_NUM_SPC
		) >main.4.o
		(
			# A != 0
			lr35902_set_reg regB $GBOS_TILE_NUM_BLACK

			# A == 0 の処理を飛ばす
			local sz_4=$(stat -c '%s' main.4.o)
			lr35902_rel_jump $(two_digits_d $sz_4)
		) >main.3.o
		local sz_3=$(stat -c '%s' main.3.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_3)
		cat main.3.o	# A != 0
		cat main.4.o	# A == 0
		lr35902_copy_to_addr_from_regA $var_blink_tile_flg

		local blink_tile_addr_bh=66
		local blink_tile_addr_th=98
		lr35902_set_reg regE $blink_tile_addr_bh
		lr35902_set_reg regD $blink_tile_addr_th

		tdq_enqueue
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
	lr35902_pop_reg regAF
	lr35902_return
}

make_bin() {
	# vars.o生成
	vars >vars.o

	# main.oのサイズ確認
	main >main.o
	local sz_main=$(stat -c '%s' main.o)
	local sz_main16=$(to16 $sz_main)

	# 変数領域ベースアドレス算出
	VARS_BASE=$(calc16 "$VARS_BASE + $sz_main16")

	# main.o再生成
	main >main.o

	# 結合
	cat main.o vars.o
}

make_bin

#!/bin/bash

set -uex
# set -ue

. include/gb.sh
. include/map.sh
. include/tiles.sh
. include/gbos.sh

VARS_BASE=$GB_WRAM1_BASE	# make_bin()で更新する

vars() {
	# 汎用フラグ変数
	echo -en '\x00'	# 全て0
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
		# 初期化処理
		init_glider

		# 初期化済みフラグをセット
		lr35902_copy_to_regA_from_addr $VARS_BASE
		lr35902_set_bitN_of_reg $flg_bitnum_inited regA
		lr35902_copy_to_addr_from_regA $VARS_BASE
	) >main.1.o
	local sz_1=$(stat -c '%s' main.1.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_1)
	cat main.1.o

	# (
	# 	# 定常処理
	# )

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

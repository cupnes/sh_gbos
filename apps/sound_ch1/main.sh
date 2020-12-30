#!/bin/bash

# サウンドテスト

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
	# 初期化済みフラグ
	var_is_inited=$APP_VARS_BASE
	echo -e "var_is_inited=$var_is_inited" >>$map_file
	echo -en '\x00'
}
# 変数設定のために空実行
vars >/dev/null
rm -f $map_file

funcs() {
	:
}
# 変数設定のために空実行
funcs >/dev/null
rm -f $map_file

init() {
	# サウンド有効化
	lr35902_copy_to_regA_from_ioport $GB_IO_NR52
	lr35902_set_bitN_of_reg $GB_NR52_BITNUM_ALL_ONOFF regA
	lr35902_copy_to_ioport_from_regA $GB_IO_NR52

	# ボリュームを半分程に設定
	local s02_lv=$(to16 $((GBOS_NR50_DEF_S02_LV << GB_NR50_BIT_S02_LV_SHIFT)))
	local s01_lv=$(to16 $((GBOS_NR50_DEF_S01_LV << GB_NR50_BIT_S01_LV_SHIFT)))
	lr35902_set_reg regA $(calc16 "$GB_NR50_BIT_VIN_SO2_EN+$s02_lv+$GB_NR50_BIT_VIN_SO1_EN+$s01_lv")
	lr35902_copy_to_ioport_from_regA $GB_IO_NR50

	# サウンド出力設定
	lr35902_set_reg regA ff
	lr35902_copy_to_ioport_from_regA $GB_IO_NR51

	# ch1: 有効化
	lr35902_set_reg regA f8
	lr35902_copy_to_ioport_from_regA $GB_IO_NR12
	lr35902_set_reg regA 80
	lr35902_copy_to_ioport_from_regA $GB_IO_NR14

	# ch2: ミュート
	lr35902_clear_reg regA
	lr35902_copy_to_ioport_from_regA $GB_IO_NR22
	lr35902_set_reg regA 80
	lr35902_copy_to_ioport_from_regA $GB_IO_NR24

	# ch3: ミュート
	lr35902_clear_reg regA
	lr35902_copy_to_ioport_from_regA $GB_IO_NR30
	lr35902_copy_to_ioport_from_regA $GB_IO_NR32
	lr35902_set_reg regA 80
	lr35902_copy_to_ioport_from_regA $GB_IO_NR34

	# ch4: ミュート
	lr35902_clear_reg regA
	lr35902_copy_to_ioport_from_regA $GB_IO_NR42
	lr35902_set_reg regA 80
	lr35902_copy_to_ioport_from_regA $GB_IO_NR44

	# 初期化済みフラグをセットする
	lr35902_set_reg regA 01
	lr35902_copy_to_addr_from_regA $var_is_inited
}

main() {
	# push
	lr35902_push_reg regAF

	# 初期化済みフラグをチェック
	lr35902_copy_to_regA_from_addr $var_is_inited
	lr35902_compare_regA_and 00
	(
		# 初期化済みフラグ == 0
		init

		# pop & return
		lr35902_pop_reg regAF
		lr35902_return
	) >main.1.o
	local sz_1=$(stat -c '%s' main.1.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_1)
	cat main.1.o

	# アプリ用ボタンリリースフラグをregAへ取得
	lr35902_copy_to_regA_from_addr $var_app_release_btn

	# Aボタン(右クリック): 終了
	lr35902_test_bitN_of_reg $GBOS_A_KEY_BITNUM regA
	(
		# Aボタン(右クリック)のリリースがあった場合

		# ch1: ミュート
		lr35902_clear_reg regA
		lr35902_copy_to_ioport_from_regA $GB_IO_NR12
		lr35902_set_reg regA 80
		lr35902_copy_to_ioport_from_regA $GB_IO_NR14

		# run_exe_cycを終了させる
		lr35902_call $a_exit_exe

		# pop & return
		lr35902_pop_reg regAF
		lr35902_return
	) >main.2.o
	local sz_2=$(stat -c '%s' main.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	cat main.2.o

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

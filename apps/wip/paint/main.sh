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
	:
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

	# フラグ変数の初期化済みフラグチェック
	lr35902_copy_to_regA_from_addr $APP_VARS_BASE
	lr35902_test_bitN_of_reg $flg_bitnum_inited regA

	# フラグがセットされていたら(初期化済みだったら)、
	# 初期化処理をスキップ

	(
		# 定常処理

		# リリースされたボタンをregAへ取得
		lr35902_copy_to_regA_from_addr $var_app_release_btn

		# Aボタン(右クリック): 終了
		lr35902_test_bitN_of_reg $GBOS_A_KEY_BITNUM regA
		(
			# Aボタン(右クリック)のリリースがあった場合

			# TODO 描画されているタイル座標のリストを
			#      バックアップRAMへ保存

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

			# リリース情報のBボタン(左クリック)のビットをクリア
			lr35902_copy_to_from regA regC
			lr35902_res_bitN_of_reg $GBOS_B_KEY_BITNUM regA
			lr35902_copy_to_addr_from_regA $var_app_release_btn
		) >main.3.o
		local sz_3=$(stat -c '%s' main.3.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_3)
		cat main.3.o
	) >main.2.o

	(
		# アプリ用リリースボタンフラグをクリア
		lr35902_clear_reg regA
		lr35902_copy_to_addr_from_regA $var_app_release_btn

		# 初期パターン配置
		# init_paint

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

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

# RAM0オリジナルデータ用ROMバンク番号
PAINT_RAM_BANK_NUM=01

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

	# 初期化処理
	(
		# アプリ用ボタンリリースフラグをクリア
		lr35902_clear_reg regA
		lr35902_copy_to_addr_from_regA $var_app_release_btn

		# カートリッジ搭載RAMの有効化
		lr35902_set_reg regA $GB_MBC_RAM_EN_VAL
		lr35902_copy_to_addr_from_regA $GB_MBC_RAM_EN_ADDR

		# RAMバンクを設定できるようにする
		lr35902_set_reg regA $GB_MBC_SEL_RAM
		lr35902_copy_to_addr_from_regA $GB_MBC_ROMRAM_SEL_ADDR

		# paint用のバンクを設定
		lr35902_set_reg regA $PAINT_RAM_BANK_NUM
		lr35902_copy_to_addr_from_regA $GB_MBC_ROMRAM_BANK_ADDR

		# RAM_BKUP_NEXT_ADDR_TH にバックアップ領域のアドレス
		# の上位8ビット(A0h 〜 AFh)が書かれているか確認
		lr35902_copy_to_regA_from_addr $RAM_BKUP_NEXT_ADDR_TH
		lr35902_and_to_regA f0
		lr35902_compare_regA_and a0
		(
			# 書かれていなかったら
			# RAM_BKUP_NEXT_ADDR_{TH,BH}を初期化
			lr35902_set_reg regA a0
			lr35902_copy_to_addr_from_regA $RAM_BKUP_NEXT_ADDR_TH
			lr35902_set_reg regA 02
			lr35902_copy_to_addr_from_regA $RAM_BKUP_NEXT_ADDR_BH
		) >main.9.o
		local sz_9=$(stat -c '%s' main.9.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_9)
		cat main.9.o

		# デフォルトのバンクへ戻す
		lr35902_set_reg regA $GBOS_CARTRAM_BANK_DEF
		lr35902_copy_to_addr_from_regA $GB_MBC_ROMRAM_BANK_ADDR

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

		# ROMバンクモードへ戻しておく
		# TODO カーネル側でRAMバンクモードにしておいて、
		#      ずっとそのままで良いかも
		lr35902_set_reg regA $GB_MBC_SEL_ROM
		lr35902_copy_to_addr_from_regA $GB_MBC_ROMRAM_SEL_ADDR

		# カートリッジ搭載RAMの無効化
		lr35902_clear_reg regA
		lr35902_copy_to_addr_from_regA $GB_MBC_RAM_EN_ADDR

		# run_exe_cycを終了させる
		lr35902_call $a_exit_exe

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

		# バックアップ
		## paint用のバンクを設定
		lr35902_set_reg regA $PAINT_RAM_BANK_NUM
		lr35902_copy_to_addr_from_regA $GB_MBC_ROMRAM_BANK_ADDR
		## WALもどき
		## RAM_BKUP_NEXT_ADDR_{TH,BH}が指すRAMアドレスを
		## regHLへ設定
		lr35902_copy_to_regA_from_addr $RAM_BKUP_NEXT_ADDR_TH
		lr35902_copy_to_from regH regA
		lr35902_copy_to_regA_from_addr $RAM_BKUP_NEXT_ADDR_BH
		lr35902_copy_to_from regL regA
		## 先程描画したVRAMアドレスをregHLが指す先へ保存
		## (regHLをインクリメントしながら)
		lr35902_copy_to_from regA regD	# VRAMアドレス[15:8]
		lr35902_copyinc_to_ptrHL_from_regA
		lr35902_copy_to_from regA regE	# VRAMアドレス[7:0]
		lr35902_copyinc_to_ptrHL_from_regA
		## regHLをRAM_BKUP_NEXT_ADDR_{TH,BH}へ書き戻す
		lr35902_copy_to_from regA regH
		lr35902_copy_to_addr_from_regA $RAM_BKUP_NEXT_ADDR_TH
		lr35902_copy_to_from regA regL
		lr35902_copy_to_addr_from_regA $RAM_BKUP_NEXT_ADDR_BH
		## デフォルトのバンクへ戻す
		lr35902_set_reg regA $GBOS_CARTRAM_BANK_DEF
		lr35902_copy_to_addr_from_regA $GB_MBC_ROMRAM_BANK_ADDR

		# アプリ用ボタンリリースフラグのBボタン(左クリック)をクリア
		lr35902_copy_to_from regA regC
		lr35902_res_bitN_of_reg $GBOS_B_KEY_BITNUM regA
		lr35902_copy_to_addr_from_regA $var_app_release_btn
	) >main.3.o
	local sz_3=$(stat -c '%s' main.3.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_3)
	cat main.3.o

	# スタートボタン: リセット
	lr35902_test_bitN_of_reg $GBOS_START_KEY_BITNUM regA
	(
		# スタートボタンのリリースがあった場合

		# ボタンリリース状態をregCへ取っておく
		lr35902_copy_to_from regC regA

		# paint用のバンクを設定
		lr35902_set_reg regA $PAINT_RAM_BANK_NUM
		lr35902_copy_to_addr_from_regA $GB_MBC_ROMRAM_BANK_ADDR

		# RAM_BKUP_NEXT_ADDR_{TH,BH}を初期化
		lr35902_set_reg regA a0
		lr35902_copy_to_addr_from_regA $RAM_BKUP_NEXT_ADDR_TH
		lr35902_set_reg regA 02
		lr35902_copy_to_addr_from_regA $RAM_BKUP_NEXT_ADDR_BH

		# デフォルトのバンクへ戻す
		lr35902_set_reg regA $GBOS_CARTRAM_BANK_DEF
		lr35902_copy_to_addr_from_regA $GB_MBC_ROMRAM_BANK_ADDR

		# TODO 画面を初期化

		# アプリ用ボタンリリースフラグのスタートボタンをクリア
		lr35902_copy_to_from regA regC
		lr35902_res_bitN_of_reg $GBOS_START_KEY_BITNUM regA
		lr35902_copy_to_addr_from_regA $var_app_release_btn
	) >main.10.o
	local sz_10=$(stat -c '%s' main.10.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_10)
	cat main.10.o

	# セレクトボタン: バックアップをロード
	## カートリッジRAMのデータを元に画面描画する
	## バックアップデータのフォーマット:
	## A000h | RAM_BKUP_NEXT_ADDR_TH | RAM_BKUP_NEXT_ADDR_BH |
	## A002h | draw_log[0].th        | draw_log[0].bh        |
	## A004h | draw_log[1].th        | draw_log[1].bh        |
	## ※ RAM_BKUP_NEXT_ADDR_{TH,BH}は次にログを保存できる場所を指す
	##    この例の場合、A003hまではデータが既に入っているので
	##    RAM_BKUP_NEXT_ADDR_TH=A0h,RAM_BKUP_NEXT_ADDR_BH=06hとなる
	lr35902_test_bitN_of_reg $GBOS_SELECT_KEY_BITNUM regA
	(
		lr35902_set_reg regB $GBOS_TILE_NUM_BLACK

		lr35902_set_reg regH a0
		lr35902_set_reg regL 02

		# 繰り返す対象の処理
		# (regHLの指す先をtdqへエンキュー)
		(
			lr35902_copyinc_to_regA_from_ptrHL
			lr35902_copy_to_from regD regA
			lr35902_copyinc_to_regA_from_ptrHL
			lr35902_copy_to_from regE regA

			# デフォルトのバンクへ戻す
			lr35902_set_reg regA $GBOS_CARTRAM_BANK_DEF
			lr35902_copy_to_addr_from_regA $GB_MBC_ROMRAM_BANK_ADDR

			lr35902_call $a_enq_tdq
		) >main.5.o
		local sz_5=$(stat -c '%s' main.5.o)
		## 条件判定処理先頭までジャンプしている命令の分を足す
		local sz_5_rel_jump=$((sz_5 + 2))

		# regH < RAM_BKUP_NEXT_ADDR_TH の間繰り返す
		(
			# paint用のバンクを設定
			lr35902_set_reg regA $PAINT_RAM_BANK_NUM
			lr35902_copy_to_addr_from_regA $GB_MBC_ROMRAM_BANK_ADDR

			lr35902_copy_to_regA_from_addr $RAM_BKUP_NEXT_ADDR_TH
			lr35902_copy_to_from regC regA
			lr35902_copy_to_from regA regH
			lr35902_compare_regA_and regC
			## regH(regA) >= RAM_BKUP_NEXT_ADDR_TH(regC)
			## だったらジャンプして飛ばす
			lr35902_rel_jump_with_cond NC $(two_digits_d $sz_5_rel_jump)
			cat main.5.o
		) >main.7.o
		cat main.7.o
		## 条件判定処理先頭までジャンプ
		local sz_7=$(stat -c '%s' main.7.o)
		lr35902_rel_jump $(two_comp_d $((sz_7 + 2)))

		# regL < RAM_BKUP_NEXT_ADDR_BH の間繰り返す
		(
			# paint用のバンクを設定
			lr35902_set_reg regA $PAINT_RAM_BANK_NUM
			lr35902_copy_to_addr_from_regA $GB_MBC_ROMRAM_BANK_ADDR

			lr35902_copy_to_regA_from_addr $RAM_BKUP_NEXT_ADDR_BH
			lr35902_copy_to_from regC regA
			lr35902_copy_to_from regA regL
			lr35902_compare_regA_and regC
			## regL(regA) >= RAM_BKUP_NEXT_ADDR_BH(regC)
			## だったらジャンプして飛ばす
			lr35902_rel_jump_with_cond NC $(two_digits_d $sz_5_rel_jump)
			cat main.5.o
		) >main.8.o
		cat main.8.o
		## 条件判定処理先頭までジャンプ
		local sz_8=$(stat -c '%s' main.8.o)
		lr35902_rel_jump $(two_comp_d $((sz_8 + 2)))

		# デフォルトのバンクへ戻す
		lr35902_set_reg regA $GBOS_CARTRAM_BANK_DEF
		lr35902_copy_to_addr_from_regA $GB_MBC_ROMRAM_BANK_ADDR

		# アプリ用ボタンリリースフラグのセレクトボタンをクリア
		lr35902_copy_to_regA_from_addr $var_app_release_btn
		lr35902_res_bitN_of_reg $GBOS_SELECT_KEY_BITNUM regA
		lr35902_copy_to_addr_from_regA $var_app_release_btn
	) >main.4.o
	local sz_4=$(stat -c '%s' main.4.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_4)
	cat main.4.o

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

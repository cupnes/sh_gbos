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

# 楽譜の音符の数
SCORE_LEN=07

map_file=map.sh
rm -f $map_file

vars() {
	# 初期化済みフラグ
	var_is_inited=$APP_VARS_BASE
	echo -e "var_is_inited=$var_is_inited" >>$map_file
	echo -en '\x00'

	# Vブランクカウンタ
	var_vblank_counter=$(calc16 "$var_is_inited+1")
	echo -e "var_vblank_counter=$var_vblank_counter" >>$map_file
	echo -en '\x00'

	# 楽譜
	var_score=$(calc16 "$var_vblank_counter+1")
	echo -e "var_score=$var_score" >>$map_file
	# echo -en "\x$GB_NR23_BIT_FREQ_C4\x$GB_NR24_BIT_FREQ_C4"	# ド4
	# ド4は初期値で入っている
	echo -en "\x$GB_NR23_BIT_FREQ_D4\x$GB_NR24_BIT_FREQ_D4"	# レ4
	echo -en "\x$GB_NR23_BIT_FREQ_E4\x$GB_NR24_BIT_FREQ_E4"	# ミ4
	echo -en "\x$GB_NR23_BIT_FREQ_F4\x$GB_NR24_BIT_FREQ_F4"	# ファ4
	echo -en "\x$GB_NR23_BIT_FREQ_G4\x$GB_NR24_BIT_FREQ_G4"	# ソ4
	echo -en "\x$GB_NR23_BIT_FREQ_A4\x$GB_NR24_BIT_FREQ_A4"	# ラ4
	echo -en "\x$GB_NR23_BIT_FREQ_B4\x$GB_NR24_BIT_FREQ_B4"	# シ4
	echo -en "\x$GB_NR23_BIT_FREQ_C5\x$GB_NR24_BIT_FREQ_C5"	# ド5

	# 次の音のアドレス
	var_next_note_bh=$(calc16 "$var_score+E")
	echo -e "var_next_note_bh=$var_next_note_bh" >>$map_file
	echo -en "\x$(echo $var_score | cut -c3-4)"
	var_next_note_th=$(calc16 "$var_next_note_bh+1")
	echo -e "var_next_note_th=$var_next_note_th" >>$map_file
	echo -en "\x$(echo $var_score | cut -c1-2)"

	# 残音数
	var_num_notes=$(calc16 "$var_next_note_th+1")
	echo -e "var_num_notes=$var_num_notes" >>$map_file
	echo -en "\x$SCORE_LEN"
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
	#
	# サウンド
	#

	# サウンドコントロールレジスタ
	## FF26 - NR52 - サウンド ON/OFF 設定
	lr35902_set_reg regA $GB_NR52_BIT_ALL_ON
	lr35902_copy_to_ioport_from_regA $GB_IO_NR52
	## FF24 - NR50 - チャンネルコントロール / ON-OFF / 音量 設定
	lr35902_set_reg regA $(calc16_2 "$GB_NR50_BIT_S02_LV_4+$GB_NR50_BIT_S01_LV_4")
	lr35902_copy_to_ioport_from_regA $GB_IO_NR50
	## FF25 - NR51 - サウンド出力端子の選択 設定
	lr35902_set_reg regA $(calc16_2 "$GB_NR51_BIT_SOUND2_TO_SO2+$GB_NR51_BIT_SOUND2_TO_SO1")
	lr35902_copy_to_ioport_from_regA $GB_IO_NR51

	# サウンドチャンネル1(矩形波とスイープ) 設定
	## FF10 - NR10 - チャンネル1スイープレジスタ 設定
	lr35902_set_reg regA $GB_NR10_BIT_SWEEP_OFF
	lr35902_copy_to_ioport_from_regA $GB_IO_NR10
	## FF12 - NR12 - チャンネル 1 音量エンベロープ 設定
	lr35902_set_reg regA $GB_NR12_BIT_NO_SOUND_STOP_ENV
	lr35902_copy_to_ioport_from_regA $GB_IO_NR12
	## FF14 - NR14 - チャンネル 1 周波数上位データ 設定
	lr35902_set_reg regA $GB_NR14_BIT_RESTART_SOUND
	lr35902_copy_to_ioport_from_regA $GB_IO_NR14

	# サウンドチャンネル2(矩形波) 設定
	## FF16 - NR21 - チャンネル 2 サウンド長/波形パターンデューティ比 設定
	lr35902_set_reg regA $GB_NR21_BIT_DUTY_50PCT
	lr35902_copy_to_ioport_from_regA $GB_IO_NR21
	## FF17 - NR22 - チャンネル 2 音量エンベロープ 設定
	lr35902_set_reg regA $(calc16_2 "$GB_NR22_BIT_INIT_ENV_VOL_8+$GB_NR22_BIT_ENV_SWEEP_NUM_STOP_ENV")
	lr35902_copy_to_ioport_from_regA $GB_IO_NR22
	## FF18 - NR23 - チャンネル 2 周波数下位データ 設定
	lr35902_set_reg regA $GB_NR23_BIT_FREQ_C4
	lr35902_copy_to_ioport_from_regA $GB_IO_NR23
	## FF19 - NR24 - チャンネル 2 周波数上位データ 設定
	lr35902_set_reg regA $(calc16_2 "$GB_NR24_BIT_RESTART_SOUND+$GB_NR24_BIT_FREQ_C4")
	lr35902_copy_to_ioport_from_regA $GB_IO_NR24

	# サウンドチャンネル3(波形出力) 設定
	## FF1A - NR30 - チャンネル 3 サウンド on/off 設定
	lr35902_set_reg regA $GB_NR30_BIT_SOUND_CH3_OFF
	lr35902_copy_to_ioport_from_regA $GB_IO_NR30
	## FF1C - NR32 - チャンネル 3 出力レベルの選択 設定
	lr35902_set_reg regA $GB_NR32_BIT_MUTE
	lr35902_copy_to_ioport_from_regA $GB_IO_NR32
	## FF1E - NR34 - チャンネル 3 周波数上位データ 設定
	lr35902_set_reg regA $GB_NR34_BIT_RESTART_SOUND
	lr35902_copy_to_ioport_from_regA $GB_IO_NR34

	# サウンドチャンネル4(ノイズ) 設定
	## FF20 - NR41 - チャンネル 4 サウンド長 設定
	lr35902_set_reg regA $GB_NR41_BIT_SOUND_LEN_00
	lr35902_copy_to_ioport_from_regA $GB_IO_NR41
	## FF21 - NR42 - チャンネル 4 音量エンベロープ 設定
	lr35902_set_reg regA $GB_NR42_BIT_INIT_ENV_VOL_MUTE
	lr35902_copy_to_ioport_from_regA $GB_IO_NR42
	## FF23 - NR44 - チャンネル 4 カウンタ/連続; 初期化 設定
	lr35902_set_reg regA $GB_NR44_BIT_RESTART_SOUND
	lr35902_copy_to_ioport_from_regA $GB_IO_NR44

	#
	# 変数設定
	#

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

		# サウンドコントロールレジスタ
		## FF26 - NR52 - サウンド ON/OFF 設定
		lr35902_set_reg regA $GB_NR52_BIT_ALL_OFF
		lr35902_copy_to_ioport_from_regA $GB_IO_NR52

		# run_exe_cycを終了させる
		lr35902_call $a_exit_exe

		# pop & return
		lr35902_pop_reg regAF
		lr35902_return
	) >main.2.o
	local sz_2=$(stat -c '%s' main.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	cat main.2.o

	# Vブランクカウンタをインクリメント
	lr35902_copy_to_regA_from_addr $var_vblank_counter
	lr35902_inc regA

	# Vブランクカウンタ(regA) >= 30(0x1e) ?
	lr35902_compare_regA_and 1e
	(
		# Vブランクカウンタ(regA) < 30(0x1e) の場合

		# インクリメントした値を変数へ設定
		lr35902_copy_to_addr_from_regA $var_vblank_counter
	) >main.4.o
	(
		# Vブランクカウンタ(regA) >= 30(0x1e) の場合

		# 変数をゼロクリア
		lr35902_clear_reg regA
		lr35902_copy_to_addr_from_regA $var_vblank_counter

		# 残音数 == 0 ?
		lr35902_copy_to_regA_from_addr $var_num_notes
		lr35902_or_to_regA regA
		(
			# 残音数 == 0

			# サウンドコントロールレジスタ
			## FF26 - NR52 - サウンド ON/OFF 設定
			lr35902_set_reg regA $GB_NR52_BIT_ALL_OFF
			lr35902_copy_to_ioport_from_regA $GB_IO_NR52
		) >main.5.o
		(
			# 残音数 != 0

			# 残音数をデクリメント
			lr35902_dec regA
			lr35902_copy_to_addr_from_regA $var_num_notes

			# 使うレジスタをpush
			lr35902_push_reg regHL

			# 次の音のアドレスをregHLへ取得
			lr35902_copy_to_regA_from_addr $var_next_note_bh
			lr35902_copy_to_from regL regA
			lr35902_copy_to_regA_from_addr $var_next_note_th
			lr35902_copy_to_from regH regA

			# 周波数下位データ取得
			lr35902_copyinc_to_regA_from_ptrHL

			# 周波数下位データ設定
			lr35902_copy_to_ioport_from_regA $GB_IO_NR23

			# 周波数上位データ取得
			lr35902_copyinc_to_regA_from_ptrHL

			# リスタートフラグを立てる
			lr35902_or_to_regA $GB_NR24_BIT_RESTART_SOUND

			# 周波数上位データ設定
			lr35902_copy_to_ioport_from_regA $GB_IO_NR24

			# 次の音のアドレスを変数へ書き戻す
			lr35902_copy_to_from regA regL
			lr35902_copy_to_addr_from_regA $var_next_note_bh
			lr35902_copy_to_from regA regH
			lr35902_copy_to_addr_from_regA $var_next_note_th

			# 使ったレジスタをpop
			lr35902_pop_reg regHL

			# 残音数 == 0の場合の処理を飛ばす
			local sz_5=$(stat -c '%s' main.5.o)
			lr35902_rel_jump $(two_digits_d $sz_5)
		) >main.6.o
		local sz_6=$(stat -c '%s' main.6.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_6)
		cat main.6.o	# 残音数 != 0
		cat main.5.o	# 残音数 == 0

		# Vブランクカウンタ(regA) < 30(0x1e) の場合の処理を飛ばす
		local sz_4=$(stat -c '%s' main.4.o)
		lr35902_rel_jump $(two_digits_d $sz_4)
	) >main.3.o
	local sz_3=$(stat -c '%s' main.3.o)
	lr35902_rel_jump_with_cond C $(two_digits_d $sz_3)
	cat main.3.o	# regA >= 0x1e
	cat main.4.o	# regA < 0x1e

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

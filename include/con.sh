if [ "${INCLUDE_CON_SH+is_defined}" ]; then
	return
fi
INCLUDE_CON_SH=true

. include/vars.sh
. include/tiles.sh

# コンソールの開始タイルアドレス
CON_TADR_BASE=9862

# 最終行最終文字のアドレス
CON_TADR_EOP=99f1

# 行末判定定数
CON_EOL_MASK=1f
CON_EOL_VAL=11

# 最終行判定
CON_LAST_LINE_MASK=e0
CON_LAST_LINE_VAL=e0

# コンソールの初期化
con_init() {
	# push
	lr35902_push_reg regAF

	# 次に描画するタイルアドレスを
	# コンソール開始アドレスで初期化
	lr35902_set_reg regA $(echo $CON_TADR_BASE | cut -c3-4)
	lr35902_copy_to_addr_from_regA $var_con_tadr_bh
	lr35902_set_reg regA $(echo $CON_TADR_BASE | cut -c1-2)
	lr35902_copy_to_addr_from_regA $var_con_tadr_th

	# pop
	lr35902_pop_reg regAF
}

# コンソールの描画領域をクリアする
# - コンソール描画領域は、ウィンドウ内のdrawableエリア
con_clear() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	# regBへクリア文字(スペース)を設定
	lr35902_set_reg regB $GBOS_TILE_NUM_SPC

	# regDEへ描画領域の開始アドレスを設定
	lr35902_set_reg regDE $CON_TADR_BASE

	# 1タイルずつクリアするエントリをtdqへ積むループ
	(
		# tdqへ追加
		lr35902_call $a_enq_tdq

		# regDEが最終行最終文字か?
		lr35902_set_reg regA $(echo $CON_TADR_EOP | cut -c3-4)
		lr35902_xor_to_regA regE
		lr35902_copy_to_from regH regA
		lr35902_set_reg regA $(echo $CON_TADR_EOP | cut -c1-2)
		lr35902_xor_to_regA regD
		lr35902_or_to_regA regH
		(
			# 最終行最終文字

			# ループを脱出
			lr35902_rel_jump $(two_digits_d 2)
		) >src/con_clear.2.o
		(
			# 最終行最終文字ではない

			# 行末か?
			lr35902_copy_to_from regA regE
			lr35902_and_to_regA $CON_EOL_MASK
			lr35902_compare_regA_and $CON_EOL_VAL
			(
				# 行末

				# 次の行の行頭のアドレスをregDEへ設定
				# (現在のアドレスに0x11を足す)
				lr35902_set_reg regHL 0011
				lr35902_add_to_regHL regDE
				lr35902_copy_to_from regE regL
				lr35902_copy_to_from regD regH
			) >src/con_clear.4.o
			(
				# 行末ではない

				# regDEをインクリメント
				lr35902_inc regDE

				# 行末の処理を飛ばす
				local sz_4=$(stat -c '%s' src/con_clear.4.o)
				lr35902_rel_jump $(two_digits_d $sz_4)
			) >src/con_clear.5.o
			local sz_5=$(stat -c '%s' src/con_clear.5.o)
			lr35902_rel_jump_with_cond Z $(two_digits_d $sz_5)
			cat src/con_clear.5.o	# 行末ではない
			cat src/con_clear.4.o	# 行末

			# 最終行最終文字の処理を飛ばす
			local sz_2=$(stat -c '%s' src/con_clear.2.o)
			lr35902_rel_jump $(two_digits_d $sz_2)
		) >src/con_clear.3.o
		local sz_3=$(stat -c '%s' src/con_clear.3.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_3)
		cat src/con_clear.3.o	# 最終行最終文字ではない
		cat src/con_clear.2.o	# 最終行最終文字
	) >src/con_clear.1.o
	cat src/con_clear.1.o
	local sz_1=$(stat -c '%s' src/con_clear.1.o)
	lr35902_rel_jump $(two_comp_d $((sz_1 + 2)))	# 2

	# pop
	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
}

# 次に描画するアドレスを更新する
# ※ con_putch()内でインライン展開されることを想定
# ※ con_putch()でpush/popしているregAF・regDEはpush/popしていない
# in : regDE - 現在のアドレス
con_update_tadr() {
	# 行末か否か?
	lr35902_copy_to_from regA regE
	lr35902_and_to_regA $CON_EOL_MASK
	lr35902_compare_regA_and $CON_EOL_VAL
	(
		# 行末

		# push
		lr35902_push_reg regHL

		# 最終行最終文字か否か?
		lr35902_set_reg regA $(echo $CON_TADR_EOP | cut -c3-4)
		lr35902_xor_to_regA regE
		lr35902_copy_to_from regH regA
		lr35902_set_reg regA $(echo $CON_TADR_EOP | cut -c1-2)
		lr35902_xor_to_regA regD
		lr35902_or_to_regA regH
		(
			# 最終行最終文字

			# 次の文字を出力する際は改ページが必要であることを
			# 示すために、var_con_tadr_thに0x00を設定する
			lr35902_clear_reg regA
			lr35902_copy_to_addr_from_regA $var_con_tadr_th
		) >src/con_update_tadr.3.o
		(
			# 最終行最終文字ではない

			# 次の行の行頭のアドレスを取得
			# (現在のアドレスに0x11を足す)
			lr35902_set_reg regHL 0011
			lr35902_add_to_regHL regDE

			# var_con_tadr_{th,bh}を更新
			lr35902_copy_to_from regA regL
			lr35902_copy_to_addr_from_regA $var_con_tadr_bh
			lr35902_copy_to_from regA regH
			lr35902_copy_to_addr_from_regA $var_con_tadr_th

			# 最終行最終文字の処理を飛ばす
			local sz_3=$(stat -c '%s' src/con_update_tadr.3.o)
			lr35902_rel_jump $(two_digits_d $sz_3)
		) >src/con_update_tadr.4.o
		local sz_4=$(stat -c '%s' src/con_update_tadr.4.o)
		lr35902_rel_jump_with_cond Z $(two_digits_d $sz_4)
		cat src/con_update_tadr.4.o	# 最終行最終文字ではない
		cat src/con_update_tadr.3.o	# 最終行最終文字

		# pop
		lr35902_pop_reg regHL
	) >src/con_update_tadr.1.o
	(
		# 行末ではない

		# アドレスをインクリメント
		lr35902_inc regDE

		# var_con_tadr_{th,bh}を更新
		lr35902_copy_to_from regA regE
		lr35902_copy_to_addr_from_regA $var_con_tadr_bh
		lr35902_copy_to_from regA regD
		lr35902_copy_to_addr_from_regA $var_con_tadr_th

		# 行末の処理を飛ばす
		local sz_1=$(stat -c '%s' src/con_update_tadr.1.o)
		lr35902_rel_jump $(two_digits_d $sz_1)
	) >src/con_update_tadr.2.o
	local sz_2=$(stat -c '%s' src/con_update_tadr.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	cat src/con_update_tadr.2.o	# 行末ではない
	cat src/con_update_tadr.1.o	# 行末
}

# 次に描画するアドレスを更新する(改行文字用)
# ※ con_putch()内でインライン展開されることを想定
# ※ con_putch()でpush/popしているregAF・regDEはpush/popしていない
# in : regDE - 現在のアドレス
con_update_tadr_for_nl() {
	# 最終行か否か?
	lr35902_copy_to_from regA regD
	lr35902_and_to_regA $CON_LAST_LINE_MASK
	lr35902_compare_regA_and $CON_LAST_LINE_VAL
	(
		# 最終行

		# 次の文字を出力する際は改ページが必要であることを
		# 示すために、var_con_tadr_thに0x00を設定する
		lr35902_clear_reg regA
		lr35902_copy_to_addr_from_regA $var_con_tadr_th
	) >src/con_update_tadr_for_nl.1.o
	(
		# 最終行ではない

		# push
		lr35902_push_reg regHL

		# 次の行の行頭のアドレスを取得
		# (現在のアドレスに0x11を足す)
		lr35902_set_reg regHL 0011
		lr35902_add_to_regHL regDE

		# var_con_tadr_{th,bh}を更新
		lr35902_copy_to_from regA regL
		lr35902_copy_to_addr_from_regA $var_con_tadr_bh
		lr35902_copy_to_from regA regH
		lr35902_copy_to_addr_from_regA $var_con_tadr_th

		# pop
		lr35902_pop_reg regHL

		# 最終行の処理を飛ばす
		local sz_1=$(stat -c '%s' src/con_update_tadr_for_nl.1.o)
		lr35902_rel_jump $(two_digits_d $sz_1)
	) >src/con_update_tadr_for_nl.2.o
	local sz_2=$(stat -c '%s' src/con_update_tadr_for_nl.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	cat src/con_update_tadr_for_nl.2.o	# 最終行ではない
	cat src/con_update_tadr_for_nl.1.o	# 最終行
}

# 指定された1文字をtdqへ積む
# in : regB - 出力する文字のタイル番号あるいは改行文字
con_putch() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regDE

	# 改ページが必要か?
	lr35902_copy_to_regA_from_addr $var_con_tadr_th
	lr35902_or_to_regA regA
	(
		# 改ページ必要

		# コンソール領域クリアのエントリをtdqへ積む
		con_clear

		# regDEへ描画領域開始アドレスを設定
		lr35902_set_reg regDE $CON_TADR_BASE
	) >src/con_putch.3.o
	(
		# 改ページ不要

		# 次に描画するアドレスをregDEへ設定
		lr35902_copy_to_regA_from_addr $var_con_tadr_th
		lr35902_copy_to_from regD regA
		lr35902_copy_to_regA_from_addr $var_con_tadr_bh
		lr35902_copy_to_from regE regA

		# 改ページ必要の処理を飛ばす
		local sz_3=$(stat -c '%s' src/con_putch.3.o)
		lr35902_rel_jump $(two_digits_d $sz_3)
	) >src/con_putch.4.o
	local sz_4=$(stat -c '%s' src/con_putch.4.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_4)
	cat src/con_putch.4.o	# 改ページ不要
	cat src/con_putch.3.o	# 改ページ必要

	# 指定された文字が改行文字か否か
	lr35902_copy_to_from regA regB
	lr35902_compare_regA_and $GBOS_CTRL_CHR_NL
	(
		# 改行文字

		# 改行文字用のアドレス更新
		con_update_tadr_for_nl
	) >src/con_putch.1.o
	(
		# 改行文字でない

		# tdqへエンキュー
		lr35902_call $a_enq_tdq

		# アドレスを更新
		con_update_tadr

		# 改行文字の処理を飛ばす
		local sz_1=$(stat -c '%s' src/con_putch.1.o)
		lr35902_rel_jump $(two_digits_d $sz_1)
	) >src/con_putch.2.o
	local sz_2=$(stat -c '%s' src/con_putch.2.o)
	lr35902_rel_jump_with_cond Z $(two_digits_d $sz_2)
	cat src/con_putch.2.o	# 改行文字でない
	cat src/con_putch.1.o	# 改行文字

	# pop
	lr35902_pop_reg regDE
	lr35902_pop_reg regAF
}
if [ "${INCLUDE_TDQ_SH+is_defined}" ]; then
	return
fi
INCLUDE_TDQ_SH=true

# memo
# - var_draw_cycle
#   - 画面描画周期
#   - tdq自体は単なるキューで、
#     「アドレスXXへYYを書いて欲しい」というリクエストの連続でしかない
#   - 1画面分の描画リクエストを積み終わった所で
#     var_draw_cycleをインクリメントするリクエストを積むことで
#     var_draw_cycleを見ていれば「今描画周期何番の描画中なのか」が分かるようになる

# タイル描画キュー用定数
GBOS_TDQ_FIRST=c300
GBOS_TDQ_LAST=cefd
GBOS_TDQ_END=cf00
GBOS_TDQ_ENTRY_SIZE=0a
GBOS_TDQ_MAX_DRAW_TILES=04
GBOS_TDQ_STAT_BITNUM_EMPTY=0
GBOS_TDQ_STAT_BITNUM_FULL=1
GBOS_TDQ_STAT_BITNUM_OVERFLOW=2

# tdq初期化
tdq_init() {
	# push
	lr35902_push_reg regAF

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

	# pop
	lr35902_pop_reg regAF
}

# tdqへエントリを追加する
# in : regB  - 配置するタイル番号
#      regD  - VRAMアドレス[15:8]
#      regE  - VRAMアドレス[7:0]
tdq_enq() {
	# push
	lr35902_push_reg regAF
	lr35902_push_reg regBC
	lr35902_push_reg regDE
	lr35902_push_reg regHL

	lr35902_copy_to_regA_from_addr $var_tdq_stat
	lr35902_test_bitN_of_reg $GBOS_TDQ_STAT_BITNUM_FULL regA
	(
		# tdqがfullになっている場合
		# ここでリクエストされたエントリは追加できない

		# tdq_statのオーバーフローフラグをセットする
		lr35902_set_bitN_of_reg $GBOS_TDQ_STAT_BITNUM_OVERFLOW regA
		lr35902_copy_to_addr_from_regA $var_tdq_stat
	) >tdq_enqueue.6.o
	(
		# tdqがfullになっていない場合

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

		# tdq_stat[full] != 0 の場合の処理を飛ばす
		local sz_6=$(stat -c '%s' tdq_enqueue.6.o)
		lr35902_rel_jump $(two_digits_d $sz_6)
	) >tdq_enqueue.5.o
	local sz_5=$(stat -c '%s' tdq_enqueue.5.o)
	lr35902_rel_jump_with_cond NZ $(two_digits_d $sz_5)
	cat tdq_enqueue.5.o	# tdq_stat[full] == 0
	cat tdq_enqueue.6.o	# tdq_stat[full] != 0

	# pop
	lr35902_pop_reg regHL
	lr35902_pop_reg regDE
	lr35902_pop_reg regBC
	lr35902_pop_reg regAF
}

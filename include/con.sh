if [ "${INCLUDE_CON_SH+is_defined}" ]; then
	return
fi
INCLUDE_CON_SH=true

. include/vars.sh

# コンソールの開始タイルアドレス
CON_TADR_BASE=9862

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

if [ "${INCLUDE_TIMER_SH+is_defined}" ]; then
	return
fi
INCLUDE_TIMER_SH=true

. include/vars.sh

# タイマーハンドラ初期化
# 最低限、pop HL(0xe1) -> pop AF(0xf1) -> reti(0xd9) は行うようにする
timer_init_handler() {
	lr35902_set_reg regHL $var_timer_handler
	lr35902_set_reg regA e1	# pop HL
	lr35902_copyinc_to_ptrHL_from_regA
	lr35902_set_reg regA f1	# pop AF
	lr35902_copyinc_to_ptrHL_from_regA
	lr35902_set_reg regA d9	# reti
	lr35902_copyinc_to_ptrHL_from_regA
}

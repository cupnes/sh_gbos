if [ "${LIB_RND_SH+is_defined}" ]; then
	return
fi
LIB_RND_SH=true

init_rnd() {
	lr35902_set_reg regB $GBOS_TILE_NUM_BLACK
	lr35902_set_reg regD $GBOS_WIN_DRAWABLE_BASE_YT
	(
		lr35902_set_reg regE $GBOS_WIN_DRAWABLE_BASE_XT
		(
			lr35902_copy_to_regA_from_ioport $GB_IO_TIMA
			lr35902_test_bitN_of_reg 0 regA
			(
				lr35902_push_reg regDE

				lr35902_call $a_tcoord_to_addr
				lr35902_copy_to_from regD regH
				lr35902_copy_to_from regE regL
				lr35902_call $a_tdq_enq

				lr35902_pop_reg regDE
			) >init_rnd.1.o
			local sz_1=$(stat -c '%s' init_rnd.1.o)
			lr35902_rel_jump_with_cond Z $(two_digits_d $sz_1)
			cat init_rnd.1.o

			lr35902_inc regE
			lr35902_copy_to_from regA regE
			lr35902_compare_regA_and $(calc16_2 "$GBOS_WIN_DRAWABLE_BASE_XT+$GBOS_WIN_DRAWABLE_WIDTH_T")
		) >init_rnd.2.o
		cat init_rnd.2.o
		local sz_2=$(stat -c '%s' init_rnd.2.o)
		lr35902_rel_jump_with_cond C $(two_comp_d $((sz_2 + 2)))

		lr35902_inc regD
		lr35902_copy_to_from regA regD
		lr35902_compare_regA_and $(calc16_2 "$GBOS_WIN_DRAWABLE_BASE_YT+$GBOS_WIN_DRAWABLE_HEIGHT_T")
	) >init_rnd.3.o
	cat init_rnd.3.o
	local sz_3=$(stat -c '%s' init_rnd.3.o)
	lr35902_rel_jump_with_cond C $(two_comp_d $((sz_3 + 2)))

	# var_draw_cycを1にするエントリを積む
	lr35902_set_reg regB 01
	lr35902_set_reg regD $(echo $var_draw_cyc | cut -c1-2)
	lr35902_set_reg regE $(echo $var_draw_cyc | cut -c3-4)
	lr35902_call $a_tdq_enq
}

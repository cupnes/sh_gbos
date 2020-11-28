if [ "${INCLUDE_FS_SH+is_defined}" ]; then
	return
fi
INCLUDE_FS_SH=true

. include/vars.sh

# ファイルシステム内のファイル数を取得する
# out: regA - ファイル数
get_num_files_in_fs() {
	# ファイルシステム先頭アドレスをregHLへ取得
	lr35902_copy_to_regA_from_addr $var_fs_base_bh
	lr35902_copy_to_from regL regA
	lr35902_copy_to_regA_from_addr $var_fs_base_th
	lr35902_copy_to_from regH regA

	# ファイル数取得
	lr35902_copy_to_from regA ptrHL
}

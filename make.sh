#!/bin/bash

set -uex
# set -ue

. include/gb.sh
. src/main.sh

if [ $# -ne 1 ]; then
	echo "Usage: $0 ROOTFS_IMAGE_FILE" 1>&2
	exit 1
fi

ROOTFS_IMAGE_FILE=$1

ROM_FILE_NAME=amado.gb

print_boot_kern() {
	# 0x0000 - 0x00ff: リスタートと割り込みのベクタテーブル (256バイト)
	gbos_vec

	# 0x0100 - 0x014f: カートリッジヘッダ (80バイト)
	gbos_const >gbos_const.o
	local offset=$(stat -c '%s' gbos_const.o)
	local offset_hex=$(echo "obase=16;${offset}" | bc)
	local bc_form="obase=16;ibase=16;${GB_ROM_FREE_BASE}+${offset_hex}"
	local entry_addr=$(echo $bc_form | bc)
	bc_form="obase=16;ibase=16;${entry_addr}+10000"
	local entry_addr_4digits=$(echo $bc_form | bc | cut -c2-5)
	gb_cart_header_no_title_mbc1 $entry_addr_4digits

	# 0x0150 - 0x3fff: カートリッジROM(Bank 00) (16048バイト)
	gbos_main >gbos_main.o
	cat gbos_const.o gbos_main.o
	## 16KBのサイズにするために残りをゼロ埋め
	local num_const_bytes=$(stat -c '%s' gbos_const.o)
	local num_main_bytes=$(stat -c '%s' gbos_main.o)
	local padding=$((GB_ROM_BANK_SIZE_NOHEAD - num_const_bytes \
						 - num_main_bytes))
	dd if=/dev/zero bs=1 count=$padding 2>/dev/null
}

print_rom() {
	# 0x00 0000 - 0x00 3fff: Bank 000 (16KB)
	print_boot_kern >boot_kern.bin
	cat boot_kern.bin
	# 0x00 4000 - 0x00 7fff: Bank 001 (16KB)
	cat $ROOTFS_IMAGE_FILE
	# 0x00 8000 - 0x00 bfff: Bank 002 (16KB)
	cat fs_ram0_orig.img

	# 0x00 c000 - 0x1f bfff: Bank 003 - 126 (2000KB)
	dd if=/dev/zero bs=K count=1984 2>/dev/null

	# 0x1f c000 - 0x1f ffff: Bank 127 (16KB)
	dd if=/dev/zero bs=1 count=260 2>/dev/null
	dd if=logo.gb bs=1 count=48 ibs=1 skip=260
	dd if=/dev/zero bs=1 count=$(((16 * 1024) - 260 - 48)) 2>/dev/null
}

print_rom >$ROM_FILE_NAME

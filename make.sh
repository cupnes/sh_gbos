#!/bin/bash

usage() {
	echo -e "Usage:\t$0 ACTION [OPTION]"
	echo
	echo 'ACTION:'
	echo -e '\tbuild [--32kb-rom]'
	echo -e '\tclean'
	echo -e '\thelp'
	echo -e '\trun'
}

TARGET=amado
ROM_FILE_NAME=${TARGET}.gb
RAM_FILE_NAME=${TARGET}.sav
EMU=bgb

if [ $# -eq 0 ]; then
	usage >&2
	exit 1
fi

case "$1" in
'build')
	action="$1"
	if [ $# -eq 2 ]; then
		opt="$2"
	else
		opt=''
	fi
	;;
'clean')
	action="$1"
	;;
'help')
	usage
	exit 0
	;;
'run')
	$EMU $ROM_FILE_NAME
	exit 0
	;;
*)
	usage >&2
	exit 1
	;;
esac

# set -uex
set -ue

. include/gb.sh
. src/main.sh

print_boot_kern() {
	if [ -f boot_kern.bin ]; then
		cat boot_kern.bin
		return
	fi

	(
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
		if [ "$opt" == "--32kb-rom" ]; then
			gb_cart_header_no_title $entry_addr_4digits
		else
			gb_cart_header_no_title_mbc1 $entry_addr_4digits
		fi
		# 0x0150 - 0x3fff: カートリッジROM(Bank 00) (16048バイト)
		gbos_main >gbos_main.o
		cat gbos_const.o gbos_main.o
		## 16KBのサイズにするために残りをゼロ埋め
		local num_const_bytes=$(stat -c '%s' gbos_const.o)
		local num_main_bytes=$(stat -c '%s' gbos_main.o)
		local padding=$((GB_ROM_BANK_SIZE_NOHEAD - num_const_bytes \
							 - num_main_bytes))
		dd if=/dev/zero bs=1 count=$padding 2>/dev/null
	) >boot_kern.bin
	cat boot_kern.bin
}

print_fs_system() {
	if [ -f fs_system.img ]; then
		cat fs_system.img
		return
	fi

	(
		mkdir -p fs_system

		# binedit.exe
		if [ ! -f fs_system/0100.exe ]; then
			make -C apps/binedit
			cp apps/binedit/binedit.exe fs_system/0100.exe
		fi

		# har22a_cover.2bpp
		if [ ! -f fs_system/0200.2bpp ]; then
			cp imgs/har22a_cover.2bpp fs_system/0200.2bpp
		fi

		# sound_ch2_rand_description.2bpp
		if [ ! -f fs_system/0300.2bpp ]; then
			cp imgs/sound_ch2_rand_description.2bpp fs_system/0300.2bpp
		fi

		# sound_ch2_rand.exe
		if [ ! -f fs_system/0400.exe ]; then
			make -C apps/sound_ch2_rand
			cp apps/sound_ch2_rand/sound_ch2_rand.exe fs_system/0400.exe
		fi

		# colophon_har22a.txt
		if [ ! -f fs_system/0500.txt ]; then
			make -C docs/colophon_har22a
			cp docs/colophon_har22a/colophon_har22a.txt fs_system/0500.txt
		fi

		# # cartram_formatter.exe
		# if [ ! -f fs_system/0200.exe ]; then
		# 	make -C apps/cartram_formatter
		# 	cp apps/cartram_formatter/cartram_formatter.exe fs_system/0200.exe
		# fi

		# # welcome.txt
		# if [ ! -f fs_system/0300.txt ]; then
		# 	make -C docs/welcome
		# 	cp docs/welcome/welcome.txt fs_system/0300.txt
		# fi

		# # version.2bpp
		# if [ ! -f fs_system/0400.2bpp ]; then
		# 	cp imgs/version.2bpp fs_system/0400.2bpp
		# fi

		# # appendix.txt
		# if [ ! -f fs_system/0450.txt ]; then
		# 	make -C docs/appendix
		# 	cp docs/appendix/appendix.txt fs_system/0450.txt
		# fi

		# # lifegame_glider.exe
		# if [ ! -f fs_system/0500.exe ]; then
		# 	make -C apps/lifegame_glider
		# 	cp apps/lifegame_glider/lifegame_glider.exe fs_system/0500.exe
		# fi

		# # lifegame_random.exe
		# if [ ! -f fs_system/0600.exe ]; then
		# 	make -C apps/lifegame_random
		# 	cp apps/lifegame_random/lifegame_random.exe fs_system/0600.exe
		# fi

		tools/make_fs fs_system fs_system.img
	) >/dev/null
	cat fs_system.img
}

print_fs_ram0_orig() {
	if [ -f fs_ram0_orig.img ]; then
		cat fs_ram0_orig.img
		return
	fi

	(
		tools/make_ram0_files.sh

		tools/make_fs fs_ram0_orig fs_ram0_orig.img
	) >/dev/null
	cat fs_ram0_orig.img
}

print_rom() {
	# 0x00 0000 - 0x00 3fff: Bank 000 (16KB)
	print_boot_kern
	# 0x00 4000 - 0x00 7fff: Bank 001 (16KB)
	print_fs_system
	if [ "$opt" == "--32kb-rom" ]; then
		return
	fi
	# 0x00 8000 - 0x00 bfff: Bank 002 (16KB)
	print_fs_ram0_orig

	# 0x00 c000 - 0x1f bfff: Bank 003 - 126 (1984KB)
	dd if=/dev/zero bs=K count=1984 2>/dev/null

	# 0x1f c000 - 0x1f ffff: Bank 127 (16KB)
	dd if=/dev/zero bs=1 count=260 2>/dev/null
	dd if=logo.gb bs=1 count=48 ibs=1 skip=260
	dd if=/dev/zero bs=1 count=$(((16 * 1024) - 260 - 48)) 2>/dev/null
}

print_fs_ram0() {
	if [ -f fs_ram0.img ]; then
		cat fs_ram0.img
		return
	fi

	tools/make_fs fs_ram0_orig fs_ram0.img ram >/dev/null
	cat fs_ram0.img
}

print_ram() {
	# 0x0000 - 0x1fff: Bank 0 (8KB)
	print_fs_ram0

	# 0x2000 - 0x7fff: Bank 1 - 3 (24KB)
	dd if=/dev/zero bs=K count=24 2>/dev/null
}

build() {
	print_rom >$ROM_FILE_NAME
	if [ "$opt" == "--32kb-rom" ]; then
		return
	fi
	print_ram >$RAM_FILE_NAME
}

clean_boot_kern() {
	rm -f boot_kern.bin
}

clean_apps() {
	# binedit.exe
	make -C apps/binedit clean

	# cartram_formatter.exe
	make -C apps/cartram_formatter clean

	# lifegame_glider.exe
	make -C apps/lifegame_glider clean

	# lifegame_random.exe
	make -C apps/lifegame_random clean

	# # sound_ch2_C4D4E4F4G4A4B4C5.exe
	# make -C apps/sound_ch2_C4D4E4F4G4A4B4C5 clean

	# sound_ch2_rand.exe
	make -C apps/sound_ch2_rand clean
}

clean_docs() {
	# welcome.txt
	make -C docs/welcome clean
}

clean_fs_system() {
	clean_apps
	clean_docs
	rm -rf fs_system.img fs_system
}

clean_fs_ram0_orig() {
	rm -rf fs_ram0_orig.img fs_ram0_orig
}

clean_rom() {
	clean_boot_kern
	clean_fs_system
	clean_fs_ram0_orig
	rm -f $ROM_FILE_NAME
}

clean_fs_ram0() {
	rm -f fs_ram0.img
}

clean_ram() {
	clean_fs_ram0
	rm -f $RAM_FILE_NAME
}

clean() {
	clean_rom
	clean_ram
}

$action

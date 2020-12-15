#!/bin/bash

# set -uex
set -ue

put_footer() {
	# 無限ループ
	echo -en '\x18\xfe'	# jr $fe
}
FOOTER_SIZE=2

create_blank_exe() {
	local size=$1
	dd if=/dev/zero bs=1 count=$((size - FOOTER_SIZE))
	put_footer
}

create_blank_txt() {
	dd if=/dev/zero bs=1 count=207
	echo -en '\x85'	# '←'
}

mkdir -p fs_ram0_orig
cd $_

# 1行目：1画面分(48バイト)の空のEXE4つ
for i in $(seq -w 01 04); do
	create_blank_exe 48 >0${i}0.exe
done

# TODO 2画面分以降のEXEには、Aでファイル一覧へ戻るヘッダ/フッタを
#      入れておくと良いかも

# 2行目：4画面分(192バイト)の空のEXE4つ
for i in $(seq -w 05 08); do
	create_blank_exe 192 >0${i}0.exe
done

# 3行目：13画面分(624バイト)の空のEXE4つ
for i in $(seq -w 09 12); do
	create_blank_exe 624 >0${i}0.exe
done

# 4行目：空のEXEが2KB2つ、そして空の1画面分(208バイト)TXT2つ
create_blank_exe 2048 >0130.exe
create_blank_exe 2048 >0140.exe
create_blank_txt >0150.txt
create_blank_txt >0160.txt

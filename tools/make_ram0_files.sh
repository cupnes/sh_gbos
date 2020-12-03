#!/bin/bash

set -uex
# set -ue

mkdir fs_ram0_orig
cd $_

# 1行目：1画面分(48バイト)の空のEXE4つ
for i in $(seq -w 01 04); do
	dd if=/dev/zero of=0${i}0.exe bs=1 count=48
done

# TODO 2画面分以降のEXEには、Aでファイル一覧へ戻るヘッダ/フッタを
#      入れておくと良いかも

# 2行目：4画面分(192バイト)の空のEXE4つ
for i in $(seq -w 05 08); do
	dd if=/dev/zero of=0${i}0.exe bs=1 count=192
done

# 3行目：13画面分(624バイト)の空のEXE4つ
for i in $(seq -w 09 12); do
	dd if=/dev/zero of=0${i}0.exe bs=1 count=624
done

# 4行目：空のEXEが2KB2つ、そして空の1画面分(208バイト)TXT2つ
dd if=/dev/zero of=0130.exe bs=K count=2
dd if=/dev/zero of=0140.exe bs=K count=2
dd if=/dev/zero of=0150.txt bs=1 count=208
dd if=/dev/zero of=0160.txt bs=1 count=208

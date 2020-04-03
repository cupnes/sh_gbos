if [ "${SRC_TILES_SH+is_defined}" ]; then
	return
fi
SRC_TILES_SH=true

. include/common.sh

GBOS_TILEDATA_AREA_BYTES=03B0
GBOS_NUM_ALL_TILES=34
GBOS_NUM_ALL_TILE_BYTES=$(four_digits $(calc16 "${GBOS_NUM_ALL_TILES}*10"))

tiles_bc_form="ibase=16;${GBOS_TILEDATA_AREA_BYTES}-${GBOS_NUM_ALL_TILE_BYTES}"
GBOS_TILERSV_AREA_BYTES=$(echo $tiles_bc_form | bc)
## ddでゼロ埋めするのに使うので10進数で

GBOS_TILE_NUM_CSL=32

char_tiles() {
	### タイルデータ(計52タイル,832(0x340)バイト) ###
	# [文字コード]
	# - 記号(13文字,208(d0)バイト)
	# 00: ' '
	echo -en '\x00\x00\x00\x00\x00\x00\x00\x00'
	echo -en '\x00\x00\x00\x00\x00\x00\x00\x00'
	# 01: ┌
	echo -en '\xff\xff\x80\x80\x80\x80\x80\x80'
	echo -en '\x80\x80\x80\x80\x80\x80\x80\x80'
	# 02: ─(上)
	echo -en '\xff\xff\x00\x00\x00\x00\x00\x00'
	echo -en '\x00\x00\x00\x00\x00\x00\x00\x00'
	# 03: ┐
	echo -en '\xff\xff\x01\x01\x01\x01\x01\x01'
	echo -en '\x01\x01\x01\x01\x01\x01\x01\x01'
	# 04: │(右)
	echo -en '\x01\x01\x01\x01\x01\x01\x01\x01'
	echo -en '\x01\x01\x01\x01\x01\x01\x01\x01'
	# 05: ┘
	echo -en '\x01\x01\x01\x01\x01\x01\x01\x01'
	echo -en '\x01\x01\x01\x01\x01\x01\xff\xff'
	# 06: ─(下)
	echo -en '\x00\x00\x00\x00\x00\x00\x00\x00'
	echo -en '\x00\x00\x00\x00\x00\x00\xff\xff'
	# 07: └
	echo -en '\x80\x80\x80\x80\x80\x80\x80\x80'
	echo -en '\x80\x80\x80\x80\x80\x80\xff\xff'
	# 08: │(左)
	echo -en '\x80\x80\x80\x80\x80\x80\x80\x80'
	echo -en '\x80\x80\x80\x80\x80\x80\x80\x80'
	# 09: →
	echo -en '\x00\x00\x08\x08\x04\x04\x02\x02'
	echo -en '\x7f\x7f\x02\x02\x04\x04\x08\x08'
	# 0a: ←
	echo -en '\x00\x00\x08\x08\x10\x10\x20\x20'
	echo -en '\x7f\x7f\x20\x20\x10\x10\x08\x08'
	# 0b: ↑
	echo -en '\x00\x00\x08\x08\x1c\x1c\x2a\x2a'
	echo -en '\x49\x49\x08\x08\x08\x08\x08\x08'
	# 0c: ↓
	echo -en '\x00\x00\x08\x08\x08\x08\x08\x08'
	echo -en '\x49\x49\x2a\x2a\x1c\x1c\x08\x08'
	# - 数字(10文字,160(a0)バイト)
	# 0d: 0
	echo -en '\x00\x00\x3e\x3e\x43\x43\x45\x45'
	echo -en '\x49\x49\x51\x51\x61\x61\x3e\x3e'
	# 0e: 1
	echo -en '\x00\x00\x08\x08\x18\x18\x08\x08'
	echo -en '\x08\x08\x08\x08\x08\x08\x3e\x3e'
	# 0f: 2
	echo -en '\x00\x00\x3e\x3e\x41\x41\x02\x02'
	echo -en '\x0c\x0c\x10\x10\x20\x20\x7f\x7f'
	# 10: 3
	echo -en '\x00\x00\x3e\x3e\x41\x41\x02\x02'
	echo -en '\x0c\x0c\x02\x02\x41\x41\x3e\x3e'
	# 11: 4
	echo -en '\x00\x00\x04\x04\x0c\x0c\x14\x14'
	echo -en '\x24\x24\x7f\x7f\x04\x04\x04\x04'
	# 12: 5
	echo -en '\x00\x00\x7f\x7f\x40\x40\x40\x40'
	echo -en '\x7e\x7e\x01\x01\x41\x41\x3e\x3e'
	# 13: 6
	echo -en '\x00\x00\x3e\x3e\x41\x41\x40\x40'
	echo -en '\x7e\x7e\x41\x41\x41\x41\x3e\x3e'
	# 14: 7
	echo -en '\x00\x00\x7f\x7f\x41\x41\x01\x01'
	echo -en '\x02\x02\x04\x04\x08\x08\x10\x10'
	# 15: 8
	echo -en '\x00\x00\x3e\x3e\x41\x41\x41\x41'
	echo -en '\x3e\x3e\x41\x41\x41\x41\x3e\x3e'
	# 16: 9
	echo -en '\x00\x00\x3e\x3e\x41\x41\x41\x41'
	echo -en '\x3f\x3f\x01\x01\x41\x41\x3e\x3e'
	# - アルファベット(26文字,416(1a0)バイト)
	# 17: A
	echo -en '\x00\x00\x1c\x1c\x22\x22\x41\x41'
	echo -en '\x41\x41\x7f\x7f\x41\x41\x41\x41'
	# 18: B
	echo -en '\x00\x00\x7e\x7e\x41\x41\x41\x41'
	echo -en '\x7e\x7e\x41\x41\x41\x41\x7e\x7e'
	# 19: C
	echo -en '\x00\x00\x3e\x3e\x41\x41\x40\x40'
	echo -en '\x40\x40\x40\x40\x41\x41\x3e\x3e'
	# 1a: D
	echo -en '\x00\x00\x7c\x7c\x42\x42\x41\x41'
	echo -en '\x41\x41\x41\x41\x42\x42\x7c\x7c'
	# 1b: E
	echo -en '\x00\x00\x7f\x7f\x40\x40\x40\x40'
	echo -en '\x7f\x7f\x40\x40\x40\x40\x7f\x7f'
	# 1c: F
	echo -en '\x00\x00\x7f\x7f\x40\x40\x40\x40'
	echo -en '\x7e\x7e\x40\x40\x40\x40\x40\x40'
	# 1d: G
	echo -en '\x00\x00\x3e\x3e\x41\x41\x40\x40'
	echo -en '\x4f\x4f\x41\x41\x41\x41\x3e\x3e'
	# 1e: H
	echo -en '\x00\x00\x41\x41\x41\x41\x41\x41'
	echo -en '\x7f\x7f\x41\x41\x41\x41\x41\x41'
	# 1f: I
	echo -en '\x00\x00\x3e\x3e\x08\x08\x08\x08'
	echo -en '\x08\x08\x08\x08\x08\x08\x3e\x3e'
	# 20: J
	echo -en '\x00\x00\x07\x07\x02\x02\x02\x02'
	echo -en '\x02\x02\x02\x02\x22\x22\x1c\x1c'
	# 21: K
	echo -en '\x00\x00\x43\x43\x44\x44\x48\x48'
	echo -en '\x50\x50\x68\x68\x44\x44\x43\x43'
	# 22: L
	echo -en '\x00\x00\x40\x40\x40\x40\x40\x40'
	echo -en '\x40\x40\x40\x40\x40\x40\x7f\x7f'
	# 23: M
	echo -en '\x00\x00\x41\x41\x41\x41\x63\x63'
	echo -en '\x55\x55\x49\x49\x41\x41\x41\x41'
	# 24: N
	echo -en '\x00\x00\x41\x41\x61\x61\x51\x51'
	echo -en '\x49\x49\x45\x45\x43\x43\x41\x41'
	# 25: O
	echo -en '\x00\x00\x3e\x3e\x41\x41\x41\x41'
	echo -en '\x41\x41\x41\x41\x41\x41\x3e\x3e'
	# 26: P
	echo -en '\x00\x00\x7e\x7e\x41\x41\x41\x41'
	echo -en '\x7e\x7e\x40\x40\x40\x40\x40\x40'
	# 27: Q
	echo -en '\x00\x00\x3e\x3e\x41\x41\x41\x41'
	echo -en '\x41\x41\x4d\x4d\x43\x43\x3f\x3f'
	# 28: R
	echo -en '\x00\x00\x7e\x7e\x41\x41\x41\x41'
	echo -en '\x7e\x7e\x41\x41\x41\x41\x41\x41'
	# 29: S
	echo -en '\x00\x00\x3e\x3e\x41\x41\x40\x40'
	echo -en '\x3e\x3e\x01\x01\x41\x41\x3e\x3e'
	# 2a: T
	echo -en '\x00\x00\x7f\x7f\x08\x08\x08\x08'
	echo -en '\x08\x08\x08\x08\x08\x08\x08\x08'
	# 2b: U
	echo -en '\x00\x00\x41\x41\x41\x41\x41\x41'
	echo -en '\x41\x41\x41\x41\x41\x41\x3e\x3e'
	# 2c: V
	echo -en '\x00\x00\x41\x41\x41\x41\x41\x41'
	echo -en '\x41\x41\x22\x22\x14\x14\x08\x08'
	# 2d: W
	echo -en '\x00\x00\x41\x41\x41\x41\x49\x49'
	echo -en '\x49\x49\x55\x55\x55\x55\x22\x22'
	# 2e: X
	echo -en '\x00\x00\x41\x41\x22\x22\x14\x14'
	echo -en '\x08\x08\x14\x14\x22\x22\x41\x41'
	# 2f: Y
	echo -en '\x00\x00\x41\x41\x22\x22\x14\x14'
	echo -en '\x08\x08\x08\x08\x08\x08\x08\x08'
	# 30: Z
	echo -en '\x00\x00\x7f\x7f\x02\x02\x04\x04'
	echo -en '\x08\x08\x10\x10\x20\x20\x7f\x7f'

	# 31: all 1
	echo -en '\xff\xff\xff\xff\xff\xff\xff\xff'
	echo -en '\xff\xff\xff\xff\xff\xff\xff\xff'

	# マウスカーソル(8x16)
	# 32: 上半分
	echo -en '\xc0\xc0\xe0\xa0\xf0\x90\xf8\x88'
	echo -en '\xfc\x84\xfe\x82\xff\x81\xff\x81'
	# 33: 下半分
	echo -en '\xfe\x86\xfc\x84\xfe\xb2\xde\xd2'
	echo -en '\x0f\x09\x0f\x09\x07\x05\x07\x07'
}

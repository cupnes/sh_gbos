if [ "${SRC_TILES_SH+is_defined}" ]; then
	return
fi
SRC_TILES_SH=true

. include/common.sh

GBOS_GFUNC_START=1000

GBOS_TILEDATA_AREA_BYTES=$(calc16 "${GBOS_GFUNC_START}-150")
GBOS_NUM_ALL_TILES=4b
GBOS_NUM_ALL_TILE_BYTES=$(four_digits $(calc16 "${GBOS_NUM_ALL_TILES}*10"))

tiles_bc_form="ibase=16;${GBOS_TILEDATA_AREA_BYTES}-${GBOS_NUM_ALL_TILE_BYTES}"
GBOS_TILERSV_AREA_BYTES=$(echo $tiles_bc_form | bc)
## ddでゼロ埋めするのに使うので10進数で

char_tiles() {
	### タイルデータ(計72(0x48)タイル,1152(0x480)バイト) ###

	# - 環境使用(VRAM常駐)
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

	# 09: ■
	echo -en '\xff\xff\xff\xff\xff\xff\xff\xff'
	echo -en '\xff\xff\xff\xff\xff\xff\xff\xff'
	# 0a: ■(ライトグレー)
	echo -en '\xff\x00\xff\x00\xff\x00\xff\x00'
	echo -en '\xff\x00\xff\x00\xff\x00\xff\x00'

	# 0b: 機能ボタン(ウィンドウタイトルバー左部)
	echo -en '\x01\x01\x01\x01\x7d\x7d\x45\x45'
	echo -en '\x45\x45\x7d\x7d\x01\x01\x01\x01'
	# 0c: 最小化ボタン
	echo -en '\x80\x80\xbe\xbe\xbe\xbe\xbe\xbe'
	echo -en '\x9c\x9c\x9c\x9c\x88\x88\x80\x80'
	# 0d: 最大化ボタン
	echo -en '\x80\x80\x88\x88\x9c\x9c\x9c\x9c'
	echo -en '\xbe\xbe\xbe\xbe\xbe\xbe\x80\x80'

	# マウスカーソル(8x16)
	# 0e: 上半分
	echo -en '\xc0\xc0\xe0\xa0\xf0\x90\xf8\x88'
	echo -en '\xfc\x84\xfe\x82\xff\x81\xff\x81'
	# 0f: 下半分
	echo -en '\xfe\x86\xfc\x84\xfe\xb2\xde\xd2'
	echo -en '\x0f\x09\x0f\x09\x07\x05\x07\x07'

	# - 矢印
	# 10: →
	echo -en '\x00\x00\x08\x08\x04\x04\x02\x02'
	echo -en '\x7f\x7f\x02\x02\x04\x04\x08\x08'
	# 11: ←
	echo -en '\x00\x00\x08\x08\x10\x10\x20\x20'
	echo -en '\x7f\x7f\x20\x20\x10\x10\x08\x08'
	# 12: ↑
	echo -en '\x00\x00\x08\x08\x1c\x1c\x2a\x2a'
	echo -en '\x49\x49\x08\x08\x08\x08\x08\x08'
	# 13: ↓
	echo -en '\x00\x00\x08\x08\x08\x08\x08\x08'
	echo -en '\x49\x49\x2a\x2a\x1c\x1c\x08\x08'
	# - 数字(10文字,160(a0)バイト)
	# 14: 0
	echo -en '\x00\x00\x3e\x3e\x43\x43\x45\x45'
	echo -en '\x49\x49\x51\x51\x61\x61\x3e\x3e'
	# 15: 1
	echo -en '\x00\x00\x08\x08\x18\x18\x08\x08'
	echo -en '\x08\x08\x08\x08\x08\x08\x3e\x3e'
	# 16: 2
	echo -en '\x00\x00\x3e\x3e\x41\x41\x02\x02'
	echo -en '\x0c\x0c\x10\x10\x20\x20\x7f\x7f'
	# 17: 3
	echo -en '\x00\x00\x3e\x3e\x41\x41\x02\x02'
	echo -en '\x0c\x0c\x02\x02\x41\x41\x3e\x3e'
	# 18: 4
	echo -en '\x00\x00\x04\x04\x0c\x0c\x14\x14'
	echo -en '\x24\x24\x7f\x7f\x04\x04\x04\x04'
	# 19: 5
	echo -en '\x00\x00\x7f\x7f\x40\x40\x40\x40'
	echo -en '\x7e\x7e\x01\x01\x41\x41\x3e\x3e'
	# 1a: 6
	echo -en '\x00\x00\x3e\x3e\x41\x41\x40\x40'
	echo -en '\x7e\x7e\x41\x41\x41\x41\x3e\x3e'
	# 1b: 7
	echo -en '\x00\x00\x7f\x7f\x41\x41\x01\x01'
	echo -en '\x02\x02\x04\x04\x08\x08\x10\x10'
	# 1c: 8
	echo -en '\x00\x00\x3e\x3e\x41\x41\x41\x41'
	echo -en '\x3e\x3e\x41\x41\x41\x41\x3e\x3e'
	# 1d: 9
	echo -en '\x00\x00\x3e\x3e\x41\x41\x41\x41'
	echo -en '\x3f\x3f\x01\x01\x41\x41\x3e\x3e'
	# - アルファベット(26文字,416(1a0)バイト)
	# 1e: A
	echo -en '\x00\x00\x1c\x1c\x22\x22\x41\x41'
	echo -en '\x41\x41\x7f\x7f\x41\x41\x41\x41'
	# 1f: B
	echo -en '\x00\x00\x7e\x7e\x41\x41\x41\x41'
	echo -en '\x7e\x7e\x41\x41\x41\x41\x7e\x7e'
	# 20: C
	echo -en '\x00\x00\x3e\x3e\x41\x41\x40\x40'
	echo -en '\x40\x40\x40\x40\x41\x41\x3e\x3e'
	# 21: D
	echo -en '\x00\x00\x7c\x7c\x42\x42\x41\x41'
	echo -en '\x41\x41\x41\x41\x42\x42\x7c\x7c'
	# 22: E
	echo -en '\x00\x00\x7f\x7f\x40\x40\x40\x40'
	echo -en '\x7f\x7f\x40\x40\x40\x40\x7f\x7f'
	# 23: F
	echo -en '\x00\x00\x7f\x7f\x40\x40\x40\x40'
	echo -en '\x7e\x7e\x40\x40\x40\x40\x40\x40'
	# 24: G
	echo -en '\x00\x00\x3e\x3e\x41\x41\x40\x40'
	echo -en '\x4f\x4f\x41\x41\x41\x41\x3e\x3e'
	# 25: H
	echo -en '\x00\x00\x41\x41\x41\x41\x41\x41'
	echo -en '\x7f\x7f\x41\x41\x41\x41\x41\x41'
	# 26: I
	echo -en '\x00\x00\x3e\x3e\x08\x08\x08\x08'
	echo -en '\x08\x08\x08\x08\x08\x08\x3e\x3e'
	# 27: J
	echo -en '\x00\x00\x07\x07\x02\x02\x02\x02'
	echo -en '\x02\x02\x02\x02\x22\x22\x1c\x1c'
	# 28: K
	echo -en '\x00\x00\x43\x43\x44\x44\x48\x48'
	echo -en '\x50\x50\x68\x68\x44\x44\x43\x43'
	# 29: L
	echo -en '\x00\x00\x40\x40\x40\x40\x40\x40'
	echo -en '\x40\x40\x40\x40\x40\x40\x7f\x7f'
	# 2a: M
	echo -en '\x00\x00\x41\x41\x41\x41\x63\x63'
	echo -en '\x55\x55\x49\x49\x41\x41\x41\x41'
	# 2b: N
	echo -en '\x00\x00\x41\x41\x61\x61\x51\x51'
	echo -en '\x49\x49\x45\x45\x43\x43\x41\x41'
	# 2c: O
	echo -en '\x00\x00\x3e\x3e\x41\x41\x41\x41'
	echo -en '\x41\x41\x41\x41\x41\x41\x3e\x3e'
	# 2d: P
	echo -en '\x00\x00\x7e\x7e\x41\x41\x41\x41'
	echo -en '\x7e\x7e\x40\x40\x40\x40\x40\x40'
	# 2e: Q
	echo -en '\x00\x00\x3e\x3e\x41\x41\x41\x41'
	echo -en '\x41\x41\x4d\x4d\x43\x43\x3f\x3f'
	# 2f: R
	echo -en '\x00\x00\x7e\x7e\x41\x41\x41\x41'
	echo -en '\x7e\x7e\x41\x41\x41\x41\x41\x41'
	# 30: S
	echo -en '\x00\x00\x3e\x3e\x41\x41\x40\x40'
	echo -en '\x3e\x3e\x01\x01\x41\x41\x3e\x3e'
	# 31: T
	echo -en '\x00\x00\x7f\x7f\x08\x08\x08\x08'
	echo -en '\x08\x08\x08\x08\x08\x08\x08\x08'
	# 32: U
	echo -en '\x00\x00\x41\x41\x41\x41\x41\x41'
	echo -en '\x41\x41\x41\x41\x41\x41\x3e\x3e'
	# 33: V
	echo -en '\x00\x00\x41\x41\x41\x41\x41\x41'
	echo -en '\x41\x41\x22\x22\x14\x14\x08\x08'
	# 34: W
	echo -en '\x00\x00\x41\x41\x41\x41\x49\x49'
	echo -en '\x49\x49\x55\x55\x55\x55\x22\x22'
	# 35: X
	echo -en '\x00\x00\x41\x41\x22\x22\x14\x14'
	echo -en '\x08\x08\x14\x14\x22\x22\x41\x41'
	# 36: Y
	echo -en '\x00\x00\x41\x41\x22\x22\x14\x14'
	echo -en '\x08\x08\x08\x08\x08\x08\x08\x08'
	# 37: Z
	echo -en '\x00\x00\x7f\x7f\x02\x02\x04\x04'
	echo -en '\x08\x08\x10\x10\x20\x20\x7f\x7f'

	# ファイルタイプ別アイコン(38-)
	# 不明なファイル(38-)(アイコン番号0)
	# 38: 左上
	echo -en '\x00\x00\x05\x05\x0a\x0f\x08\x0f'
	echo -en '\x17\x1f\x10\x1f\x2f\x3f\x20\x3f'
	# 39: 右上
	echo -en '\x00\x00\x54\x54\xa4\xfc\x0e\xfa'
	echo -en '\xea\xfa\x1e\xf2\xd2\xf2\x3e\xe2'
	# 3a: 右下
	echo -en '\x40\x7f\x40\x7f\x40\x7f\x3f\x3f'
	echo -en '\x04\x04\x07\x04\x03\x03\x00\x00'
	# 3b: 左下
	echo -en '\x22\xe2\x7e\xc2\x42\xc2\xfe\x82'
	echo -en '\x02\x02\xfe\x02\xfc\xfc\x00\x00'

	# 実行ファイルアイコン(38-)(アイコン番号1)
	# 3c: 左上
	echo -en '\x00\x00\x7f\x7f\x40\x40\x5c\x5c'
	echo -en '\x50\x50\x5c\x5c\x50\x50\x5c\x5c'
	# 3d: 右上
	echo -en '\x00\x00\xfe\xfe\x02\x02\x02\x02'
	echo -en '\x02\x02\x02\x02\x02\x02\x02\x02'
	# 3e: 右下
	echo -en '\x3a\x02\x22\x82\x3a\x02\x22\x82'
	echo -en '\x3a\x02\x02\x02\xfe\xfe\x00\x00'
	# 3f: 左下
	echo -en '\x40\x40\x40\x42\x40\x41\x40\x42'
	echo -en '\x40\x40\x40\x40\x7f\x7f\x00\x00'

	# テキストファイルアイコン(40-)(アイコン番号2)
	# 40: 左上
	echo -en '\x00\x00\x05\x05\x0a\x0f\x08\x0f'
	echo -en '\x17\x1f\x10\x1f\x2f\x3f\x20\x3f'
	# 41: 右上
	echo -en '\x00\x00\x54\x54\xa4\xfc\x0e\xfa'
	echo -en '\xea\xfa\x1e\xf2\xd2\xf2\x3e\xe2'
	# 42: 右下
	echo -en '\x22\xe2\x7e\xc2\x42\xc2\xfe\x82'
	echo -en '\x02\x02\xfe\x02\xfc\xfc\x00\x00'
	# 43: 左下
	echo -en '\x40\x7f\x40\x7f\x40\x7f\x3f\x3f'
	echo -en '\x04\x04\x07\x04\x03\x03\x00\x00'

	# テキストファイルアイコン(44-)(アイコン番号3)
	# 44: 左上
	echo -en '\x00\x00\x00\x00\x7f\x7f\x40\x40'
	echo -en '\x40\x40\x40\x44\x40\x4e\x40\x5f'
	# 45: 右上
	echo -en '\x00\x00\x00\x00\xfe\xfe\x02\x02'
	echo -en '\x02\x82\x02\x02\x22\x02\x72\x02'
	# 46: 右下
	echo -en '\x7a\x82\x3e\xc2\x1e\xe2\x0e\xf2'
	echo -en '\x06\xfa\xfe\xfe\x00\x00\x00\x00'
	# 47: 左下
	echo -en '\x40\x7f\x40\x7f\x40\x7f\x40\x7f'
	echo -en '\x40\x7f\x7f\x7f\x00\x00\x00\x00'

	# ひらがな
	# 48: あ
	echo -en '\x10\x10\x7f\x7f\x12\x12\x3f\x3f'
	echo -en '\x55\x55\x59\x59\x51\x51\x26\x26'
	# 49: い
	echo -en '\x00\x00\x42\x42\x42\x42\x41\x41'
	echo -en '\x41\x41\x41\x41\x49\x49\x38\x38'
	# 4a: う
	echo -en '\x00\x00\x3e\x3e\x00\x00\x1e\x1e'
	echo -en '\x61\x61\x01\x01\x02\x02\x1c\x1c'
}

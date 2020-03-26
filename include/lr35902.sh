if [ "${INCLUDE_LR35902_SH+is_defined}" ]; then
	return
fi
INCLUDE_LR35902_SH=true

. include/common.sh

LR35902_ENTRY_ADDR=0100

lr35902_nop() {
	echo -en '\x00'	# nop
}

lr35902_halt() {
	echo -en '\x76'	# halt

	# haltは直後の命令を実行してしまうそうなのでnopを入れる
	lr35902_nop
}

lr35902_disable_interrupts() {
	echo -en '\xf3'		# di
}

lr35902_enable_interrupts() {
	echo -en '\xfb'		# ei
}

lr35902_ei_and_ret() {
	echo -en '\xd9'	# reti
}

lr35902_set_reg() {
	local reg=$1
	local val=$2
	case $reg in
	regA)
		echo -en "\x3e\x${val}"	# ld a,${val}
		;;
	regB)
		echo -en "\x06\x${val}"	# ld b,${val}
		;;
	regC)
		echo -en "\x0e\x${val}"	# ld c,${val}
		;;
	regD)
		echo -en "\x16\x${val}"	# ld d,${val}
		;;
	regE)
		echo -en "\x1e\x${val}"	# ld e,${val}
		;;
	regH)
		echo -en "\x26\x${val}"	# ld h,${val}
		;;
	regL)
		echo -en "\x2e\x${val}"	# ld l,${val}
		;;
	regBC)
		echo -en '\x01'
		echo_2bytes $val	# ld bc,${val}
		;;
	regDE)
		echo -en '\x11'
		echo_2bytes $val	# ld de,${val}
		;;
	regHL)
		echo -en '\x21'
		echo_2bytes $val	# ld hl,${val}
		;;
	esac
}

lr35902_set_SP_from_regHL() {
	echo -en '\xf9'	# ld sp,hl
}

lr35902_set_regHL_and_SP() {
	local val=$1
	lr35902_set_reg regHL $val
	lr35902_set_SP_from_regHL
}

lr35902_push_reg() {
	local reg=$1
	case $reg in
	regBC)
		echo -en '\xc5'	# push bc
		;;
	regDE)
		echo -en '\xd5'	# push de
		;;
	regHL)
		echo -en '\xe5'	# push hl
		;;
	regAF)
		echo -en '\xf5'	# push af
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_push_reg $reg" 1>&2
		return 1
	esac
}

lr35902_pop_reg() {
	local reg=$1
	case $reg in
	regBC)
		echo -en '\xc1'	# pop bc
		;;
	regDE)
		echo -en '\xd1'	# pop de
		;;
	regHL)
		echo -en '\xe1'	# pop hl
		;;
	regAF)
		echo -en '\xf1'	# pop af
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_pop_reg $reg" 1>&2
		return 1
	esac
}

lr35902_clear_reg() {
	local reg=$1
	case $reg in
	regA)
		echo -en '\xaf'	# xor a
		;;
	reg?)
		lr35902_set_reg $reg 00
		;;
	reg??)
		lr35902_set_reg $reg 0000
		;;
	esac
}

lr35902_copy_to_regA_from() {
	local reg=$1
	case $reg in
	ptrBC)
		echo -en '\x0a'	# ld a,[bc]
		;;
	ptrDE)
		echo -en '\x1a'	# ld a,[de]
		;;
	regB)
		echo -en '\x78'	# ld a,b
		;;
	regC)
		echo -en '\x79'	# ld a,c
		;;
	regD)
		echo -en '\x7a'	# ld a,d
		;;
	regE)
		echo -en '\x7b'	# ld a,e
		;;
	regH)
		echo -en '\x7c'	# ld a,h
		;;
	regL)
		echo -en '\x7d'	# ld a,l
		;;
	ptrHL)
		echo -en '\x7e'	# ld a,[hl]
		;;
	regA)
		echo -en '\x7f'	# ld a,a
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_copy_to_regA_from $reg" 1>&2
		return 1
	esac
}

lr35902_copy_to_regB_from() {
	local reg=$1
	case $reg in
	regB)
		echo -en '\x40'	# ld b,b
		;;
	regC)
		echo -en '\x41'	# ld b,c
		;;
	regD)
		echo -en '\x42'	# ld b,d
		;;
	regE)
		echo -en '\x43'	# ld b,e
		;;
	regH)
		echo -en '\x44'	# ld b,h
		;;
	regL)
		echo -en '\x45'	# ld b,l
		;;
	ptrHL)
		echo -en '\x46'	# ld b,[hl]
		;;
	regA)
		echo -en '\x47'	# ld b,a
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_copy_to_regB_from $reg" 1>&2
		return 1
	esac
}

lr35902_copy_to_regC_from() {
	local reg=$1
	case $reg in
	regB)
		echo -en '\x48'	# ld c,b
		;;
	regC)
		echo -en '\x49'	# ld c,c
		;;
	regD)
		echo -en '\x4a'	# ld c,d
		;;
	regE)
		echo -en '\x4b'	# ld c,e
		;;
	regH)
		echo -en '\x4c'	# ld c,h
		;;
	regL)
		echo -en '\x4d'	# ld c,l
		;;
	ptrHL)
		echo -en '\x4e'	# ld c,[hl]
		;;
	regA)
		echo -en '\x4f'	# ld c,a
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_copy_to_regC_from $reg" 1>&2
		return 1
	esac
}

lr35902_copy_to_regD_from() {
	local reg=$1
	case $reg in
	regB)
		echo -en '\x50'	# ld d,b
		;;
	regC)
		echo -en '\x51'	# ld d,c
		;;
	regD)
		echo -en '\x52'	# ld d,d
		;;
	regE)
		echo -en '\x53'	# ld d,e
		;;
	regH)
		echo -en '\x54'	# ld d,h
		;;
	regL)
		echo -en '\x55'	# ld d,l
		;;
	ptrHL)
		echo -en '\x56'	# ld d,[hl]
		;;
	regA)
		echo -en '\x57'	# ld d,a
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_copy_to_regD_from $reg" 1>&2
		return 1
	esac
}

lr35902_copy_to_regE_from() {
	local reg=$1
	case $reg in
	regB)
		echo -en '\x58'	# ld e,b
		;;
	regC)
		echo -en '\x59'	# ld e,c
		;;
	regD)
		echo -en '\x5a'	# ld e,d
		;;
	regE)
		echo -en '\x5b'	# ld e,e
		;;
	regH)
		echo -en '\x5c'	# ld e,h
		;;
	regL)
		echo -en '\x5d'	# ld e,l
		;;
	ptrHL)
		echo -en '\x5e'	# ld e,[hl]
		;;
	regA)
		echo -en '\x5f'	# ld e,a
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_copy_to_regE_from $reg" 1>&2
		return 1
	esac
}

lr35902_copy_to_regH_from() {
	local reg=$1
	case $reg in
	regB)
		echo -en '\x60'	# ld h,b
		;;
	regC)
		echo -en '\x61'	# ld h,c
		;;
	regD)
		echo -en '\x62'	# ld h,d
		;;
	regE)
		echo -en '\x63'	# ld h,e
		;;
	regH)
		echo -en '\x64'	# ld h,h
		;;
	regL)
		echo -en '\x65'	# ld h,l
		;;
	ptrHL)
		echo -en '\x66'	# ld h,[hl]
		;;
	regA)
		echo -en '\x67'	# ld h,a
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_copy_to_regH_from $reg" 1>&2
		return 1
	esac
}

lr35902_copy_to_regL_from() {
	local reg=$1
	case $reg in
	regB)
		echo -en '\x68'	# ld l,b
		;;
	regC)
		echo -en '\x69'	# ld l,c
		;;
	regD)
		echo -en '\x6a'	# ld l,d
		;;
	regE)
		echo -en '\x6b'	# ld l,e
		;;
	regH)
		echo -en '\x6c'	# ld l,h
		;;
	regL)
		echo -en '\x6d'	# ld l,l
		;;
	ptrHL)
		echo -en '\x6e'	# ld l,[hl]
		;;
	regA)
		echo -en '\x6f'	# ld l,a
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_copy_to_regL_from $reg" 1>&2
		return 1
	esac
}

lr35902_copy_to_ptrBC_from() {
	local reg=$1
	case $reg in
	regA)
		echo -en '\x02'	# ld [bc],a
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_copy_to_ptrBC_from $reg" 1>&2
		return 1
	esac
}

lr35902_copy_to_ptrDE_from() {
	local reg=$1
	case $reg in
	regA)
		echo -en '\x12'	# ld [de],a
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_copy_to_ptrDE_from $reg" 1>&2
		return 1
	esac
}

lr35902_copy_to_ptrHL_from() {
	local reg=$1
	case $reg in
	regB)
		echo -en '\x70'	# ld [hl],b
		;;
	regC)
		echo -en '\x71'	# ld [hl],c
		;;
	regD)
		echo -en '\x72'	# ld [hl],d
		;;
	regE)
		echo -en '\x73'	# ld [hl],e
		;;
	regH)
		echo -en '\x74'	# ld [hl],h
		;;
	regL)
		echo -en '\x75'	# ld [hl],l
		;;
	# ld [hl],[hl] という命令は無い
	# 77 は halt に使われている
	regA)
		echo -en '\x77'	# ld [hl],a
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_copy_to_ptrHL_from $reg" 1>&2
		return 1
	esac
}

lr35902_copy_to_from() {
	local dst=$1
	local src=$2
	lr35902_copy_to_${dst}_from $src
}

lr35902_copyinc_to_ptrHL_from_regA() {
	echo -en '\x22'	# ldi [hl],a
}

lr35902_copyinc_to_regA_from_ptrHL() {
	echo -en '\x2a'	# ldi a,[hl]
}

lr35902_copydec_to_ptrHL_from_regA() {
	echo -en '\x32'	# ldd [hl],a
}

lr35902_copydec_to_regA_from_ptrHL() {
	echo -en '\x3a'	# ldd a,[hl]
}

lr35902_copy_to_regA_from_addr() {
	local addr=$1
	echo -en '\xfa'
	echo_2bytes $addr	# ld a,[${addr}]
}

lr35902_copy_to_addr_from_regA() {
	local addr=$1
	echo -en '\xea'
	echo_2bytes $addr	# ld [${addr}],a
}

lr35902_copy_to_regA_from_high_addr() {
	local addr=$1
	echo -en "\xf0\x${addr}"	# ld a,[0xff00+${addr}]
}

lr35902_copy_to_high_addr_from_regA() {
	local addr=$1
	echo -en "\xe0\x${addr}"	# ld [0xff00+${addr}],a
}

lr35902_copy_to_regA_from_ioport() {
	local ioport=$1
	echo -en "\xf0\x${ioport}"	# ld a,[0xff00+${ioport}]
}

lr35902_copy_to_ioport_from_regA() {
	local ioport=$1
	echo -en "\xe0\x${ioport}"	# ld [0xff00+${ioport}],a
}

lr35902_compare_regA_and() {
	local reg_or_val=$1
	case $reg_or_val in
	regA)
		echo -en '\xbf'	# cp a
		;;
	regB)
		echo -en '\xb8'	# cp b
		;;
	regC)
		echo -en '\xb9'	# cp c
		;;
	regD)
		echo -en '\xba'	# cp d
		;;
	regE)
		echo -en '\xbb'	# cp e
		;;
	regH)
		echo -en '\xbc'	# cp h
		;;
	regL)
		echo -en '\xbd'	# cp l
		;;
	ptrHL)
		echo -en '\xbe'	# cp [hl]
		;;
	*)
		echo -en "\xfe\x${reg_or_val}"	# cp ${reg_or_val}
		;;
	esac
}

lr35902_inc() {
	local reg=$1
	case $reg in
	regA)
		echo -en '\x3c'	# inc a
		;;
	regB)
		echo -en '\x04'	# inc b
		;;
	regC)
		echo -en '\x0c'	# inc c
		;;
	regD)
		echo -en '\x14'	# inc d
		;;
	regE)
		echo -en '\x1c'	# inc e
		;;
	regH)
		echo -en '\x24'	# inc h
		;;
	regL)
		echo -en '\x2c'	# inc l
		;;
	regBC)
		echo -en '\x03'	# inc bc
		;;
	regDE)
		echo -en '\x13'	# inc de
		;;
	regHL)
		echo -en '\x23'	# inc hl
		;;
	ptrHL)
		echo -en '\x34'	# inc [hl]
		;;
	esac
}

lr35902_dec() {
	local reg=$1
	case $reg in
	regA)
		echo -en '\x3d'	# dec a
		;;
	regB)
		echo -en '\x05'	# dec b
		;;
	regC)
		echo -en '\x0d'	# dec c
		;;
	regD)
		echo -en '\x15'	# dec d
		;;
	regE)
		echo -en '\x1d'	# dec e
		;;
	regH)
		echo -en '\x25'	# dec h
		;;
	regL)
		echo -en '\x2d'	# dec l
		;;
	regBC)
		echo -en '\x0b'	# dec bc
		;;
	regDE)
		echo -en '\x1b'	# dec de
		;;
	regHL)
		echo -en '\x2b'	# dec hl
		;;
	ptrHL)
		echo -en '\x35'	# dec [hl]
		;;
	esac
}

lr35902_rel_jump() {
	local offset=$1
	echo -en "\x18\x${offset}"	# jr ${offset}
}

lr35902_rel_jump_with_cond() {
	local cond=$1
	local offset=$2
	case $cond in
	NZ)
		echo -en "\x20\x${offset}"	# jr nz,${offset}
		;;
	Z)
		echo -en "\x28\x${offset}"	# jr z,${offset}
		;;
	NC)
		echo -en "\x30\x${offset}"	# jr nc,${offset}
		;;
	C)
		echo -en "\x38\x${offset}"	# jr c,${offset}
		;;
	esac
}

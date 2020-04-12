if [ "${INCLUDE_LR35902_SH+is_defined}" ]; then
	return
fi
INCLUDE_LR35902_SH=true

. include/common.sh

LR35902_ENTRY_ADDR=0100

ASM_LIST_FILE=asm.lst

to_regname() {
	local reg=$1
	case $reg in
	regA)
		echo a
		;;
	regB)
		echo b
		;;
	regC)
		echo c
		;;
	regD)
		echo d
		;;
	regE)
		echo e
		;;
	regH)
		echo h
		;;
	regL)
		echo l
		;;
	regAF)
		echo af
		;;
	regBC)
		echo bc
		;;
	regDE)
		echo de
		;;
	regHL)
		echo hl
		;;
	regSP)
		echo sp
		;;
	ptrBC)
		echo '[bc]'
		;;
	ptrDE)
		echo '[de]'
		;;
	ptrHL)
		echo '[hl]'
		;;
	*)
		echo -n 'Error: no such register string: ' 1>&2
		echo "to_regname $reg" 1>&2
		return 1
	esac
}

to_regnum_pat0() {
	local reg=$1
	case $reg in
	regB)
		echo 0
		;;
	regC)
		echo 1
		;;
	regD)
		echo 2
		;;
	regE)
		echo 3
		;;
	regH)
		echo 4
		;;
	regL)
		echo 5
		;;
	ptrHL)
		echo 6
		;;
	regA)
		echo 7
		;;
	*)
		echo error
	esac
}

to_regnum_pat1() {
	local reg=$1
	case $reg in
	regB)
		echo 8
		;;
	regC)
		echo 9
		;;
	regD)
		echo a
		;;
	regE)
		echo b
		;;
	regH)
		echo c
		;;
	regL)
		echo d
		;;
	ptrHL)
		echo e
		;;
	regA)
		echo f
		;;
	*)
		echo error
	esac
}

lr35902_nop() {
	echo -en '\x00'	# nop
	echo -e 'nop\t;4' >>$ASM_LIST_FILE
}

lr35902_halt() {
	echo -en '\x76'	# halt
	echo -e 'halt\t;4' >>$ASM_LIST_FILE

	# haltは直後の命令を実行してしまうそうなのでnopを入れる
	lr35902_nop
}

lr35902_call() {
	local addr=$1
	echo -en '\xcd'
	echo_2bytes $addr	# call $addr
	echo -e "call \$$addr\t;24" >>$ASM_LIST_FILE
}

lr35902_return() {
	echo -en '\xc9'	# ret
	echo -e 'ret\t;16' >>$ASM_LIST_FILE
}

lr35902_disable_interrupts() {
	echo -en '\xf3'		# di
	echo -e 'di\t;4' >>$ASM_LIST_FILE
}

lr35902_enable_interrupts() {
	echo -en '\xfb'		# ei
	echo -e 'ei\t;4' >>$ASM_LIST_FILE
}

lr35902_ei_and_ret() {
	echo -en '\xd9'	# reti
	echo -e 'reti\t;16' >>$ASM_LIST_FILE
}

lr35902_set_reg() {
	local reg=$1
	local val=$2
	case $reg in
	regA)
		echo -en "\x3e\x${val}"	# ld a,${val}
		echo -e "ld a,\$$val\t;8" >>$ASM_LIST_FILE
		;;
	regB)
		echo -en "\x06\x${val}"	# ld b,${val}
		echo -e "ld b,\$$val\t;8" >>$ASM_LIST_FILE
		;;
	regC)
		echo -en "\x0e\x${val}"	# ld c,${val}
		echo -e "ld c,\$$val\t;8" >>$ASM_LIST_FILE
		;;
	regD)
		echo -en "\x16\x${val}"	# ld d,${val}
		echo -e "ld d,\$$val\t;8" >>$ASM_LIST_FILE
		;;
	regE)
		echo -en "\x1e\x${val}"	# ld e,${val}
		echo -e "ld e,\$$val\t;8" >>$ASM_LIST_FILE
		;;
	regH)
		echo -en "\x26\x${val}"	# ld h,${val}
		echo -e "ld h,\$$val\t;8" >>$ASM_LIST_FILE
		;;
	regL)
		echo -en "\x2e\x${val}"	# ld l,${val}
		echo -e "ld l,\$$val\t;8" >>$ASM_LIST_FILE
		;;
	regBC)
		echo -en '\x01'
		echo_2bytes $val	# ld bc,${val}
		echo -e "ld bc,\$$val\t;12" >>$ASM_LIST_FILE
		;;
	regDE)
		echo -en '\x11'
		echo_2bytes $val	# ld de,${val}
		echo -e "ld de,\$$val\t;12" >>$ASM_LIST_FILE
		;;
	regHL)
		echo -en '\x21'
		echo_2bytes $val	# ld hl,${val}
		echo -e "ld hl,\$$val\t;12" >>$ASM_LIST_FILE
		;;
	esac
}

lr35902_set_SP_from_regHL() {
	echo -en '\xf9'	# ld sp,hl
	echo -e 'ld sp,hl\t;8' >>$ASM_LIST_FILE
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
		echo -e 'push bc\t;16' >>$ASM_LIST_FILE
		;;
	regDE)
		echo -en '\xd5'	# push de
		echo -e 'push de\t;16' >>$ASM_LIST_FILE
		;;
	regHL)
		echo -en '\xe5'	# push hl
		echo -e 'push hl\t;16' >>$ASM_LIST_FILE
		;;
	regAF)
		echo -en '\xf5'	# push af
		echo -e 'push af\t;16' >>$ASM_LIST_FILE
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
		echo -e 'pop bc\t;12' >>$ASM_LIST_FILE
		;;
	regDE)
		echo -en '\xd1'	# pop de
		echo -e 'pop de\t;12' >>$ASM_LIST_FILE
		;;
	regHL)
		echo -en '\xe1'	# pop hl
		echo -e 'pop hl\t;12' >>$ASM_LIST_FILE
		;;
	regAF)
		echo -en '\xf1'	# pop af
		echo -e 'pop af\t;12' >>$ASM_LIST_FILE
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
		echo -e 'xor a\t;4' >>$ASM_LIST_FILE
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
		echo -e 'ld a,[bc]\t;8' >>$ASM_LIST_FILE
		;;
	ptrDE)
		echo -en '\x1a'	# ld a,[de]
		echo -e 'ld a,[de]\t;8' >>$ASM_LIST_FILE
		;;
	regB)
		echo -en '\x78'	# ld a,b
		echo -e 'ld a,b\t;4' >>$ASM_LIST_FILE
		;;
	regC)
		echo -en '\x79'	# ld a,c
		echo -e 'ld a,c\t;4' >>$ASM_LIST_FILE
		;;
	regD)
		echo -en '\x7a'	# ld a,d
		echo -e 'ld a,d\t;4' >>$ASM_LIST_FILE
		;;
	regE)
		echo -en '\x7b'	# ld a,e
		echo -e 'ld a,e\t;4' >>$ASM_LIST_FILE
		;;
	regH)
		echo -en '\x7c'	# ld a,h
		echo -e 'ld a,h\t;4' >>$ASM_LIST_FILE
		;;
	regL)
		echo -en '\x7d'	# ld a,l
		echo -e 'ld a,l\t;4' >>$ASM_LIST_FILE
		;;
	ptrHL)
		echo -en '\x7e'	# ld a,[hl]
		echo -e 'ld a,[hl]\t;8' >>$ASM_LIST_FILE
		;;
	regA)
		echo -en '\x7f'	# ld a,a
		echo -e 'ld a,a\t;4' >>$ASM_LIST_FILE
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
		echo -e 'ld b,b\t;4' >>$ASM_LIST_FILE
		;;
	regC)
		echo -en '\x41'	# ld b,c
		echo -e 'ld b,c\t;4' >>$ASM_LIST_FILE
		;;
	regD)
		echo -en '\x42'	# ld b,d
		echo -e 'ld b,d\t;4' >>$ASM_LIST_FILE
		;;
	regE)
		echo -en '\x43'	# ld b,e
		echo -e 'ld b,e\t;4' >>$ASM_LIST_FILE
		;;
	regH)
		echo -en '\x44'	# ld b,h
		echo -e 'ld b,h\t;4' >>$ASM_LIST_FILE
		;;
	regL)
		echo -en '\x45'	# ld b,l
		echo -e 'ld b,l\t;4' >>$ASM_LIST_FILE
		;;
	ptrHL)
		echo -en '\x46'	# ld b,[hl]
		echo -e 'ld b,[hl]\t;8' >>$ASM_LIST_FILE
		;;
	regA)
		echo -en '\x47'	# ld b,a
		echo -e 'ld b,a\t;4' >>$ASM_LIST_FILE
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
		echo -e 'ld c,b\t;4' >>$ASM_LIST_FILE
		;;
	regC)
		echo -en '\x49'	# ld c,c
		echo -e 'ld c,c\t;4' >>$ASM_LIST_FILE
		;;
	regD)
		echo -en '\x4a'	# ld c,d
		echo -e 'ld c,d\t;4' >>$ASM_LIST_FILE
		;;
	regE)
		echo -en '\x4b'	# ld c,e
		echo -e 'ld c,e\t;4' >>$ASM_LIST_FILE
		;;
	regH)
		echo -en '\x4c'	# ld c,h
		echo -e 'ld c,h\t;4' >>$ASM_LIST_FILE
		;;
	regL)
		echo -en '\x4d'	# ld c,l
		echo -e 'ld c,l\t;4' >>$ASM_LIST_FILE
		;;
	ptrHL)
		echo -en '\x4e'	# ld c,[hl]
		echo -e 'ld c,[hl]\t;8' >>$ASM_LIST_FILE
		;;
	regA)
		echo -en '\x4f'	# ld c,a
		echo -e 'ld c,a\t;4' >>$ASM_LIST_FILE
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
		echo -e 'ld d,b\t;4' >>$ASM_LIST_FILE
		;;
	regC)
		echo -en '\x51'	# ld d,c
		echo -e 'ld d,c\t;4' >>$ASM_LIST_FILE
		;;
	regD)
		echo -en '\x52'	# ld d,d
		echo -e 'ld d,d\t;4' >>$ASM_LIST_FILE
		;;
	regE)
		echo -en '\x53'	# ld d,e
		echo -e 'ld d,e\t;4' >>$ASM_LIST_FILE
		;;
	regH)
		echo -en '\x54'	# ld d,h
		echo -e 'ld d,h\t;4' >>$ASM_LIST_FILE
		;;
	regL)
		echo -en '\x55'	# ld d,l
		echo -e 'ld d,l\t;4' >>$ASM_LIST_FILE
		;;
	ptrHL)
		echo -en '\x56'	# ld d,[hl]
		echo -e 'ld d,[hl]\t;8' >>$ASM_LIST_FILE
		;;
	regA)
		echo -en '\x57'	# ld d,a
		echo -e 'ld d,a\t;4' >>$ASM_LIST_FILE
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
		echo -e 'ld e,b\t;4' >>$ASM_LIST_FILE
		;;
	regC)
		echo -en '\x59'	# ld e,c
		echo -e 'ld e,c\t;4' >>$ASM_LIST_FILE
		;;
	regD)
		echo -en '\x5a'	# ld e,d
		echo -e 'ld e,d\t;4' >>$ASM_LIST_FILE
		;;
	regE)
		echo -en '\x5b'	# ld e,e
		echo -e 'ld e,e\t;4' >>$ASM_LIST_FILE
		;;
	regH)
		echo -en '\x5c'	# ld e,h
		echo -e 'ld e,h\t;4' >>$ASM_LIST_FILE
		;;
	regL)
		echo -en '\x5d'	# ld e,l
		echo -e 'ld e,l\t;4' >>$ASM_LIST_FILE
		;;
	ptrHL)
		echo -en '\x5e'	# ld e,[hl]
		echo -e 'ld e,[hl]\t;8' >>$ASM_LIST_FILE
		;;
	regA)
		echo -en '\x5f'	# ld e,a
		echo -e 'ld e,a\t;4' >>$ASM_LIST_FILE
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
		echo -e 'ld h,b\t;4' >>$ASM_LIST_FILE
		;;
	regC)
		echo -en '\x61'	# ld h,c
		echo -e 'ld h,c\t;4' >>$ASM_LIST_FILE
		;;
	regD)
		echo -en '\x62'	# ld h,d
		echo -e 'ld h,d\t;4' >>$ASM_LIST_FILE
		;;
	regE)
		echo -en '\x63'	# ld h,e
		echo -e 'ld h,e\t;4' >>$ASM_LIST_FILE
		;;
	regH)
		echo -en '\x64'	# ld h,h
		echo -e 'ld h,h\t;4' >>$ASM_LIST_FILE
		;;
	regL)
		echo -en '\x65'	# ld h,l
		echo -e 'ld h,l\t;4' >>$ASM_LIST_FILE
		;;
	ptrHL)
		echo -en '\x66'	# ld h,[hl]
		echo -e 'ld h,[hl]\t;8' >>$ASM_LIST_FILE
		;;
	regA)
		echo -en '\x67'	# ld h,a
		echo -e 'ld h,a\t;4' >>$ASM_LIST_FILE
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
		echo -e 'ld l,b\t;4' >>$ASM_LIST_FILE
		;;
	regC)
		echo -en '\x69'	# ld l,c
		echo -e 'ld l,c\t;4' >>$ASM_LIST_FILE
		;;
	regD)
		echo -en '\x6a'	# ld l,d
		echo -e 'ld l,d\t;4' >>$ASM_LIST_FILE
		;;
	regE)
		echo -en '\x6b'	# ld l,e
		echo -e 'ld l,e\t;4' >>$ASM_LIST_FILE
		;;
	regH)
		echo -en '\x6c'	# ld l,h
		echo -e 'ld l,h\t;4' >>$ASM_LIST_FILE
		;;
	regL)
		echo -en '\x6d'	# ld l,l
		echo -e 'ld l,l\t;4' >>$ASM_LIST_FILE
		;;
	ptrHL)
		echo -en '\x6e'	# ld l,[hl]
		echo -e 'ld l,[hl]\t;8' >>$ASM_LIST_FILE
		;;
	regA)
		echo -en '\x6f'	# ld l,a
		echo -e 'ld l,a\t;4' >>$ASM_LIST_FILE
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
		echo -e 'ld [bc],a\t;8' >>$ASM_LIST_FILE
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
		echo -e 'ld [de],a\t;8' >>$ASM_LIST_FILE
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
		echo -e 'ld [hl],b\t;8' >>$ASM_LIST_FILE
		;;
	regC)
		echo -en '\x71'	# ld [hl],c
		echo -e 'ld [hl],c\t;8' >>$ASM_LIST_FILE
		;;
	regD)
		echo -en '\x72'	# ld [hl],d
		echo -e 'ld [hl],d\t;8' >>$ASM_LIST_FILE
		;;
	regE)
		echo -en '\x73'	# ld [hl],e
		echo -e 'ld [hl],e\t;8' >>$ASM_LIST_FILE
		;;
	regH)
		echo -en '\x74'	# ld [hl],h
		echo -e 'ld [hl],h\t;8' >>$ASM_LIST_FILE
		;;
	regL)
		echo -en '\x75'	# ld [hl],l
		echo -e 'ld [hl],l\t;8' >>$ASM_LIST_FILE
		;;
	# ld [hl],[hl] という命令は無い
	# 77 は halt に使われている
	regA)
		echo -en '\x77'	# ld [hl],a
		echo -e 'ld [hl],a\t;8' >>$ASM_LIST_FILE
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
	echo -e 'ldi [hl],a\t;8' >>$ASM_LIST_FILE
}

lr35902_copyinc_to_regA_from_ptrHL() {
	echo -en '\x2a'	# ldi a,[hl]
	echo -e 'ldi a,[hl]\t;8' >>$ASM_LIST_FILE
}

lr35902_copydec_to_ptrHL_from_regA() {
	echo -en '\x32'	# ldd [hl],a
	echo -e 'ldd [hl],a\t;8' >>$ASM_LIST_FILE
}

lr35902_copydec_to_regA_from_ptrHL() {
	echo -en '\x3a'	# ldd a,[hl]
	echo -e 'ldd a,[hl]\t;8' >>$ASM_LIST_FILE
}

lr35902_copy_to_regA_from_addr() {
	local addr=$1
	echo -en '\xfa'
	echo_2bytes $addr	# ld a,[${addr}]
	echo -e "ld a,[\$$addr]\t;16" >>$ASM_LIST_FILE
}

lr35902_copy_to_addr_from_regA() {
	local addr=$1
	echo -en '\xea'
	echo_2bytes $addr	# ld [${addr}],a
	echo -e "ld [\$$addr],a\t;16" >>$ASM_LIST_FILE
}

lr35902_copy_to_regA_from_high_addr() {
	local addr=$1
	echo -en "\xf0\x${addr}"	# ld a,[0xff00+${addr}]
	echo -e "ld a,[\$ff00+\$$addr]\t;12" >>$ASM_LIST_FILE
}

lr35902_copy_to_high_addr_from_regA() {
	local addr=$1
	echo -en "\xe0\x${addr}"	# ld [0xff00+${addr}],a
	echo -e "ld [\$ff00+\$$addr],a\t;12" >>$ASM_LIST_FILE
}

lr35902_copy_to_regA_from_ioport() {
	local ioport=$1
	echo -en "\xf0\x${ioport}"	# ld a,[0xff00+${ioport}]
	echo -e "ld a,[\$ff00+\$$ioport]\t;12" >>$ASM_LIST_FILE
}

lr35902_copy_to_ioport_from_regA() {
	local ioport=$1
	echo -en "\xe0\x${ioport}"	# ld [0xff00+${ioport}],a
	echo -e "ld [\$ff00+\$$ioport],a\t;12" >>$ASM_LIST_FILE
}

lr35902_compare_regA_and() {
	local reg_or_val=$1
	case $reg_or_val in
	regA)
		echo -en '\xbf'	# cp a
		echo -e 'cp a\t;4' >>$ASM_LIST_FILE
		;;
	regB)
		echo -en '\xb8'	# cp b
		echo -e 'cp b\t;4' >>$ASM_LIST_FILE
		;;
	regC)
		echo -en '\xb9'	# cp c
		echo -e 'cp c\t;4' >>$ASM_LIST_FILE
		;;
	regD)
		echo -en '\xba'	# cp d
		echo -e 'cp d\t;4' >>$ASM_LIST_FILE
		;;
	regE)
		echo -en '\xbb'	# cp e
		echo -e 'cp e\t;4' >>$ASM_LIST_FILE
		;;
	regH)
		echo -en '\xbc'	# cp h
		echo -e 'cp h\t;4' >>$ASM_LIST_FILE
		;;
	regL)
		echo -en '\xbd'	# cp l
		echo -e 'cp l\t;4' >>$ASM_LIST_FILE
		;;
	ptrHL)
		echo -en '\xbe'	# cp [hl]
		echo -e 'cp [hl]\t;8' >>$ASM_LIST_FILE
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
		echo -e 'inc a\t;4' >>$ASM_LIST_FILE
		;;
	regB)
		echo -en '\x04'	# inc b
		echo -e 'inc b\t;4' >>$ASM_LIST_FILE
		;;
	regC)
		echo -en '\x0c'	# inc c
		echo -e 'inc c\t;4' >>$ASM_LIST_FILE
		;;
	regD)
		echo -en '\x14'	# inc d
		echo -e 'inc d\t;4' >>$ASM_LIST_FILE
		;;
	regE)
		echo -en '\x1c'	# inc e
		echo -e 'inc e\t;4' >>$ASM_LIST_FILE
		;;
	regH)
		echo -en '\x24'	# inc h
		echo -e 'inc h\t;4' >>$ASM_LIST_FILE
		;;
	regL)
		echo -en '\x2c'	# inc l
		echo -e 'inc l\t;4' >>$ASM_LIST_FILE
		;;
	regBC)
		echo -en '\x03'	# inc bc
		echo -e 'inc bc\t;8' >>$ASM_LIST_FILE
		;;
	regDE)
		echo -en '\x13'	# inc de
		echo -e 'inc de\t;8' >>$ASM_LIST_FILE
		;;
	regHL)
		echo -en '\x23'	# inc hl
		echo -e 'inc hl\t;8' >>$ASM_LIST_FILE
		;;
	ptrHL)
		echo -en '\x34'	# inc [hl]
		echo -e 'inc [hl]\t;12' >>$ASM_LIST_FILE
		;;
	esac
}

lr35902_dec() {
	local reg=$1
	case $reg in
	regA)
		echo -en '\x3d'	# dec a
		echo -e 'dec a\t;4' >>$ASM_LIST_FILE
		;;
	regB)
		echo -en '\x05'	# dec b
		echo -e 'dec b\t;4' >>$ASM_LIST_FILE
		;;
	regC)
		echo -en '\x0d'	# dec c
		echo -e 'dec c\t;4' >>$ASM_LIST_FILE
		;;
	regD)
		echo -en '\x15'	# dec d
		echo -e 'dec d\t;4' >>$ASM_LIST_FILE
		;;
	regE)
		echo -en '\x1d'	# dec e
		echo -e 'dec e\t;4' >>$ASM_LIST_FILE
		;;
	regH)
		echo -en '\x25'	# dec h
		echo -e 'dec h\t;4' >>$ASM_LIST_FILE
		;;
	regL)
		echo -en '\x2d'	# dec l
		echo -e 'dec l\t;4' >>$ASM_LIST_FILE
		;;
	regBC)
		echo -en '\x0b'	# dec bc
		echo -e 'dec bc\t;8' >>$ASM_LIST_FILE
		;;
	regDE)
		echo -en '\x1b'	# dec de
		echo -e 'dec de\t;8' >>$ASM_LIST_FILE
		;;
	regHL)
		echo -en '\x2b'	# dec hl
		echo -e 'dec hl\t;8' >>$ASM_LIST_FILE
		;;
	ptrHL)
		echo -en '\x35'	# dec [hl]
		echo -e 'dec [hl]\t;12' >>$ASM_LIST_FILE
		;;
	esac
}

lr35902_add_to_regA() {
	local reg_or_val=$1
	case $reg_or_val in
	regB)
		echo -en '\x80'	# add a,b
		echo -e 'add a,b\t;4' >>$ASM_LIST_FILE
		;;
	regC)
		echo -en '\x81'	# add a,c
		echo -e 'add a,c\t;4' >>$ASM_LIST_FILE
		;;
	regD)
		echo -en '\x82'	# add a,d
		echo -e 'add a,d\t;4' >>$ASM_LIST_FILE
		;;
	regE)
		echo -en '\x83'	# add a,e
		echo -e 'add a,e\t;4' >>$ASM_LIST_FILE
		;;
	regH)
		echo -en '\x84'	# add a,h
		echo -e 'add a,h\t;4' >>$ASM_LIST_FILE
		;;
	regL)
		echo -en '\x85'	# add a,l
		echo -e 'add a,l\t;4' >>$ASM_LIST_FILE
		;;
	ptrHL)
		echo -en '\x86'	# add a,[hl]
		echo -e 'add a,[hl]\t;8' >>$ASM_LIST_FILE
		;;
	regA)
		echo -en '\x87'	# add a,a
		echo -e 'add a,a\t;4' >>$ASM_LIST_FILE
		;;
	*)
		echo -en "\xc6\x${reg_or_val}"	# add a,${reg_or_val}
		echo -e "add a,\$$reg_or_val\t;8" >>$ASM_LIST_FILE
		;;
	esac
}

lr35902_add_to_regHL() {
	local reg=$1
	case $reg in
	regBC)
		echo -en '\x09'	# add hl,bc
		echo -e 'add hl,bc\t;8' >>$ASM_LIST_FILE
		;;
	regDE)
		echo -en '\x19'	# add hl,de
		echo -e 'add hl,de\t;8' >>$ASM_LIST_FILE
		;;
	regHL)
		echo -en '\x29'	# add hl,hl
		echo -e 'add hl,hl\t;8' >>$ASM_LIST_FILE
		;;
	regSP)
		echo -en '\x39'	# add hl,sp
		echo -e 'add hl,sp\t;8' >>$ASM_LIST_FILE
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_add_to_regHL $reg" 1>&2
		return 1
	esac
}

lr35902_and_to_regA() {
	local reg_or_val=$1
	case $reg_or_val in
	regB)
		echo -en '\xa0'	# and b
		echo -e 'and b\t;4' >>$ASM_LIST_FILE
		;;
	regC)
		echo -en '\xa1'	# and c
		echo -e 'and c\t;4' >>$ASM_LIST_FILE
		;;
	regD)
		echo -en '\xa2'	# and d
		echo -e 'and d\t;4' >>$ASM_LIST_FILE
		;;
	regE)
		echo -en '\xa3'	# and e
		echo -e 'and e\t;4' >>$ASM_LIST_FILE
		;;
	regH)
		echo -en '\xa4'	# and h
		echo -e 'and h\t;4' >>$ASM_LIST_FILE
		;;
	regL)
		echo -en '\xa5'	# and l
		echo -e 'and l\t;4' >>$ASM_LIST_FILE
		;;
	ptrHL)
		echo -en '\xa6'	# and [hl]
		echo -e 'and [hl]\t;8' >>$ASM_LIST_FILE
		;;
	regA)
		echo -en '\xa7'	# and a
		echo -e 'and a\t;4' >>$ASM_LIST_FILE
		;;
	*)
		echo -en "\xe6\x${reg_or_val}"	# and ${reg_or_val}
		echo -e "and \$$reg_or_val\t;8" >>$ASM_LIST_FILE
		;;
	esac
}

lr35902_xor_to_regA() {
	local reg_or_val=$1

	local regnum=$(to_regnum_pat1 $reg_or_val)
	if [ "$regnum" != 'error' ]; then
		echo -en "\xa$regnum"
		local regname=$(to_regname $reg_or_val)
		local cyc
		if [ "$reg_or_val" = 'ptrHL' ]; then
			cyc=8
		else
			cyc=4
		fi
		echo -e "xor $regname\t;$cyc" >>$ASM_LIST_FILE
	else
		echo -en "\xee\x$reg_or_val"
		echo -e "xor \$$reg_or_val\t;8" >>$ASM_LIST_FILE
	fi
}

# MEMO: rl/rlcやrr/rrcを実装する際は
#       rl側をrotate_left_through_carryという名前で実装する
#       ∵ 振る舞いからしてrl側がCarryを通してシフトしている

lr35902_shift_left_arithmetic() {
	local reg=$1

	local regnum=$(to_regnum_pat0 $reg)
	if [ "$regnum" = 'error' ]; then
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_shift_left_arithmetic $reg" 1>&2
		return 1
	fi
	local pref=2
	echo -en "\xcb\x${pref}${regnum}"

	local regname=$(to_regname $reg)
	local cyc
	if [ "$regnum" = "$(to_regnum_pat0 ptrHL)" ]; then
		cyc=16
	else
		cyc=8
	fi
	echo -e "sla $regname\t;$cyc" >>$ASM_LIST_FILE
}

lr35902_func_bitN_of_reg_impl() {
	local n=$1
	local reg=$2
	local to_regnum=$3
	local pref=$4
	local func=$5

	local as_code
	if [ "$func" = 'test' ]; then
		as_code='bit'
	else
		as_code="$func"
	fi

	local regnum=$($to_regnum $reg)
	if [ "$regnum" = 'error' ]; then
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_${func}_bit${n}_of_reg $reg" 1>&2
		return 1
	fi
	echo -en "\xcb\x${pref}${regnum}"

	local regname=$(to_regname $reg)
	local cyc
	if [ "$regnum" = "$($to_regnum ptrHL)" ]; then
		cyc=16
	else
		cyc=8
	fi
	echo -e "${as_code} ${n},$regname\t;$cyc" >>$ASM_LIST_FILE
}

lr35902_test_bitN_of_reg() {
	local n=$1
	local reg=$2
	case $n in
	0)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat0 4 test
		;;
	1)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat1 4 test
		;;
	2)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat0 5 test
		;;
	3)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat1 5 test
		;;
	4)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat0 6 test
		;;
	5)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat1 6 test
		;;
	6)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat0 7 test
		;;
	7)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat1 7 test
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_test_bitN_of_reg $n $reg" 1>&2
		return 1
	esac
}

lr35902_res_bitN_of_reg() {
	local n=$1
	local reg=$2
	case $n in
	0)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat0 8 res
		;;
	1)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat1 8 res
		;;
	2)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat0 9 res
		;;
	3)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat1 9 res
		;;
	4)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat0 a res
		;;
	5)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat1 a res
		;;
	6)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat0 b res
		;;
	7)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat1 b res
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_res_bitN_of_reg $n $reg" 1>&2
		return 1
	esac
}

lr35902_set_bitN_of_reg() {
	local n=$1
	local reg=$2
	case $n in
	0)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat0 c set
		;;
	1)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat1 c set
		;;
	2)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat0 d set
		;;
	3)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat1 d set
		;;
	4)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat0 e set
		;;
	5)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat1 e set
		;;
	6)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat0 f set
		;;
	7)
		lr35902_func_bitN_of_reg_impl $n $reg to_regnum_pat1 f set
		;;
	*)
		echo -n 'Error: no such instruction: ' 1>&2
		echo "lr35902_set_bitN_of_reg $n $reg" 1>&2
		return 1
	esac
}

lr35902_abs_jump() {
	local addr=$1
	echo -en '\xc3'
	echo_2bytes $addr	# jp ${addr}
	echo -e "jp \$$addr\t;16" >>$ASM_LIST_FILE
}

lr35902_rel_jump() {
	local offset=$1
	echo -en "\x18\x${offset}"	# jr ${offset}
	echo -e "jr \$$offset\t;12" >>$ASM_LIST_FILE
}

lr35902_rel_jump_with_cond() {
	local cond=$1
	local offset=$2
	case $cond in
	NZ)
		echo -en "\x20\x${offset}"	# jr nz,${offset}
		echo -e "jr nz,\$$offset\t;12/8" >>$ASM_LIST_FILE
		;;
	Z)
		echo -en "\x28\x${offset}"	# jr z,${offset}
		echo -e "jr z,\$$offset\t;12/8" >>$ASM_LIST_FILE
		;;
	NC)
		echo -en "\x30\x${offset}"	# jr nc,${offset}
		echo -e "jr nc,\$$offset\t;12/8" >>$ASM_LIST_FILE
		;;
	C)
		echo -en "\x38\x${offset}"	# jr c,${offset}
		echo -e "jr c,\$$offset\t;12/8" >>$ASM_LIST_FILE
		;;
	esac
}

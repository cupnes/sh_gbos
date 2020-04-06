#!/bin/bash

# set -uex
set -ue

SRC_TXT_FILE=$1
DST_2BPP_FILE=$2

txt22bpp() {
	local txt=$1
	local out=$2

	local msb=''
	local lsb=''
	for i in $(seq 64); do
		local ch=$(cut -c${i} ${txt})
		case $ch in
		A|'*')
			msb="${msb}1"
			lsb="${lsb}1"
			;;
		B|'+')
			msb="${msb}1"
			lsb="${lsb}0"
			;;
		C|'.')
			msb="${msb}0"
			lsb="${lsb}1"
			;;
		D|'_')
			msb="${msb}0"
			lsb="${lsb}0"
			;;
		esac
		if [ $((i % 8)) -eq 0 ]; then
			local msb_hex=$(echo "obase=16;ibase=2;${msb}" | bc)
			local lsb_hex=$(echo "obase=16;ibase=2;${lsb}" | bc)
			echo -en "\x${lsb_hex}\x${msb_hex}" >>${out}
			printf '\\x%02x\\x%02x' 0x${lsb_hex} 0x${msb_hex}
			msb=''
			lsb=''
		fi
	done
	echo
}

tr -d '\n' <$SRC_TXT_FILE >${SRC_TXT_FILE}.tmp
trap "rm ${SRC_TXT_FILE}.tmp" EXIT

rm -f $DST_2BPP_FILE
txt22bpp ${SRC_TXT_FILE}.tmp $DST_2BPP_FILE

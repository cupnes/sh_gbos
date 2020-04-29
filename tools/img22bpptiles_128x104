#!/bin/bash

# set -uex
set -ue

if [ $# -ne 2 ]; then
	echo "Usage: $0 SRC_IMG_FILE DST_TILES_DIR" 1>&2
	exit 1
fi

SRC_IMG_FILE=$1
DST_TILES_DIR=$2

if [ -e $DST_TILES_DIR -a ! -d $DST_TILES_DIR ]; then
	echo -n "Error: Destination path '$DST_TILES_DIR' already exists" 1>&2
	echo " and is not a directory." 1>&2
	exit 1
fi

if [ -n "$(ls $DST_TILES_DIR 2>/dev/null)" ]; then
	echo -n "Error: Destination path '$DST_TILES_DIR' already exists" 1>&2
	echo " and is not an empty directory." 1>&2
	exit 1
fi

txt22bpp() {
	local txt=$1
	local out=$2

	local msb=''
	local lsb=''
	for i in $(seq 64); do
		local ch=$(cut -c${i} ${txt})
		case $ch in
		A)
			msb="${msb}1"
			lsb="${lsb}1"
			;;
		B)
			msb="${msb}1"
			lsb="${lsb}0"
			;;
		C)
			msb="${msb}0"
			lsb="${lsb}1"
			;;
		D)
			msb="${msb}0"
			lsb="${lsb}0"
			;;
		esac
		if [ $((i % 8)) -eq 0 ]; then
			local msb_hex=$(echo "obase=16;ibase=2;${msb}" | bc)
			local lsb_hex=$(echo "obase=16;ibase=2;${lsb}" | bc)
			echo -en "\x${lsb_hex}\x${msb_hex}" >>${out}
			msb=''
			lsb=''
		fi
	done
}

tempdir=$(mktemp -d)
trap "rm -rf $tempdir" EXIT

src_name=$(basename $SRC_IMG_FILE | rev | cut -d'.' -f2- | rev)

convert $SRC_IMG_FILE -type GrayScale $tempdir/${src_name}_gray.png
convert $tempdir/${src_name}_gray.png -depth 2 $tempdir/${src_name}_depth2.png
convert $tempdir/${src_name}_depth2.png $tempdir/${src_name}_depth2.pgm

oct4col=$(sed -n '$p' $tempdir/${src_name}_depth2.pgm | od -bv -w1 \
		  | cut -d' ' -f2 | head -n -1 | sort -nu | sed 's/^/\\/' \
		  | tr -d '\n')

mkdir $tempdir/${src_name}_crop
convert $tempdir/${src_name}_depth2.pgm \
	-crop 8x8 $tempdir/${src_name}_crop/%03d.pgm

mkdir $tempdir/${src_name}_txt
for pgm_file in $(ls $tempdir/${src_name}_crop); do
	pgm_name=$(echo $pgm_file | rev | cut -d'.' -f2- | rev)
	sed -n '$p' $tempdir/${src_name}_crop/$pgm_file \
		| tr "$oct4col" 'ABCD' \
		     >$tempdir/${src_name}_txt/${pgm_name}.txt
done

mkdir -p $DST_TILES_DIR
for txt_file in $(ls $tempdir/${src_name}_txt); do
	txt_name=$(echo $txt_file | rev | cut -d'.' -f2- | rev)
	txt22bpp $tempdir/${src_name}_txt/$txt_file \
			  ${DST_TILES_DIR}/${txt_name}.2bpp
done

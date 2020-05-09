#!/bin/bash

set -uex
# set -ue

. include/gb.sh

VAR_AREA_SZ=0

main() {
	infinite_halt
}

make_bin() {
	echo_2bytes $(four_digits $VAR_AREA_SZ)

	main
}

make_bin

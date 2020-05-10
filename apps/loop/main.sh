#!/bin/bash

set -uex
# set -ue

. include/gb.sh

main() {
	infinite_halt
}

make_bin() {
	main
}

make_bin

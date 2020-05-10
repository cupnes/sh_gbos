#!/bin/bash

set -uex
# set -ue

. include/gb.sh

main() {
	lr35902_return
}

make_bin() {
	main
}

make_bin

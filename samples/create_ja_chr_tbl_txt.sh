#!/bin/bash

# set -uex
set -ue

dump_char() {
	n=$1
	echo -ne "\x$(printf '%02x' $n)"
}

dump_chars_ln() {
	start_n=$1
	end_n=$2
	for n in $(seq $start_n $end_n); do
		dump_char $n
	done
	echo
}

# 4c-50: あ〜お
dump_chars_ln 76 80

# 51-55: か〜こ
dump_chars_ln 81 85

# 56-5a: さ〜そ
dump_chars_ln 86 90

# 5b-5f: た〜と
dump_chars_ln 91 95

# 60-64: な〜の
dump_chars_ln 96 100

# 65-69: は〜ほ
dump_chars_ln 101 105

# 6a-6e: ま〜も
dump_chars_ln 106 110

# 6f-71: や〜よ
dump_char 111
dump_char 0
dump_char 112
dump_char 0
dump_char 113
echo

# 72-76: ら〜ろ
dump_chars_ln 114 118

# 77-79: わ〜ん
dump_chars_ln 119 121

# 4b: ゛(濁点)
dump_char 75

# 7a: ゜(半濁点)
dump_char 122

# 7f: ―
dump_char 127

# 48: (
dump_char 72

# 49: )
dump_char 73

echo

# 7b-7e: 、。!?
dump_chars_ln 123 126

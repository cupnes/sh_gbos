if [ "${INCLUDE_COMMON_SH+is_defined}" ]; then
	return
fi
INCLUDE_COMMON_SH=true

echo_2bytes() {
	local val=$1
	local top_half=$(echo $val | cut -c-2)
	local bottom_half=$(echo $val | cut -c3-4)
	echo -en "\x${bottom_half}\x${top_half}"
}

two_comp() {
	local val=$1
	local val_up=$(echo $val | tr [:lower:] [:upper:])
	echo "obase=16;ibase=16;100-${val_up}" | bc
}

two_comp_d() {
	local val=$1
	echo "obase=16;256-${val}" | bc
}

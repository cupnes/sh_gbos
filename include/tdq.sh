if [ "${INCLUDE_TDQ_SH+is_defined}" ]; then
	return
fi
INCLUDE_TDQ_SH=true

# タイル描画キュー用定数
GBOS_TDQ_FIRST=c300
GBOS_TDQ_LAST=cefd
GBOS_TDQ_END=cf00
GBOS_TDQ_ENTRY_SIZE=0a
GBOS_TDQ_MAX_DRAW_TILES=04
GBOS_TDQ_STAT_BITNUM_EMPTY=0
GBOS_TDQ_STAT_BITNUM_FULL=1
if [ "${INCLUDE_VARS_SH+is_defined}" ]; then
	return
fi
INCLUDE_VARS_SH=true

var_mouse_x=c000	# マウスカーソルX座標
var_mouse_y=c001	# マウスカーソルY座標
var_btn_stat=c002	# 現在のキー状態を示す変数
var_win_xt=c003	# ウィンドウのX座標(タイル番目)
var_win_yt=c004	# ウィンドウのY座標(タイル番目)
var_prv_btn=c005	# 前回のキー状態を示す変数
var_draw_act_stat=c006	# 描画アクション(DA)ステータス
var_da_var1=c007	# DA用変数1
			# - view_txt: 残り文字数(下位8ビット)
var_da_var2=c008	# DA用変数2
			# - view_txt: 残り文字数(上位8ビット)
var_da_var3=c009	# DA用変数3
			# - view_txt: 次に配置する文字のアドレス下位8ビット
var_da_var4=c00a	# DA用変数4
			# - view_txt: 次に配置する文字のアドレス上位8ビット
var_da_var5=c00b	# DA用変数5
			# - view_txt: 次に配置するウィンドウタイル座標Y
var_da_var6=c00c	# DA用変数6
			# - view_txt: 次に配置するウィンドウタイル座標X
var_clr_win_nyt=c00d	# - clr_win: 次にクリアするウィンドウタイル座標Y
var_view_img_nt=c00e	# view_img: 次に描画するタイル番号
var_view_img_ntadr_bh=c00f	# view_img: 次に使用するタイルアドレス(下位8ビット)
var_view_img_ntadr_th=c010	# view_img: 次に使用するタイルアドレス(上位8ビット)
var_view_img_dtadr_bh=c011	# view_img: 次に描画するタイルデータアドレス(下位8ビット)
var_view_img_dtadr_th=c012	# view_img: 次に描画するタイルデータアドレス(下位8ビット)
var_view_img_nyt=c013	# view_img: 次に描画するウィンドウタイル座標Y
var_view_img_nxt=c014	# view_img: 次に描画するウィンドウタイル座標X
var_win_stat=c015	# ウィンドウステータス
var_view_dir_file_th=c016	# view_dir: 表示するのは何番目のファイルか(0始まり)
var_tdq_head_bh=c017	# tdq.head[7:0]
var_tdq_head_th=c018	# tdq.head[15:8]
var_tdq_tail_bh=c019	# tdq.tail[7:0]
var_tdq_tail_th=c01a	# tdq.tail[15:8]
var_tdq_stat=c01b	# tdq.stat
var_app_release_btn=c01c	# アプリ用ボタンリリースフラグ

var_dbg_over_vblank=cf00	# vblank期間を超えたことを示すフラグ

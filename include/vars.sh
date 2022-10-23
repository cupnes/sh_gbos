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

# tdq用変数
var_tdq_head_bh=c017	# tdq.head[7:0]
var_tdq_head_th=c018	# tdq.head[15:8]
var_tdq_tail_bh=c019	# tdq.tail[7:0]
var_tdq_tail_th=c01a	# tdq.tail[15:8]
var_tdq_stat=c01b	# tdq.stat

var_app_release_btn=c01c	# アプリ用ボタンリリースフラグ
var_hidden_com_stat=c01d	# 隠しコマンドステート

# 実行ファイル用変数は使い終わったらゼロクリアすること
# bineditはこの変数が0か否かで、
# ファイル右クリックで呼び出されたか
# bineditを直接起動したかを判定している
var_exe_1=c01e	# 実行ファイル用変数1
var_exe_2=c01f	# 実行ファイル用変数2

var_mouse_enable=c020	# マウスの有効(=0x01)/無効(=0x00)
var_fs_base_bh=c021	# ファイルシステム先頭アドレス(下位8ビット)
var_fs_base_th=c022	# ファイルシステム先頭アドレス(上位8ビット)

# th == 0x00は、
# ・画面クリア
# ・var_con_tadr_{th,bh}を$CON_TADR_BASEへ更新
# が必要であることを示す
var_con_tadr_bh=c023	# コンソールで次に描画するタイルアドレス(下位8ビット)
var_con_tadr_th=c024	# コンソールで次に描画するタイルアドレス(上位8ビット)

# 実行ファイル用変数
var_exe_3=c025	# ファイルタイプ

# タイマーハンドラの実体
# タイマー割り込みで、このアドレスへジャンプしてくる
# push AF -> push HLの後、ここへジャンプしてくるため
# 最低限、pop HL(0xe1) -> pop AF(0xf1) -> reti(0xd9) は行うこと
# タイマーハンドラの実装はinclude/timer.shのtimer_init_handler()
# 2022-09-22現在、timer_init_handler()で$var_timer_handlerに並べているのは
# 上記したpop HL・pop AF・retiの3バイト
# ただし、今後、タイマーハンドラに色々と実装するかもしれない事を考えて
# 100バイトの領域は確保しておくことにする
var_timer_handler=c026
# ↑100(0x64)バイトは確保しておくということで、
# 　0xc026 - 0xc089 は変数等に使わないこと

# バイナリ生物用変数
var_cell_next_tile=c08a	# 次に描画する細胞タイルのタイル番号
var_cell_data_first_bh=c08b	# 1つ目の細胞データのアドレス(下位8ビット)
var_cell_data_first_th=c08c	# 1つ目の細胞データのアドレス(上位8ビット)
var_cell_data_current_bh=c08d	# 選択中の細胞データのアドレス(下位8ビット)
var_cell_data_current_th=c08e	# 選択中の細胞データのアドレス(上位8ビット)

# 0xc08f : 未使用
# ※ 念の為、細胞データを2バイト境界に配置する為

# 0xc090 - 0xc161 : 細胞データ1
# (include/binbio.sh 参照)
# var_cell_tadr_bh=c092	# 描画アドレス(下位8ビット)
# var_cell_tadr_th=c093	# 描画アドレス(上位8ビット)
# TODO 細胞データ初期化関数を追加し↑2つの変数は消す

# 0xc300 - 0xcefd : TDQ
# (include/tdq.sh 参照)

var_dbg_over_vblank=cf00	# vblank期間を超えたことを示すフラグ

# 0xdc00 - : タイルミラー領域

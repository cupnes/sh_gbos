# ファイルシステム
## データ構造
※ バイトオーダーはリトルエンディアン

ファイルシステムイメージは[tools/make_fs](../tools/make_fs)で生成
- [create_rootfs()](../tools/make_fs#L141)
  - [create_dir_head()](../tools/make_fs#L98)
    | オフセット | 内容 | サイズ[バイト] |
    | --- | --- | --- |
    | 0 | ファイルシステム内のファイル数 | 1 |
    | 1 | 予約(0xff埋め) | 2 |
  - [create_file_heads()](../tools/make_fs#L104)
    - 以下のデータ構造をファイルシステム上のファイル順にファイル数分並べる
      | オフセット | 内容 | サイズ[バイト] |
      | --- | --- | --- |
      | 0 | 拡張子を除いたファイル名[^about_filename] | 4 |
      | 4 | ファイルタイプ(exe:0x01、txt:0x02、2bpp:0x03、その他:0x00) | 1 |
      | 5 | ファイルデータへのオフセット | 2 |
  - [create_data_area()](../tools/make_fs#L131)
    - 以下のデータ構造をファイルシステム上のファイル順にファイル数分並べる
      | オフセット | 内容 | サイズ[バイト] |
      | --- | --- | --- |
      | 0 | ファイルサイズ | 2 |
      | 2 | ファイルデータ | ファイルサイズ |
  - [「GB_BANK_SIZE - ここまでの合計サイズ」をゼロ埋め](../tools/make_fs#L149L151)
    - GB_BANK_SIZE: [ROMの場合16KB](../tools/make_fs#L6)、[RAMの場合8KB](../tools/make_fs#L30)
[^about_filename]: ファイル名はアルファベットで、拡張子を除いた部分が4文字であること。バイトオーダーとしては、最初の文字から順に並ぶ

## クリックからファイルシステムへのアクセスまでの流れ
例) 左クリック(Bボタン)の場合
- [event_driven()](../src/main.sh#L3823)内で[btn_release_handler()を呼び出し](../src/main.sh#L3928)
  - [btn_release_handler()](../src/main.sh#L3561)内で[f_click_event()を呼び出し](../src/main.sh#L3567)
    - [f_click_event()](../src/main.sh#L2694)内で、
      - [f_check_click_icon_area_{x,y}()を呼び出してクリックした場所のファイル番号を取得](../src/main.sh#L2719L2720)
      - [view_file()を呼び出してファイルアクセス](../src/main.sh#L2727)
        - [view_file()](../src/main.sh#L2590)内で、
          - ファイルシステムを解析し指定されたファイル番号のファイルのファイルタイプを取得
          - ファイルタイプに応じた実行/閲覧の関数を呼び出す
            - 例えば画像の場合[f_view_img()](../src/main.sh#L2684)を呼び出す
              - [f_view_img()](../src/main.sh#L814)内で、
                - ファイルシステムを解析し指定されたファイル番号のファイルデータ先頭アドレスを取得
                - 取得したアドレス以下を画像データとして画面描画するように周期関数([f_view_img_cyc()](../src/main.sh#L918))向け設定

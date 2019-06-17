# poyo-v blink
poyo-vに対して、以下の修正を行ったバージョンです。
* 単純なLチカ(blink)のプログラムのみを命令メモリ(imem)にハードコーディング
* UART, hardware_counterを除去し、LEDを接続するGPIO（1bitのみ）を追加
* LEDのプログラムで用いないデータメモリ(dmem)をコメントアウト

# 使い方の一例

オープンソースな論理合成・配置配線ツールのQflowで、チップレイアウト(GDS)まで作成できます。

* ソース一式をsource/におく
* こちらの手順にそって、ターゲット名の「openMSP430」を、トップモジュール名(poyov_blink)に置き換えて作業を進める

[MakeLSIのQflowの使い方](https://scrapbox.io/makelsi/Qflow%E3%81%AE%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB)の「はじめてのLSI設計」

* 10000ゲート、1.9x1.3mmくらいのレイアウトができるはず。
* 使っていないレジスタを、regfile.vを修正して削除すれば、5000ゲートくらいにはなりそう

## Author

* Junichi Akita / @akita11 / akita@ifdl.jp

## License
This project is released under the MIT License - see the [LICENSE](LICENSE) file for details

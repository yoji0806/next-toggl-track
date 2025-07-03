#  <#Title#>

## TODO: リファクタリング

- InputText, KeyInputParserでそれぞれlogファイルを作っているので整理。
- KeyInputParserの名前が微妙。中にIMEが入っているのでそれをまずは切り分ける。
- xxxMonitorも、もっと綺麗に分けられそう。
- ContentViewがごちゃごちゃしているので整理
    - mainのonApper()で初期化した方がいいインスタンス変数も多そう。
    - 関数を別ファイルに切り分ける
- 1クラス、1ファイル?

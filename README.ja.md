<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.it.md">Italiano</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt-BR.md">Português</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <b>日本語</b> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ru.md">Русский</a>
</p>

<p align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="Porter は使用上限に達したアカウントから、まだ余裕のあるアカウントへ Claude Code のセッションを運びます">
</p>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-2B2522?logo=apple&logoColor=white">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9-C96442?logo=swift&logoColor=white">
  <img alt="10 languages" src="https://img.shields.io/badge/languages-10-433053">
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/license-MIT-4F8A5B"></a>
  <a href="https://github.com/sponsors/matteogilioli"><img alt="Sponsor" src="https://img.shields.io/badge/sponsor-♥-E8906A"></a>
</p>

**Porter** は、Claude Desktop の **Code** タブのための小さな macOS メニューバーアプリです。あるアカウントが使用上限に達したら、Porter が Claude Code のセッションを別のアカウントへ運び、止まったところからそのまま同じ会話を再開できます。さらに、アカウントごとに **複数の Claude Desktop を並べて起動** でき、セッションの整理（アーカイブ、復元、削除、プロジェクト丸ごとの移動）もできます。

> [!NOTE]
> 非公式であり、Anthropic とは無関係です。Porter は Claude Desktop 自身のファイルを読み書きしますが、これらは仕様が公開されておらず、アップデートで変わる可能性があります。変更の前には必ずバックアップを作成します。

## 複数の Claude Desktop を同時に

<p align="center">
  <img src="assets/readme/profiles.svg" width="100%" alt="3 つの Claude Desktop ウインドウが同時に開き、それぞれ別のアカウントでサインインしていて、すべて Porter のパネルに一覧表示されている">
</p>

Claude Desktop は通常、一度に 1 つのアカウントしか使えません。別のアカウントを使うには、サインアウトしてサインインし直す必要があります。Porter ならその手間は要りません。

- **新規プロファイル…** で、サインイン情報・設定・セッション一覧を独立して持つ別の Claude Desktop を開きます。そこで別のアカウントにサインインすれば、2 つのウインドウを開いたままにできます。
- アカウントの数だけプロファイル（仕事用、個人用、クライアント用など）を作れます。すべて**同時に**動き、ほかのアプリと同じく Dock に並び、⌘-Tab でも切り替えられます。
- Porter は各プロファイルのアカウント、最後に記録された使用状況、上限で止まったセッションを一覧にします。プロファイルを開く、前面に出す、名前を変更する、削除する、といった操作もここからできます。
- プロファイル間のセッション移動はワンクリック。アカウントが上限に達したら、次のウインドウでそのまま作業を続けるだけです。
- **リンクを正しいプロファイルで開く**（オプション内）：すべてのプロファイルは同じ Claude アプリなので、ブラウザでサインインした後、macOS は開いているどのプロファイルに戻すかわかりません。オンにすると、Porter が Claude のリンクを最後に使ったプロファイルに渡します。

Claude Desktop は 1 つだけにして、サインアウト／サインインでアカウントを切り替えたい場合は、オプションで**複数のプロファイル**をオフにしてください。Porter はアプリではなくアカウントを一覧にし、古いアカウントのセッションを、いまサインインしているアカウントへ移動します。

## メニューバーのパネル

<img src="assets/readme/panel.svg" width="44%" align="right" alt="Porter のメニューバーのパネル：5 時間と 7 日間の使用量バーを持つアカウントカード、上限で止まったセッションのバッジ、それらを移動するボタン">

メニューバーのポーターをクリックすると、すべてのアカウントを一目で確認できます。

- アカウントごとの **5 時間と 7 日間の使用量**：余裕があるうちは緑、上限が近いとオレンジ、上限に達すると赤で表示されます。Claude Desktop が少し前に記録した値は、経過時間とともに薄く表示され、すでにリセットされているはずの 5 時間枠はその旨が表示されます。
- **上限で止まったセッション**を各アカウントごとに集計し、メニューバーアイコンにはドットを表示します。
- **6 件を Personal に移動 →**：ワンクリックで、止まったセッションを最も余裕のあるアカウントへ移動します。
- **セッション ›** で、そのアカウントがメインウインドウで開きます。

<br clear="right">

## メインウインドウ

<p align="center">
  <img src="assets/readme/window.svg" width="100%" alt="Porter のメインウインドウ：サイドバーにアカウント、プロジェクトごとにグループ化されたセッション、選択された 3 つのセッション、そしてアーカイブ・削除・移動先のアクションバー">
</p>

すべてのアカウントと Claude Code のセッションを 1 か所に。

- **プロジェクトごとにグループ化されたセッション**。フィルタ（開いている、上限で停止、アーカイブ済み）、プロジェクトメニュー、検索を備えています。いま動作中のセッションには緑のバッジが付くので、返信の途中で移動してしまうことはありません。
- クリックで**選択**、⇧ クリックで範囲選択、または*すべて選択*。画面下部にアクションバーが表示されます。
  - **移動先…**：移動先のアカウントを選びます。同じセッションを 2 か所で続けてしまわないよう、元のセッションはアーカイブされます。
  - **コピー**：セッションは両方のアカウントに残り、コピーにはそれぞれ独立した会話が作られます。
  - **アーカイブ**、**復元**、**削除**（ゴミ箱へ入るので、あとで戻せます）。
- セッションをサイドバーの別のアカウントに**ドラッグ**すると、そこへ移動します。
- **プロジェクトフォルダを移動**（または Finder で動かしたあとに再リンク）：そのフォルダを使うすべてのセッションを、全アカウントにわたって、会話や git worktree ごと Porter が更新します。フォルダがなくなったプロジェクトには*フォルダが見つかりません*と表示されます。

## しくみ

<p align="center">
  <img src="assets/readme/how-it-works.svg" width="100%" alt="図：Porter は小さなセッションファイルを、あるアカウントのセッション一覧から別のアカウントの一覧へコピーする。会話は ~/.claude/projects に残り、すべてのアカウントで共有される。チャットは Anthropic のサーバに保存されたまま">
</p>

Claude Code の会話は、どのアカウントにも属さない Claude Code 自身のフォルダ `~/.claude/projects` にあります。アカウントに属するのは、Claude Desktop のセッション**一覧**だけです。

```
<data folder>/claude-code-sessions/<account>/<organization>/local_<session>.json
```

（既定のデータフォルダは `~/Library/Application Support/Claude` です。）セッションを移動すると、この小さなファイルが別のアカウントの一覧にコピーされ、「You've hit your limit」エラーが消え、使用中の git worktree も一緒に運ばれます。起動中の Claude Desktop は一覧をメモリに保持しているため、Porter はいったん終了させ、完了後にもう一度開きます。

> [!IMPORTANT]
> Porter が扱うのは、Claude Desktop が **Mac 上** に保存しているもの、つまり **Code** タブのセッションです。チャット（Claude があなたのファイルを扱うチャットを含む）は Anthropic のサーバに保存され、それぞれのアカウントに残ります。

## インストール

**macOS 14** 以降と [Claude Desktop](https://claude.ai/download) が必要です。

**ダウンロード：** [最新リリース](../../releases/latest)から `Porter.dmg` を入手して開き、**Porter for Claude Desktop** を `Applications` にドラッグします。アプリは公証されていないため、初回は macOS にブロックされます。**システム設定 → プライバシーとセキュリティ**を開いて**このまま開く**をクリックするか、次のコマンドを実行してください。

```bash
xattr -dr com.apple.quarantine "/Applications/Porter for Claude Desktop.app"
```

**ソースからビルド**（Xcode またはコマンドラインツール）：

```bash
git clone https://github.com/matteogilioli/porter-for-claude-desktop.git
cd porter-for-claude-desktop
./scripts/build-app.sh --install
```

`dist/Porter for Claude Desktop.app` をビルドし、`~/Applications` にコピーします。オプションで**ログイン時に開く**をオンにすると、Porter が常に待機します。

Porter は English、Italiano、Español、Français、Deutsch、Português、简体中文、日本語、한국어、Русский に対応し、Mac の言語設定に従います。

## コマンドライン

同じアプリで、スクリプトからセッションを移動することもできます。

```bash
PORTER="/Applications/Porter for Claude Desktop.app/Contents/MacOS/Porter"
"$PORTER" --list                                        # アカウント、プロファイル、そのセッション一覧
"$PORTER" --move --from STORE --to STORE --dry-run      # 実行内容の確認のみ
"$PORTER" --move --from STORE --to STORE --restart      # 移動（元はアーカイブ）
"$PORTER" --move --from STORE --to STORE --copy         # 移動ではなくコピー
```

`STORE` は `--list` が表示するパスです。特定のセッションには `--session local_…`（複数指定可）、アーカイブ済みも対象にするには `--include-archived`、Porter がまだ知らない Claude のデータフォルダには `--data-dir PATH` を追加します。

Porter が起動中の Claude Desktop を終了するのは `--restart` を付けたときだけです（その後もう一度開き、移動先も再起動または起動してセッションを読み込ませます）。付けない場合、アプリの終了が必要な移動は止まり、どのアプリかを表示します。`--dry-run` は終了するアプリを一覧にします。

## 知っておくこと

- **取り消し：** すべての変更は、`~/Library/Application Support/Porter/backups` へのバックアップから始まります。移動を取り消すには、Claude Desktop を終了し、保存されたファイルをバックアップ内の `README.txt` に書かれたパスへコピーして戻します。
- **使用量の数値**は Claude Desktop が記録した内容に基づきます。記録はアカウントの使用中に随時行われます。Porter は値がどれだけ前のものかを表示します。
- **同時に 1 か所だけ：** 同じセッションを 2 つのアカウントで同時に使い続けないでください。移動で元がアーカイブされるのはそのためです。独立した 2 つのセッションが本当に必要なときは、コピーを使ってください。
- ご自身のアカウントだけを使い、Claude プランの利用規約に従ってください。

## サポート

Porter は無料のオープンソースです。待ち時間が少しでも減ったなら、[GitHub でスポンサー](https://github.com/sponsors/matteogilioli)していただけるとうれしいです。

## ライセンス

[MIT](LICENSE)。Claude は Anthropic, PBC の商標です。Porter は独立したプロジェクトであり、Anthropic とは無関係で、承認も受けていません。

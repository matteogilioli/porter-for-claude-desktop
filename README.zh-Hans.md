<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.it.md">Italiano</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt-BR.md">Português</a> ·
  <b>简体中文</b> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ru.md">Русский</a>
</p>

<p align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="Porter 把 Claude Code 会话从已达使用限额的账户搬到还有余量的账户">
</p>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-2B2522?logo=apple&logoColor=white">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9-C96442?logo=swift&logoColor=white">
  <img alt="10 languages" src="https://img.shields.io/badge/languages-10-433053">
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/license-MIT-4F8A5B"></a>
  <a href="https://github.com/sponsors/matteogilioli"><img alt="Sponsor" src="https://img.shields.io/badge/sponsor-♥-E8906A"></a>
</p>

**Porter** 是一款小巧的 macOS 菜单栏应用，服务于 Claude Desktop 的 **Code** 标签页。当某个账户达到使用限额时，Porter 会把你的 Claude Code 会话转移到另一个账户，让你从中断的地方原样继续同一段对话。它还能让你**同时并排运行多个 Claude Desktop**，每个对应一个账户，并帮你整理会话：归档、恢复、删除，以及整体移动项目。

> [!NOTE]
> 非官方，与 Anthropic 无关联。Porter 会读写 Claude Desktop 自己的文件，这些文件没有公开文档，可能随任何更新而改变。每次更改之前，Porter 都会先做备份。

## 同时运行多个 Claude Desktop

<p align="center">
  <img src="assets/readme/profiles.svg" width="100%" alt="三个 Claude Desktop 窗口同时打开，各自登录不同的账户，全部列在 Porter 的面板中">
</p>

Claude Desktop 通常一次只能使用一个账户：要换账户，就得退出登录再重新登录。有了 Porter，就不必这样了。

- **新建配置文件…** 会打开一个独立的 Claude Desktop，拥有自己的登录状态、设置和会话列表。在里面登录另一个账户，两个窗口可以同时开着。
- 有几个账户就建几个配置文件（工作、个人、某个客户……）。它们**同时运行**，像普通应用一样出现在 Dock 中，也能用 ⌘-Tab 切换。
- Porter 会列出每个配置文件对应的账户、最近记录的用量，以及因限额而停止的会话。你可以用它打开某个配置文件或把它带到最前面，也可以重命名或移除。
- 在配置文件之间移动会话只需点一下；一个账户用完了，直接到下一个窗口接着干。
- **在正确的配置中打开链接**（在选项中）：所有配置都是同一个 Claude 应用，所以在浏览器中登录后，macOS 可能把你送回任意一个已打开的配置。开启后，Porter 会把 Claude 链接交给你最近使用的配置。

更喜欢只用一个 Claude Desktop，靠退出再登录来切换账户？在选项中关闭**多个配置文件**即可：Porter 此时列出的是账户而不是应用，并把旧账户的会话移动到你当前登录的账户。

## 菜单栏面板

<img src="assets/readme/panel.svg" width="44%" align="right" alt="Porter 的菜单栏面板：账户卡片显示 5 小时和 7 天用量条，带有因限额而停止的会话徽章，以及移动它们的按钮">

点按菜单栏里的搬运工图标，即可总览所有账户：

- 每个账户的 **5 小时和 7 天用量**：有余量时为绿色，接近限额时为橙色，达到限额时为红色。Claude Desktop 较早之前记录的数值会淡色显示并标明时间，已经必然重置的 5 小时窗口也会注明。
- **因限额而停止的会话**会按账户统计，并在菜单栏图标上显示一个圆点。
- **将 6 个移动到 Personal →**：一键把停止的会话移动到余量最多的账户。
- **会话 ›** 会在主窗口中打开该账户。

<br clear="right">

## 主窗口

<p align="center">
  <img src="assets/readme/window.svg" width="100%" alt="Porter 的主窗口：侧边栏中是各账户，会话按项目分组，选中了三个会话，底部操作栏有归档、删除和移动到">
</p>

所有账户及其 Claude Code 会话，集中在一处：

- **会话按项目分组**，配有筛选（打开、因限额停止、已归档）、项目菜单和搜索。绿色徽章标记当前正在活动的会话，避免你在它回复到一半时移动它。
- 点按即可**选择**，⇧-点按选择范围，也可以用*全选*。操作栏会出现在底部：
  - **移动到…**：选择目标账户。原会话会被归档，这样同一个会话不会在两处同时继续。
  - **拷贝**：会话在两个账户中都保留，每份拷贝都有各自独立的对话。
  - **归档**、**恢复**和**删除**（移到废纸篓，仍可找回）。
- 把会话**拖到**侧边栏中的另一个账户上，即可移动过去。
- **移动项目文件夹**（或在你于访达中移动它之后重新关联）：Porter 会更新所有账户中使用该文件夹的每个会话，连同它们的对话和 git worktree。文件夹已不存在的项目会标记为*文件夹缺失*。

## 工作原理

<p align="center">
  <img src="assets/readme/how-it-works.svg" width="100%" alt="示意图：Porter 把一个小小的会话文件从一个账户的会话列表复制到另一个账户的列表；对话保留在 ~/.claude/projects 中，由所有账户共享；聊天保存在 Anthropic 的服务器上">
</p>

Claude Code 的对话存放在 Claude Code 自己的文件夹 `~/.claude/projects` 中，它不属于任何账户。属于账户的，只有 Claude Desktop 的会话**列表**：

```
<data folder>/claude-code-sessions/<account>/<organization>/local_<session>.json
```

（默认数据文件夹是 `~/Library/Application Support/Claude`。）移动会话就是把这个小文件复制到另一个账户的列表中，清除“You've hit your limit”错误，并一并带上它用到的 git worktree。运行中的 Claude Desktop 会把列表保存在内存里，所以 Porter 会先退出它，完成后再重新打开。

> [!IMPORTANT]
> Porter 处理的是 Claude Desktop 保存在**你的 Mac 上**的内容：**Code** 标签页的会话。聊天（包括 Claude 处理你文件的聊天）存放在 Anthropic 的服务器上，仍归各自账户所有。

## 安装

需要 **macOS 14** 或更高版本，以及 [Claude Desktop](https://claude.ai/download)。

**下载：**从[最新版本](../../releases/latest)获取 `Porter.dmg`，打开后把 **Porter for Claude Desktop** 拖到 `Applications`。该应用未经公证，首次打开时 macOS 会阻止它：打开**系统设置 → 隐私与安全性**并点按**仍要打开**，或运行：

```bash
xattr -dr com.apple.quarantine "/Applications/Porter for Claude Desktop.app"
```

**从源码构建**（Xcode 或命令行工具）：

```bash
git clone https://github.com/matteogilioli/porter-for-claude-desktop.git
cd porter-for-claude-desktop
./scripts/build-app.sh --install
```

这会构建 `dist/Porter for Claude Desktop.app` 并将其拷贝到 `~/Applications`。在选项中打开**登录时打开**，让 Porter 常驻。

Porter 支持 English、Italiano、Español、Français、Deutsch、Português、简体中文、日本語、한국어 和 Русский，并跟随你 Mac 的语言。

## 命令行

同一个应用也能在脚本中移动会话：

```bash
PORTER="/Applications/Porter for Claude Desktop.app/Contents/MacOS/Porter"
"$PORTER" --list                                        # 账户、配置文件及其会话列表
"$PORTER" --move --from STORE --to STORE --dry-run      # 预演会发生什么
"$PORTER" --move --from STORE --to STORE --restart      # 移动（原会话归档）
"$PORTER" --move --from STORE --to STORE --copy         # 改为拷贝
```

`STORE` 是 `--list` 打印出的路径。用 `--session local_…`（可重复）指定具体会话，用 `--include-archived` 一并处理已归档的会话，用 `--data-dir PATH` 指定 Porter 尚不认识的 Claude 数据文件夹。

只有加上 `--restart`，Porter 才会关闭正在运行的 Claude Desktop（之后会重新打开它，并重启或打开目标以载入会话）；否则，需要关闭某个应用的移动会停止并指出是哪个。`--dry-run` 会列出将要关闭的应用。

## 须知

- **撤销：**每次更改都会先在 `~/Library/Application Support/Porter/backups` 中备份。要撤销一次移动，请退出 Claude Desktop，把备份的文件拷回备份中 `README.txt` 所写的路径。
- **用量数字**来自 Claude Desktop 的记录，它在你使用账户期间会不定时记录。Porter 会显示数值是多久以前的。
- **同一时间只在一处：**不要同时在两个账户中继续处理同一个会话。移动会归档原会话正是出于这个原因；确实需要两个独立的会话时，请使用“拷贝”。
- 请只使用你自己的账户，并遵守你的 Claude 套餐条款。

## 支持

Porter 免费且开源。如果它帮你省下了一些等待时间，欢迎[在 GitHub 上赞助](https://github.com/sponsors/matteogilioli)。

## 许可证

[MIT](LICENSE)。Claude 是 Anthropic, PBC 的商标。Porter 是独立项目，与 Anthropic 无关联，也未获其认可。

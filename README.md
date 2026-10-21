<p align="center">
  <b>English</b> ·
  <a href="README.it.md">Italiano</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt-BR.md">Português</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ru.md">Русский</a>
</p>

<p align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="Porter carries Claude Code sessions from an account at its usage limit to one with room left">
</p>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-2B2522?logo=apple&logoColor=white">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9-C96442?logo=swift&logoColor=white">
  <img alt="10 languages" src="https://img.shields.io/badge/languages-10-433053">
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/license-MIT-4F8A5B"></a>
  <a href="https://github.com/sponsors/matteogilioli"><img alt="Sponsor" src="https://img.shields.io/badge/sponsor-♥-E8906A"></a>
</p>

**Porter** is a small macOS menu-bar app for the **Code** tab of Claude Desktop. When one account hits its usage limit, Porter carries your Claude Code sessions to another account, so you pick up the same conversations right where they stopped. It also lets you run **several Claude Desktops side by side**, one account each, and keeps your sessions tidy: archive, restore, delete, and move whole projects.

> [!NOTE]
> Unofficial and not affiliated with Anthropic. Porter reads and writes Claude Desktop's own files, which are undocumented and may change with any update. It makes a backup before every change.

## Several Claude Desktops at once

<p align="center">
  <img src="assets/readme/profiles.svg" width="100%" alt="Three Claude Desktop windows open at the same time, each signed in to a different account, all listed in Porter's panel">
</p>

Claude Desktop normally runs one account at a time: to use another one you sign out and in. With Porter you don't have to.

- **New Profile…** opens a separate Claude Desktop with its own sign-in, settings and session list. Sign in there with another account and keep both windows open.
- Make as many profiles as you have accounts (work, personal, a client…). They all run **at the same time**, in the Dock and with ⌘-Tab like any app.
- Porter lists every profile with its account, its latest usage and the sessions stopped by a limit. It opens or brings each one to the front, renames it or removes it.
- Moving sessions between profiles is one click, and when one account runs out you just keep working in the next window.
- **Open Links in the Right Profile** (in the options): all profiles are the same Claude app, so after you sign in in the browser macOS may send you back to any open one. With this on, Porter passes Claude links to the profile you used last.

Prefer one Claude Desktop and switching accounts by signing out and in? Turn off **Multiple Profiles** in the settings: Porter then lists accounts instead of apps and moves the old account's sessions to the one you are signed in to.

## The menu-bar panel

<img src="assets/readme/panel.svg" width="44%" align="right" alt="Porter's menu-bar panel: account cards with 5-hour and 7-day usage bars, a badge for sessions stopped by the limit and a button to move them">

Click the porter in the menu bar for an overview of every account:

- **5-hour and 7-day usage** for each account: green while there is room, orange near the limit, red at it. A value Claude Desktop recorded a while ago is shown faded with its age, and a 5-hour window that has surely reset says so.
- **Sessions stopped by the limit**, counted on each account and with a dot on the menu-bar icon.
- **Move 6 to Personal →**: one click moves the stopped sessions to the account with the most room left.
- **Sessions ›** opens that account in the main window.

<br clear="right">

## The main window

<p align="center">
  <img src="assets/readme/window.svg" width="100%" alt="Porter's main window: accounts in a sidebar, sessions grouped by project, three sessions selected and an action bar with Archive, Delete and Move To">
</p>

Every account and its Claude Code sessions, in one place:

- **Sessions grouped by project**, with filters (open, stopped by the limit, archived), a project menu and search. A green badge marks sessions active right now, so you don't move one mid-reply.
- **Select** with a click, ⇧-click for a range or *Select All*. The action bar appears at the bottom:
  - **Move To…**: pick the destination account. The originals are archived, so the same session is not continued from two places.
  - **Copy**: the sessions stay in both accounts, and each copy gets a conversation of its own.
  - **Archive**, **Restore** and **Delete** (to the Trash, so you can still get it back).
- **Drag** sessions onto another account in the sidebar to move them there.
- **Move a project folder** (or relink it after you moved it in Finder): Porter updates every session that uses it, in every account, together with its conversations and git worktrees. Projects whose folder is gone are flagged *Folder missing*.

## How it works

<p align="center">
  <img src="assets/readme/how-it-works.svg" width="100%" alt="Diagram: Porter copies a small session file from one account's session list to another's; the conversation stays in ~/.claude/projects, shared by every account; chats stay on Anthropic's servers">
</p>

A Claude Code conversation lives in Claude Code's own folder, `~/.claude/projects`, which belongs to no account. What belongs to an account is only Claude Desktop's **list** of sessions:

```
<data folder>/claude-code-sessions/<account>/<organization>/local_<session>.json
```

(the default data folder is `~/Library/Application Support/Claude`). Moving a session copies that small file to the other account's list, clears the "You've hit your limit" error, and carries the git worktrees it uses. A running Claude Desktop keeps its list in memory, so Porter quits it first and reopens it afterwards.

> [!IMPORTANT]
> Porter works with what Claude Desktop keeps **on your Mac**: sessions of the **Code** tab. Chats, including chats where Claude works on your files, are stored on Anthropic's servers and stay with their account.

## Install

Requires **macOS 14** or later and [Claude Desktop](https://claude.ai/download).

**Download:** get `Porter.dmg` from the [latest release](../../releases/latest), open it and drag **Porter for Claude Desktop** to `Applications`. The app is not notarized, so macOS blocks it the first time: open **System Settings → Privacy & Security** and click **Open Anyway**, or run:

```bash
xattr -dr com.apple.quarantine "/Applications/Porter for Claude Desktop.app"
```

**Build from source** (Xcode or the Command Line Tools):

```bash
git clone https://github.com/matteogilioli/porter-for-claude-desktop.git
cd porter-for-claude-desktop
./scripts/build-app.sh --install
```

This builds `dist/Porter for Claude Desktop.app` and copies it to `~/Applications`. Turn on **Launch at Login** in the settings to keep Porter around.

Porter speaks English, Italiano, Español, Français, Deutsch, Português, 简体中文, 日本語, 한국어 and Русский, following your Mac's language.

## Command line

The same app moves sessions from scripts:

```bash
PORTER="/Applications/Porter for Claude Desktop.app/Contents/MacOS/Porter"
"$PORTER" --list                                        # accounts, profiles and their session lists
"$PORTER" --move --from STORE --to STORE --dry-run      # what would happen
"$PORTER" --move --from STORE --to STORE --restart      # move (originals archived)
"$PORTER" --move --from STORE --to STORE --copy         # copy instead
```

`STORE` is a path printed by `--list`. Add `--session local_…` (repeatable) for specific sessions, `--include-archived` to take archived ones too, and `--data-dir PATH` for a Claude data folder Porter does not know yet.

Porter closes a running Claude Desktop only with `--restart` (it then reopens it, and restarts or opens the destination so it loads the sessions); without it, a move that needs an app closed stops and says which one. `--dry-run` lists the apps it would close.

## Good to know

- **Undo:** every change starts with a backup in `~/Library/Application Support/Porter/backups`. To undo a move, quit Claude Desktop and copy the saved files back to the path written in the backup's `README.txt`.
- **Usage numbers** come from what Claude Desktop records, which it does now and then while you use an account. Porter shows how old a value is.
- **One place at a time:** don't keep working on the same session from two accounts at once. Moving archives the original for this reason; use Copy when you really want two independent sessions.
- Use only accounts you own, and follow the terms of your Claude plan.

## Support

Porter is free and open source. If it saves you some waiting, you can [sponsor it on GitHub](https://github.com/sponsors/matteogilioli).

## License

[MIT](LICENSE). Claude is a trademark of Anthropic, PBC. Porter is an independent project and is not affiliated with or endorsed by Anthropic.

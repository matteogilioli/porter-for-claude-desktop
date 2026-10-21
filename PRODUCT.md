# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Static HTML/CSS published by GitHub Pages at matteogilioli.github.io/porter-for-claude-desktop, with no framework. The site comes in all 10 languages the app speaks (en, it, es, fr, de, pt-BR, zh-Hans, ja, ko, ru), so the pages are generated from one template and one copy file per language by a small script in the repo.

## Users

Developers on macOS who use the **Code** tab of Claude Desktop (Claude Code sessions) with more than one Claude account: personal and work, several team seats, a client's. They hit 5-hour or weekly usage limits mid-task and want to keep going in another account without losing the conversation. Many use the app in a language other than English.

The page itself is read by people arriving from GitHub, awesome lists, Reddit/Hacker News posts and search, deciding whether to install an unsigned app from an independent developer.

## Product Purpose

Porter is a free, open-source macOS menu-bar app for Claude Desktop. When an account hits its usage limit, it carries the Claude Code sessions to another account so the same conversations continue where they stopped. It runs several Claude Desktops side by side, one account each, shows the usage of every account, and keeps sessions tidy (archive, restore, delete, move whole project folders).

Success for the page: a visitor understands in seconds what Porter does, trusts it enough to download the DMG, and gets past macOS's first-launch block.

## Positioning

Other Claude tools show usage; Porter acts on it. It moves sessions between accounts (Claude Code conversations live in `~/.claude/projects`, which belongs to no account, so only Claude Desktop's small per-account session list needs to change) and runs multiple Claude Desktop profiles at once. It works on what Claude Desktop keeps on the Mac, the Code tab's sessions, not on chats stored on Anthropic's servers.

## Operating Context

- Lives in the macOS menu bar (a porter/bellhop icon); a panel shows one card per profile with 5h/7d usage, reset times and sessions stopped by a limit; a main window lists sessions by project.
- Profiles are separate Claude Desktop data folders (`--user-data-dir`), all running at once in the Dock.
- Live Usage (opt-in) asks claude.ai with each profile's own session; macOS asks once for Claude's Keychain key. Otherwise usage comes from what Claude Desktop records.
- Updates itself with Sparkle; releases are GitHub releases with `Porter.dmg` (latest: github.com/matteogilioli/porter-for-claude-desktop/releases/latest/download/Porter.dmg).
- Command line: `Porter --list`, `--move`, `--usage-json`.

## Capabilities and Constraints

- macOS 14 or later; requires Claude Desktop. Swift/SwiftUI, native.
- Not notarized: macOS blocks the first launch; users open it via System Settings → Privacy & Security → Open Anyway, or `xattr -dr com.apple.quarantine`.
- Makes a backup before every change; deletes go to the Trash.
- MIT license, free; sponsorship via GitHub Sponsors.
- Unofficial and not affiliated with Anthropic; Claude Desktop's files are undocumented and may change.

## Brand Commitments

- Name: **Porter** (full: "Porter for Claude Desktop"). Mascot/logo: the bellhop (assets/brand/porter-app-icon.svg, porter-menubar.svg); app icon assets/icon.png.
- No Claude or Anthropic marks, logos or trade dress; say "for Claude Desktop" descriptively.
- Voice: plain, factual, short sentences, no hype (as in the README and release notes).

## Evidence on Hand

- README illustrations (SVG): assets/readme/hero.svg, profiles.svg, panel.svg, window.svg, how-it-works.svg.
- README copy translated into the 10 languages (README.*.md).
- No testimonials, user counts, press or ratings exist; do not invent any. Stars are few; do not show counts.

## Product Principles

- Tell the truth about what it touches: local files, backups, unofficial status, the first-launch block.
- Show the product working rather than describing it.
- One obvious action: download the DMG; GitHub for the curious.
- Respect every language as a first-class one.

---
name: Porter for Claude Desktop
description: The app's warm paper world, carried into a plum lobby at night.
colors:
  night: "#1c1420"
  night-2: "#2a1f2e"
  plum: "#34263a"
  plum-line: "#45334b"
  uniform: "#57406b"
  well: "#120c11"
  paper: "#fffdf9"
  paper-2: "#f5f0e8"
  paper-line: "#e7ddd1"
  track: "#ede4d8"
  ink: "#2b2522"
  ink-2: "#6f645b"
  ink-3: "#776c63"
  text: "#f2ebe3"
  text-2: "#c4b4be"
  text-3: "#8f7d8b"
  terra: "#d97757"
  terra-deep: "#c96442"
  terra-ink: "#a9502f"
  brass: "#e8b866"
  green: "#4f8a5b"
  green-ink: "#3b7347"
  orange: "#c2711f"
  red: "#c2452d"
  warn-tint: "#f8e3d5"
  warn-ink: "#9a4f17"
  ok-tint: "#e6f1e7"
  ok-ink: "#2f6339"
typography:
  display:
    fontFamily: "Gloock, Prata, ui-serif, New York, Georgia, serif"
    fontSize: "clamp(2.9rem, 5.6vw, 5.5rem)"
    fontWeight: 400
    lineHeight: 1
    letterSpacing: "-0.025em"
  headline:
    fontFamily: "Gloock, Prata, ui-serif, New York, Georgia, serif"
    fontSize: "clamp(2.1rem, 4.6vw, 3.6rem)"
    fontWeight: 400
    lineHeight: 1.04
    letterSpacing: "-0.02em"
  title-serif:
    fontFamily: "Gloock, Prata, ui-serif, New York, Georgia, serif"
    fontSize: "1.6rem"
    fontWeight: 400
    lineHeight: 1.15
  card-name:
    fontFamily: "Gloock, Prata, ui-serif, New York, Georgia, serif"
    fontSize: "1.35rem"
    fontWeight: 400
    lineHeight: 1.1
    letterSpacing: "-0.01em"
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, SF Pro Text, system-ui, sans-serif"
    fontSize: "1.25rem"
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, SF Pro Text, system-ui, sans-serif"
    fontSize: "1.0625rem"
    fontWeight: 400
    lineHeight: 1.6
  lead:
    fontFamily: "-apple-system, BlinkMacSystemFont, SF Pro Text, system-ui, sans-serif"
    fontSize: "clamp(1.0625rem, 1.3vw, 1.2rem)"
    fontWeight: 400
    lineHeight: 1.6
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, SF Pro Text, system-ui, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 600
    lineHeight: 1.3
    fontFeature: "tnum"
  caption:
    fontFamily: "-apple-system, BlinkMacSystemFont, SF Pro Text, system-ui, sans-serif"
    fontSize: "0.72rem"
    fontWeight: 400
    lineHeight: 1.5
  mono:
    fontFamily: "ui-monospace, SF Mono, Menlo, Consolas, monospace"
    fontSize: "0.875em"
    fontWeight: 400
    lineHeight: 1.9
rounded:
  sm: "8px"
  md: "12px"
  lg: "14px"
  xl: "18px"
  2xl: "22px"
  pill: "999px"
spacing:
  gutter: "clamp(1rem, 4vw, 3.5rem)"
  max: "76rem"
  section: "clamp(5rem, 11vw, 9rem)"
  stack: "1.3rem"
  actions: "0.75rem"
components:
  button-primary:
    backgroundColor: "{colors.terra}"
    textColor: "#1e1210"
    rounded: "{rounded.pill}"
    padding: "0 1.35rem"
    height: "3rem"
  button-primary-hover:
    backgroundColor: "#e3876a"
  button-primary-small:
    backgroundColor: "{colors.terra}"
    textColor: "#1e1210"
    rounded: "{rounded.pill}"
    padding: "0 1.1rem"
    height: "2.5rem"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.text}"
    rounded: "{rounded.pill}"
    padding: "0 1.35rem"
    height: "3rem"
  account-card:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.xl}"
    padding: "1.1rem 1.15rem 1rem"
  session-card:
    backgroundColor: "{colors.paper-2}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "0.7rem 0.8rem 0.75rem"
    width: "17rem"
  panel:
    backgroundColor: "{colors.paper-2}"
    rounded: "20px"
    padding: "0.8rem"
    width: "24rem"
  panel-card:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: "0.95rem 1rem 0.85rem"
  ledger:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.2xl}"
    padding: "clamp(1.25rem, 3vw, 2rem)"
  terminal:
    backgroundColor: "{colors.well}"
    textColor: "{colors.text}"
    rounded: "16px"
    padding: "1.3rem 1.4rem"
  install-step:
    backgroundColor: "{colors.night-2}"
    textColor: "{colors.text}"
    rounded: "{rounded.xl}"
    padding: "1.5rem 1.4rem"
  badge-warn:
    backgroundColor: "{colors.warn-tint}"
    textColor: "{colors.warn-ink}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "0.2rem 0.55rem"
  pill-ok:
    backgroundColor: "{colors.ok-tint}"
    textColor: "{colors.ok-ink}"
    rounded: "{rounded.pill}"
    padding: "0.1rem 0.4rem"
  menubar:
    backgroundColor: "rgb(28 20 32 / .78)"
    textColor: "{colors.text-2}"
    height: "3rem"
    padding: "0 {spacing.gutter}"
---

# Design System: Porter for Claude Desktop

## Overview

**Creative North Star: "The Lobby at Night"**

Porter's macOS app lives on warm paper with terracotta and serif titles. The web renders that same world after hours: a deep plum lobby, darkened from the porter's uniform, where the app's paper cards glow like lit objects on a desk. Nothing on the night ground pretends to be the app; everything on paper is the app, rebuilt at its real scale with its real states (usage bars, the limit error, reset times).

Density is calm and editorial: wide sections on one shared rhythm, a two-column split of copy against an object, and one authored moment of motion. Depth comes from light, not from chrome: soft lamplight gradients in the plum, long diffuse shadows under the paper objects, and a brass line that marks the porter's route. Detail is brass; action is terracotta; status is the app's own green, orange and red.

The world takes its type from the app's serif titles, set in Gloock (Prata for Cyrillic, the native Mincho/Song/Myeongjo serif for CJK), with the Mac system face for everything read and SF Mono only for real paths and commands.

**Key Characteristics:**
- Plum night ground (#1c1420) with radial lamplight in the uniform plum (#57406b).
- App paper (#fffdf9 / #f5f0e8) for every object that represents Porter's UI.
- One terracotta action, brass for detail and path, usage colors only for usage.
- High-contrast serif display, system sans body, mono only for literal code.
- One scroll-scrubbed signature moment; everything else is still.

## Colors

A dark, warm-purple ground carrying warm paper objects, with two metals: terracotta for action and brass for detail.

### Primary
- **Porter Terracotta** (terra): the fill of the download button and nothing else on the night ground. Hover lifts to a lighter terracotta (#e3876a); button text is a near-black clay (#1e1210), never white.
- **Deep Terracotta** (terra-deep): terracotta as ink on light ground: the current language in the language menu, the ledger's move arrow.
- **Terracotta Ink** (terra-ink): the darker terracotta used for small action text on paper ("Move 3 to Personal", "Sessions"), dark enough to read at 0.75rem.

### Secondary
- **Lobby Brass** (brass): the porter's path, the second line of the hero headline, serif subheads on night, install step numerals, the terminal prompt, copy buttons, diamond list markers, focus rings and text selection. Detail and wayfinding, never a fill for actions.

### Tertiary (usage, from the app)
- **Room Green** (green) / **Green Ink** (green-ink): bar fill and status dot while an account has room; green-ink for the percentage and "Ready to continue" on paper.
- **Near-limit Orange** (orange): bar fill only, 75 to 99 percent.
- **Limit Red** (red): bar fill, percentage and the limit error at 100 percent.
- **Warn Tint / Warn Ink** (warn-tint, warn-ink): the "stopped by limit" badge and stopped-session pill.
- **OK Tint / OK Ink** (ok-tint, ok-ink): running-session pill and the landing row in the ledger.

### Neutral
- **Night** (night): page ground and selection text; **Night 2** (night-2): install step cards; **Plum** (plum) and **Plum Line** (plum-line): hairlines, ghost button ring, dividers, terminal and step outlines; **Uniform** (uniform): only as translucent lamplight in radial gradients.
- **Well** (well): the darker-than-night inset of the terminal and command field.
- **Paper** (paper), **Paper 2** (paper-2), **Paper Line** (paper-line), **Track** (track): the app's card, background, divider and empty bar track.
- **Ink** (ink), **Ink 2** (ink-2), **Ink 3** (ink-3): text on paper; ink also fills the ledger's dark shelf.
- **Text** (text), **Text 2** (text-2), **Text 3** (text-3): text on night: headlines, body copy, notes and captions.

### Named Rules
**The Lit Object Rule.** Paper appears on the night ground only as an object from Porter's own UI (account card, session, panel, window, ledger). Paper is never a generic section background.

**The One Action Rule.** Terracotta fills exactly one kind of thing on the night ground: the download button. Every other accent on night is brass.

**The Usage Colors Rule.** Green, orange and red mean usage state, with the app's thresholds (under 75, 75 to 99, 100). They are never decoration. Orange is a bar fill, not text on paper.

## Typography

**Display Font:** Gloock (with Prata for Cyrillic, then ui-serif, New York, Georgia)
**Body Font:** the Mac system face (-apple-system, SF Pro Text, with Hiragino Sans, PingFang SC, Apple SD Gothic Neo for CJK)
**Label/Mono Font:** ui-monospace, SF Mono, Menlo

**Character:** a high-contrast, slightly sharp-edged serif speaks for the porter in a single regular weight; the system face does the reading, as it does in the app.

### Hierarchy
- **Display** (400, clamp(2.9rem, 5.6vw, 5.5rem), 1): the hero headline only, two lines, the second in brass.
- **Headline** (400, clamp(2.1rem, 4.6vw, 3.6rem), 1.04): every section title; the closing title grows to clamp(2.4rem, 6vw, 4.8rem) at 14ch.
- **Title Serif** (400, 1.6rem, 1.15): sub-headings inside a section (brass on night) and the honest notes heading.
- **Card Name** (400, 1.35rem, 1.1): account names on paper cards; the window title bar uses the same face at 1rem.
- **Title** (600 sans, 1.25rem, 1.3): install step titles.
- **Body** (400, 1.0625rem, 1.6): running copy in text-2, max 34rem; lead at max 30rem.
- **Label** (600, 0.75rem, tabular numerals): bar labels, percentages, ledger labels, badges.
- **Caption** (400, 0.72rem): "Example data" notes and figure captions in text-3.
- **Mono** (0.875em, 1.9 in the terminal): real paths, file names and commands only.

### Named Rules
**The One Weight Serif Rule.** Gloock is set at 400 only; hierarchy comes from size and color, never bold serif.

**The Script-Native Serif Rule.** Each language gets a display serif made for its script: Prata for Cyrillic; on ja, zh-Hans and ko pages the display stack swaps to Hiragino Mincho, Songti or AppleMyungjo, the CJK hero drops to clamp(2.3rem, 4.4vw, 4.4rem) at 1.12, and Japanese breaks by phrase.

**The Real Code Rule.** Monospace marks something the reader could type or find on disk. It is not a style.

## Layout

One centered column of max 76rem plus a fluid gutter (clamp(1rem, 4vw, 3.5rem)). Every section after the hero shares one top padding (clamp(5rem, 11vw, 9rem)) and splits copy against an object on a fractional grid: 5/7 (how it works), 6/6 (profiles), 5/6 (usage, object first), 4/8 (main window, command line). Install uses three equal step cards; the honest notes use a 3/9 split with a three-column list. Copy measures cap at 30 to 34rem.

The hero is a sticky stage under the 3rem menu bar, height 100vh minus the bar: title across the top, copy left (5fr), the deck of cards right (7fr). The carry section is 290vh tall so scroll has room to scrub.

At 860px and below everything stacks to one column: the menu bar drops its section links and the language name, the carry shortens to 240vh, the hero stacks title, copy, deck, the ghost button and demo note hide, account cards shrink to 66% width showing only the 5h bar, the ledger stacks with the arrow turned 90 degrees, the usage panel moves below its copy, and the terminal wraps. Below 860px wide and 700px tall the lead hides so the deck stays in view.

## Elevation & Depth

Depth is light on a dark ground. The plum carries two fixed radial lamps down the page and one behind the deck; paper objects float on long, soft, negative-spread shadows that read as light falling off them, plus a one-pixel inner highlight on their top edge. Surfaces on the night ground (install steps, terminal, ghost button) are flat and outlined with an inset plum hairline instead of a shadow.

### Shadow Vocabulary
- **Card float** (`0 30px 60px -28px rgb(0 0 0 / .8)`, with `0 2px 0 rgb(255 255 255 / .6) inset`): account cards; the same family at -24px and .85 for the fanned windows and the close icon.
- **Sheet float** (`0 40px 80px -40px rgb(0 0 0 / .9)`): the ledger.
- **Panel float** (`0 50px 90px -40px rgb(0 0 0 / .95)`): the menu-bar panel and the main window illustration.
- **Lift** (scales with `--lift` from 0 to 26px offset, 50px blur): the session card while carried.
- **Button** (`0 10px 24px -12px rgb(0 0 0 / .8)`, hover `0 16px 30px -12px rgb(0 0 0 / .85)`): primary button only.
- **Menu** (`0 18px 40px -12px rgb(0 0 0 / .55), 0 2px 6px rgb(0 0 0 / .2)`): the language dropdown.
- **Hairline** (`inset 0 0 0 1px` plum-line on night, paper-line on paper): outlines instead of borders.
- **Brass glow** (`drop-shadow(0 0 6px rgb(232 184 102 / .5))`): the drawn path only.

### Named Rules
**The Light Falls Off Rule.** Shadows are long, soft and pulled in by negative spread; no hard offsets, no colored shadows. On night, outline with an inset hairline rather than lifting.

## Shapes

Soft, app-like rounding that grows with the object: 8px for code chips and list rows, 12px for the session card and menus, 14px for panel cards and windows, 16px for the terminal and screenshot, 18px for account cards and install steps, 20px for the panel, 22px for the ledger, 26px for the large icon, and full pills for buttons, badges and bar tracks. The usage panel keeps the menu-bar caret on top. The hero's empty slot is a 1.5px dashed brass-tan (#e3c58f) landing outline. List markers are small brass diamonds (a 0.5rem square, 2px radius, turned 45 degrees). Windows wear the macOS traffic lights.

## Components

### Buttons
- **Shape:** full pill (999px), 3rem tall (2.5rem small), sans 600 at 1rem with an 18px inline SVG icon.
- **Primary:** terracotta fill, clay text, button shadow; hover lifts 1px, lightens and deepens the shadow; active settles back. Transitions on the shared ease (transform .25s, color .2s).
- **Ghost:** transparent with an inset plum-line ring, text color; hover adds a 5% white wash. Hidden on narrow screens.
- **Copy:** a flat brass text button joined to the command field by a plum hairline; hover a brass wash; label swaps to "Copied" for 1.8s.
- **Focus:** every focusable element takes a 2px brass outline, offset 3px, 6px radius.

### Navigation (menu bar)
A 3rem sticky strip rendered as the macOS menu bar: night at 78% with saturate(1.4) blur(18px) and a 6% white bottom hairline. Brand is the icon (7px radius) plus "Porter" in display serif. Section links in text-2, text on hover. On the right, Porter's own status item (the bellhop glyph in a 14% white highlight, 5px radius, as when its panel is open), a live tabular clock, a language menu (globe plus name; a paper dropdown with 12px radius, current language in deep terracotta) and the GitHub mark.

### Account Card
Paper, 18px radius, card float. Header: green status dot, card-name serif, a warn badge pushed right. Usage bars below, then a slot for a session, then a 0.75rem footer count in ink-2.

### Usage Bar
A three-column row: label (0.75rem ink-2), a 0.3rem pill track (track color) whose fill scales from the left by `--v`, and a right-aligned tabular percentage colored by tone. Fill transitions over .6s on the shared ease; a minimum 2% sliver shows at zero. The wide variant adds a reset time column (0.7rem ink-3). A smaller 0.25rem version lives in the window sidebars.

### Session Card
Paper-2, 12px radius, 17rem wide: project line (chat glyph, 0.72rem ink-3), title (600, 0.9rem), status line. The status is a crossfade: the red limit error dissolves (opacity, 4px blur, 4px rise) into green-ink "Ready to continue" with a haloed green dot. While carried, the porter icon rides its corner.

### Menu-bar Panel
Paper-2 tray, 20px radius, max 24rem, with the top caret and an inner white highlight, holding paper panel cards (14px radius, paper-line hairline): name, email, wide usage bars with reset times, and a footer with badge and a terracotta-ink action link. The Personal card's 5h bar ticks up live while in view.

### Ledger
A paper sheet (22px radius) showing two session lists side by side joined by a dashed terracotta arrow; rows are 8px paper-2 code chips, the moving row in a terracotta tint, the landing row in the OK tint. Below, an ink shelf (14px radius) with a brass label holds the shared conversation path.

### Fanned Windows
Three miniature Claude Desktop windows (14px radius, paper, card float) overlapped and rotated -3, 1.5 and -1 degrees: paper-2 title bar with traffic lights and serif name, a sidebar with account email and a small usage bar, and session rows with a status dot and OK or warn pill. Static.

### Terminal and Command Field
Well (#120c11) with an inset plum-line ring, 16px radius (10px for the inline command field), mono at 0.85rem and 1.9 line height, brass prompt, text-3 comments, hanging indent for wrapped lines.

### Install Steps and Honest Notes
Three night-2 cards (18px radius, plum-line inset) counted with a large brass serif numeral (2.4rem), sans title, text-2 copy. The honest notes follow under a plum-line rule: a serif heading and three plain columns of text-2. Every illustrated object carries a small text-3 "Example data" caption.

### Signature: The Carry
One sticky stage, scrubbed by scroll progress p over the 290vh section. The session lifts out of the red account (lift 0.06 to 0.2), travels a quadratic arc measured from the cards' real positions (0.18 to 0.78, cubic ease-out, tilting up to -4 degrees and scaling 6%), and sets down (0.74 to 0.86). The brass ink draws along a dotted brass track with the travel and fades after landing (0.86 to 0.98). State attributes drive CSS: `data-lifted` moves the dashed slot to the source card, `data-landed` (p at 0.8) clears the warn badge, dissolves the error into "Ready to continue", bumps the target count and its 5h bar from 12 to 18 percent; `data-step` crossfades three serif captions (blur 6px, 0.6rem rise, .5s); `data-scrolled` fades the scroll cue. With reduced motion the section collapses to its own height, the stage is static, the carry renders at its landed end state, and the live ticker stops.

## Do's and Don'ts

### Do:
- **Do** set every app object on paper at the app's real proportions, with real states and an "Example data" caption.
- **Do** keep terracotta for the download action and brass for every other accent on night.
- **Do** use the shared ease (cubic-bezier(.16, 1, .3, 1)) for every transition and keep motion to the carry plus small state changes.
- **Do** give every language a display serif made for its script and test the hero headline in ja, zh-Hans, ko and ru.
- **Do** outline night surfaces with an inset plum-line hairline and float paper objects on long, soft negative-spread shadows.
- **Do** honor reduced motion by showing the end state, not a frozen midpoint.

### Don't:
- **Don't** use Claude or Anthropic marks, logos or trade dress; the bellhop is the only mascot.
- **Don't** use green, orange or red for anything but usage state.
- **Don't** set Gloock bold or use a second display face for Latin text.
- **Don't** add a second scroll-driven or ambient motion moment; the carry is the page's one authored motion.
- **Don't** use monospace for anything that is not a literal path, file or command.
- **Don't** invent numbers: usage figures are labeled example data, and there are no counts, ratings or testimonials.

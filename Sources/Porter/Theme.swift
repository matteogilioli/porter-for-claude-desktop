import AppKit
import SwiftUI

/// The app's look: warm paper and terracotta, like its icon, with serif titles.
/// Every color has a light and a dark variant and follows the system appearance.
enum Theme {
    static let background = dynamic(0xF5F0E8, 0x1E1A17)
    static let card = dynamic(0xFFFDF9, 0x2A2420)
    static let raised = dynamic(0xFBF7F1, 0x332C27)
    static let line = dynamic(0xE7DDD1, 0x3B332D)
    static let text = dynamic(0x2B2522, 0xF2EBE3)
    static let secondary = dynamic(0x857A70, 0xA99C90)
    static let tertiary = dynamic(0xB0A498, 0x75695F)
    static let accent = dynamic(0xC96442, 0xD97757)
    static let accentSoft = dynamic(0xF6E4DA, 0x41291F)
    static let track = dynamic(0xEDE4D8, 0x3B332D)
    static let green = dynamic(0x4F8A5B, 0x7CC08A)
    static let orange = dynamic(0xC2711F, 0xE8A15A)
    static let red = dynamic(0xC2452D, 0xEF7A62)
    /// The floating action bar: dark on light, light on dark.
    static let bar = dynamic(0x2B2522, 0xF2EBE3)
    static let barText = dynamic(0xF5F0E8, 0x2B2522)

    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .serif) }

    /// Green while there is room, orange near the limit, red at it.
    static func usage(_ percent: Int) -> Color {
        percent >= 100 ? red : percent >= 75 ? orange : green
    }

    private static func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let hex = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        })
    }
}

let relativeFormatter: RelativeDateTimeFormatter = {
    let f = RelativeDateTimeFormatter()
    f.unitsStyle = .short
    return f
}()

func relative(_ date: Date) -> String { relativeFormatter.localizedString(for: date, relativeTo: Date()) }

// MARK: - Pieces

/// The app's name as headers show it: "Porter" large, "for Claude Desktop" small underneath.
struct AppTitle: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: Icon.appImage(size: 96))
                .resizable()
                .frame(width: 36, height: 36)
                .padding(-3)
            VStack(alignment: .leading, spacing: 0) {
                Text("Porter").font(Theme.title(18))
                Text("for Claude Desktop")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Porter for Claude Desktop")
    }
}

/// Spins while data reloads or an operation runs. It watches the reload on its own, so a reload
/// redraws only this.
struct ActivitySpinner: View {
    @ObservedObject var loading: LoadState
    let busy: Bool
    var scale: CGFloat = 0.8

    var body: some View {
        if loading.refreshing || busy { ProgressView().controlSize(.small).scaleEffect(scale) }
    }
}

/// A small uppercase heading above a group.
struct Caption: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.7)
            .foregroundStyle(Theme.secondary)
    }
}

struct UsageBar: View {
    let label: String
    let percent: Int
    /// The window has started over since the sample: no bar, just "reset".
    var expired = false
    /// The sidebar's smaller version.
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 4 : 7) {
            Text(label)
                .font(.system(size: compact ? 9 : 10, weight: .medium))
                .foregroundStyle(Theme.secondary)
                .frame(width: compact ? nil : 15, alignment: .leading)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.track)
                    if !expired {
                        Capsule()
                            .fill(Theme.usage(percent))
                            .frame(width: max(compact ? 3 : 5, g.size.width * CGFloat(min(percent, 100)) / 100))
                    }
                }
            }
            .frame(height: compact ? 4 : 5)
            Text(expired ? tr("reset") : "\(percent)%")
                .font(.system(size: compact ? 9 : 10, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(expired ? Theme.secondary : Theme.usage(percent))
                .lineLimit(1)
                .fixedSize()
                .frame(minWidth: compact ? 28 : 32, alignment: .trailing)
        }
    }
}

/// Both usage windows, or a quiet note when the app has none recorded. `compact` puts them side by
/// side, without the note on old data (it is still faded).
struct UsageBars: View {
    let usage: Usage?
    var compact = false

    var body: some View {
        if let usage, compact {
            HStack(spacing: 8) {
                UsageBar(label: "5h", percent: usage.fiveHour ?? 0, expired: usage.fiveHourExpired, compact: true)
                UsageBar(label: "7d", percent: usage.sevenDay ?? 0, expired: usage.sevenDayExpired, compact: true)
            }
            .opacity(usage.isStale ? 0.6 : 1)
        } else if let usage {
            // A closed Claude app records nothing: an old sample is shown faded, with its age.
            let stale = usage.isStale
            VStack(alignment: .leading, spacing: 5) {
                UsageBar(label: "5h", percent: usage.fiveHour ?? 0, expired: usage.fiveHourExpired)
                UsageBar(label: "7d", percent: usage.sevenDay ?? 0, expired: usage.sevenDayExpired)
                if stale {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(tr("data from %@", relative(usage.sampledAt)))
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.tertiary)
                }
            }
            .opacity(stale ? 0.6 : 1)
            .help(stale ? tr("Claude Desktop records usage only now and then, while you use that account: this is the last value it saved.") : "")
        } else {
            Text(tr("No usage data"))
                .font(.system(size: 11))
                .foregroundStyle(Theme.tertiary)
        }
    }
}

struct Badge: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage).font(.system(size: 8, weight: .bold))
            Text(text).font(.system(size: 11, weight: .medium)).lineLimit(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.13)))
        .fixedSize()
    }
}

struct Chip: View {
    let title: String
    let count: Int
    let selected: Bool
    var tint: Color = Theme.accent
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title).font(.system(size: 12, weight: selected ? .semibold : .regular)).lineLimit(1)
                Text("\(count)")
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(selected ? Color.white.opacity(0.25) : Theme.track))
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .foregroundStyle(selected ? Color.white : Theme.text)
            .background(Capsule().fill(selected ? tint : hover ? Theme.track : Theme.card))
            .overlay(Capsule().strokeBorder(selected ? Color.clear : Theme.line))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .onHover { hover = $0 }
        .animation(.easeOut(duration: 0.12), value: selected)
    }
}

/// Terracotta, for the one action that matters on a surface.
struct PrimaryButtonStyle: ButtonStyle {
    var large = false
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: large ? 13 : 12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, large ? 16 : 12)
            .padding(.vertical, large ? 8 : 6)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Theme.accent.opacity(configuration.isPressed ? 0.8 : 1)))
            .opacity(enabled ? 1 : 0.4)
            .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var large = false
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: large ? 13 : 12, weight: .medium))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, large ? 16 : 12)
            .padding(.vertical, large ? 8 : 6)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(configuration.isPressed ? Theme.track : Theme.raised))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Theme.line))
            .opacity(enabled ? 1 : 0.4)
            .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// A round icon button, for secondary controls in headers and cards.
struct IconButtonLabel: View {
    let systemImage: String
    @State private var hover = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.secondary)
            .frame(width: 26, height: 26)
            .background(Circle().fill(hover ? Theme.track : Color.clear))
            .contentShape(Circle())
            .onHover { hover = $0 }
    }
}

extension View {
    /// The card surface used across the app.
    func card(padding: CGFloat = 14, highlighted: Bool = false) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(highlighted ? Theme.accentSoft : Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(highlighted ? Theme.accent : Theme.line, lineWidth: highlighted ? 2 : 1))
    }
}

/// An account with its usage: the source, or a destination to pick.
struct AccountTile: View {
    let title: String
    /// The account's email, or why its sessions are not visible yet.
    let detail: String?
    let usage: Usage?
    var selected = false
    @State private var hover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 6) {
                Text(title)
                    .font(Theme.title(14))
                    .lineLimit(1)
                Spacer(minLength: 4)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            Text(detail ?? " ")
                .font(.system(size: 11))
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            // Tiles sit side by side: each keeps room for the tallest case (bars plus their age),
            // so they line up whether or not their data is fresh.
            ZStack(alignment: .topLeading) {
                UsageBars(usage: Usage(fiveHour: 0, sevenDay: 0, sampledAt: .distantPast)).hidden()
                UsageBars(usage: usage)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(selected ? Theme.accentSoft : Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(selected ? Theme.accent : hover ? Theme.tertiary : Theme.line, lineWidth: selected ? 2 : 1))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onHover { hover = $0 }
        .animation(.easeOut(duration: 0.15), value: selected)
    }
}

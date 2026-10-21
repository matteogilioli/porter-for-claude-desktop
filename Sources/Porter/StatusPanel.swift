import AppKit
import SwiftUI

/// The window that drops down from the menu-bar icon. A borderless panel rather than an NSPopover,
/// so the whole surface, arrow area included, takes the app's own colors.
final class StatusPanel: NSPanel, NSWindowDelegate {
    private var anchor: NSPoint = .zero
    private var outsideClicks: Any?

    init(controller: AppController) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 380, height: 300),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        isFloatingPanel = true
        level = .statusBar
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        hidesOnDeactivate = false
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        let host = NSHostingController(rootView: PanelView(controller: controller))
        host.sizingOptions = [.preferredContentSize]
        contentViewController = host
        delegate = self
    }

    override var canBecomeKey: Bool { true }

    /// Opens right below the status item, kept inside the screen.
    func show(below button: NSStatusBarButton) {
        guard let window = button.window else { return }
        let frame = window.convertToScreen(button.convert(button.bounds, to: nil))
        let screen = (window.screen ?? NSScreen.main)?.visibleFrame ?? .zero
        let width = self.frame.width
        let x = min(max(frame.midX - width / 2, screen.minX + 8), screen.maxX - width - 8)
        anchor = NSPoint(x: x, y: frame.minY - 6)
        setFrameTopLeftPoint(anchor)
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
        outsideClicks = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }
    }

    override func close() {
        if let outsideClicks { NSEvent.removeMonitor(outsideClicks) }
        outsideClicks = nil
        super.close()
    }

    /// Esc closes it, like a menu.
    override func cancelOperation(_ sender: Any?) { close() }

    func windowDidResignKey(_ notification: Notification) {
        // A dialog or the picker took over: get out of the way.
        if isVisible { close() }
    }

    /// The content grows and shrinks with the data; the top edge stays under the icon.
    func windowDidResize(_ notification: Notification) {
        if anchor != .zero { setFrameTopLeftPoint(anchor) }
    }
}

// MARK: - Content

private struct PanelView: View {
    @ObservedObject var controller: AppController

    private var maxHeight: CGFloat { (NSScreen.main?.visibleFrame.height ?? 800) - 40 }

    var body: some View {
        VStack(spacing: 0) {
            header
            ViewThatFits(in: .vertical) {
                content
                ScrollView { content }
            }
            footer
        }
        .frame(width: 380)
        .frame(maxHeight: maxHeight)
        .fixedSize(horizontal: false, vertical: true)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.line))
        .foregroundStyle(Theme.text)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            AppTitle()
            Spacer()
            ActivitySpinner(loading: controller.loading, busy: controller.busy)
            Button { controller.reload() } label: { IconButtonLabel(systemImage: "arrow.clockwise") }
                .buttonStyle(.plain)
                .help(tr("Refresh"))
            Button { controller.openMain() } label: { IconButtonLabel(systemImage: "macwindow") }
                .buttonStyle(.plain)
                .help(tr("Open Porter"))
            SettingsMenu(controller: controller)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: Body

    @ViewBuilder private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let activity = controller.activity {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(activity).font(.system(size: 12, weight: .medium))
                }
                .card(padding: 10, highlighted: true)
            }
            if controller.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(Theme.tertiary)
                    EmptyText(loading: controller.loading)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            } else if controller.multipleProfiles {
                ForEach(controller.profileSections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Caption(section.title)
                        ForEach(section.profiles) { ProfileCard(controller: controller, entry: $0) }
                    }
                }
            } else {
                ForEach(controller.accountSections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Caption(section.title)
                        ForEach(section.stores, id: \.key) { AccountCard(controller: controller, store: $0) }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    // MARK: Footer

    @ViewBuilder private var footer: some View {
        if controller.multipleProfiles {
            VStack(spacing: 0) {
                Rectangle().fill(Theme.line).frame(height: 1)
                Button { controller.newProfile() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text(tr("New Profile…"))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Cards

/// One Claude app: who is signed in, their usage, and what can be moved out of it.
private struct ProfileCard: View {
    @ObservedObject var controller: AppController
    let entry: ProfileEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(controller.isRunning(entry.dir) ? Theme.green : Theme.tertiary)
                    .frame(width: 7, height: 7)
                Text(controller.profileTitle(entry.dir))
                    .font(Theme.title(15))
                    .lineLimit(1)
                Spacer(minLength: 6)
                moreMenu
            }
            if let main = entry.main {
                StoreSummary(controller: controller, store: main, detail: controller.accountDetail(main))
                MoveActions(controller: controller, store: main)
            } else {
                Text(tr("Not signed in"))
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondary)
            }
            if !entry.others.isEmpty {
                VStack(spacing: 0) {
                    ForEach(entry.others, id: \.key) { other in
                        Rectangle().fill(Theme.line).frame(height: 1)
                        OtherStoreRow(controller: controller, store: other)
                    }
                }
            }
        }
        .card()
    }

    private var moreMenu: some View {
        MoreMenu {
            Button(controller.openAppTitle(entry.dir)) { controller.openApp(entry.dir) }
            if let main = entry.main {
                Button(tr("Sessions")) { controller.openMain(main) }
            }
            Divider()
            ProfileMenuItems(controller: controller, dir: entry.dir)
        }
    }
}

/// Classic mode: one account of the single Claude app.
private struct AccountCard: View {
    @ObservedObject var controller: AppController
    let store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(controller.name(store))
                    .font(Theme.title(15))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 6)
                MoreMenu {
                    Button(controller.openAppTitle(store.dataDir)) { controller.openApp(store.dataDir) }
                    Button(tr("Sessions")) { controller.openMain(store) }
                    AccountMenuItems(controller: controller, store: store)
                }
            }
            StoreSummary(controller: controller, store: store,
                         detail: store.isSignedIn ? nil : controller.accountDetail(store))
            MoveActions(controller: controller, store: store)
        }
        .card()
    }
}

/// Email, usage bars and the session counts of one account.
private struct StoreSummary: View {
    @ObservedObject var controller: AppController
    let store: Store
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            if let detail {
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    // Closer to the title it belongs to, further from the usage below.
                    .padding(.top, -7)
                    .padding(.bottom, 4)
            }
            if store.isSignedIn { UsageBars(usage: store.usage) }
            HStack(spacing: 6) {
                Text(tr("%ld open", store.open.count))
                if !store.isSignedIn, let last = store.lastActivity {
                    Text("·")
                    Text(tr("last used %@", relative(last)))
                }
                if !store.stopped.isEmpty {
                    Badge(text: tr("%ld stopped by limit", store.stopped.count),
                          systemImage: "exclamationmark.triangle.fill", color: Theme.orange)
                }
                Spacer(minLength: 4)
                if !store.sessions.isEmpty, !controller.targets(for: store).isEmpty {
                    Button { controller.openMain(store) } label: {
                        HStack(spacing: 3) {
                            Text(tr("Sessions"))
                            Image(systemName: "chevron.right").font(.system(size: 8, weight: .bold))
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .disabled(controller.busy)
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(Theme.secondary)
        }
    }
}

/// The move people make most: the sessions stopped by a limit, to the best destination.
private struct MoveActions: View {
    @ObservedObject var controller: AppController
    let store: Store

    var body: some View {
        if !store.stopped.isEmpty, let target = controller.bestTarget(for: store) {
            Button {
                controller.move(store.stopped, from: store, to: target)
            } label: {
                HStack(spacing: 6) {
                    Text(tr("Move %ld to %@", store.stopped.count, controller.label(target)))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Image(systemName: "arrow.right").font(.system(size: 10, weight: .bold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(controller.busy)
        }
    }
}

/// An account that used this Claude app before, or another organization of the signed-in one.
private struct OtherStoreRow: View {
    @ObservedObject var controller: AppController
    let store: Store

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(controller.name(store))
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 5) {
                    Text(tr("%ld open", store.open.count))
                    if let last = store.lastActivity {
                        Text("·")
                        Text(tr("last used %@", relative(last)))
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(Theme.secondary)
            }
            Spacer(minLength: 6)
            if !store.stopped.isEmpty {
                Badge(text: "\(store.stopped.count)", systemImage: "exclamationmark.triangle.fill", color: Theme.orange)
            }
            MoreMenu {
                Button(tr("Sessions")) { controller.openMain(store) }
                AccountMenuItems(controller: controller, store: store)
            }
        }
        .padding(.top, 9)
    }
}

/// The empty panel: still loading, or really nothing to show.
private struct EmptyText: View {
    @ObservedObject var loading: LoadState

    var body: some View {
        Text(loading.refreshing ? tr("Loading…") : tr("No Claude Code sessions found"))
    }
}

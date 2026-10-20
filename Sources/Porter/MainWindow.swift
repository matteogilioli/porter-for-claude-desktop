import AppKit
import SwiftUI

/// A project sessions belong to: its folder, named after the Claude Desktop environment that uses it.
struct PickerProject: Hashable {
    let path: String
    let name: String
}

/// The app's main window: accounts on the left, the chosen account's sessions on the right, and
/// an action bar for whatever is selected. While it is open the app shows in the Dock.
final class MainWindow: NSObject, NSWindowDelegate {
    let window: NSWindow

    init(controller: AppController) {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1160, height: 720),
                          styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
                          backing: .buffered, defer: false)
        super.init()
        window.title = "Porter for Claude Desktop"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 860, height: 520)
        window.delegate = self
        window.contentViewController = NSHostingController(rootView: MainView(controller: controller))
        // After the content, which resizes the window: the saved frame is read before anything overwrites it.
        if !window.setFrameUsingName("MainWindow") {
            window.setContentSize(NSSize(width: 1160, height: 720))
            window.center()
        }
        window.setFrameAutosaveName("MainWindow")
    }

    func show() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        // Back to a menu-bar-only app.
        DispatchQueue.main.async { NSApp.setActivationPolicy(.accessory) }
    }
}

private struct MainView: View {
    @ObservedObject var controller: AppController

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(controller: controller)
                .frame(width: 260)
            Rectangle().fill(Theme.line).frame(width: 1)
            SwiftUI.Group {
                if let store = controller.store(controller.selectedKey) {
                    AccountView(controller: controller, storeKey: store.key)
                        .id(store.key)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "sidebar.left").font(.system(size: 30, weight: .light)).foregroundStyle(Theme.tertiary)
                        Text(controller.isEmpty ? tr("No Claude Code sessions found") : tr("Choose an account"))
                            .font(Theme.title(16))
                            .foregroundStyle(Theme.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.background)
        .foregroundStyle(Theme.text)
        .ignoresSafeArea()
        .sheet(item: $controller.moveDraft) { draft in
            MoveSheet(controller: controller, draft: draft)
        }
    }
}

// MARK: - Sidebar

private struct Sidebar: View {
    @ObservedObject var controller: AppController

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                AppTitle()
                Spacer()
                ActivitySpinner(loading: controller.loading, busy: controller.busy, scale: 0.7)
            }
            .padding(.horizontal, 16)
            .padding(.top, 44)
            .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if controller.multipleProfiles {
                        ForEach(controller.profileSections, id: \.title) { section in
                            VStack(alignment: .leading, spacing: 4) {
                                Caption(section.title).padding(.horizontal, 8)
                                ForEach(section.profiles) { entry in
                                    if let main = entry.main {
                                        SidebarRow(controller: controller, store: main,
                                                   title: controller.profileTitle(entry.dir),
                                                   running: controller.isRunning(entry.dir))
                                    } else {
                                        EmptyProfileRow(controller: controller, dir: entry.dir)
                                    }
                                    ForEach(entry.others, id: \.key) { other in
                                        SidebarRow(controller: controller, store: other, title: controller.name(other),
                                                   running: nil, indented: true)
                                    }
                                }
                            }
                        }
                    } else {
                        ForEach(controller.accountSections, id: \.title) { section in
                            VStack(alignment: .leading, spacing: 4) {
                                Caption(section.title).padding(.horizontal, 8)
                                ForEach(section.stores, id: \.key) { store in
                                    SidebarRow(controller: controller, store: store, title: controller.name(store),
                                               running: nil)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            }

            Rectangle().fill(Theme.line).frame(height: 1)
            HStack(spacing: 6) {
                if controller.multipleProfiles {
                    Button { controller.newProfile() } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                            Text(tr("New Profile…"))
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button { controller.reload() } label: { IconButtonLabel(systemImage: "arrow.clockwise") }
                    .buttonStyle(.plain)
                    .help(tr("Refresh"))
                SettingsMenu(controller: controller)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
        .background(Theme.raised)
    }
}

/// The settings, shared by the panel and the main window.
struct SettingsMenu: View {
    @ObservedObject var controller: AppController

    var body: some View {
        Menu {
            Toggle(tr("Multiple Profiles"), isOn: Binding(get: { controller.multipleProfiles },
                                                         set: { _ in controller.toggleMultipleProfiles() }))
            Toggle(tr("Launch at Login"), isOn: Binding(get: { controller.launchAtLogin },
                                                       set: { _ in controller.toggleLaunchAtLogin() }))
            Divider()
            Button(tr("Show Backups")) { controller.showBackups() }
            Divider()
            Button(tr("Quit")) { controller.quit() }
        } label: {
            IconButtonLabel(systemImage: "gearshape")
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .help(tr("Options"))
    }
}

/// One account in the sidebar; sessions can be dropped on it to move them there.
private struct SidebarRow: View {
    @ObservedObject var controller: AppController
    let store: Store
    let title: String
    /// Whether its Claude app is running; nil hides the dot.
    let running: Bool?
    var indented = false
    @State private var hover = false
    @State private var targeted = false

    private var selected: Bool { controller.selectedKey == store.key }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let running {
                Circle().fill(running ? Theme.green : Theme.tertiary).frame(width: 7, height: 7).padding(.top, 5)
            } else if indented {
                Image(systemName: "arrow.turn.down.right").font(.system(size: 9)).foregroundStyle(Theme.tertiary).padding(.top, 3)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 13, weight: indented ? .regular : .semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 4)
                    if !store.stopped.isEmpty {
                        Badge(text: "\(store.stopped.count)", systemImage: "exclamationmark.triangle.fill", color: Theme.orange)
                    }
                }
                if let usage = store.usage, store.isSignedIn {
                    UsageBars(usage: usage, compact: true)
                } else {
                    Text(controller.accountDetail(store) ?? tr("%ld open", store.open.count))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .padding(.leading, indented ? 14 : 0)
        .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(targeted ? Theme.accentSoft : selected ? Theme.card : hover ? Theme.track.opacity(0.6) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
            .strokeBorder(targeted || selected ? Theme.accent : Color.clear, lineWidth: targeted ? 2 : 1))
        .contentShape(RoundedRectangle(cornerRadius: 9))
        .onHover { hover = $0 }
        .onTapGesture { controller.selectedKey = store.key }
        .dropDestination(for: String.self) { items, _ in
            items.first.map { controller.drop($0, onto: store) } ?? false
        } isTargeted: { targeted = $0 }
    }
}

/// A Claude app nobody is signed in to yet.
private struct EmptyProfileRow: View {
    @ObservedObject var controller: AppController
    let dir: DataDir

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(controller.isRunning(dir) ? Theme.green : Theme.tertiary).frame(width: 7, height: 7).padding(.top, 5)
            VStack(alignment: .leading, spacing: 3) {
                Text(controller.profileTitle(dir)).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                Text(tr("Not signed in")).font(.system(size: 11)).foregroundStyle(Theme.secondary)
            }
            Spacer()
            MoreMenu {
                Button(controller.openAppTitle(dir)) { controller.openApp(dir) }
                ProfileMenuItems(controller: controller, dir: dir)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .opacity(0.8)
    }
}

// MARK: - Account

private struct AccountView: View {
    enum Filter: Hashable, CaseIterable { case open, stopped, archived, all }

    /// Sessions of one project, as one section of the list.
    struct Section: Identifiable {
        let id: String
        let project: PickerProject?
        let sessions: [SessionInfo]
    }

    /// A session with what the list needs from it, worked out once per update rather than per row.
    struct Entry {
        let session: SessionInfo
        let project: PickerProject?
        let text: String
    }

    @ObservedObject var controller: AppController
    let storeKey: String

    @State private var filter: Filter = .open
    @State private var project: String?
    @State private var query = ""
    @State private var selection = Set<String>()
    @State private var anchor: String?
    @State private var banner: (text: String, success: Bool)?

    private var store: Store? { controller.store(storeKey) }

    init(controller: AppController, storeKey: String) {
        self.controller = controller
        self.storeKey = storeKey
        let stopped = controller.store(storeKey)?.stopped ?? []
        _filter = State(initialValue: stopped.isEmpty ? .open : .stopped)
    }

    private func matches(_ s: SessionInfo, _ filter: Filter) -> Bool {
        switch filter {
        case .open: return !s.isArchived
        case .stopped: return s.stoppedByLimit
        case .archived: return s.isArchived
        case .all: return true
        }
    }

    private func entries(_ store: Store) -> [Entry] {
        store.sessions.map { s in
            let project = controller.project(of: s)
            return Entry(session: s, project: project,
                         text: (s.title + " " + (project?.name ?? "") + " " + (s.cwd ?? "")).lowercased())
        }
    }

    /// The filter in effect: one whose sessions are all gone falls back to the open ones.
    private func activeFilter(_ entries: [Entry]) -> Filter {
        filter == .open || entries.contains(where: { matches($0.session, filter) }) ? filter : .open
    }

    /// The project in effect: one with no sessions left (moved, deleted, relinked) is dropped.
    private func activeProject(_ entries: [Entry]) -> String? {
        project.flatMap { p in entries.contains(where: { $0.project?.path == p }) ? p : nil }
    }

    private func rows(_ entries: [Entry]) -> [SessionInfo] {
        let words = query.lowercased().split(separator: " ")
        let filter = activeFilter(entries), project = activeProject(entries)
        return entries.filter { e in
            guard matches(e.session, filter), project == nil || e.project?.path == project else { return false }
            return words.isEmpty || words.allSatisfy { e.text.contains($0) }
        }.map(\.session)
    }

    /// Rows by project, the project with the most recent session first.
    private func sections(_ rows: [SessionInfo]) -> [Section] {
        var order: [String] = []
        var byKey: [String: [SessionInfo]] = [:]
        for s in rows {
            let key = s.projectPath ?? ""
            if byKey[key] == nil { order.append(key) }
            byKey[key, default: []].append(s)
        }
        return order.map { key in
            let list = byKey[key] ?? []
            return Section(id: key, project: list.first.flatMap { controller.project(of: $0) }, sessions: list)
        }
    }

    private func projectList(_ entries: [Entry]) -> [(project: PickerProject, count: Int)] {
        var counts: [String: (project: PickerProject, count: Int)] = [:]
        for e in entries { if let p = e.project { counts[p.path, default: (p, 0)].count += 1 } }
        return counts.values.map { ($0.project, $0.count, $0.project.name.lowercased()) }
            .sorted { ($1.1, $0.2) < ($0.1, $1.2) }
            .map { ($0.0, $0.1) }
    }

    var body: some View {
        if let store {
            let entries = self.entries(store)
            let rows = self.rows(entries)
            VStack(spacing: 0) {
                header(store)
                    .padding(.horizontal, 28)
                    .padding(.top, 40)
                    .padding(.bottom, 16)
                toolbar(entries)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 12)
                Rectangle().fill(Theme.line).frame(height: 1)
                list(rows)
            }
            .overlay(alignment: .bottom) {
                if !selection.isEmpty {
                    actionBar(store, rows)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 18)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .overlay(alignment: .top) {
                if let banner {
                    BannerView(controller: controller, text: banner.text, success: banner.success) { self.banner = nil }
                        .padding(.top, 14)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.18), value: selection.isEmpty)
            .animation(.easeOut(duration: 0.2), value: banner?.text)
            // Only what is on screen stays selected: actions never reach a session the user cannot see.
            .onChange(of: rows.map(\.id)) { _, visible in
                selection.formIntersection(visible)
                if let a = anchor, !selection.contains(a) { anchor = nil }
            }
            .onChange(of: controller.changes) { clearSelection() }
        }
    }

    private func clearSelection() {
        selection.removeAll()
        anchor = nil
    }

    // MARK: Header

    private func header(_ store: Store) -> some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text(controller.label(store))
                    .font(Theme.title(26))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if controller.multipleProfiles {
                        Circle().fill(controller.isRunning(store.dataDir) ? Theme.green : Theme.tertiary).frame(width: 7, height: 7)
                    }
                    Text([controller.accountDetail(store), tr("%ld open", store.open.count)]
                        .compactMap { $0 }.joined(separator: " · "))
                        .lineLimit(1)
                }
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondary)
            }
            // The name wins over the bars when space runs short.
            .layoutPriority(1)
            Spacer(minLength: 12)
            if store.isSignedIn {
                UsageBars(usage: store.usage).frame(minWidth: 140, maxWidth: 220)
            }
            HStack(spacing: 6) {
                Button { controller.openApp(store.dataDir) } label: {
                    Label(controller.openAppTitle(store.dataDir), systemImage: "arrow.up.forward.app")
                        .lineLimit(1)
                }
                .buttonStyle(SecondaryButtonStyle())
                .fixedSize()
                if controller.multipleProfiles || controller.isPrevious(store) {
                    MoreMenu {
                        if controller.multipleProfiles { ProfileMenuItems(controller: controller, dir: store.dataDir) }
                        AccountMenuItems(controller: controller, store: store)
                    }
                }
            }
        }
    }

    // MARK: Filters

    private func toolbar(_ entries: [Entry]) -> some View {
        let filter = activeFilter(entries), project = activeProject(entries)
        return HStack(spacing: 8) {
            ForEach(Filter.allCases, id: \.self) { f in
                let n = entries.filter { matches($0.session, f) }.count
                if n > 0 || f == .open {
                    Chip(title: title(f), count: n, selected: filter == f,
                         tint: f == .stopped ? Theme.orange : Theme.accent) { self.filter = f }
                }
            }
            let projects = projectList(entries)
            if projects.count > 1 || project != nil {
                Menu {
                    Button(tr("All Projects")) { self.project = nil }
                    Divider()
                    ForEach(projects, id: \.project.path) { item in
                        Button("\(item.project.name)  (\(item.count))") { self.project = item.project.path }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                        Text(projects.first { $0.project.path == project }?.project.name ?? tr("All Projects")).lineLimit(1)
                        Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(project == nil ? Theme.card : Theme.accentSoft))
                    .overlay(Capsule().strokeBorder(project == nil ? Theme.line : Theme.accent))
                }
                .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).fixedSize()
                .padding(.leading, 4)
            }
            Spacer(minLength: 12)
            SearchField(text: $query).frame(width: 220)
        }
    }

    private func title(_ filter: Filter) -> String {
        switch filter {
        case .open: return tr("Open")
        case .stopped: return tr("Stopped by Limit")
        case .archived: return tr("Archived")
        case .all: return tr("All")
        }
    }

    // MARK: Sessions

    private func list(_ rows: [SessionInfo]) -> some View {
        let groups = sections(rows)
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(groups) { group in
                    SwiftUI.Section {
                        VStack(spacing: 0) {
                            ForEach(Array(group.sessions.enumerated()), id: \.element.id) { i, s in
                                if i > 0 { Rectangle().fill(Theme.line).frame(height: 1) }
                                SessionRow(session: s, selected: selection.contains(s.id)) { shift in
                                    toggle(s.id, shift: shift)
                                }
                                .equatable()
                                .draggable(dragPayload(for: s)) {
                                    Label(selection.contains(s.id) && selection.count > 1
                                          ? tr("%ld selected", selection.count) : s.title,
                                          systemImage: "bubble.left.and.bubble.right")
                                        .padding(8)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.card))
                                }
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.card))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.line))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } header: {
                        sectionHeader(group)
                    }
                }
            }
            .padding(.horizontal, 28)
            // Room for the action bar, so it never covers the last row.
            .padding(.bottom, selection.isEmpty ? 20 : 90)
        }
        .overlay {
            if rows.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray").font(.system(size: 28, weight: .light)).foregroundStyle(Theme.tertiary)
                    Text(tr("No sessions match")).font(.system(size: 13)).foregroundStyle(Theme.secondary)
                }
            }
        }
    }

    /// Dragging a selected row drags the whole selection.
    private func dragPayload(for s: SessionInfo) -> String {
        let ids = selection.contains(s.id) ? Array(selection) : [s.id]
        return storeKey + "\n" + ids.joined(separator: ",")
    }

    private func sectionHeader(_ group: Section) -> some View {
        let ids = Set(group.sessions.map(\.id))
        let all = ids.isSubset(of: selection)
        return HStack(spacing: 8) {
            Text(group.project?.name ?? tr("Other")).font(Theme.title(14))
            Text("\(group.sessions.count)")
                .font(.system(size: 11, weight: .semibold)).monospacedDigit()
                .foregroundStyle(Theme.secondary)
                .padding(.horizontal, 6).padding(.vertical, 1)
                .background(Capsule().fill(Theme.track))
            if let path = group.project?.path {
                Text((path as NSString).abbreviatingWithTildeInPath)
                    .font(.system(size: 11)).foregroundStyle(Theme.tertiary)
                    .lineLimit(1).truncationMode(.middle)
            }
            if let project = group.project {
                let missing = controller.isMissing(project)
                if missing {
                    Button { controller.relocateProject(project, moveFolder: false) } label: {
                        Badge(text: tr("Folder missing"), systemImage: "questionmark.folder.fill", color: Theme.orange)
                    }
                    .buttonStyle(.plain)
                    .help(tr("Relink to…"))
                    .disabled(controller.busy)
                }
                MoreMenu {
                    Button(tr("Move Project…")) { controller.relocateProject(project, moveFolder: true) }
                        .disabled(missing)
                    Button(tr("Relink to…")) { controller.relocateProject(project, moveFolder: false) }
                    Divider()
                    Button(tr("Show in Finder")) {
                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: project.path)])
                    }
                    .disabled(missing)
                }
                .disabled(controller.busy)
            }
            Spacer(minLength: 8)
            Button(all ? tr("Deselect All") : tr("Select All")) {
                if all { selection.subtract(ids) } else { selection.formUnion(ids) }
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Theme.accent)
        }
        .padding(.horizontal, 4)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .background(Theme.background)
    }

    /// A click toggles one session; a shift-click sets the range from the last one clicked to the
    /// state of that one (a plain click when there is none).
    private func toggle(_ id: String, shift: Bool) {
        // Read now, not when the row was drawn: a row that did not change keeps its old closure.
        let visible = store.map { sections(rows(entries($0))).flatMap(\.sessions).map(\.id) } ?? []
        if shift, let anchor, let a = visible.firstIndex(of: anchor), let b = visible.firstIndex(of: id) {
            let range = visible[min(a, b)...max(a, b)]
            if selection.contains(anchor) { selection.formUnion(range) } else { selection.subtract(range) }
        } else if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
        anchor = id
    }

    // MARK: Action bar

    private func actionBar(_ store: Store, _ rows: [SessionInfo]) -> some View {
        let shown = Set(rows.map(\.id))
        let chosen = rows.filter { selection.contains($0.id) }
        return HStack(spacing: 14) {
            Text(tr("%ld selected", chosen.count))
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .fixedSize()
            // The links give way first when the bar runs short: the buttons never wrap.
            if !shown.isSubset(of: selection) {
                Button(tr("Select All (%ld)", shown.count)) { selection.formUnion(shown) }.buttonStyle(BarLinkStyle())
                    .layoutPriority(-1)
            }
            Button(tr("Deselect All")) { clearSelection() }.buttonStyle(BarLinkStyle())
                .layoutPriority(-1)
            Spacer(minLength: 12)
            if chosen.contains(where: { !$0.isArchived }) {
                Button { act(.archive, chosen, store) } label: { Label(tr("Archive"), systemImage: "archivebox") }
                    .buttonStyle(BarButtonStyle())
            }
            if chosen.contains(where: \.isArchived) {
                Button { act(.unarchive, chosen, store) } label: { Label(tr("Restore"), systemImage: "tray.and.arrow.up") }
                    .buttonStyle(BarButtonStyle())
            }
            Button { act(.delete, chosen, store) } label: { Label(tr("Delete…"), systemImage: "trash") }
                .buttonStyle(BarButtonStyle(destructive: true))
            Button { controller.move(chosen, from: store, to: nil) } label: {
                HStack(spacing: 6) {
                    Text(tr("Move To…"))
                    Image(systemName: "arrow.right").font(.system(size: 10, weight: .bold))
                }
            }
            .buttonStyle(PrimaryButtonStyle(large: true))
            .fixedSize()
            .disabled(controller.targets(for: store).isEmpty)
        }
        // Corners concentric with the buttons: their 8-point radius plus the 8-point inset.
        .padding(.leading, 18)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .foregroundStyle(Theme.barText)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.bar))
        .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
        .disabled(controller.busy)
    }

    private func act(_ action: SessionAction, _ sessions: [SessionInfo], _ store: Store) {
        controller.apply(action, to: sessions, in: store) { result in
            switch result {
            case nil: break
            case .success?:
                let n = sessions.count
                banner = (action == .archive ? tr("Archived %ld session(s).", n)
                          : action == .unarchive ? tr("Restored %ld session(s).", n) : tr("Moved %ld session(s) to the Trash.", n), true)
                let shown = banner?.text
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { if banner?.text == shown { banner = nil } }
            case .failure(let error)?:
                banner = (error.localizedDescription, false)
            }
        }
    }
}

/// A short note at the top of the account, after an action.
private struct BannerView: View {
    let controller: AppController
    let text: String
    let success: Bool
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: success ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .foregroundStyle(success ? Theme.green : Theme.red)
            Text(text).font(.system(size: 12, weight: .medium)).lineLimit(2)
            if success {
                Button(tr("Show Backups")) { controller.showBackups() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            Button(action: dismiss) { Image(systemName: "xmark").font(.system(size: 9, weight: .bold)) }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Capsule().fill(Theme.card))
        .overlay(Capsule().strokeBorder(Theme.line))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
    }
}

private struct BarButtonStyle: ButtonStyle {
    var destructive = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(destructive ? Theme.red : Theme.barText)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            // The bar is dark on light and light on dark: tint with its text color, not white.
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.barText.opacity(configuration.isPressed ? 0.18 : 0.08)))
            .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct BarLinkStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Theme.barText.opacity(configuration.isPressed ? 0.5 : 0.75))
            .lineLimit(1)
    }
}

// MARK: - Move sheet

/// Destination and options of a move, then its progress and outcome.
private struct MoveSheet: View {
    enum Phase { case choosing, moving, done(String), failed(String) }

    @ObservedObject var controller: AppController
    let draft: MoveDraft
    @Environment(\.dismiss) private var dismiss

    @State private var targetKey: String?
    @State private var restart = true
    @State private var mode = MoveOptions.Mode.move
    @State private var phase = Phase.choosing
    /// What the move is doing right now, while it runs.
    @State private var step: String?

    init(controller: AppController, draft: MoveDraft) {
        self.controller = controller
        self.draft = draft
        let target = controller.store(draft.targetKey)
            ?? controller.store(draft.sourceKey).flatMap { controller.bestTarget(for: $0) }
        _targetKey = State(initialValue: target?.key)
    }

    private var source: Store? { controller.store(draft.sourceKey) }
    private var target: Store? { controller.store(targetKey) }
    private var sessions: [SessionInfo] {
        let ids = Set(draft.sessionIds)
        return source?.sessions.filter { ids.contains($0.id) } ?? []
    }

    private var options: MoveOptions { MoveOptions(mode: mode, restartTarget: restart) }

    /// What this move would do, with the apps as the last refresh saw them (refreshed when the sheet opens).
    private var plan: MovePlan? {
        guard let source, let target else { return nil }
        return Mover.plan(sessions, from: source, to: target)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch phase {
            case .choosing: choosing
            case .moving:
                VStack(spacing: 14) {
                    ProgressView().controlSize(.large)
                    Text(tr(mode == .move ? "Moving sessions…" : "Copying sessions…")).font(Theme.title(18))
                    Text(step ?? " ")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondary)
                        .animation(.easeOut(duration: 0.15), value: step)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 70)
            case .done(let report): outcome(true, report)
            case .failed(let message): outcome(false, message)
            }
        }
        .frame(width: 640)
        .background(Theme.background)
        .foregroundStyle(Theme.text)
        .onAppear { controller.reload() }
    }

    private var choosing: some View {
        let plan = self.plan
        let effects = plan.map { MoveEffects($0, options, running: controller.snapshot.running) }
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode == .move ? tr("Move %ld to…", sessions.count) : tr("Copy %ld to…", sessions.count)).font(Theme.title(22))
                    Text(sessions.prefix(3).map(\.title).joined(separator: " · ")
                         + (sessions.count > 3 ? " · " + tr("+%ld more", sessions.count - 3) : ""))
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(2)
                }
                if let source {
                    let targets = controller.targets(for: source)
                    if targets.isEmpty {
                        Text(tr("No other account to move to")).foregroundStyle(Theme.secondary)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                            ForEach(targets, id: \.key) { t in
                                AccountTile(title: controller.label(t), detail: controller.accountDetail(t), usage: t.usage,
                                            selected: t.key == targetKey)
                                    .onTapGesture { targetKey = t.key }
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Picker("", selection: $mode) {
                            Text(tr("Move")).tag(MoveOptions.Mode.move)
                            Text(tr("Copy")).tag(MoveOptions.Mode.copy)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 200)
                        Text(modeNote(closesSource: effects?.closesSource == true))
                            .font(.system(size: 11))
                            .foregroundStyle(effects?.closesSource == true ? Theme.orange : Theme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let target, let effects {
                        let running = controller.isRunning(target.dataDir)
                        OptionRow(title: running ? tr("Restart %@ to load them", target.dataDir.label)
                                                 : tr("Open %@ afterwards", target.dataDir.label),
                                  note: effects.restartForced
                                      ? tr("Moving within %@ archives the sessions in the same app, so it is always closed and reopened.", target.dataDir.label)
                                      : running ? tr("%@ is open and keeps its session list in memory: it is closed and reopened so the moved sessions show up.", target.dataDir.label)
                                                : tr("Opens %@ when the move is done.", target.dataDir.label),
                                  isOn: effects.restartForced ? .constant(true) : $restart, enabled: !effects.restartForced)
                    }
                    if let plan, let target { warnings(plan, target) }
                }
            }
            .padding(24)
            footer {
                Button(tr("Cancel")) { dismiss() }
                    .buttonStyle(SecondaryButtonStyle(large: true))
                    .keyboardShortcut(.cancelAction)
                Button(action: start) {
                    HStack(spacing: 6) {
                        Text(target.map { tr(mode == .move ? "Move %ld to %@" : "Copy %ld to %@", sessions.count, controller.label($0)) }
                             ?? tr(mode == .move ? "Move" : "Copy"))
                        Image(systemName: "arrow.right").font(.system(size: 11, weight: .bold))
                    }
                }
                .buttonStyle(PrimaryButtonStyle(large: true))
                .keyboardShortcut(.defaultAction)
                .disabled(target == nil || sessions.isEmpty || controller.busy)
            }
        }
    }

    /// What the user should know about the destination before going ahead.
    @ViewBuilder private func warnings(_ plan: MovePlan, _ target: Store) -> some View {
        let lines = [
            target.usage?.exhausted == true ? tr("⚠︎ The destination account has reached a usage limit too.") : nil,
            target.isSignedIn ? nil : tr("The destination account is not signed in: sessions appear once you sign in to it."),
            plan.upToDate.isEmpty ? nil
                : mode == .move ? tr("%ld already up to date in the destination.", plan.upToDate.count)
                : tr("%ld are already in the destination: copying them again makes another copy of each.", plan.upToDate.count),
        ].compactMap { $0 }
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(lines, id: \.self) { Text($0) }
            }
            .font(.system(size: 11))
            .foregroundStyle(Theme.orange)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func modeNote(closesSource: Bool) -> String {
        let label = source?.dataDir.label ?? ""
        switch mode {
        case .move where closesSource:
            return tr("They are archived in %@, which is open: it is closed and reopened, and anything running in it stops.", label)
        case .move:
            return tr("They are archived in the source account, so each session goes on in one place only.")
        case .copy:
            return tr("They stay in the source account too. Each copy gets a conversation of its own: what you write in one does not show up in the other.")
        }
    }

    private func start() {
        guard let plan, !sessions.isEmpty else { return }
        phase = .moving
        controller.run(plan, options: options, progress: { step = $0 }) { result in
            switch result {
            case .success(let report): phase = .done(report)
            case .failure(let error): phase = .failed(error.localizedDescription)
            }
        }
    }

    private func outcome(_ success: Bool, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 14) {
                Image(systemName: success ? "checkmark" : "xmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(success ? Theme.green : Theme.red))
                Text(success ? tr(mode == .move ? "Sessions moved to %@" : "Sessions copied to %@", target.map(controller.label) ?? "")
                             : tr("Something went wrong"))
                    .font(Theme.title(20))
                    .multilineTextAlignment(.center)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(text.split(separator: "\n").enumerated()), id: \.offset) { _, line in
                        Text(String(line))
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.secondary)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .card(padding: 14)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            footer {
                if success {
                    Button(tr("Show Backups")) { controller.showBackups() }
                        .buttonStyle(SecondaryButtonStyle(large: true))
                } else {
                    Button(tr("Back")) { phase = .choosing }
                        .buttonStyle(SecondaryButtonStyle(large: true))
                }
                Button(tr("Done")) { dismiss() }
                    .buttonStyle(PrimaryButtonStyle(large: true))
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func footer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(Theme.line).frame(height: 1)
            HStack(spacing: 10) {
                Spacer()
                content()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .background(Theme.card)
    }
}

/// A switch with its label and an explanation underneath; a disabled one shows what will happen anyway.
private struct OptionRow: View {
    let title: String
    let note: String
    @Binding var isOn: Bool
    let enabled: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(note)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(Theme.accent)
                .controlSize(.small)
                .disabled(!enabled)
        }
    }
}

// MARK: - Pieces

/// The "…" button of a card, row or header.
struct MoreMenu<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        Menu(content: content) { IconButtonLabel(systemImage: "ellipsis") }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            .help(tr("More"))
    }
}

/// What can be done to a profile (a Claude app), wherever it is listed.
struct ProfileMenuItems: View {
    @ObservedObject var controller: AppController
    let dir: DataDir

    var body: some View {
        Button(tr("Rename Profile…")) { controller.renameProfile(dir) }
        if !dir.isDefault {
            Button(tr("Remove Profile…"), role: .destructive) { controller.removeProfile(dir) }
                .disabled(controller.busy)
        }
    }
}

/// What can be done to an account of a profile: only a previous one can be removed.
struct AccountMenuItems: View {
    @ObservedObject var controller: AppController
    let store: Store

    var body: some View {
        if controller.isPrevious(store) {
            Divider()
            Button(tr("Remove Account…"), role: .destructive) { controller.removeAccount(store) }
                .disabled(controller.busy)
        }
    }
}

private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").font(.system(size: 12)).foregroundStyle(Theme.secondary)
            TextField(tr("Search"), text: $text).textFieldStyle(.plain)
            if !text.isEmpty {
                Button { text = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.tertiary) }
                    .buttonStyle(.plain)
            }
        }
        .font(.system(size: 12))
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(Capsule().fill(Theme.card))
        .overlay(Capsule().strokeBorder(Theme.line))
    }
}

/// One session. Equatable, so a click redraws only the rows whose selection changed.
private struct SessionRow: View, Equatable {
    let session: SessionInfo
    let selected: Bool
    let action: (_ shift: Bool) -> Void
    @State private var hover = false

    static func == (a: SessionRow, b: SessionRow) -> Bool {
        a.selected == b.selected && a.session.id == b.session.id && a.session.title == b.session.title
            && a.session.lastActivity == b.session.lastActivity && a.session.isArchived == b.session.isArchived
            && a.session.error == b.session.error && a.session.runCwd == b.session.runCwd
    }

    /// Probably still running: moving it would leave a turn half-written in the source.
    private var isActive: Bool {
        guard let last = session.lastActivity, !session.isArchived else { return false }
        return Date().timeIntervalSince(last) < 120
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(selected ? Theme.accent : Theme.tertiary, lineWidth: 1.5)
                    .background(Circle().fill(selected ? Theme.accent : Color.clear))
                if selected {
                    Image(systemName: "checkmark").font(.system(size: 9, weight: .heavy)).foregroundStyle(.white)
                }
            }
            .frame(width: 18, height: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title).font(.system(size: 13, weight: .medium)).lineLimit(1)
                HStack(spacing: 5) {
                    if let last = session.lastActivity { Text(relative(last)) }
                    if let worktree = session.worktree {
                        Text("·")
                        Image(systemName: "arrow.triangle.branch")
                        Text(worktree).lineLimit(1)
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(Theme.secondary)
            }
            Spacer(minLength: 8)
            if isActive { Badge(text: tr("Active now"), systemImage: "circle.fill", color: Theme.green) }
            if session.stoppedByLimit { Badge(text: tr("Limit reached"), systemImage: "exclamationmark.triangle.fill", color: Theme.orange) }
            if session.isArchived { Badge(text: tr("Archived"), systemImage: "archivebox.fill", color: Theme.secondary) }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(selected ? Theme.accentSoft : hover ? Theme.raised : Color.clear)
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .onTapGesture { action(NSEvent.modifierFlags.contains(.shift)) }
    }
}

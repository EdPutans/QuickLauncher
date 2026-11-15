import SwiftUI
import AppKit
import WidgetKit

struct ContentView: View {
    @State private var shortcuts: [ShortcutItem] = ShortcutStore.shared.load()
    @State private var selectedID: UUID?

    private let presetIcons: [String] = [
        "curlybraces.square.fill",
        "chevron.left.forwardslash.chevron.right",
        "terminal.fill",
        "apple.terminal.fill",
        "folder.fill",
        "doc.text.fill",
        "arrow.triangle.branch",
        "bolt.fill",
        "play.fill",
        "hammer.fill",
        "wrench.and.screwdriver.fill",
        "externaldrive.fill",
        "safari.fill",
        "cpu.fill",
        "server.rack",
        "trash.fill"
    ]

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: $selectedID) {
                    ForEach(shortcuts) { item in
                        HStack(spacing: 10) {
                            Image(systemName: item.iconName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.tint)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Text(item.actionType.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                        .tag(item.id)
                    }
                    .onMove(perform: moveItems)
                }
                .listStyle(.sidebar)

                Divider()

                HStack(spacing: 12) {
                    Button(action: addItem) {
                        Label("Add Shortcut", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)

                    Spacer()

                    if selectedID != nil {
                        Button(role: .destructive, action: deleteSelected) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Delete selected shortcut")
                    }
                }
                .padding(10)
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            detailPane
        }
        .onAppear {
            if selectedID == nil {
                selectedID = shortcuts.first?.id
            }
        }
    }

    @ViewBuilder
    private var detailPane: some View {
        if let selectedID,
           let index = shortcuts.firstIndex(where: { $0.id == selectedID }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Image(systemName: shortcuts[index].iconName)
                            .font(.system(size: 22, weight: .semibold))
                            .frame(width: 42, height: 42)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(shortcuts[index].title.isEmpty ? "Untitled Shortcut" : shortcuts[index].title)
                                .font(.title3.weight(.semibold))
                            Text(shortcuts[index].actionType.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title")
                            .font(.headline)
                        TextField("e.g. Dev in Cursor", text: $shortcuts[index].title)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Action Type")
                            .font(.headline)
                        Picker("", selection: $shortcuts[index].actionType) {
                            ForEach(ActionType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    if shortcuts[index].actionType == .openWithApp {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Application Name")
                                .font(.headline)
                            HStack {
                                TextField("e.g. Cursor, Visual Studio Code, Finder", text: $shortcuts[index].appName)
                                    .textFieldStyle(.roundedBorder)
                                Button("Choose App…") {
                                    chooseApp(for: index)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("File or Folder Path")
                                .font(.headline)
                            HStack {
                                TextField("e.g. ~/Dev", text: $shortcuts[index].target)
                                    .textFieldStyle(.roundedBorder)
                                Button("Browse…") {
                                    chooseTargetPath(for: index)
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Shell Command (/bin/zsh -lc)")
                                .font(.headline)
                            TextField("e.g. cd ~/Dev && ./run-job.sh", text: $shortcuts[index].target)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.headline)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                            ForEach(presetIcons, id: \.self) { icon in
                                Button {
                                    shortcuts[index].iconName = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 15))
                                        .frame(width: 34, height: 34)
                                        .background(
                                            shortcuts[index].iconName == icon
                                                ? Color.accentColor.opacity(0.25)
                                                : Color.primary.opacity(0.06)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    shortcuts[index].iconName == icon ? Color.accentColor : Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack {
                            Text("Custom SF Symbol:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("terminal.fill", text: $shortcuts[index].iconName)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    Divider()

                    HStack(spacing: 12) {
                        Button {
                            saveAndReload()
                        } label: {
                            Label("Save & Sync Widget", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button {
                            saveAndReload()
                            ShortcutStore.execute(shortcuts[index])
                        } label: {
                            Label("Test Run", systemImage: "play.fill")
                        }
                        .controlSize(.large)

                        Spacer()

                        Button(role: .destructive) {
                            deleteSelected()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .controlSize(.large)
                    }
                }
                .padding(24)
            }
        } else {
            VStack(spacing: 10) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                Text("Select a shortcut in the sidebar or click + to add one.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func addItem() {
        let newItem = ShortcutItem(
            title: "New Shortcut",
            iconName: "bolt.fill",
            actionType: .shellCommand,
            target: "echo 'Hello'",
            appName: ""
        )
        shortcuts.append(newItem)
        selectedID = newItem.id
        saveAndReload()
    }

    private func deleteSelected() {
        guard let selectedID,
              let index = shortcuts.firstIndex(where: { $0.id == selectedID }) else { return }
        shortcuts.remove(at: index)
        self.selectedID = shortcuts.first?.id
        saveAndReload()
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        shortcuts.move(fromOffsets: source, toOffset: destination)
        saveAndReload()
    }

    private func saveAndReload() {
        ShortcutStore.shared.save(shortcuts)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func chooseTargetPath(for index: Int) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            shortcuts[index].target = url.path
        }
    }

    private func chooseApp(for index: Int) {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            shortcuts[index].appName = url.deletingPathExtension().lastPathComponent
        }
    }
}


import Foundation

enum ActionType: String, Codable, CaseIterable, Identifiable {
    case shellCommand = "Shell Command"
    case openWithApp = "Open with App"

    var id: String { rawValue }
}

struct ShortcutItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var iconName: String
    var actionType: ActionType
    /// Shell command string OR file/folder path to open
    var target: String
    /// Application name or path (used when actionType == .openWithApp, e.g. "Cursor" or "Visual Studio Code")
    var appName: String

    static let defaults: [ShortcutItem] = [
        ShortcutItem(
            title: "Dev in Cursor",
            iconName: "curlybraces.square.fill",
            actionType: .openWithApp,
            target: "~/Dev",
            appName: "Cursor"
        ),
        ShortcutItem(
            title: "Dev in VS Code",
            iconName: "chevron.left.forwardslash.chevron.right",
            actionType: .openWithApp,
            target: "~/Dev",
            appName: "Visual Studio Code"
        ),
        ShortcutItem(
            title: "Git Status Check",
            iconName: "arrow.triangle.branch",
            actionType: .shellCommand,
            target: "cd ~/Dev && git status",
            appName: ""
        ),
        ShortcutItem(
            title: "Run Daily Job",
            iconName: "terminal.fill",
            actionType: .shellCommand,
            target: "osascript -e 'display notification \"Job finished!\" with title \"QuickLauncher\"'",
            appName: ""
        )
    ]
}

final class ShortcutStore {
    static let shared = ShortcutStore()

    private var storageURL: URL {
        let fm = FileManager.default
        let sharedDir = URL(fileURLWithPath: "/Users/Shared/QuickLauncher", isDirectory: true)
        try? fm.createDirectory(at: sharedDir, withIntermediateDirectories: true)
        return sharedDir.appendingPathComponent("shortcuts.json")
    }

    func load() -> [ShortcutItem] {
        guard let data = try? Data(contentsOf: storageURL),
              let items = try? JSONDecoder().decode([ShortcutItem].self, from: data),
              !items.isEmpty else {
            return ShortcutItem.defaults
        }
        return items
    }

    func save(_ items: [ShortcutItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    static func execute(_ item: ShortcutItem) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")

        switch item.actionType {
        case .shellCommand:
            process.arguments = ["-lc", item.target]
        case .openWithApp:
            let expandedTarget = (item.target as NSString).expandingTildeInPath
            let escapedApp = item.appName.replacingOccurrences(of: "\"", with: "\\\"")
            let escapedTarget = expandedTarget.replacingOccurrences(of: "\"", with: "\\\"")
            process.arguments = ["-lc", "open -a \"\(escapedApp)\" \"\(escapedTarget)\""]
        }

        try? process.run()
    }
}

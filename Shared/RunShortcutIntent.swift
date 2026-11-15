import AppIntents
import Foundation
import AppKit

struct RunShortcutIntent: AppIntent {
    static var title: LocalizedStringResource = "Run Quick Shortcut"
    static var description = IntentDescription("Executes a configured shell command or opens a path with an app.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Shortcut ID")
    var shortcutID: String

    init() {}

    init(shortcutID: String) {
        self.shortcutID = shortcutID
    }

    func perform() async throws -> some IntentResult {
        guard let url = URL(string: "quicklauncher://run?id=\(shortcutID)") else {
            return .result()
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        config.addsToRecentItems = false
        config.createsNewApplicationInstance = false
        _ = try? await NSWorkspace.shared.open(url, configuration: config)
        return .result()
    }
}

struct OpenSettingsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open QuickLauncher Settings"
    static var description = IntentDescription("Opens the QuickLauncher configuration window.")
    static var openAppWhenRun: Bool = false

    init() {}

    func perform() async throws -> some IntentResult {
        guard let url = URL(string: "quicklauncher://settings") else {
            return .result()
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.createsNewApplicationInstance = false
        _ = try? await NSWorkspace.shared.open(url, configuration: config)
        return .result()
    }
}


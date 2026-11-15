import SwiftUI
import AppKit
import WidgetKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let windowIdentifier = NSUserInterfaceItemIdentifier("QuickLauncherSettingsWindow")
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false

        let items = ShortcutStore.shared.load()
        ShortcutStore.shared.save(items)
        WidgetCenter.shared.reloadAllTimelines()

        showSettingsWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettingsWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            guard url.scheme == "quicklauncher" else { continue }

            switch url.host {
            case "run":
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let id = components.queryItems?.first(where: { $0.name == "id" })?.value {
                    let items = ShortcutStore.shared.load()
                    if let item = items.first(where: { $0.id.uuidString == id }) {
                        ShortcutStore.execute(item)
                    }
                }
            case "settings":
                showSettingsWindow()
            default:
                break
            }
        }
    }

    func showSettingsWindow() {
        // Reuse existing window if already created
        if settingsWindow == nil {
            if let existing = NSApp.windows.first(where: { $0.identifier == Self.windowIdentifier }) {
                settingsWindow = existing
            }
        }

        if settingsWindow == nil {
            let hostingController = NSHostingController(rootView: ContentView())
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 740, height: 540),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.identifier = Self.windowIdentifier
            window.title = "QuickLauncher Settings"
            window.minSize = NSSize(width: 680, height: 480)
            window.tabbingMode = .disallowed
            window.contentViewController = hostingController
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }

        // Close any unexpected extra windows so only 1 ever exists
        for window in NSApp.windows where window !== settingsWindow && window.identifier == Self.windowIdentifier {
            window.close()
        }

        NSApp.setActivationPolicy(.regular)
        if settingsWindow?.isMiniaturized == true {
            settingsWindow?.deminiaturize(nil)
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct QuickLauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}




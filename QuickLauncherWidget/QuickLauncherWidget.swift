import WidgetKit
import SwiftUI
import AppIntents

struct ShortcutEntry: TimelineEntry {
    let date: Date
    let shortcuts: [ShortcutItem]
}

struct ShortcutProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShortcutEntry {
        ShortcutEntry(date: .now, shortcuts: ShortcutItem.defaults)
    }

    func getSnapshot(in context: Context, completion: @escaping (ShortcutEntry) -> Void) {
        completion(ShortcutEntry(date: .now, shortcuts: ShortcutStore.shared.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShortcutEntry>) -> Void) {
        let entry = ShortcutEntry(date: .now, shortcuts: ShortcutStore.shared.load())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct QuickLauncherWidgetEntryView: View {
    var entry: ShortcutProvider.Entry
    @Environment(\.widgetFamily) private var family

    private var maxItems: Int {
        switch family {
        case .systemSmall: return 4
        case .systemMedium: return 4
        case .systemLarge: return 9
        default: return 5
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Header row with title + Settings gear button
            HStack {
                Text("Shortcuts")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(intent: OpenSettingsIntent()) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 1)

            // Vertical list of full-width shortcut buttons
            ForEach(Array(entry.shortcuts.prefix(maxItems))) { item in
                Button(intent: RunShortcutIntent(shortcutID: item.id.uuidString)) {
                    HStack(spacing: 8) {
                        Image(systemName: item.iconName)
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 16)
                        Text(item.title)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .widgetURL(URL(string: "quicklauncher://noop"))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct QuickLauncherWidget: Widget {
    let kind: String = "QuickLauncherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShortcutProvider()) { entry in
            QuickLauncherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Launcher")
        .description("Vertical list of shortcuts for apps and shell commands.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}


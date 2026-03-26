import SwiftUI
import WidgetKit

struct RepoStatusWidget: Widget {
    let kind = "RepoStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RepoStatusTimelineProvider()) { entry in
            RepoStatusWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Git Repo Status")
        .description("Monitor your Git repositories at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RepoStatusWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: RepoStatusEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallRepoWidgetView(entry: entry)
        case .systemMedium:
            MediumRepoWidgetView(entry: entry)
        default:
            SmallRepoWidgetView(entry: entry)
        }
    }
}

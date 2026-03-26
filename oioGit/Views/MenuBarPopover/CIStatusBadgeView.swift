import SwiftUI

struct CIStatusBadgeView: View {
    let status: CIStatus

    var body: some View {
        if status.state != .none {
            Image(systemName: status.state.sfSymbol)
                .font(.caption2)
                .foregroundStyle(status.state.color)
                .help(tooltipText)
        }
    }

    private var tooltipText: String {
        var parts: [String] = []
        if let name = status.workflowName {
            parts.append(name)
        }
        parts.append(status.state.label)
        if let date = status.lastRunDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            parts.append(formatter.localizedString(for: date, relativeTo: Date()))
        }
        return parts.joined(separator: " — ")
    }
}

#Preview("Success") {
    CIStatusBadgeView(status: CIStatus(
        state: .success,
        workflowName: "CI",
        lastRunDate: Date().addingTimeInterval(-3600)
    ))
    .padding()
}

#Preview("Failure") {
    CIStatusBadgeView(status: CIStatus(
        state: .failure,
        workflowName: "Tests",
        lastRunDate: Date().addingTimeInterval(-120)
    ))
    .padding()
}

#Preview("Running") {
    CIStatusBadgeView(status: CIStatus(state: .running, workflowName: "Deploy"))
        .padding()
}

#Preview("None") {
    CIStatusBadgeView(status: .none)
        .padding()
}

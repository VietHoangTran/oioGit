import SwiftUI

enum CIStatusState: String, Sendable, Codable {
    case success
    case failure
    case pending
    case running
    case none

    var color: Color {
        switch self {
        case .success: return .green
        case .failure: return .red
        case .pending: return .gray
        case .running: return .yellow
        case .none: return .clear
        }
    }

    var sfSymbol: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .failure: return "xmark.circle.fill"
        case .pending: return "clock.fill"
        case .running: return "arrow.triangle.2.circlepath"
        case .none: return "circle.dashed"
        }
    }

    var label: String {
        switch self {
        case .success: return "Success"
        case .failure: return "Failed"
        case .pending: return "Pending"
        case .running: return "Running"
        case .none: return "No CI"
        }
    }
}

struct CIStatus: Sendable {
    var state: CIStatusState
    var workflowName: String?
    var lastRunDate: Date?
    var htmlURL: String?

    static let none = CIStatus(state: .none)
}

import Foundation

enum FileChangeStatus: String, Sendable {
    case modified = "M"
    case added = "A"
    case deleted = "D"
    case renamed = "R"
    case copied = "C"
    case untracked = "?"
    case conflict = "U"

    var label: String {
        switch self {
        case .modified: return "Modified"
        case .added: return "Added"
        case .deleted: return "Deleted"
        case .renamed: return "Renamed"
        case .copied: return "Copied"
        case .untracked: return "Untracked"
        case .conflict: return "Conflict"
        }
    }

    var symbol: String {
        rawValue
    }
}

struct FileChange: Identifiable, Equatable, Sendable {
    var id: String { "\(isStaged ? "s" : "u"):\(path)" }
    let path: String
    let status: FileChangeStatus
    let isStaged: Bool

    var fileName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
}

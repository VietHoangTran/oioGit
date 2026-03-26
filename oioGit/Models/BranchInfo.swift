import Foundation

struct BranchInfo: Identifiable, Equatable, Sendable {
    var id: String { name }
    let name: String
    let isRemote: Bool
    let isCurrent: Bool
}

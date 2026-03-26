import Foundation

struct CommitInfo: Identifiable, Equatable, Sendable {
    let id: String // short hash
    let hash: String
    let message: String
    let author: String
    let date: Date

    var shortHash: String {
        String(hash.prefix(7))
    }
}

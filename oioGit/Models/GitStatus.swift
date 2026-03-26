import Foundation

struct GitStatus: Equatable, Sendable {
    var modifiedCount: Int = 0
    var addedCount: Int = 0
    var deletedCount: Int = 0
    var untrackedCount: Int = 0
    var conflictCount: Int = 0

    var isClean: Bool {
        modifiedCount == 0 && addedCount == 0 && deletedCount == 0
            && untrackedCount == 0 && conflictCount == 0
    }

    var hasConflict: Bool {
        conflictCount > 0
    }

    var totalChanges: Int {
        modifiedCount + addedCount + deletedCount + untrackedCount
    }

    var summary: String {
        if isClean { return "Clean" }
        var parts: [String] = []
        if modifiedCount > 0 { parts.append("\(modifiedCount)M") }
        if addedCount > 0 { parts.append("\(addedCount)A") }
        if deletedCount > 0 { parts.append("\(deletedCount)D") }
        if untrackedCount > 0 { parts.append("\(untrackedCount)?") }
        if conflictCount > 0 { parts.append("\(conflictCount)U") }
        return parts.joined(separator: " ")
    }

    static let empty = GitStatus()
}

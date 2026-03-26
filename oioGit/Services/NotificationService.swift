import UserNotifications

enum NotificationType: String, CaseIterable, Sendable {
    case conflict = "conflict"
    case behindRemote = "behind_remote"
    case staleChanges = "stale_changes"
    case detachedHead = "detached_head"

    var title: String {
        switch self {
        case .conflict: return "Merge Conflict"
        case .behindRemote: return "Behind Remote"
        case .staleChanges: return "Stale Changes"
        case .detachedHead: return "Detached HEAD"
        }
    }

    var description: String {
        switch self {
        case .conflict: return "Merge conflicts detected"
        case .behindRemote: return "Branch is behind remote"
        case .staleChanges: return "Uncommitted changes for 2+ hours"
        case .detachedHead: return "HEAD is detached"
        }
    }
}

final class NotificationService: Sendable {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func send(
        type: NotificationType,
        repoName: String,
        message: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = "\(repoName): \(type.title)"
        content.body = message ?? type.description
        content.sound = .default
        content.categoryIdentifier = "REPO_STATUS"

        let id = "\(repoName).\(type.rawValue)"
        let request = UNNotificationRequest(
            identifier: id, content: content, trigger: nil
        )
        center.add(request)
    }

    func removeNotification(repoName: String, type: NotificationType) {
        let id = "\(repoName).\(type.rawValue)"
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }
}

import Foundation
import SwiftUI

enum ContactSortOrder: String, CaseIterable {
    case name = "Name"
    case lastSeen = "Last Seen"
    case recentlyAdded = "Recently Added"
}

struct ChatItem: Identifiable, Hashable {
    let id: Int64
    let name: String
    let lastMessage: String
    let lastActivity: String
    let ctype: String

    var initials: String {
        name.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }
}

struct ContactItem: Identifiable {
    let id: Int64
    let displayName: String
    let username: String
    let phone: String?
    let avatarColor: Color
    let isOnline: Bool
    let lastSeenAt: String?
    let nickname: String?
    let isFavorite: Bool

    var initials: String {
        displayName.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }

    var resolvedName: String {
        nickname ?? displayName
    }

    var lastSeenFormatted: String {
        if isOnline { return "online" }
        guard let ts = lastSeenAt, let date = ISO8601Lite.parse(ts) else { return "" }
        let fmt = DateFormatter()
        let diff = Date().timeIntervalSince(date)
        if diff < 3600 {
            let mins = Int(diff / 60)
            return "last seen \(mins)m ago"
        } else if diff < 86400 {
            fmt.dateFormat = "HH:mm"
            return "last seen \(fmt.string(from: date))"
        } else {
            fmt.dateFormat = "MM/dd/yy"
            return "last seen \(fmt.string(from: date))"
        }
    }
}

struct Message: Identifiable {
    let id: Int64
    let senderId: Int64
    let currentUserId: Int64
    let senderName: String
    let mtype: String
    let sentAt: String
    let body: String?
    let eventType: String?
    let payload: String?
    let mediaUrl: String?
    let mediaKind: String?
    var reactions: [Reaction] = []

    var isMine: Bool { senderId == currentUserId }

    var displayTime: String {
        guard let date = ISO8601Lite.parse(sentAt) else { return sentAt }
        let fmt = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            fmt.dateFormat = "HH:mm"
        } else {
            fmt.dateFormat = "MMM d"
        }
        return fmt.string(from: date)
    }
}

struct Reaction: Identifiable {
    var id: String { emoji }
    let emoji: String
    let count: Int
}

enum ISO8601Lite {
    static func parse(_ s: String) -> Date? {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return fmt.date(from: s)
    }
}

extension ChatDatabase.ContactRow {
    func makeContactItem() -> ContactItem {
        ContactItem(
            id: userId,
            displayName: displayName,
            username: username,
            phone: phone,
            avatarColor: Color(hex: avatarColor),
            isOnline: isOnline,
            lastSeenAt: lastSeenAt,
            nickname: nickname,
            isFavorite: isFavorite
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double(rgb & 0xFF) / 255
        )
    }
}

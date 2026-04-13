import Foundation

struct ChatItem: Identifiable {
    let id: Int64
    let name: String
    let lastMessage: String
    let lastActivity: String
    let ctype: String

    var initials: String {
        name.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }
}

struct Message: Identifiable {
    let id: Int64
    let senderId: Int64
    let senderName: String
    let mtype: String
    let sentAt: String
    let body: String?
    let eventType: String?
    let payload: String?
    let mediaUrl: String?
    let mediaKind: String?
    var reactions: [Reaction] = []

    var isMine: Bool { senderId == 1 }

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

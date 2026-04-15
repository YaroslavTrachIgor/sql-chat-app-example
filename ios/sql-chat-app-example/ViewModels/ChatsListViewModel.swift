import Foundation
import Observation

/// Drives the Chats tab: loads the signed-in user's chat list from SQLite and applies local search.
@Observable @MainActor
final class ChatsListViewModel {
    private let database: ChatDatabaseServing
    let currentUserId: Int64

    var chats: [ChatItem] = []
    var chatSearchText = ""

    init(database: ChatDatabaseServing = ChatDatabase.shared, currentUserId: Int64 = 1) {
        self.database = database
        self.currentUserId = currentUserId
    }

    var filteredChats: [ChatItem] {
        guard !chatSearchText.isEmpty else { return chats }
        let q = chatSearchText.lowercased()
        return chats.filter { $0.name.lowercased().contains(q) }
    }

    func loadChats() {
        let items = database.fetchChatList(userId: currentUserId)
        chats = items.map { Self.mapListItem($0) }
    }

    private static func mapListItem(_ item: ChatDatabase.ChatListItem) -> ChatItem {
        ChatItem(
            id: item.chatId,
            name: item.name,
            lastMessage: item.lastMessage ?? "No messages yet",
            lastActivity: formatActivity(item.lastActivity),
            ctype: item.ctype
        )
    }

    private static func formatActivity(_ ts: String?) -> String {
        guard let ts, let d = ISO8601Lite.parse(ts) else { return "" }
        let fmt = DateFormatter()
        if Calendar.current.isDateInToday(d) { fmt.dateFormat = "HH:mm" }
        else { fmt.dateFormat = "MMM d" }
        return fmt.string(from: d)
    }
}

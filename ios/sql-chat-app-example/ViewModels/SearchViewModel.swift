import Foundation
import Observation
import SwiftUI

/// Global search tab: SQL-backed chat/contact search plus a lightweight “recent chats” list.
@Observable @MainActor
final class SearchViewModel {
    private let database: ChatDatabaseServing
    let currentUserId: Int64

    var searchQuery = ""
    var chatResults: [ChatItem] = []
    var contactResults: [ContactItem] = []
    var navigateToChatId: Int64?

    init(database: ChatDatabaseServing = ChatDatabase.shared, currentUserId: Int64 = 1) {
        self.database = database
        self.currentUserId = currentUserId
    }

    /// First rows from ``fetchChatList`` for the empty-query state (not persisted as “recents”).
    var recentChatListItems: [ChatDatabase.ChatListItem] {
        Array(database.fetchChatList(userId: currentUserId).prefix(5))
    }

    func performSearch() {
        guard !searchQuery.isEmpty else {
            chatResults = []
            contactResults = []
            return
        }

        let contactRows = database.searchContacts(userId: currentUserId, query: searchQuery)
        contactResults = contactRows.map { $0.makeContactItem() }

        let chatRows = database.searchChats(userId: currentUserId, query: searchQuery)
        chatResults = chatRows.map {
            ChatItem(
                id: $0.chatId,
                name: $0.name,
                lastMessage: $0.lastMessage ?? "No messages yet",
                lastActivity: "",
                ctype: $0.ctype
            )
        }
    }

    func openDirectChat(contactUserId: Int64) -> Int64 {
        database.findOrCreateDirectChat(currentUserId: currentUserId, contactUserId: contactUserId)
    }
}

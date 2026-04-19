import Foundation
@testable import sql_chat_app_example

/// In-memory stand-in for ``ChatDatabase`` used by view model unit tests.
final class MockChatDatabase: ChatDatabaseServing {
    var chatListItems: [ChatDatabase.ChatListItem] = []
    var contactsSorted: [ChatDatabase.ContactRow] = []
    var contactSearchResults: [ChatDatabase.ContactRow] = []
    var chatSearchResults: [ChatDatabase.ChatListItem] = []
    var directChatIdToReturn: Int64 = 99
    var insertUserResult: Int64 = 42
    var messagesByChat: [Int64: [ChatDatabase.MessageRow]] = [:]
    var reactionsByMessage: [Int64: [ChatDatabase.ReactionSummary]] = [:]
    var chatTitles: [Int64: String] = [:]
    var participantCounts: [Int64: Int] = [:]
    var sentMessages: [(chatId: Int64, senderId: Int64, body: String)] = []

    func fetchChatList(userId: Int64) -> [ChatDatabase.ChatListItem] {
        _ = userId
        return chatListItems
    }

    func fetchContacts(userId: Int64) -> [ChatDatabase.ContactRow] {
        _ = userId
        return contactsSorted
    }

    func fetchContactsSorted(userId: Int64, sortOrder: ContactSortOrder) -> [ChatDatabase.ContactRow] {
        _ = userId
        _ = sortOrder
        return contactsSorted
    }

    func searchContacts(userId: Int64, query: String) -> [ChatDatabase.ContactRow] {
        _ = userId
        _ = query
        return contactSearchResults
    }

    func searchChats(userId: Int64, query: String) -> [ChatDatabase.ChatListItem] {
        _ = userId
        _ = query
        return chatSearchResults
    }

    func findOrCreateDirectChat(currentUserId: Int64, contactUserId: Int64) -> Int64 {
        _ = currentUserId
        _ = contactUserId
        return directChatIdToReturn
    }

    func insertUserAndContact(currentUserId: Int64, username: String, displayName: String, phone: String?) -> Int64 {
        _ = currentUserId
        _ = username
        _ = displayName
        _ = phone
        return insertUserResult
    }

    func fetchMessages(chatId: Int64) -> [ChatDatabase.MessageRow] {
        messagesByChat[chatId] ?? []
    }

    func fetchReactions(messageId: Int64) -> [ChatDatabase.ReactionSummary] {
        reactionsByMessage[messageId] ?? []
    }

    func sendTextMessage(chatId: Int64, senderId: Int64, body: String) {
        sentMessages.append((chatId, senderId, body))
    }

    func chatName(chatId: Int64, currentUserId: Int64) -> String {
        _ = currentUserId
        chatTitles[chatId] ?? "Chat"
    }

    func participantCount(chatId: Int64) -> Int {
        participantCounts[chatId] ?? 0
    }
}

import Foundation

/// Abstraction over ``ChatDatabase`` so view models can be tested with mocks or
/// in-memory instances without touching the app singleton or the documents database.
protocol ChatDatabaseServing: AnyObject {
    func fetchChatList(userId: Int64) -> [ChatDatabase.ChatListItem]
    func fetchContacts(userId: Int64) -> [ChatDatabase.ContactRow]
    func fetchContactsSorted(userId: Int64, sortOrder: ContactSortOrder) -> [ChatDatabase.ContactRow]
    func searchContacts(userId: Int64, query: String) -> [ChatDatabase.ContactRow]
    func searchChats(userId: Int64, query: String) -> [ChatDatabase.ChatListItem]
    func findOrCreateDirectChat(currentUserId: Int64, contactUserId: Int64) -> Int64
    func insertUserAndContact(currentUserId: Int64, username: String, displayName: String, phone: String?) -> Int64
    func fetchMessages(chatId: Int64) -> [ChatDatabase.MessageRow]
    func fetchReactions(messageId: Int64) -> [ChatDatabase.ReactionSummary]
    func sendTextMessage(chatId: Int64, senderId: Int64, body: String)
    func chatName(chatId: Int64, currentUserId: Int64) -> String
    func participantCount(chatId: Int64) -> Int
}

extension ChatDatabase: ChatDatabaseServing {}

import Testing
@testable import sql_chat_app_example

@MainActor
struct ChatDatabaseTests {

    @Test func inMemory_seed_loadsUsersAndChats() throws {
        let db = ChatDatabase.makeForTesting()
        let list = db.fetchChatList(userId: 1)
        #expect(!list.isEmpty)
        let names = Set(list.map(\.name))
        #expect(names.contains("Bob Smith") || names.contains("Project Alpha"))
    }

    @Test func fetchMessages_returnsSeededRowsForChat1() throws {
        let db = ChatDatabase.makeForTesting()
        let msgs = db.fetchMessages(chatId: 1)
        #expect(!msgs.isEmpty)
        let textBodies = msgs.compactMap(\.body)
        #expect(textBodies.contains { $0.contains("Bob") || $0.contains("design") })
    }

    @Test func sendTextMessage_appendsToChat() throws {
        let db = ChatDatabase.makeForTesting()
        let before = db.fetchMessages(chatId: 1).count
        db.sendTextMessage(chatId: 1, senderId: 1, body: "Unit test ping")
        let after = db.fetchMessages(chatId: 1).count
        #expect(after == before + 1)
        let last = db.fetchMessages(chatId: 1).last
        #expect(last?.body == "Unit test ping")
    }

    @Test func findOrCreateDirectChat_returnsStableId() throws {
        let db = ChatDatabase.makeForTesting()
        let a = db.findOrCreateDirectChat(currentUserId: 1, contactUserId: 2)
        let b = db.findOrCreateDirectChat(currentUserId: 1, contactUserId: 2)
        #expect(a == b)
        #expect(a > 0)
    }

    @Test func fetchContactsSorted_returnsRowsForOwner() throws {
        let db = ChatDatabase.makeForTesting()
        let rows = db.fetchContactsSorted(userId: 1, sortOrder: .name)
        #expect(!rows.isEmpty)
        #expect(rows.contains { $0.username == "bob" || $0.displayName.contains("Bob") })
    }

    @Test func searchContacts_findsByDisplayName() throws {
        let db = ChatDatabase.makeForTesting()
        let hits = db.searchContacts(userId: 1, query: "Bob")
        #expect(!hits.isEmpty)
    }
}

import Testing
@testable import sql_chat_app_example

@MainActor
struct ChatsListViewModelTests {

    @Test func loadChats_mapsRowsFromDatabase() {
        let mock = MockChatDatabase()
        mock.chatListItems = [
            ChatDatabase.ChatListItem(
                chatId: 7,
                name: "Alpha",
                lastMessage: "Hi",
                lastActivity: "2026-04-15 12:00:00",
                ctype: "group"
            )
        ]
        let vm = ChatsListViewModel(database: mock, currentUserId: 1)
        vm.loadChats()
        #expect(vm.chats.count == 1)
        #expect(vm.chats[0].id == 7)
        #expect(vm.chats[0].name == "Alpha")
        #expect(vm.chats[0].lastMessage == "Hi")
    }

    @Test func filteredChats_appliesSearchCaseInsensitive() {
        let mock = MockChatDatabase()
        mock.chatListItems = [
            .init(chatId: 1, name: "Team", lastMessage: "x", lastActivity: nil, ctype: "group"),
            .init(chatId: 2, name: "Direct DM", lastMessage: "y", lastActivity: nil, ctype: "direct")
        ]
        let vm = ChatsListViewModel(database: mock, currentUserId: 1)
        vm.loadChats()
        vm.chatSearchText = "direct"
        #expect(vm.filteredChats.count == 1)
        #expect(vm.filteredChats[0].name == "Direct DM")
    }
}

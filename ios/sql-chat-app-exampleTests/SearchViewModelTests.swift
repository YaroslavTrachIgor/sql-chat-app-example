import Testing
@testable import sql_chat_app_example

@MainActor
struct SearchViewModelTests {

    @Test func performSearch_clearsWhenQueryEmpty() {
        let mock = MockChatDatabase()
        mock.contactSearchResults = [.init(userId: 1, displayName: "X", username: "x", phone: nil, avatarColor: "#fff", isOnline: false, lastSeenAt: nil, nickname: nil, isFavorite: false)]
        let vm = SearchViewModel(database: mock, currentUserId: 1)
        vm.searchQuery = "a"
        vm.performSearch()
        #expect(!vm.contactResults.isEmpty)
        vm.searchQuery = ""
        vm.performSearch()
        #expect(vm.contactResults.isEmpty)
        #expect(vm.chatResults.isEmpty)
    }

    @Test func performSearch_populatesBothSections() {
        let mock = MockChatDatabase()
        mock.contactSearchResults = [
            .init(userId: 5, displayName: "Pat", username: "pat", phone: nil, avatarColor: "#eee", isOnline: true, lastSeenAt: nil, nickname: nil, isFavorite: false)
        ]
        mock.chatSearchResults = [
            .init(chatId: 9, name: "Pat chat", lastMessage: "m", lastActivity: nil, ctype: "direct")
        ]
        let vm = SearchViewModel(database: mock, currentUserId: 1)
        vm.searchQuery = "Pat"
        vm.performSearch()
        #expect(vm.contactResults.count == 1)
        #expect(vm.chatResults.count == 1)
        #expect(vm.chatResults[0].id == 9)
    }

    @Test func recentChatListItems_respectsPrefix() {
        let mock = MockChatDatabase()
        mock.chatListItems = (1 ... 7).map {
            ChatDatabase.ChatListItem(chatId: Int64($0), name: "C\($0)", lastMessage: nil, lastActivity: nil, ctype: "direct")
        }
        let vm = SearchViewModel(database: mock, currentUserId: 1)
        #expect(vm.recentChatListItems.count == 5)
        #expect(vm.recentChatListItems.first?.chatId == 1)
    }
}

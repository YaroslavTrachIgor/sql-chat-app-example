import Testing
@testable import sql_chat_app_example

@MainActor
struct ContactsViewModelTests {

    @Test func loadContacts_sortsAccordingToDatabaseOrder() {
        let mock = MockChatDatabase()
        mock.contactsSorted = [
            .init(
                userId: 2,
                displayName: "Zed",
                username: "zed",
                phone: nil,
                avatarColor: "#111111",
                isOnline: true,
                lastSeenAt: nil,
                nickname: nil,
                isFavorite: false
            )
        ]
        let vm = ContactsViewModel(database: mock, currentUserId: 1)
        vm.sortOrder = .name
        vm.loadContacts()
        #expect(vm.contacts.count == 1)
        #expect(vm.contacts[0].displayName == "Zed")
    }

    @Test func filteredContacts_matchesDisplayName() {
        let mock = MockChatDatabase()
        mock.contactsSorted = [
            .init(userId: 1, displayName: "Alice", username: "a", phone: nil, avatarColor: "#fff", isOnline: false, lastSeenAt: nil, nickname: nil, isFavorite: false),
            .init(userId: 2, displayName: "Bob", username: "b", phone: nil, avatarColor: "#000", isOnline: false, lastSeenAt: nil, nickname: nil, isFavorite: false)
        ]
        let vm = ContactsViewModel(database: mock, currentUserId: 1)
        vm.loadContacts()
        vm.contactSearchText = "bob"
        #expect(vm.filteredContacts.count == 1)
        #expect(vm.filteredContacts[0].username == "b")
    }

    @Test func openDirectChat_delegatesToDatabase() {
        let mock = MockChatDatabase()
        mock.directChatIdToReturn = 55
        let vm = ContactsViewModel(database: mock, currentUserId: 1)
        let id = vm.openDirectChat(contactUserId: 2)
        #expect(id == 55)
    }
}

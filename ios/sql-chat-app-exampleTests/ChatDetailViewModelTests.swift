import Testing
@testable import sql_chat_app_example

@MainActor
struct ChatDetailViewModelTests {

    @Test func load_buildsMessagesWithReactions() {
        let mock = MockChatDatabase()
        mock.chatTitles[1] = "Room"
        mock.participantCounts[1] = 2
        mock.messagesByChat[1] = [
            .init(
                messageId: 10,
                senderId: 2,
                senderName: "Bob",
                mtype: "text",
                sentAt: "2026-04-15 10:00:00",
                body: "Hey",
                eventType: nil,
                payload: nil,
                mediaUrl: nil,
                mediaKind: nil
            )
        ]
        mock.reactionsByMessage[10] = [.init(emoji: "👍", count: 1)]
        let vm = ChatDetailViewModel(chatId: 1, currentUserId: 1, database: mock)
        vm.load()
        #expect(vm.chatName == "Room")
        #expect(vm.memberCount == 2)
        #expect(vm.messages.count == 1)
        #expect(vm.messages[0].body == "Hey")
        #expect(vm.messages[0].isMine == false)
        #expect(vm.messages[0].reactions.first?.emoji == "👍")
    }

    @Test func sendDraft_callsDatabaseAndCallback() {
        let mock = MockChatDatabase()
        mock.chatTitles[3] = "C"
        mock.participantCounts[3] = 2
        mock.messagesByChat[3] = []
        var callbackCount = 0
        let vm = ChatDetailViewModel(chatId: 3, currentUserId: 1, database: mock) {
            callbackCount += 1
        }
        vm.draft = "  hello  "
        vm.sendDraft()
        #expect(mock.sentMessages.count == 1)
        #expect(mock.sentMessages[0].body == "hello")
        #expect(mock.sentMessages[0].chatId == 3)
        #expect(callbackCount == 1)
        #expect(vm.draft.isEmpty)
    }

    @Test func apply_updatesChatIdAndReloads() {
        let mock = MockChatDatabase()
        mock.chatTitles[1] = "One"
        mock.chatTitles[2] = "Two"
        mock.participantCounts[1] = 2
        mock.participantCounts[2] = 3
        mock.messagesByChat[1] = []
        mock.messagesByChat[2] = []
        let vm = ChatDetailViewModel(chatId: 1, currentUserId: 1, database: mock)
        vm.load()
        #expect(vm.chatName == "One")
        vm.apply(chatId: 2)
        #expect(vm.chatId == 2)
        #expect(vm.chatName == "Two")
    }
}

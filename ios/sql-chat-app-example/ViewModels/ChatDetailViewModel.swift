import Foundation
import Observation

/// Drives a single chat screen: header metadata, message transcript, compose field, and send.
@Observable @MainActor
final class ChatDetailViewModel {
    private let database: ChatDatabaseServing
    private let onSend: () -> Void

    var chatId: Int64
    let currentUserId: Int64

    var messages: [Message] = []
    var chatName: String = ""
    var memberCount: Int = 0
    var draft: String = ""

    init(
        chatId: Int64,
        currentUserId: Int64,
        database: ChatDatabaseServing = ChatDatabase.shared,
        onSend: @escaping () -> Void = {}
    ) {
        self.chatId = chatId
        self.currentUserId = currentUserId
        self.database = database
        self.onSend = onSend
    }

    func apply(chatId: Int64) {
        self.chatId = chatId
        load()
    }

    func load() {
        chatName = database.chatName(chatId: chatId, currentUserId: currentUserId)
        memberCount = database.participantCount(chatId: chatId)
        let rows = database.fetchMessages(chatId: chatId)
        messages = rows.map { r in
            var msg = Message(
                id: r.messageId,
                senderId: r.senderId,
                currentUserId: currentUserId,
                senderName: r.senderName,
                mtype: r.mtype,
                sentAt: r.sentAt,
                body: r.body,
                eventType: r.eventType,
                payload: r.payload,
                mediaUrl: r.mediaUrl,
                mediaKind: r.mediaKind
            )
            msg.reactions = database.fetchReactions(messageId: r.messageId).map {
                Reaction(emoji: $0.emoji, count: $0.count)
            }
            return msg
        }
    }

    func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        database.sendTextMessage(chatId: chatId, senderId: currentUserId, body: text)
        draft = ""
        load()
        onSend()
    }
}

import SwiftUI

struct ChatDetailView: View {
    let chatId: Int64
    let currentUserId: Int64
    var onSend: () -> Void = {}

    @State private var messages: [Message] = []
    @State private var chatName: String = ""
    @State private var memberCount: Int = 0
    @State private var draft: String = ""

    var body: some View {
        VStack(spacing: 0) {
            messageList
            composeBar
        }
        .navigationTitle(chatName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .onAppear { loadData() }
        .onChange(of: chatId) { loadData() }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 1) {
                Text(chatName)
                    .font(.headline)
                Text(memberCount > 2 ? "\(memberCount) members" : "Direct message")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(messages) { msg in
                        messageView(msg)
                            .id(msg.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: messages.count) {
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    @ViewBuilder
    private func messageView(_ msg: Message) -> some View {
        if msg.mtype == "system" {
            systemBubble(msg)
        } else {
            messageBubble(msg)
        }
    }

    private func systemBubble(_ msg: Message) -> some View {
        let text: String = {
            if let p = msg.payload,
               let data = p.data(using: .utf8),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let name = dict["display_name"] as? String {
                return "\(name) joined"
            }
            return msg.eventType ?? "system event"
        }()
        return Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
    }

    private func messageBubble(_ msg: Message) -> some View {
        let mine = msg.isMine
        return VStack(alignment: mine ? .trailing : .leading, spacing: 2) {
            if !mine {
                Text(msg.senderName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
                    .padding(.leading, 4)
            }

            HStack {
                if mine { Spacer(minLength: 60) }
                VStack(alignment: .trailing, spacing: 4) {
                    if msg.mtype == "media" {
                        HStack(spacing: 4) {
                            Image(systemName: "paperclip")
                            Text(msg.mediaKind ?? "file")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    } else {
                        Text(msg.body ?? "")
                            .font(.body)
                            .foregroundStyle(mine ? .white : .primary)
                    }
                    Text(msg.displayTime)
                        .font(.system(size: 10))
                        .foregroundStyle(mine ? .white.opacity(0.6) : .secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(mine
                    ? Color.blue
                    : Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                if !mine { Spacer(minLength: 60) }
            }

            if !msg.reactions.isEmpty {
                HStack(spacing: 4) {
                    ForEach(msg.reactions) { r in
                        Text("\(r.emoji) \(r.count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
    }

    private var composeBar: some View {
        HStack(spacing: 10) {
            TextField("Message", text: $draft)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(Capsule())
                .onSubmit { send() }

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        ChatDatabase.shared.sendTextMessage(chatId: chatId, senderId: currentUserId, body: text)
        draft = ""
        loadData()
        onSend()
    }

    private func loadData() {
        chatName = ChatDatabase.shared.chatName(chatId: chatId, currentUserId: currentUserId)
        memberCount = ChatDatabase.shared.participantCount(chatId: chatId)
        let rows = ChatDatabase.shared.fetchMessages(chatId: chatId)
        messages = rows.map { r in
            var msg = Message(
                id: r.messageId,
                senderId: r.senderId,
                senderName: r.senderName,
                mtype: r.mtype,
                sentAt: r.sentAt,
                body: r.body,
                eventType: r.eventType,
                payload: r.payload,
                mediaUrl: r.mediaUrl,
                mediaKind: r.mediaKind
            )
            msg.reactions = ChatDatabase.shared.fetchReactions(messageId: r.messageId).map {
                Reaction(emoji: $0.emoji, count: $0.count)
            }
            return msg
        }
    }
}

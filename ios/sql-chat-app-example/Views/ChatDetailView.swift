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

    // MARK: - Header toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 1) {
                Text(chatName)
                    .font(.system(size: 17, weight: .semibold))
                Text(memberCount > 2 ? "\(memberCount) members" : "Direct message")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Messages

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
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
    }

    private func messageBubble(_ msg: Message) -> some View {
        let mine = msg.isMine
        return VStack(alignment: mine ? .trailing : .leading, spacing: 2) {
            if !mine {
                Text(msg.senderName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
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
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    } else {
                        Text(msg.body ?? "")
                            .font(.system(size: 15))
                    }
                    Text(msg.displayTime)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(mine ? 0.5 : 0.35))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(mine
                    ? Color.accentColor
                    : Color(red: 0.15, green: 0.15, blue: 0.27))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                if !mine { Spacer(minLength: 60) }
            }

            if !msg.reactions.isEmpty {
                HStack(spacing: 4) {
                    ForEach(msg.reactions) { r in
                        Text("\(r.emoji) \(r.count)")
                            .font(.system(size: 13))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
    }

    // MARK: - Compose

    private var composeBar: some View {
        HStack(spacing: 12) {
            TextField("Type a message…", text: $draft)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(red: 0.1, green: 0.1, blue: 0.24))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.gray.opacity(0.25), lineWidth: 1))
                .onSubmit { send() }

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.accentColor)
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Actions

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

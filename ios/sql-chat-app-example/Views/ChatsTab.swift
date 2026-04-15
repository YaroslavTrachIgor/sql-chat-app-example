import SwiftUI

struct ChatsTab: View {
    @State private var chats: [ChatItem] = []
    @State private var chatSearchText = ""

    private let currentUserId: Int64 = 1

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredChats) { chat in
                    NavigationLink(value: chat.id) {
                        chatRow(chat)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Chats")
            .searchable(text: $chatSearchText, prompt: "Search chats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .onAppear { loadChats() }
            .navigationDestination(for: Int64.self) { chatId in
                ChatDetailView(chatId: chatId, currentUserId: currentUserId) {
                    loadChats()
                }
            }
        }
    }

    private var filteredChats: [ChatItem] {
        guard !chatSearchText.isEmpty else { return chats }
        let q = chatSearchText.lowercased()
        return chats.filter { $0.name.lowercased().contains(q) }
    }

    private func chatRow(_ chat: ChatItem) -> some View {
        HStack(spacing: 12) {
            avatarCircle(chat.initials, size: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text(chat.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(chat.lastMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Text(chat.lastActivity)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func loadChats() {
        let items = ChatDatabase.shared.fetchChatList(userId: currentUserId)
        chats = items.map {
            ChatItem(
                id: $0.chatId,
                name: $0.name,
                lastMessage: $0.lastMessage ?? "No messages yet",
                lastActivity: formatActivity($0.lastActivity),
                ctype: $0.ctype
            )
        }
    }

    private func formatActivity(_ ts: String?) -> String {
        guard let ts, let d = ISO8601Lite.parse(ts) else { return "" }
        let fmt = DateFormatter()
        if Calendar.current.isDateInToday(d) { fmt.dateFormat = "HH:mm" }
        else { fmt.dateFormat = "MMM d" }
        return fmt.string(from: d)
    }
}

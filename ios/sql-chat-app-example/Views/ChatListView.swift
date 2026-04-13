import SwiftUI

struct ChatListView: View {
    @State private var chats: [ChatItem] = []
    @State private var selectedChatId: Int64?

    private let currentUserId: Int64 = 1

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationTitle("Chats")
        } detail: {
            if let chatId = selectedChatId {
                ChatDetailView(chatId: chatId, currentUserId: currentUserId) {
                    loadChats()
                }
            } else {
                emptyState
            }
        }
        .onAppear { loadChats() }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(chats, selection: $selectedChatId) { chat in
            chatRow(chat)
                .tag(chat.id)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedChatId == chat.id
                              ? Color.accentColor.opacity(0.15)
                              : Color.clear)
                )
        }
        .listStyle(.sidebar)
    }

    private func chatRow(_ chat: ChatItem) -> some View {
        HStack(spacing: 12) {
            avatarCircle(chat.initials, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(chat.name)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
                Text(chat.lastMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(chat.lastActivity)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text("Select a chat to start messaging")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Data

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

// MARK: - Shared avatar helper

func avatarCircle(_ initials: String, size: CGFloat) -> some View {
    ZStack {
        Circle()
            .fill(Color(red: 0.06, green: 0.2, blue: 0.37))
            .frame(width: size, height: size)
        Text(initials)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(Color.accentColor)
    }
}

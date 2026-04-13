import SwiftUI

struct ChatsTab: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool

    @State private var chats: [ChatItem] = []
    @State private var selectedChatId: Int64?
    @State private var chatSearchText = ""

    private let currentUserId: Int64 = 1

    var body: some View {
        NavigationStack {
            List(filteredChats, selection: $selectedChatId) { chat in
                NavigationLink(value: chat.id) {
                    chatRow(chat)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedChatId == chat.id
                              ? Color.accentColor.opacity(0.15)
                              : Color.clear)
                )
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Chats")
            .searchable(text: $chatSearchText, prompt: "Search chats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                    } label: {
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
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                Text(chat.lastMessage)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(chat.lastActivity)
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
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

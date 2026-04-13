import SwiftUI

struct SearchView: View {
    let selectedTab: AppTab

    @State private var searchQuery = ""
    @State private var chatResults: [ChatItem] = []
    @State private var contactResults: [ContactItem] = []
    @State private var navigateToChatId: Int64?

    @Environment(\.isSearching) private var isSearching
    @Environment(\.dismissSearch) private var dismissSearch

    private let currentUserId: Int64 = 1

    var body: some View {
        NavigationStack {
            List {
                if searchQuery.isEmpty {
                    recentSection
                } else {
                    if !contactResults.isEmpty {
                        Section("Contacts") {
                            ForEach(contactResults) { contact in
                                contactResultRow(contact)
                            }
                        }
                    }
                    if !chatResults.isEmpty {
                        Section("Chats") {
                            ForEach(chatResults) { chat in
                                chatResultRow(chat)
                            }
                        }
                    }
                    if contactResults.isEmpty && chatResults.isEmpty {
                        ContentUnavailableView.search(text: searchQuery)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Search")
            .searchable(text: $searchQuery, prompt: searchPrompt)
            .onChange(of: searchQuery) { performSearch() }
            .navigationDestination(item: $navigateToChatId) { chatId in
                ChatDetailView(chatId: chatId, currentUserId: currentUserId)
            }
        }
    }

    private var searchPrompt: String {
        switch selectedTab {
        case .contacts: return "Search contacts"
        case .chats:    return "Search chats and contacts"
        }
    }

    private var recentSection: some View {
        Section("Recent") {
            let recentChats = ChatDatabase.shared.fetchChatList(userId: currentUserId).prefix(5)
            ForEach(Array(recentChats.enumerated()), id: \.offset) { _, item in
                Button {
                    navigateToChatId = item.chatId
                } label: {
                    HStack(spacing: 12) {
                        let initials = item.name.split(separator: " ").prefix(2)
                            .compactMap { $0.first.map(String.init) }.joined()
                        avatarCircle(initials, size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                            if let msg = item.lastMessage {
                                Text(msg)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
    }

    private func contactResultRow(_ contact: ContactItem) -> some View {
        Button {
            let chatId = ChatDatabase.shared.findOrCreateDirectChat(
                currentUserId: currentUserId,
                contactUserId: contact.id
            )
            navigateToChatId = chatId
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(contact.avatarColor)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(contact.initials)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.resolvedName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(contact.lastSeenFormatted)
                        .font(.system(size: 12))
                        .foregroundStyle(contact.isOnline ? .green : .secondary)
                }
            }
        }
    }

    private func chatResultRow(_ chat: ChatItem) -> some View {
        Button {
            navigateToChatId = chat.id
        } label: {
            HStack(spacing: 12) {
                avatarCircle(chat.initials, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(chat.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(chat.lastMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private func performSearch() {
        guard !searchQuery.isEmpty else {
            chatResults = []
            contactResults = []
            return
        }

        let contactRows = ChatDatabase.shared.searchContacts(userId: currentUserId, query: searchQuery)
        contactResults = contactRows.map {
            ContactItem(
                id: $0.userId,
                displayName: $0.displayName,
                username: $0.username,
                phone: $0.phone,
                avatarColor: Color(hex: $0.avatarColor),
                isOnline: $0.isOnline,
                lastSeenAt: $0.lastSeenAt,
                nickname: $0.nickname,
                isFavorite: $0.isFavorite
            )
        }

        let chatRows = ChatDatabase.shared.searchChats(userId: currentUserId, query: searchQuery)
        chatResults = chatRows.map {
            ChatItem(
                id: $0.chatId,
                name: $0.name,
                lastMessage: $0.lastMessage ?? "No messages yet",
                lastActivity: "",
                ctype: $0.ctype
            )
        }
    }
}

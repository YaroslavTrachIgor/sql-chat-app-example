import Observation
import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        @Bindable var vm = viewModel
        NavigationStack {
            List {
                if vm.searchQuery.isEmpty {
                    recentSection
                } else {
                    if !vm.contactResults.isEmpty {
                        Section("Contacts") {
                            ForEach(vm.contactResults) { contact in
                                contactResultRow(contact)
                            }
                        }
                    }
                    if !vm.chatResults.isEmpty {
                        Section("Chats") {
                            ForEach(vm.chatResults) { chat in
                                chatResultRow(chat)
                            }
                        }
                    }
                    if vm.contactResults.isEmpty && vm.chatResults.isEmpty {
                        ContentUnavailableView.search(text: vm.searchQuery)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Search")
            .searchable(text: $vm.searchQuery, prompt: "Search chats and contacts")
            .onChange(of: viewModel.searchQuery) { _, _ in
                viewModel.performSearch()
            }
            .navigationDestination(item: $vm.navigateToChatId) { chatId in
                ChatDetailView(chatId: chatId, currentUserId: viewModel.currentUserId)
            }
        }
    }

    private var recentSection: some View {
        Section("Recent Chats") {
            ForEach(viewModel.recentChatListItems, id: \.chatId) { item in
                Button {
                    viewModel.navigateToChatId = item.chatId
                } label: {
                    HStack(spacing: 12) {
                        let initials = item.name.split(separator: " ").prefix(2)
                            .compactMap { $0.first.map(String.init) }.joined()
                        avatarCircle(initials, size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            if let msg = item.lastMessage {
                                Text(msg)
                                    .font(.subheadline)
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
            let chatId = viewModel.openDirectChat(contactUserId: contact.id)
            viewModel.navigateToChatId = chatId
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
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(contact.lastSeenFormatted)
                        .font(.caption)
                        .foregroundStyle(contact.isOnline ? .green : .secondary)
                }
            }
        }
    }

    private func chatResultRow(_ chat: ChatItem) -> some View {
        Button {
            viewModel.navigateToChatId = chat.id
        } label: {
            HStack(spacing: 12) {
                avatarCircle(chat.initials, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(chat.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(chat.lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

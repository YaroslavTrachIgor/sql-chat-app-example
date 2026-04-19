import Observation
import SwiftUI

struct ChatsTab: View {
    @State private var viewModel = ChatsListViewModel()

    var body: some View {
        @Bindable var vm = viewModel
        NavigationStack {
            List {
                ForEach(vm.filteredChats) { chat in
                    NavigationLink(value: chat.id) {
                        chatRow(chat)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Chats")
            .searchable(text: $vm.chatSearchText, prompt: "Search chats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .onAppear { viewModel.loadChats() }
            .navigationDestination(for: Int64.self) { chatId in
                ChatDetailView(chatId: chatId, currentUserId: viewModel.currentUserId) {
                    viewModel.loadChats()
                }
            }
        }
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
}

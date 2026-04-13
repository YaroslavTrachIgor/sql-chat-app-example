import SwiftUI

struct ContactsTab: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool

    @State private var contacts: [ContactItem] = []
    @State private var navigateToChatId: Int64?
    @State private var contactSearchText = ""

    private let currentUserId: Int64 = 1

    var body: some View {
        NavigationStack {
            List {
                if filteredContacts.isEmpty && !contactSearchText.isEmpty {
                    ContentUnavailableView.search(text: contactSearchText)
                } else {
                    let favorites = filteredContacts.filter(\.isFavorite)
                    let others = filteredContacts.filter { !$0.isFavorite }

                    if !favorites.isEmpty {
                        Section("Favorites") {
                            ForEach(favorites) { contact in
                                contactRow(contact)
                            }
                        }
                    }

                    Section(favorites.isEmpty ? "Contacts" : "All Contacts") {
                        ForEach(others) { contact in
                            contactRow(contact)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Contacts")
            .searchable(text: $contactSearchText, prompt: "Search contacts")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sort") {}
                        .font(.system(size: 15))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear { loadContacts() }
            .navigationDestination(item: $navigateToChatId) { chatId in
                ChatDetailView(chatId: chatId, currentUserId: currentUserId)
            }
        }
    }

    private var filteredContacts: [ContactItem] {
        guard !contactSearchText.isEmpty else { return contacts }
        let q = contactSearchText.lowercased()
        return contacts.filter {
            $0.displayName.lowercased().contains(q) ||
            $0.username.lowercased().contains(q) ||
            ($0.nickname?.lowercased().contains(q) ?? false)
        }
    }

    private func contactRow(_ contact: ContactItem) -> some View {
        Button {
            let chatId = ChatDatabase.shared.findOrCreateDirectChat(
                currentUserId: currentUserId,
                contactUserId: contact.id
            )
            navigateToChatId = chatId
        } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(contact.avatarColor)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(contact.initials)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        )

                    if contact.isOnline {
                        Circle()
                            .fill(.green)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                            .offset(x: 2, y: 2)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.resolvedName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(contact.lastSeenFormatted)
                        .font(.system(size: 13))
                        .foregroundStyle(contact.isOnline ? .green : .secondary)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private func loadContacts() {
        let rows = ChatDatabase.shared.fetchContacts(userId: currentUserId)
        contacts = rows.map {
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
    }
}

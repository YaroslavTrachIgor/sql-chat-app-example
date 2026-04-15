import SwiftUI

enum ContactSortOrder: String, CaseIterable {
    case name         = "Name"
    case lastSeen     = "Last Seen"
    case recentlyAdded = "Recently Added"
}

struct ContactsTab: View {
    @State private var contacts: [ContactItem] = []
    @State private var navigateToChatId: Int64?
    @State private var contactSearchText = ""
    @State private var sortOrder: ContactSortOrder = .name
    @State private var showAddContact = false

    private let currentUserId: Int64 = 1

    var body: some View {
        NavigationStack {
            List {
                if filteredContacts.isEmpty && !contactSearchText.isEmpty {
                    ContentUnavailableView.search(text: contactSearchText)
                } else {
                    let favorites = filteredContacts.filter(\.isFavorite)
                    let others = filteredContacts.filter { !$0.isFavorite }

                    if !favorites.isEmpty && contactSearchText.isEmpty {
                        Section("Favorites") {
                            ForEach(favorites) { contact in
                                contactRow(contact)
                            }
                        }
                    }

                    Section(favorites.isEmpty || !contactSearchText.isEmpty ? "Contacts" : "All Contacts") {
                        ForEach(contactSearchText.isEmpty ? others : filteredContacts) { contact in
                            contactRow(contact)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Contacts")
            .searchable(text: $contactSearchText, prompt: "Search contacts")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(ContactSortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrder = order
                                loadContacts()
                            } label: {
                                HStack {
                                    Text(order.rawValue)
                                    if sortOrder == order {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Text("Sort")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddContact = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear { loadContacts() }
            .navigationDestination(item: $navigateToChatId) { chatId in
                ChatDetailView(chatId: chatId, currentUserId: currentUserId)
            }
            .sheet(isPresented: $showAddContact) {
                AddContactSheet {
                    loadContacts()
                }
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
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(contact.lastSeenFormatted)
                        .font(.subheadline)
                        .foregroundStyle(contact.isOnline ? .green : .secondary)
                }

                Spacer()
            }
            .padding(.vertical, 2)
        }
    }

    private func loadContacts() {
        let rows = ChatDatabase.shared.fetchContactsSorted(
            userId: currentUserId,
            sortOrder: sortOrder
        )
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

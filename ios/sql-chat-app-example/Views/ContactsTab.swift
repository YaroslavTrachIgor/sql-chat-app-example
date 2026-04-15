import Observation
import SwiftUI

struct ContactsTab: View {
    @State private var viewModel = ContactsViewModel()

    var body: some View {
        @Bindable var vm = viewModel
        NavigationStack {
            List {
                if vm.filteredContacts.isEmpty && !vm.contactSearchText.isEmpty {
                    ContentUnavailableView.search(text: vm.contactSearchText)
                } else {
                    let favorites = vm.filteredContacts.filter(\.isFavorite)
                    let others = vm.filteredContacts.filter { !$0.isFavorite }

                    if !favorites.isEmpty && vm.contactSearchText.isEmpty {
                        Section("Favorites") {
                            ForEach(favorites) { contact in
                                contactRow(contact)
                            }
                        }
                    }

                    Section(favorites.isEmpty || !vm.contactSearchText.isEmpty ? "Contacts" : "All Contacts") {
                        ForEach(vm.contactSearchText.isEmpty ? others : vm.filteredContacts) { contact in
                            contactRow(contact)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Contacts")
            .searchable(text: $vm.contactSearchText, prompt: "Search contacts")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(ContactSortOrder.allCases, id: \.self) { order in
                            Button {
                                vm.sortOrder = order
                                viewModel.loadContacts()
                            } label: {
                                HStack {
                                    Text(order.rawValue)
                                    if vm.sortOrder == order {
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
                    Button { vm.showAddContact = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear { viewModel.loadContacts() }
            .navigationDestination(item: $vm.navigateToChatId) { chatId in
                ChatDetailView(chatId: chatId, currentUserId: viewModel.currentUserId)
            }
            .sheet(isPresented: $vm.showAddContact) {
                AddContactSheet {
                    viewModel.loadContacts()
                }
            }
        }
    }

    private func contactRow(_ contact: ContactItem) -> some View {
        Button {
            let chatId = viewModel.openDirectChat(contactUserId: contact.id)
            viewModel.navigateToChatId = chatId
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
}

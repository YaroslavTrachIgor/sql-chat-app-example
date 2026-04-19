import Foundation
import Observation

/// Drives the Contacts tab: sorted contact list, local filtering, and opening direct chats.
@Observable @MainActor
final class ContactsViewModel {
    private let database: ChatDatabaseServing
    let currentUserId: Int64

    var contacts: [ContactItem] = []
    var contactSearchText = ""
    var sortOrder: ContactSortOrder = .name
    var navigateToChatId: Int64?
    var showAddContact = false

    init(database: ChatDatabaseServing = ChatDatabase.shared, currentUserId: Int64 = 1) {
        self.database = database
        self.currentUserId = currentUserId
    }

    var filteredContacts: [ContactItem] {
        guard !contactSearchText.isEmpty else { return contacts }
        let q = contactSearchText.lowercased()
        return contacts.filter {
            $0.displayName.lowercased().contains(q) ||
            $0.username.lowercased().contains(q) ||
            ($0.nickname?.lowercased().contains(q) ?? false)
        }
    }

    func loadContacts() {
        let rows = database.fetchContactsSorted(userId: currentUserId, sortOrder: sortOrder)
        contacts = rows.map { $0.makeContactItem() }
    }

    func openDirectChat(contactUserId: Int64) -> Int64 {
        database.findOrCreateDirectChat(currentUserId: currentUserId, contactUserId: contactUserId)
    }
}

import Foundation
import Observation

/// Form state and validation for adding a contact; persists via ``ChatDatabaseServing``.
@Observable @MainActor
final class AddContactViewModel {
    private let database: ChatDatabaseServing
    let currentUserId: Int64

    var firstName = ""
    var lastName = ""
    var phone = ""
    var showError = false

    init(database: ChatDatabaseServing = ChatDatabase.shared, currentUserId: Int64 = 1) {
        self.database = database
        self.currentUserId = currentUserId
    }

    /// Returns the new `app_user` id on success, `0` on failure.
    @discardableResult
    func saveContact() -> Int64 {
        let first = firstName.trimmingCharacters(in: .whitespaces)
        guard !first.isEmpty else {
            showError = true
            return 0
        }

        let last = lastName.trimmingCharacters(in: .whitespaces)
        let displayName = last.isEmpty ? first : "\(first) \(last)"
        let username = displayName.lowercased().replacingOccurrences(of: " ", with: ".")
        let phoneVal = phone.trimmingCharacters(in: .whitespaces)

        let userId = database.insertUserAndContact(
            currentUserId: currentUserId,
            username: username,
            displayName: displayName,
            phone: phoneVal.isEmpty ? nil : phoneVal
        )
        if userId > 0 { showError = false }
        return userId
    }

    var canSave: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

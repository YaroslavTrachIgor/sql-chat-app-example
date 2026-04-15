import SwiftUI

struct AddContactSheet: View {
    @Environment(\.dismiss) private var dismiss

    var onAdded: () -> Void = {}

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color(.tertiarySystemFill))
                                .frame(width: 80, height: 80)
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                }

                Section {
                    TextField("Phone Number", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }

                if showError {
                    Section {
                        Label("Please enter at least a first name.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { addContact() }
                        .bold()
                        .disabled(firstName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addContact() {
        let first = firstName.trimmingCharacters(in: .whitespaces)
        guard !first.isEmpty else {
            showError = true
            return
        }

        let last = lastName.trimmingCharacters(in: .whitespaces)
        let displayName = last.isEmpty ? first : "\(first) \(last)"
        let username = displayName.lowercased().replacingOccurrences(of: " ", with: ".")
        let phoneVal = phone.trimmingCharacters(in: .whitespaces)

        let userId = ChatDatabase.shared.insertUserAndContact(
            currentUserId: 1,
            username: username,
            displayName: displayName,
            phone: phoneVal.isEmpty ? nil : phoneVal
        )

        if userId > 0 {
            onAdded()
            dismiss()
        }
    }
}

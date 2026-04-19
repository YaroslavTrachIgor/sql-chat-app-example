import Observation
import SwiftUI

struct AddContactSheet: View {
    @Environment(\.dismiss) private var dismiss

    var onAdded: () -> Void = {}

    @State private var viewModel = AddContactViewModel()

    var body: some View {
        @Bindable var vm = viewModel
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
                    TextField("First Name", text: $vm.firstName)
                        .textContentType(.givenName)
                    TextField("Last Name", text: $vm.lastName)
                        .textContentType(.familyName)
                }

                Section {
                    TextField("Phone Number", text: $vm.phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }

                if vm.showError {
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
                        .disabled(!vm.canSave)
                }
            }
        }
    }

    private func addContact() {
        let userId = viewModel.saveContact()
        if userId > 0 {
            onAdded()
            dismiss()
        }
    }
}

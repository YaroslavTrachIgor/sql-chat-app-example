import Testing
@testable import sql_chat_app_example

@MainActor
struct AddContactViewModelTests {

    @Test func saveContact_emptyFirstName_setsError() {
        let mock = MockChatDatabase()
        let vm = AddContactViewModel(database: mock, currentUserId: 1)
        vm.firstName = "   "
        let id = vm.saveContact()
        #expect(id == 0)
        #expect(vm.showError == true)
    }

    @Test func saveContact_success_clearsError() {
        let mock = MockChatDatabase()
        mock.insertUserResult = 100
        let vm = AddContactViewModel(database: mock, currentUserId: 1)
        vm.firstName = "Sam"
        vm.lastName = "Lee"
        vm.phone = "555"
        let id = vm.saveContact()
        #expect(id == 100)
        #expect(vm.showError == false)
    }

    @Test func canSave_requiresNonEmptyFirstName() {
        let mock = MockChatDatabase()
        let vm = AddContactViewModel(database: mock, currentUserId: 1)
        vm.firstName = ""
        #expect(vm.canSave == false)
        vm.firstName = "A"
        #expect(vm.canSave == true)
    }
}

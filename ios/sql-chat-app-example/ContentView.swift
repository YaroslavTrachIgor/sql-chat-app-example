import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Contacts", systemImage: "person.crop.circle.fill") {
                ContactsTab()
            }

            Tab("Chats", systemImage: "bubble.left.and.bubble.right.fill") {
                ChatsTab()
            }

            Tab(role: .search) {
                SearchView()
            }
        }
        .preferredColorScheme(.dark)
        .tint(.blue)
    }
}

#Preview {
    ContentView()
}

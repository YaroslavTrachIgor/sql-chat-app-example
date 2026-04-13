import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .chats
    @State private var searchText = ""
    @State private var isSearching = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Contacts", systemImage: "person.crop.circle.fill", value: .contacts) {
                ContactsTab(
                    searchText: $searchText,
                    isSearching: $isSearching
                )
            }

            Tab("Chats", systemImage: "bubble.left.and.bubble.right.fill", value: .chats) {
                ChatsTab(
                    searchText: $searchText,
                    isSearching: $isSearching
                )
            }

            Tab(role: .search) {
                SearchView(selectedTab: selectedTab)
            }
        }
        .preferredColorScheme(.dark)
        .tint(Color(red: 0.26, green: 0.38, blue: 0.93))
    }
}

enum AppTab: Hashable {
    case contacts
    case chats
}

#Preview {
    ContentView()
}

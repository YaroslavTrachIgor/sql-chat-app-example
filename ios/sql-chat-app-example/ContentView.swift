import SwiftUI

struct ContentView: View {
    var body: some View {
        ChatListView()
            .preferredColorScheme(.dark)
            .tint(Color(red: 0.26, green: 0.38, blue: 0.93))
    }
}

#Preview {
    ContentView()
}

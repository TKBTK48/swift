import SwiftUI

struct ContentView: View {
    private let hostedBaseURL = "https://main.d3mjoduvktf61b.amplifyapp.com"

    var body: some View {
        TabView {
            EmbeddedAuthenticationView(baseURL: hostedBaseURL)
                .tabItem {
                    Label("WKWebView", systemImage: "globe")
                }

            AuthenticationSessionView(baseURL: hostedBaseURL)
                .tabItem {
                    Label("認証セッション", systemImage: "lock.shield")
                }
            
            NativeTodoListView()
                .tabItem {
                    Label("Native Todo", systemImage: "list.bullet.rectangle")
                }
        }
    }
}

#Preview {
    ContentView()
}

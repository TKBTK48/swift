import SwiftUI

struct EmbeddedAuthenticationView: View {
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isAlertPresented = false

    // 認証に使用するURL
    let baseURL: String

    private var webViewURL: URL {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "from", value: "iOS"),
            URLQueryItem(name: "trainee", value: "読売新聞"),
            URLQueryItem(name: "session", value: "07")
        ]
        return components.url!
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Text("WKWebView")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                }
                .background(Color(.systemGray6))

                // WebView（埋め込み表示）
                WebView(url: webViewURL) { title, message in
                    alertTitle = title
                    alertMessage = message
                    isAlertPresented = true
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .alert(alertTitle, isPresented: $isAlertPresented) {
                Button("OK", role: .cancel) {
                    isAlertPresented = false
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

#Preview {
    EmbeddedAuthenticationView(baseURL: "https://example.amplifyapp.com")
}

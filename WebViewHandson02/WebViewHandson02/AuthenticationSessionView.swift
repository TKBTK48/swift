import SwiftUI
import AuthenticationServices

struct AuthenticationSessionView: View {
    @State private var isAuthenticating = false
    @State private var resultMessage = ""

    // presentationContextProviderを保持するための変数
    private let presentationContext = AuthenticationPresentationContext()

    // 認証に使用するURL
    let baseURL: String

    // コールバックURLスキーム(認証完了後にアプリに戻るためのURLスキーム)
    let callbackURLScheme = "myapp"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Text("ASWebAuthenticationSession テスト")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                }
                .background(Color(.systemGray6))

                Button(action: {
                    startAuthentication()
                }) {
                    Text("認証セッションを開始")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isAuthenticating)
                .padding(.vertical, 20)

                if !resultMessage.isEmpty {
                    GeometryReader { geometry in
                        Text(resultMessage)
                            .padding()
                            .frame(width: geometry.size.width * 0.9, height: 100, alignment: .topLeading)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: 100)
                }

                Spacer()
            }
        }
    }

    private func startAuthentication() {
        isAuthenticating = true

        // ASWebAuthenticationSessionの作成
        let session = ASWebAuthenticationSession(
            url: URL(string: baseURL)!,
            callbackURLScheme: callbackURLScheme
        ) { callbackURL, error in
            isAuthenticating = false

            if let error = error {
                // ユーザーがキャンセルした場合
                if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    resultMessage = "認証がキャンセルされました"
                } else {
                    resultMessage = "エラー: \(error.localizedDescription)"
                }
                return
            }

            if let callbackURL = callbackURL {
                resultMessage = "認証成功!\nコールバックURL: \(callbackURL.absoluteString)"
            }
        }

        // プレゼンテーションコンテキストの設定
        // 認証画面を表示する際に、どのウィンドウ(マルチウィンドウ)上に表示するか
        // インスタンスをプロパティとして保持しないと即座に解放される
        session.presentationContextProvider = presentationContext

        // セッションの開始
        session.start()
    }
}

// ASWebAuthenticationPresentationContextProvidingの実装
class AuthenticationPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // iOS 15以降に対応したウィンドウの取得方法
        // connectedScenesから適切なUIWindowSceneを取得し、そのキーウィンドウを返す
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.windows.first { $0.isKeyWindow } ?? windowScene.windows.first!
        }

        // フォールバック: 最初のシーンのウィンドウを返す
        fatalError("No window scene found")
    }
}

#Preview {
    AuthenticationSessionView(baseURL: "https://example.amplifyapp.com")
}

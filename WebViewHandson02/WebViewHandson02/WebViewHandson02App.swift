import SwiftUI
import Amplify
import AWSAPIPlugin
import AWSCognitoAuthPlugin

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        configureAmplify()
        return true
    }

    private func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin())

            // amplifyconfiguration.json を自動検出して読み込む
            try Amplify.configure()

            print("✅ Amplify configured successfully")
        } catch {
            print("❌ Amplify configure failed: \(error)")
        }
    }
}

@main
struct WebViewHandson02App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

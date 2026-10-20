//
//  WebView.swift
//  WebViewHandson02
//
//  Created by 竹内浩子 on 2026/05/29.
//

import SwiftUI
@preconcurrency import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    /// Web → iOS へのメッセージコールバック。引数は (タイトル, 本文)。
    var onMessage: (String, String) -> Void
    func makeCoordinator() -> Coordinator {
        Coordinator(onMessage: onMessage)
    }


    func makeUIView(context: Context) -> WKWebView {
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "trainingBridge")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        // WebView 破棄時にハンドラを解放してメモリリークを防ぐ
        uiView.configuration.userContentController
            .removeScriptMessageHandler(forName: "trainingBridge")
    }

    // MARK: - Coordinator

    /// UIKit/WebKit デリゲートをまとめるクラス。
    /// @MainActor を付けることで、コールバック呼び出しをメインスレッドで保証する。
    @MainActor
    final class Coordinator: NSObject {
        private let onMessage: (String, String) -> Void
        init(onMessage: @escaping (String, String) -> Void) {
        self.onMessage = onMessage
        }
    }
}

// MARK: - WKScriptMessageHandler（Web → iOS 受信）

// WebKit 側の並行処理注釈が未整備なため、import 側で @preconcurrency を付ける
extension WebView.Coordinator: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "trainingBridge" else { return }

        // body が辞書型かつ type が文字列であることを確認する
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String else {
            onMessage("受信エラー", "メッセージ形式が不正です")
            return
        }

        switch type {
        case "OPEN_ALERT":
            let payload = body["payload"] as? [String: Any]
            let title   = payload?["title"]   as? String ?? "Web通知"
            let text    = payload?["message"] as? String ?? "メッセージを受信しました"
            onMessage(title, text)
        default:
            onMessage("未対応メッセージ", "type=\(type) は未対応です")
        }
    }
}

// MARK: - WKNavigationDelegate（読み込みエラー検知）

extension WebView.Coordinator: WKNavigationDelegate {
    /// ページ読み込み中のエラー（例: ネットワーク切断）
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        onMessage("読み込み失敗", error.localizedDescription)
    }
    
    /// 接続開始前のエラー（例: ホスト名解決失敗、URL 不正）
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        onMessage("接続エラー", error.localizedDescription)
    }
}

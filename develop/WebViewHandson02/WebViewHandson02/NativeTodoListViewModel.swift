import Foundation
import Combine
import Amplify

@MainActor
final class NativeTodoListViewModel: ObservableObject {
    @Published var todos: [NativeTodo] = []
    @Published var errorMessage: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var userEmail: String = ""
    @Published var isAwaitingMFA: Bool = false
    @Published var isLoading: Bool = false

    func checkAuthStatus() async {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            self.isAuthenticated = session.isSignedIn

            if session.isSignedIn {
                // ユーザー情報を取得
                let user = try await Amplify.Auth.getCurrentUser()
                self.userEmail = user.username
            } else {
                self.userEmail = ""
            }
        } catch {
            self.isAuthenticated = false
            self.userEmail = ""
            print("❌ Auth status check failed: \(error)")
        }
    }

    func signIn(username: String, password: String) async {
        self.isLoading = true
        self.errorMessage = ""

        do {
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password
            )

            // MFAが必要な場合
            if case .confirmSignInWithTOTPCode = signInResult.nextStep {
                self.isAwaitingMFA = true
                self.isLoading = false
                print("✅ MFA required")
            } else if signInResult.isSignedIn {
                // ログイン完了
                self.isAwaitingMFA = false
                self.isLoading = false
                await checkAuthStatus()
                await loadTodos()
                print("✅ Sign in successful")
            }
        } catch {
            self.errorMessage = "ログインエラー: \(error.localizedDescription)"
            self.isLoading = false
            self.isAwaitingMFA = false
            print("❌ Sign in failed: \(error)")
        }
    }

    func confirmSignIn(totpCode: String) async {
        self.isLoading = true
        self.errorMessage = ""

        do {
            let signInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: totpCode
            )

            if signInResult.isSignedIn {
                self.isAwaitingMFA = false
                self.isLoading = false
                await checkAuthStatus()
                await loadTodos()
                print("✅ MFA confirmation successful")
            }
        } catch {
            self.errorMessage = "MFA認証エラー: \(error.localizedDescription)"
            self.isLoading = false
            print("❌ MFA confirmation failed: \(error)")
        }
    }

    func cancelSignIn() {
        self.isAwaitingMFA = false
        self.errorMessage = ""
    }

    func signOut() async {
        _ = await Amplify.Auth.signOut()
        self.isAuthenticated = false
        self.userEmail = ""
        self.todos = []
        self.errorMessage = ""
        self.isAwaitingMFA = false
        self.isLoading = false
    }

    func loadTodos() async {
        // 認証状態を確認
        await checkAuthStatus()

        guard isAuthenticated else {
            self.errorMessage = ""
            self.todos = []
            return
        }

        // GraphQL クエリを実行
        do {
            let document = """
            query ListTodos {
              listTodos {
                items {
                  id
                  title
                  detail
                  isDone
                  priority
                }
              }
            }
            """

            let request = GraphQLRequest<JSONValue>(
                document: document,
                responseType: JSONValue.self,
                decodePath: nil
            )

            let result = try await Amplify.API.query(request: request)
            switch result {
            case .success(let json):
                let parsed = Self.parseTodos(from: json)
                self.todos = parsed
                self.errorMessage = parsed.isEmpty ? "表示できるTodoがありません" : ""
            case .failure(let apiError):
                self.errorMessage = "API呼び出しエラー: \(apiError.errorDescription)"
                print("❌ API Error: \(apiError)")
            }
        } catch {
            self.errorMessage = "エラー: \(error.localizedDescription)"
            print("❌ Exception: \(error)")
        }
    }

    func createTodo(title: String, detail: String?, isDone: Bool, priority: Int?) async {
        let document = """
        mutation CreateTodo($title: String!, $detail: String, $isDone: Boolean, $priority: Int) {
          createTodo(input: {
            title: $title
            detail: $detail
            isDone: $isDone
            priority: $priority
          }) {
            id
            title
            detail
            isDone
            priority
          }
        }
        """

        let variables = buildVariables(title: title, detail: detail, isDone: isDone, priority: priority)
        await executeMutation(document: document, variables: variables, operationName: "作成")
    }

    func updateTodo(id: String, title: String, detail: String?, isDone: Bool, priority: Int?) async {
        let document = """
        mutation UpdateTodo($id: ID!, $title: String!, $detail: String, $isDone: Boolean, $priority: Int) {
          updateTodo(input: {
            id: $id
            title: $title
            detail: $detail
            isDone: $isDone
            priority: $priority
          }) {
            id
            title
            detail
            isDone
            priority
          }
        }
        """

        let variables = buildVariables(id: id, title: title, detail: detail, isDone: isDone, priority: priority)
        await executeMutation(document: document, variables: variables, operationName: "更新")
    }

    // MARK: - Private Helper Methods

    private func buildVariables(
        id: String? = nil,
        title: String,
        detail: String?,
        isDone: Bool,
        priority: Int?
    ) -> [String: Any] {
        let detailValue = detail?.isEmpty == false ? detail : nil

        var variables: [String: Any] = [
            "title": title,
            "detail": detailValue as Any,
            "isDone": isDone,
            "priority": priority as Any
        ]

        if let id = id {
            variables["id"] = id
        }

        return variables.compactMapValues { $0 }
    }

    private func executeMutation(
        document: String,
        variables: [String: Any],
        operationName: String
    ) async {
        guard isAuthenticated else {
            self.errorMessage = "ログインが必要です"
            return
        }

        self.isLoading = true
        self.errorMessage = ""

        do {
            let request = GraphQLRequest<JSONValue>(
                document: document,
                variables: variables,
                responseType: JSONValue.self
            )

            let result = try await Amplify.API.mutate(request: request)
            switch result {
            case .success:
                await loadTodos()
                print("✅ Todo \(operationName) successfully")
            case .failure(let apiError):
                self.errorMessage = "\(operationName)エラー: \(apiError.errorDescription)"
                print("❌ \(operationName) Error: \(apiError)")
            }
        } catch {
            self.errorMessage = "エラー: \(error.localizedDescription)"
            print("❌ Exception: \(error)")
        }

        self.isLoading = false
    }

    func deleteTodo(id: String) async {
        let document = """
        mutation DeleteTodo($id: ID!) {
          deleteTodo(input: {
            id: $id
          }) {
            id
          }
        }
        """

        let variables: [String: Any] = ["id": id]
        await executeMutation(document: document, variables: variables, operationName: "削除")
    }

    func toggleTodoDone(todo: NativeTodo) async {
        await updateTodo(
            id: todo.id,
            title: todo.title,
            detail: todo.detail,
            isDone: !(todo.isDone ?? false),
            priority: todo.priority
        )
    }

    private static func parseTodos(from json: JSONValue) -> [NativeTodo] {
        guard
            case .object(let root) = json,
            case .object(let listTodos)? = root["listTodos"],
            case .array(let items)? = listTodos["items"]
        else {
            return []
        }

        return items.compactMap { item -> NativeTodo? in
            guard
                case .object(let object) = item,
                case .string(let id)? = object["id"],
                case .string(let title)? = object["title"]
            else {
                return nil
            }

            let detail: String?
            if case .string(let value)? = object["detail"] { detail = value } else { detail = nil }

            let isDone: Bool?
            if case .boolean(let value)? = object["isDone"] { isDone = value } else { isDone = nil }

            let priority: Int?
            if case .number(let value)? = object["priority"] { priority = Int(value) } else { priority = nil }

            return NativeTodo(id: id, title: title, detail: detail, isDone: isDone, priority: priority)
        }
    }
}

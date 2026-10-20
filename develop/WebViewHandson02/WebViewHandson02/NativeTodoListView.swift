import SwiftUI

struct NativeTodoListView: View {
    @StateObject private var viewModel = NativeTodoListViewModel()
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var totpCode: String = ""
    @State private var showingCreateSheet = false
    @State private var editingTodo: NativeTodo?
    @State private var deletingTodo: NativeTodo?
    @State private var isPasswordVisible = false

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.isAuthenticated {
                    // 未ログイン時の表示
                    if viewModel.isAwaitingMFA {
                        // MFAコード入力画面
                        VStack(spacing: 20) {
                            Text("認証アプリのコードを入力してください")
                                .font(.headline)
                                .padding(.top)

                            TextField("TOTPコード", text: $totpCode)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)

                            if !viewModel.errorMessage.isEmpty {
                                Text(viewModel.errorMessage)
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                    .padding(.horizontal)
                            }

                            Button(action: {
                                Task {
                                    await viewModel.confirmSignIn(totpCode: totpCode)
                                    totpCode = ""
                                }
                            }) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text("認証")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding()
                            .background(totpCode.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(totpCode.isEmpty || viewModel.isLoading)
                            .padding(.horizontal)

                            Button("キャンセル") {
                                viewModel.cancelSignIn()
                                totpCode = ""
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding()
                    } else {
                        // ログイン画面
                        VStack(spacing: 20) {
                            Text("Native Todoを表示するにはログインが必要です")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .padding(.top)

                            VStack(spacing: 12) {
                                TextField("メールアドレス", text: $username)
                                    .textContentType(.username)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textFieldStyle(.roundedBorder)

                                HStack {
                                    if isPasswordVisible {
                                        TextField("パスワード", text: $password)
                                            .textContentType(.password)
                                            .autocapitalization(.none)
                                    } else {
                                        SecureField("パスワード", text: $password)
                                            .textContentType(.password)
                                    }

                                    Button(action: {
                                        isPasswordVisible.toggle()
                                    }) {
                                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundStyle(.gray)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal)

                            if !viewModel.errorMessage.isEmpty {
                                Text(viewModel.errorMessage)
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                    .padding(.horizontal)
                            }

                            Button(action: {
                                Task {
                                    await viewModel.signIn(username: username, password: password)
                                }
                            }) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Label("ログイン", systemImage: "person.circle")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding()
                            .background(username.isEmpty || password.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(username.isEmpty || password.isEmpty || viewModel.isLoading)
                            .padding(.horizontal)

                            Text("※ MFA必須のため、ログイン後にTOTPコードの入力が必要です")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }
                        .padding()
                    }
                } else {
                    // ログイン済み時の表示
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundStyle(.red)
                            .padding()
                    } else if viewModel.todos.isEmpty {
                        VStack(spacing: 16) {
                            Text("表示できるTodoがありません")
                                .foregroundStyle(.secondary)
                            Text("WKWebViewタブでTodoを作成してください")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        List {
                            ForEach(viewModel.todos) { todo in
                                HStack {
                                    // チェックボックス
                                    Button(action: {
                                        Task {
                                            await viewModel.toggleTodoDone(todo: todo)
                                        }
                                    }) {
                                        Image(systemName: todo.isDone == true ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(todo.isDone == true ? .green : .gray)
                                            .font(.title3)
                                    }
                                    .buttonStyle(.plain)

                                    // タイトルと詳細
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(todo.title)
                                            .font(.headline)
                                            .strikethrough(todo.isDone == true)
                                        if let detail = todo.detail, !detail.isEmpty {
                                            Text(detail)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    // 編集・削除ボタン
                                    HStack(spacing: 16) {
                                        Button(action: {
                                            editingTodo = todo
                                        }) {
                                            Image(systemName: "pencil.circle.fill")
                                                .foregroundStyle(.blue)
                                                .font(.title2)
                                        }
                                        .buttonStyle(.plain)

                                        Button(action: {
                                            deletingTodo = todo
                                        }) {
                                            Image(systemName: "trash.circle.fill")
                                                .foregroundStyle(.red)
                                                .font(.title2)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deletingTodo = todo
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Native Todo")
            .toolbar {
                if viewModel.isAuthenticated {
                    ToolbarItem(placement: .navigationBarLeading) {
                        // 作成ボタン
                        Button(action: {
                            showingCreateSheet = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.blue))
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            // 再読込ボタン
                            Button(action: {
                                Task { await viewModel.loadTodos() }
                            }) {
                                Label("再読込", systemImage: "arrow.clockwise")
                            }

                            // サインアウトボタン
                            Button(role: .destructive, action: {
                                Task { await viewModel.signOut() }
                            }) {
                                Label("サインアウト", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("再読込") {
                            Task { await viewModel.checkAuthStatus() }
                        }
                    }
                }
            }
            .task {
                await viewModel.loadTodos()
            }
            .sheet(isPresented: $showingCreateSheet) {
                TodoFormView(viewModel: viewModel, todo: nil)
            }
            .sheet(item: $editingTodo) { todo in
                TodoFormView(viewModel: viewModel, todo: todo)
            }
            .alert(item: $deletingTodo) { todo in
                Alert(
                    title: Text("削除の確認"),
                    message: Text("\"\(todo.title)\"を削除しますか？\nこの操作は取り消せません。"),
                    primaryButton: .destructive(Text("削除")) {
                        Task {
                            await viewModel.deleteTodo(id: todo.id)
                        }
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
        }
    }
}

#Preview {
    NativeTodoListView()
}

//
//  TodoFormView.swift
//  WebViewHandson02
//
//  Created by 竹内浩子 on 2026/07/14.
//

import SwiftUI

struct TodoFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: NativeTodoListViewModel
    var todo: NativeTodo?

    @State private var title: String
    @State private var detail: String
    @State private var isDone: Bool
    @State private var priority: String

    init(viewModel: NativeTodoListViewModel, todo: NativeTodo? = nil) {
        self.viewModel = viewModel
        self.todo = todo

        _title = State(initialValue: todo?.title ?? "")
        _detail = State(initialValue: todo?.detail ?? "")
        _isDone = State(initialValue: todo?.isDone ?? false)
        _priority = State(initialValue: todo?.priority != nil ? "\(todo!.priority!)" : "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("タイトル", text: $title)
                    TextField("詳細", text: $detail, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("ステータス") {
                    Toggle("完了", isOn: $isDone)
                }

                Section("優先度") {
                    TextField("優先度（数値）", text: $priority)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(todo == nil ? "Todo作成" : "Todo編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(todo == nil ? "作成" : "保存") {
                        Task {
                            let priorityValue = Int(priority)
                            if let existingTodo = todo {
                                await viewModel.updateTodo(
                                    id: existingTodo.id,
                                    title: title,
                                    detail: detail.isEmpty ? nil : detail,
                                    isDone: isDone,
                                    priority: priorityValue
                                )
                            } else {
                                await viewModel.createTodo(
                                    title: title,
                                    detail: detail.isEmpty ? nil : detail,
                                    isDone: isDone,
                                    priority: priorityValue
                                )
                            }
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    TodoFormView(
        viewModel: NativeTodoListViewModel(),
        todo: NativeTodo(
            id: "preview-id",
            title: "サンプルTodo",
            detail: "これはプレビュー用のサンプルです",
            isDone: false,
            priority: 1
        )
    )
}

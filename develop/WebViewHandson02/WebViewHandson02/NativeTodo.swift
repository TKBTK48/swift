//
//  NativeTodo.swift
//  WebViewHandson02
//
//  Created by 竹内浩子 on 2026/07/14.
//

import Foundation

struct NativeTodo: Identifiable, Decodable {
    let id: String
    let title: String
    let detail: String?
    let isDone: Bool?
    let priority: Int?
}

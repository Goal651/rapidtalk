//
//  WSManager.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/15/25.
//
//

import Foundation
import SwiftUI

final class WebSocketManager: ObservableObject {
    private var task: URLSessionWebSocketTask?
    @Published var messages: [String] = []
    @Published var isConnected = false

    func connect() {
        let url = URL(string: "ws://10.12.75.116:8080/ws")!
        task = URLSession.shared.webSocketTask(with: url)
        task?.resume()
        isConnected = true
        listen()
    }

    private func listen() {
        task?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    DispatchQueue.main.async {
                        self?.messages.append(text)
                    }
                }
                self?.listen()
            case .failure(let error):
                print("WS error:", error)
            }
        }
    }

    func send(_ text: String) {
        task?.send(.string(text)) { error in
            if let error = error {
                print("Send error:", error)
            }
        }
    }

    func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }
}

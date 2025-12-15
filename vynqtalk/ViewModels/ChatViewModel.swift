//
//  ChatViewModel.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/15/25.
//

import Foundation
import SwiftUI
import Combine


class ChatViewModel: ObservableObject {
    @Published var messages: [String] = []          // Messages for the UI
    private var webSocketTask: URLSessionWebSocketTask?
    
    func connect() {
        // Replace with your WebSocket URL
        let url = URL(string: "wss://example.com/chat")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        listen()   // Start listening
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    func send(_ text: String) {
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }
    
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self?.messages.append(text)
                    }
                case .data(let data):
                    print("Received binary data: \(data)")
                @unknown default:
                    break
                }
            case .failure(let error):
                print("WebSocket receive error: \(error)")
            }
            // Keep listening
            self?.listen()
        }
    }
}

//
//  APIClient.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/15/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - API Response Wrapper
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let message: String
}

// MARK: - API Client
final class APIClient: ObservableObject {
    
    static let shared = APIClient()
    
    private let baseURL = "http://10.12.73.3:8080/api/v2"
    private var logoutListeners: [() -> Void] = []
    
    private init() {}
    
    // MARK: - AppStorage (localStorage-like)
    @AppStorage("auth_token") private var authToken: String = ""
    @AppStorage("refresh_token") private var refreshToken: String = ""
    @AppStorage("loggedIn") var loggedIn: Bool = false
    
    func getAuthToken() -> String? {
        authToken.isEmpty ? nil : authToken
    }
    
    func saveAuthToken(_ token: String) {
        authToken = token
    }
    
    func saveRefreshToken(_ token: String) {
        refreshToken = token
    }
    
    func logout() {
        authToken = ""
        refreshToken = ""
        loggedIn = false
        logoutListeners.forEach { $0() }
    }
    
    func addLogoutListener(_ callback: @escaping () -> Void) {
        logoutListeners.append(callback)
    }
    
    func removeLogoutListener(_ callback: @escaping () -> Void) {
        logoutListeners.removeAll { $0 as AnyObject === callback as AnyObject }
    }
    
    // MARK: - HTTP Requests
    private func makeRequest<T: Decodable>(
        _ endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
    
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            logout()
            throw URLError(.userAuthenticationRequired)
        }
        
        if httpResponse.statusCode >= 500 {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(T.self, from: data)
        return decoded
    }
    
    // MARK: - Public CRUD Methods
    func get<T: Decodable>(_ endpoint: String) async throws -> APIResponse<T> {
        try await makeRequest(endpoint)
    }
    
    func post<T: Decodable>(_ endpoint: String, data: Encodable) async throws -> APIResponse<T> {
        let body = try JSONEncoder().encode(data)
        return try await makeRequest(endpoint, method: "POST", body: body)
    }
    
    func put<T: Decodable>(_ endpoint: String, data: Encodable) async throws -> APIResponse<T> {
        let body = try JSONEncoder().encode(data)
        return try await makeRequest(endpoint, method: "PUT", body: body)
    }
    
    func patch<T: Decodable>(_ endpoint: String, data: Encodable) async throws -> APIResponse<T> {
        let body = try JSONEncoder().encode(data)
        return try await makeRequest(endpoint, method: "PATCH", body: body)
    }
    
    func delete<T: Decodable>(_ endpoint: String) async throws -> APIResponse<T> {
        try await makeRequest(endpoint, method: "DELETE")
    }
    
    // MARK: - File Upload
    func uploadFile<T: Decodable>(_ endpoint: String, fileURL: URL) async throws -> APIResponse<T> {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let filename = fileURL.lastPathComponent
        let data = try Data(contentsOf: fileURL)
        let mimeType = mimeTypeForPath(path: filename)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            logout()
            throw URLError(.userAuthenticationRequired)
        }
        
        let decoded = try JSONDecoder().decode(APIResponse<T>.self, from: responseData)
        return decoded
    }
    
    private func mimeTypeForPath(path: String) -> String {
        if path.hasSuffix(".png") { return "image/png" }
        if path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") { return "image/jpeg" }
        if path.hasSuffix(".gif") { return "image/gif" }
        return "application/octet-stream"
    }
}

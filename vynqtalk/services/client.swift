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
    
    // Environment configuration
    #if DEBUG
    static var environment: APIEnvironment = .development
    #else
    static var environment: APIEnvironment = .production
    #endif
    
    private var baseURL: String {
        Self.environment.baseURL
    }
    
    private var logoutListeners: [() -> Void] = []

    static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()

            // 1) ISO-8601 string dates (common for Java Instant)
            if let str = try? container.decode(String.self) {
                let f1 = ISO8601DateFormatter()
                f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let f2 = ISO8601DateFormatter()
                f2.formatOptions = [.withInternetDateTime]

                if let date = f1.date(from: str) ?? f2.date(from: str) {
                    return date
                }

                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid date string: \(str)"
                )
            }

            // 2) Numeric epoch dates (seconds or milliseconds)
            if let num = try? container.decode(Double.self) {
                let seconds: TimeInterval = num > 100_000_000_000 ? (num / 1000.0) : num
                return Date(timeIntervalSince1970: seconds)
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported date value"
            )
        }
        return decoder
    }()

    static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(f.string(from: date))
        }
        return encoder
    }()
    
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
            throw APIError.invalidResponse
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
        
        // Log request
        logRequest(request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Log response
            logResponse(data, response)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
        
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                logout()
                throw APIError.authenticationRequired
            }
            
            if httpResponse.statusCode >= 500 {
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }
            
            if httpResponse.statusCode >= 400 {
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }
            
            let decoded = try Self.jsonDecoder.decode(T.self, from: data)
            return decoded
            
        } catch let error as APIError {
            #if DEBUG
            print("  API Error: \(error.localizedDescription ?? "Unknown error")")
            #endif
            throw error
        } catch let error as URLError {
            #if DEBUG
            print("  URL Error: \(error.localizedDescription)")
            #endif
            throw handleURLError(error)
        } catch let error as DecodingError {
            #if DEBUG
            print("  Decoding Error: \(error)")
            #endif
            throw APIError.decodingError(error)
        } catch {
            #if DEBUG
            print("  Unknown Error: \(error.localizedDescription)")
            #endif
            throw APIError.unknown(error)
        }
    }
    
    // MARK: - Logging
    private func logRequest(_ request: URLRequest) {
        #if DEBUG
        print("📤 \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        if let headers = request.allHTTPHeaderFields {
            print("📤 Headers: \(headers)")
        }
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            let sanitized = sanitizeLog(bodyString)
            print("📤 Body: \(sanitized)")
        }
        #endif
    }
    
    private func logResponse(_ data: Data, _ response: URLResponse?) {
        #if DEBUG
        if let httpResponse = response as? HTTPURLResponse {
            print("📥 Status: \(httpResponse.statusCode)")
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response: \(responseString)")
        }
        #endif
    }
    
    private func sanitizeLog(_ string: String) -> String {
        var sanitized = string
        // Remove password values
        sanitized = sanitized.replacingOccurrences(
            of: #""password"\s*:\s*"[^"]*""#,
            with: #""password":"***""#,
            options: .regularExpression
        )
        // Remove token values
        sanitized = sanitized.replacingOccurrences(
            of: #""token"\s*:\s*"[^"]*""#,
            with: #""token":"***""#,
            options: .regularExpression
        )
        sanitized = sanitized.replacingOccurrences(
            of: #""accessToken"\s*:\s*"[^"]*""#,
            with: #""accessToken":"***""#,
            options: .regularExpression
        )
        return sanitized
    }
    
    // MARK: - Error Handling
    private func handleURLError(_ error: URLError) -> APIError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .timedOut:
            return .timeout
        case .userAuthenticationRequired:
            return .authenticationRequired
        default:
            return .networkError
        }
    }
    
    // MARK: - Public CRUD Methods
    func get<T: Decodable>(_ endpoint: String) async throws -> APIResponse<T> {
        try await makeRequest(endpoint)
    }
    
    // Direct request method for endpoints that return data without APIResponse wrapper
    func makeDirectRequest<T: Decodable>(_ endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
        try await makeRequest(endpoint, method: method, body: body)
    }
    
    func post<T: Decodable>(_ endpoint: String, data: Encodable) async throws -> APIResponse<T> {
        let body = try Self.jsonEncoder.encode(AnyEncodable(data))
        return try await makeRequest(endpoint, method: "POST", body: body)
    }
    
    func put<T: Decodable>(_ endpoint: String, data: Encodable) async throws -> APIResponse<T> {
        let body = try Self.jsonEncoder.encode(AnyEncodable(data))
        return try await makeRequest(endpoint, method: "PUT", body: body)
    }
    
    func patch<T: Decodable>(_ endpoint: String, data: Encodable) async throws -> APIResponse<T> {
        let body = try Self.jsonEncoder.encode(AnyEncodable(data))
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
        
        let decoded = try Self.jsonDecoder.decode(APIResponse<T>.self, from: responseData)
        return decoded
    }
    
    private func mimeTypeForPath(path: String) -> String {
        if path.hasSuffix(".png") { return "image/png" }
        if path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") { return "image/jpeg" }
        if path.hasSuffix(".gif") { return "image/gif" }
        return "application/octet-stream"
    }
}

// MARK: - Encode any Encodable (type-erasure)
private struct AnyEncodable: Encodable {
    private let encodeImpl: (Encoder) throws -> Void

    init(_ value: Encodable) {
        self.encodeImpl = value.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encodeImpl(encoder)
    }
}


// MARK: - Avatar Upload
extension APIClient {
    func uploadAvatar(imageData: Data, filename: String) async throws -> APIResponse<User> {
        guard let url = URL(string: "\(baseURL)/users/avatar") else {
            throw APIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        #if DEBUG
        print("📤 POST /users/avatar")
        print("📤 Image size: \(imageData.count) bytes")
        #endif
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        #if DEBUG
        if let responseString = String(data: responseData, encoding: .utf8) {
            print("📥 Response: \(responseString)")
        }
        #endif
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            logout()
            throw APIError.authenticationRequired
        }
        
        if httpResponse.statusCode >= 400 {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoded = try Self.jsonDecoder.decode(APIResponse<User>.self, from: responseData)
        return decoded
    }
}


// MARK: - Message File Upload
extension APIClient {
    func uploadMessageAttachment(fileData: Data, filename: String, mimeType: String) async throws -> APIResponse<String> {
        guard let url = URL(string: "\(baseURL)/messages/upload") else {
            throw APIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        #if DEBUG
        print("📤 POST /messages/upload")
        print("📤 File: \(filename) (\(fileData.count) bytes)")
        #endif
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        #if DEBUG
        if let responseString = String(data: responseData, encoding: .utf8) {
            print("📥 Response: \(responseString)")
        }
        #endif
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            logout()
            throw APIError.authenticationRequired
        }
        
        if httpResponse.statusCode >= 400 {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoded = try Self.jsonDecoder.decode(APIResponse<String>.self, from: responseData)
        return decoded
    }
}

# Design Document: API Integration Fixes

## Overview

This design addresses critical API integration issues between the VynqTalk iOS app and the Vapor backend server. The primary issues are incorrect endpoint paths and hardcoded configuration values that prevent proper communication with the backend.

## Architecture

### Current Architecture
```
iOS App (Swift)
    ↓
APIClient (singleton)
    ↓
URLSession
    ↓
Backend Server (Vapor)
```

### Component Responsibilities

**APIClient:**
- Manages HTTP requests/responses
- Handles authentication tokens
- Provides CRUD methods (GET, POST, PUT, PATCH, DELETE)
- Manages error handling and retries

**ViewModels:**
- AuthViewModel: Handles login/signup
- UserViewModel: Manages user list
- MessageViewModel: Manages conversations
- ProfileViewModel: Manages user profile

**Models:**
- User, Message, Reaction
- Auth request/response models
- Enums: MessageType, UserRole

## Components and Interfaces

### 1. Environment Configuration

**Purpose:** Support multiple environments (development, staging, production)

**Implementation:**
```swift
enum APIEnvironment {
    case development
    case staging
    case production
    case custom(String)
    
    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:8080"
        case .staging:
            return "https://staging-api.vynqtalk.com"
        case .production:
            return "https://api.vynqtalk.com"
        case .custom(let url):
            return url
        }
    }
    
    var wsURL: String {
        switch self {
        case .development:
            return "ws://localhost:8080"
        case .staging:
            return "wss://staging-api.vynqtalk.com"
        case .production:
            return "wss://api.vynqtalk.com"
        case .custom(let url):
            return url.replacingOccurrences(of: "http", with: "ws")
        }
    }
}
```

**Configuration:**
```swift
// In APIClient
#if DEBUG
static var environment: APIEnvironment = .development
#else
static var environment: APIEnvironment = .production
#endif

private var baseURL: String {
    Self.environment.baseURL
}
```

### 2. Enhanced APIClient with Logging

**Debug Logging:**
```swift
private func logRequest(_ request: URLRequest) {
    #if DEBUG
    print("📤 \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
    if let headers = request.allHTTPHeaderFields {
        print("📤 Headers: \(headers)")
    }
    if let body = request.httpBody,
       let bodyString = String(data: body, encoding: .utf8) {
        // Sanitize sensitive data
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
    return sanitized
}
```

### 3. Endpoint Constants

**Purpose:** Centralize endpoint definitions to prevent typos

**Implementation:**
```swift
enum APIEndpoint {
    // Auth
    case login
    case signup
    case currentUser
    
    // Users
    case users
    case userSearch(query: String)
    case userById(id: Int)
    case updateUserStatus(id: Int)
    
    // Messages
    case conversation(user1: Int, user2: Int)
    case sendMessage
    
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .signup:
            return "/auth/signup"
        case .currentUser:
            return "/user"
        case .users:
            return "/users"
        case .userSearch(let query):
            return "/users/search?query=\(query)"
        case .userById(let id):
            return "/users/\(id)"
        case .updateUserStatus(let id):
            return "/users/\(id)/status"
        case .conversation(let user1, let user2):
            return "/messages/conversation/\(user1)/\(user2)"
        case .sendMessage:
            return "/messages"
        }
    }
}
```

### 4. Enhanced Error Handling

**Error Types:**
```swift
enum APIError: LocalizedError {
    case networkError
    case serverError(statusCode: Int)
    case authenticationRequired
    case invalidResponse
    case decodingError(Error)
    case timeout
    case noConnection
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network error. Please check your connection."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .authenticationRequired:
            return "Your session has expired. Please log in again."
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingError:
            return "Failed to process server response."
        case .timeout:
            return "Request timed out. Please try again."
        case .noConnection:
            return "No internet connection."
        }
    }
}
```

**Error Handling in APIClient:**
```swift
private func handleError(_ error: Error) -> APIError {
    if let urlError = error as? URLError {
        switch urlError.code {
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
    
    if let decodingError = error as? DecodingError {
        return .decodingError(decodingError)
    }
    
    return .networkError
}
```

### 5. Updated MessageViewModel

**Fix conversation endpoint:**
```swift
@MainActor
func loadConversation(meId: Int, otherUserId: Int) async {
    guard meId > 0, otherUserId > 0 else {
        errorMessage = "Invalid user ids"
        messages = []
        return
    }

    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
        // ✅ Fixed endpoint path
        let endpoint = APIEndpoint.conversation(user1: meId, user2: otherUserId)
        let response: APIResponse<[Message]> =
            try await APIClient.shared.get(endpoint.path)
            
        guard response.success, let data = response.data else {
            errorMessage = response.message
            messages = []
            return
        }
        messages = data
    } catch {
        if let apiError = error as? APIError {
            errorMessage = apiError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        messages = []
    }
}
```

### 6. Message Sending with REST Fallback

**Implementation:**
```swift
struct SendMessageRequest: Encodable {
    let receiverId: Int
    let content: String
    let type: MessageType
}

// In MessageViewModel
@MainActor
func sendMessage(receiverId: Int, content: String, type: MessageType = .text) async -> Bool {
    do {
        let payload = SendMessageRequest(
            receiverId: receiverId,
            content: content,
            type: type
        )
        
        let response: APIResponse<Message> =
            try await APIClient.shared.post(APIEndpoint.sendMessage.path, data: payload)
            
        guard response.success, let message = response.data else {
            errorMessage = response.message
            return false
        }
        
        // Add to local list
        append(message)
        return true
        
    } catch {
        if let apiError = error as? APIError {
            errorMessage = apiError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        return false
    }
}
```

### 7. WebSocket Manager Enhancement

**Connection with Token:**
```swift
class WebSocketManager: ObservableObject {
    private var webSocket: URLSessionWebSocketTask?
    private let baseURL = APIClient.environment.wsURL
    
    func connect() {
        guard let token = APIClient.shared.getAuthToken() else {
            print("❌ No auth token available")
            return
        }
        
        guard let url = URL(string: "\(baseURL)/ws?token=\(token)") else {
            print("❌ Invalid WebSocket URL")
            return
        }
        
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        receiveMessage()
        
        #if DEBUG
        print("🔌 WebSocket connecting to: \(url)")
        #endif
    }
    
    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        
        #if DEBUG
        print("🔌 WebSocket disconnected")
        #endif
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage() // Continue listening
                
            case .failure(let error):
                print("❌ WebSocket error: \(error)")
                // Attempt reconnection
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self?.connect()
                }
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            #if DEBUG
            print("📨 WebSocket received: \(text)")
            #endif
            
            guard let data = text.data(using: .utf8) else { return }
            
            do {
                let response = try JSONDecoder().decode(WebSocketResponse.self, from: data)
                handleWebSocketResponse(response)
            } catch {
                print("❌ Failed to decode WebSocket message: \(error)")
            }
            
        case .data(let data):
            #if DEBUG
            print("📨 WebSocket received binary data")
            #endif
            
        @unknown default:
            break
        }
    }
    
    func sendChatMessage(receiverId: Int, content: String, type: MessageType = .text) {
        let message = WebSocketMessage(
            type: "chat_message",
            receiverId: receiverId,
            content: content,
            messageType: type
        )
        
        guard let data = try? JSONEncoder().encode(message),
              let string = String(data: data, encoding: .utf8) else {
            return
        }
        
        webSocket?.send(.string(string)) { error in
            if let error = error {
                print("❌ Failed to send message: \(error)")
            } else {
                #if DEBUG
                print("📤 WebSocket sent: \(string)")
                #endif
            }
        }
    }
}

struct WebSocketMessage: Encodable {
    let type: String
    let receiverId: Int
    let content: String
    let messageType: MessageType
    
    enum CodingKeys: String, CodingKey {
        case type
        case receiverId
        case content
        case messageType = "type"
    }
}

struct WebSocketResponse: Decodable {
    let success: Bool
    let data: WebSocketData?
    let message: String
}

enum WebSocketData: Decodable {
    case message(Message)
    case userStatus(UserStatus)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let message = try? container.decode(Message.self) {
            self = .message(message)
        } else if let status = try? container.decode(UserStatus.self) {
            self = .userStatus(status)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown WebSocket data type"
            )
        }
    }
}

struct UserStatus: Decodable {
    let userId: Int
    let online: Bool
    let lastActive: Date?
}
```

## Data Models

### No Changes Required

The existing models are correct:
- `User` with optional fields
- `Message` with reactions
- `MessageType` enum (TEXT, IMAGE, AUDIO, VIDEO, FILE)
- `UserRole` enum (USER, ADMIN)
- `LoginRequest`, `SignupRequest`, `LoginResponse`

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Environment URL Consistency
*For any* environment configuration, the base URL and WebSocket URL should use matching protocols (http/ws or https/wss)
**Validates: Requirements 1.1, 1.2**

### Property 2: Endpoint Path Correctness
*For any* API endpoint, the path should match the backend API documentation exactly
**Validates: Requirements 2.1, 3.1**

### Property 3: Authentication Token Inclusion
*For any* protected API request, the Authorization header should include a valid Bearer token
**Validates: Requirements 5.4**

### Property 4: Response Structure Validation
*For any* API response, it should contain success, data, and message fields matching the APIResponse structure
**Validates: Requirements 4.1, 4.2**

### Property 5: Error Message User-Friendliness
*For any* error condition, the displayed message should be user-friendly and not expose technical details
**Validates: Requirements 7.1, 7.2, 7.3, 7.4**

### Property 6: Sensitive Data Sanitization
*For any* debug log output, sensitive fields (password, token) should be masked or removed
**Validates: Requirements 8.5**

### Property 7: WebSocket Token Authentication
*For any* WebSocket connection, the URL should include the auth token as a query parameter
**Validates: Requirements 9.1, 9.2**

### Property 8: Message Type Encoding
*For any* message being sent, the type field should be encoded as an uppercase string (TEXT, IMAGE, etc.)
**Validates: Requirements 11.1, 11.2**

### Property 9: Auto-Logout on Auth Failure
*For any* 401 or 403 response, the system should automatically log out the user and clear stored credentials
**Validates: Requirements 5.5**

### Property 10: Request Retry on Network Error
*For any* transient network error (timeout, connection lost), the system should not immediately fail but should provide retry capability
**Validates: Requirements 7.1, 7.3**

## Error Handling

### Network Errors
- **No Connection:** Show "No internet connection" message
- **Timeout:** Show "Request timed out" with retry option
- **Connection Lost:** Attempt automatic retry

### Server Errors
- **401/403:** Auto-logout and redirect to login
- **404:** Show "Resource not found"
- **500:** Show "Server error, please try again"
- **Other:** Show generic error with status code

### Data Errors
- **Decoding Error:** Log details, show "Invalid response"
- **Missing Data:** Handle gracefully with empty states
- **Invalid Format:** Show "Unexpected data format"

### WebSocket Errors
- **Connection Failed:** Attempt reconnection after 5 seconds
- **Auth Failed:** Disconnect and show login prompt
- **Message Send Failed:** Fall back to REST API

## Testing Strategy

### Unit Tests
- Test environment URL generation
- Test endpoint path construction
- Test error handling for each error type
- Test log sanitization
- Test WebSocket message encoding/decoding

### Integration Tests
- Test login flow end-to-end
- Test user list loading
- Test conversation loading
- Test message sending via REST
- Test WebSocket connection and messaging

### Property-Based Tests
- **Property 1:** Generate random environments, verify URL format
- **Property 2:** Generate random endpoint parameters, verify path format
- **Property 3:** Generate random requests, verify token inclusion
- **Property 4:** Generate random responses, verify structure parsing
- **Property 5:** Generate random errors, verify user-friendly messages
- **Property 6:** Generate random log strings, verify sanitization
- **Property 7:** Generate random tokens, verify WebSocket URL format
- **Property 8:** Generate random message types, verify encoding
- **Property 9:** Generate 401/403 responses, verify auto-logout
- **Property 10:** Generate network errors, verify retry behavior

### Manual Testing
- Test with actual backend server
- Test on different networks (WiFi, cellular, no connection)
- Test with invalid credentials
- Test with expired tokens
- Test WebSocket reconnection
- Test message sending and receiving

## Implementation Notes

### Phase 1: Critical Fixes
1. Add APIEnvironment enum
2. Update APIClient to use environment
3. Fix message conversation endpoint
4. Add request/response logging

### Phase 2: Error Handling
5. Add APIError enum
6. Update error handling in APIClient
7. Update ViewModels to use APIError
8. Add user-friendly error messages

### Phase 3: WebSocket
9. Update WebSocket connection with token
10. Add message sending via WebSocket
11. Add reconnection logic
12. Add REST fallback

### Phase 4: Testing
13. Write unit tests
14. Write integration tests
15. Write property-based tests
16. Manual testing with backend

## Dependencies

- Foundation (URLSession, JSONEncoder/Decoder)
- SwiftUI (@AppStorage, @Published)
- Combine (for reactive updates)

## Performance Considerations

- **Request Timeout:** 30 seconds default
- **WebSocket Reconnection:** 5 second delay
- **Log Output:** Only in DEBUG builds
- **Token Storage:** Secure @AppStorage
- **Memory:** Avoid retaining large response data

## Security Considerations

- **Token Storage:** Use @AppStorage (UserDefaults) for now, consider Keychain for production
- **HTTPS:** Use HTTPS in staging/production
- **WSS:** Use WSS (secure WebSocket) in staging/production
- **Log Sanitization:** Never log passwords or tokens
- **Token Expiration:** Handle 401/403 gracefully
- **Input Validation:** Validate user IDs before API calls

## Future Enhancements

- Add request caching
- Add offline mode support
- Add request queue for failed requests
- Add analytics tracking
- Add performance monitoring
- Add A/B testing support
- Add feature flags

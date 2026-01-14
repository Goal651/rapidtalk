# API Integration Analysis - VynqTalk

## Overview
This document analyzes the current API integration between the VynqTalk iOS app and the backend server, identifying discrepancies and issues.

---

## Current Implementation vs Backend API

### 1. Base URL Configuration ⚠️

**Current Implementation:**
```swift
private let baseURL = "http://10.12.75.116:8080"
```

**Backend Documentation:**
```
Base URL: http://localhost:8080
```

**Issue:** Hardcoded IP address instead of localhost. This will fail when:
- Running on different networks
- Backend server IP changes
- Testing on simulator vs device

**Recommendation:** Use environment-based configuration or make it configurable.

---

### 2. Message Conversation Endpoint ❌

**Current Implementation:**
```swift
// MessageViewModel.swift
let response: APIResponse<[Message]> =
    try await APIClient.shared.get("/messages/all/\(meId)/\(otherUserId)")
```

**Backend Documentation:**
```
GET /messages/conversation/:user1ID/:user2ID
```

**Issue:** Wrong endpoint path. Using `/messages/all/` instead of `/messages/conversation/`.

**Impact:** 
- Conversation loading will fail with 404
- Users cannot view message history

**Fix Required:**
```swift
let response: APIResponse<[Message]> =
    try await APIClient.shared.get("/messages/conversation/\(meId)/\(otherUserId)")
```

---

### 3. User List Endpoint ⚠️

**Current Implementation:**
```swift
// UserViewModel.swift
let response: APIResponse<[User]> = try await APIClient.shared.get("/users")
```

**Backend Documentation:**
```
GET /users/search?query=searchTerm
GET /users/:userID
```

**Issue:** The `/users` endpoint may not exist. Backend only documents:
- Search endpoint: `/users/search?query=`
- Single user: `/users/:userID`

**Recommendation:** 
- Verify if `/users` endpoint exists for listing all users
- If not, use `/users/search?query=` with empty query
- Or implement pagination

---

### 4. User ID Type Mismatch ⚠️

**Current Implementation:**
```swift
// User.swift
let id: Int?

// AuthViewModel.swift
@AppStorage("user_id") var userId: Int = 0
```

**Backend Documentation:**
```
Uses UUID for user IDs in examples
```

**Potential Issue:** If backend uses UUID (String), the Int type will fail.

**Verification Needed:** Check actual backend implementation to confirm ID type.

**If UUID is used, fix required:**
```swift
let id: String?  // Change from Int to String
@AppStorage("user_id") var userId: String = ""
```

---

### 5. Authentication Response Handling ✅

**Current Implementation:**
```swift
struct LoginResponse: Decodable {
    let user: User
    let accessToken: String
}
```

**Backend Documentation:**
```json
{
  "success": true,
  "data": {
    "user": { ... },
    "accessToken": "..."
  },
  "message": "..."
}
```

**Status:** ✅ Correct! The `APIResponse<LoginResponse>` wrapper handles this properly.

---

### 6. Message Type Enum ✅

**Current Implementation:**
```swift
enum MessageType: String, Codable {
    case text = "TEXT"
    case image = "IMAGE"
    case audio = "AUDIO"
    case video = "VIDEO"
    case file = "FILE"
}
```

**Backend Documentation:**
```
Message Type: TEXT, IMAGE, AUDIO, VIDEO, FILE
```

**Status:** ✅ Correct! Matches backend exactly.

---

### 7. User Role Enum ✅

**Current Implementation:**
```swift
enum UserRole: String, Codable {
    case user = "USER"
    case admin = "ADMIN"
}
```

**Backend Documentation:**
```
User Role: USER, ADMIN
```

**Status:** ✅ Correct! Matches backend exactly.

---

### 8. Error Handling ⚠️

**Current Implementation:**
```swift
if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
    logout()
    throw URLError(.userAuthenticationRequired)
}

if httpResponse.statusCode >= 500 {
    throw URLError(.badServerResponse)
}
```

**Status:** ✅ Good! Handles auth errors and server errors.

**Enhancement Needed:** Add more specific error messages for users:
- Network errors
- Timeout errors
- Invalid response format

---

### 9. WebSocket Implementation ❌

**Current Status:** Not fully implemented in the files reviewed.

**Backend Documentation:**
```
WebSocket URL: ws://localhost:8080/ws?token=<auth_token>

Events:
- chat_message (send)
- chat_message (receive)
- user_status (receive)
```

**Required Implementation:**
1. Connect with token in URL query parameter
2. Send messages with type "chat_message"
3. Handle incoming messages
4. Handle user status updates

---

### 10. Request/Response Logging ⚠️

**Current Implementation:**
```swift
// No logging visible in APIClient
```

**Recommendation:** Add debug logging for:
- Request URL, method, headers
- Request body (sanitized)
- Response status, headers
- Response body
- Errors

**Example:**
```swift
#if DEBUG
print("📤 \(method) \(url)")
print("📤 Headers: \(request.allHTTPHeaderFields ?? [:])")
if let body = body, let str = String(data: body, encoding: .utf8) {
    print("📤 Body: \(str)")
}
#endif
```

---

## Critical Issues Summary

### 🔴 Critical (Must Fix):
1. **Message Endpoint:** `/messages/all/` → `/messages/conversation/`
2. **Base URL:** Hardcoded IP → Configurable URL

### 🟡 Important (Should Fix):
3. **User List Endpoint:** Verify `/users` exists or use `/users/search`
4. **User ID Type:** Verify Int vs UUID/String
5. **Error Messages:** Add user-friendly error messages
6. **Request Logging:** Add debug logging

### 🟢 Enhancement (Nice to Have):
7. **WebSocket:** Complete implementation
8. **Message Sending:** Add REST fallback
9. **User Status:** Implement status updates

---

## Testing Checklist

### Authentication:
- [ ] Signup with valid credentials
- [ ] Login with valid credentials
- [ ] Login with invalid credentials (should show error)
- [ ] Token stored correctly
- [ ] Token included in subsequent requests
- [ ] Auto-logout on 401/403

### Users:
- [ ] Load user list successfully
- [ ] Search users by name
- [ ] Handle empty user list
- [ ] Show online indicators

### Messages:
- [ ] Load conversation history
- [ ] Display messages correctly
- [ ] Handle empty conversations
- [ ] Show message timestamps
- [ ] Display reactions

### Error Handling:
- [ ] Network error shows user-friendly message
- [ ] Server error shows user-friendly message
- [ ] Auth error logs user out
- [ ] Invalid data handled gracefully

---

## Recommended Fix Priority

### Phase 1: Critical Fixes (Do First)
1. Fix message conversation endpoint
2. Make base URL configurable
3. Add request/response logging

### Phase 2: Verification (Do Second)
4. Verify user list endpoint
5. Verify user ID type (Int vs String)
6. Test all endpoints with backend

### Phase 3: Enhancements (Do Third)
7. Improve error messages
8. Complete WebSocket implementation
9. Add REST message sending fallback

---

## Configuration Recommendations

### Environment-Based URLs:
```swift
enum Environment {
    case development
    case staging
    case production
    
    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:8080"
        case .staging:
            return "https://staging.vynqtalk.com"
        case .production:
            return "https://api.vynqtalk.com"
        }
    }
}

// In APIClient:
private let baseURL = Environment.development.baseURL
```

### Or use Build Configuration:
```swift
#if DEBUG
private let baseURL = "http://localhost:8080"
#else
private let baseURL = "https://api.vynqtalk.com"
#endif
```

---

## Next Steps

1. **Review this analysis** with the team
2. **Verify backend endpoints** by testing with Postman/curl
3. **Create spec** for API integration fixes
4. **Implement fixes** in priority order
5. **Test thoroughly** with actual backend
6. **Document** any additional findings

---

## Questions for Backend Team

1. Does `/users` endpoint exist for listing all users?
2. Are user IDs Int or UUID/String?
3. Is there pagination for user lists?
4. What's the expected behavior for empty conversations?
5. Are there rate limits on API endpoints?
6. What's the WebSocket reconnection strategy?
7. Is there a health check endpoint?

---

## Conclusion

The current implementation is mostly correct but has **2 critical issues**:
1. Wrong message endpoint path
2. Hardcoded IP address

These must be fixed before the app can work with the backend. The other issues are important but not blocking.

Once these fixes are applied and tested, the app should be able to:
- ✅ Authenticate users
- ✅ Load user lists
- ✅ Load conversations
- ✅ Display messages
- ✅ Handle errors gracefully

# VynqTalk Backend Requirements - Vapor Server

## 📋 Overview

This document outlines all backend requirements for the VynqTalk iOS app. The backend should be built using **Vapor 4** (Swift server-side framework).

**Base URL:** `http://YOUR_SERVER:8080`  
**WebSocket URL:** `ws://YOUR_SERVER:8080/ws`

---

## 🗄️ Database Models

### 1. User Model
```swift
final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password")
    var password: String  // Hashed with Bcrypt
    
    @OptionalField(key: "avatar")
    var avatar: String?  // URL to avatar image
    
    @Enum(key: "user_role")
    var userRole: UserRole
    
    @OptionalField(key: "status")
    var status: String?  // Custom status message
    
    @OptionalField(key: "bio")
    var bio: String?
    
    @Timestamp(key: "last_active", on: .none)
    var lastActive: Date?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Field(key: "online")
    var online: Bool
    
    init() { }
}

enum UserRole: String, Codable {
    case user = "USER"
    case admin = "ADMIN"
}
```

### 2. Message Model
```swift
final class Message: Model, Content {
    static let schema = "messages"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "content")
    var content: String
    
    @Enum(key: "type")
    var type: MessageType
    
    @Parent(key: "sender_id")
    var sender: User
    
    @Parent(key: "receiver_id")
    var receiver: User
    
    @Timestamp(key: "timestamp", on: .create)
    var timestamp: Date?
    
    @OptionalField(key: "file_name")
    var fileName: String?
    
    @Field(key: "edited")
    var edited: Bool
    
    @Children(for: \.$message)
    var reactions: [Reaction]
    
    @OptionalParent(key: "reply_to_id")
    var replyTo: Message?
    
    init() { }
}

enum MessageType: String, Codable {
    case text = "TEXT"
    case image = "IMAGE"
    case audio = "AUDIO"
    case video = "VIDEO"
    case file = "FILE"
}
```

### 3. Reaction Model
```swift
final class Reaction: Model, Content {
    static let schema = "reactions"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "emoji")
    var emoji: String
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "message_id")
    var message: Message
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
}
```

---

## 🔐 Authentication Endpoints

### 1. POST `/auth/signup`
**Description:** Register a new user

**Request Body:**
```json
{
  "email": "user@example.com",
  "name": "John Doe",
  "password": "securePassword123"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "user@example.com",
      "avatar": null,
      "userRole": "USER",
      "status": null,
      "bio": null,
      "lastActive": "2026-01-14T10:30:00Z",
      "createdAt": "2026-01-14T10:30:00Z",
      "online": true
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "User registered successfully"
}
```

**Error Response (400 Bad Request):**
```json
{
  "success": false,
  "data": null,
  "message": "Email already exists"
}
```

**Requirements:**
- Hash password with Bcrypt (minimum cost: 12)
- Validate email format
- Check for duplicate email
- Generate JWT token (expires in 7 days)
- Set user as online
- Set lastActive to current time

---

### 2. POST `/auth/login`
**Description:** Login existing user

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "user@example.com",
      "avatar": "https://example.com/avatar.jpg",
      "userRole": "USER",
      "status": "Available",
      "bio": "Hello, I'm using VynqTalk!",
      "lastActive": "2026-01-14T10:30:00Z",
      "createdAt": "2026-01-13T08:00:00Z",
      "online": true
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "Login successful"
}
```

**Error Response (401 Unauthorized):**
```json
{
  "success": false,
  "data": null,
  "message": "Invalid email or password"
}
```

**Requirements:**
- Verify password with Bcrypt
- Generate JWT token (expires in 7 days)
- Update user online status to true
- Update lastActive timestamp

---

## 👤 User Endpoints

### 3. GET `/users`
**Description:** Get all users (for chat list)

**Headers:**
```
Authorization: Bearer {accessToken}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": 2,
      "name": "Jane Smith",
      "email": "jane@example.com",
      "avatar": "https://example.com/jane.jpg",
      "userRole": "USER",
      "status": "Busy",
      "bio": "Software Developer",
      "lastActive": "2026-01-14T09:45:00Z",
      "createdAt": "2026-01-10T12:00:00Z",
      "online": true,
      "latestMessage": {
        "id": 42,
        "content": "See you tomorrow!",
        "timestamp": "2026-01-14T09:45:00Z"
      },
      "unreadMessages": []
    },
    {
      "id": 3,
      "name": "Bob Johnson",
      "email": "bob@example.com",
      "avatar": null,
      "userRole": "USER",
      "status": null,
      "bio": null,
      "lastActive": "2026-01-13T18:30:00Z",
      "createdAt": "2026-01-12T14:20:00Z",
      "online": false,
      "latestMessage": null,
      "unreadMessages": []
    }
  ],
  "message": "Users retrieved successfully"
}
```

**Requirements:**
- Exclude current user from list
- Include latest message for each user (if exists)
- Include unread message count
- Sort by latest message timestamp (most recent first)
- Include online status

---

### 4. GET `/user`
**Description:** Get current user profile

**Headers:**
```
Authorization: Bearer {accessToken}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "user@example.com",
    "avatar": "https://example.com/avatar.jpg",
    "userRole": "USER",
    "status": "Available",
    "bio": "Hello, I'm using VynqTalk!",
    "lastActive": "2026-01-14T10:30:00Z",
    "createdAt": "2026-01-13T08:00:00Z",
    "online": true
  },
  "message": "Profile retrieved successfully"
}
```

**Requirements:**
- Return authenticated user's profile
- Update lastActive timestamp

---

### 5. PUT `/user`
**Description:** Update user profile

**Headers:**
```
Authorization: Bearer {accessToken}
```

**Request Body:**
```json
{
  "name": "John Updated",
  "status": "Away",
  "bio": "New bio text",
  "avatar": "https://example.com/new-avatar.jpg"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Updated",
    "email": "user@example.com",
    "avatar": "https://example.com/new-avatar.jpg",
    "userRole": "USER",
    "status": "Away",
    "bio": "New bio text",
    "lastActive": "2026-01-14T10:35:00Z",
    "createdAt": "2026-01-13T08:00:00Z",
    "online": true
  },
  "message": "Profile updated successfully"
}
```

---

## 💬 Message Endpoints

### 6. GET `/messages/all/{userId1}/{userId2}`
**Description:** Get conversation between two users

**Headers:**
```
Authorization: Bearer {accessToken}
```

**URL Parameters:**
- `userId1`: First user ID (usually current user)
- `userId2`: Second user ID (chat partner)

**Example:** `GET /messages/all/1/2`

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "content": "Hey, how are you?",
      "type": "TEXT",
      "sender": {
        "id": 1,
        "name": "John Doe",
        "avatar": "https://example.com/john.jpg"
      },
      "receiver": {
        "id": 2,
        "name": "Jane Smith",
        "avatar": "https://example.com/jane.jpg"
      },
      "timestamp": "2026-01-14T09:00:00Z",
      "fileName": null,
      "edited": false,
      "reactions": [
        {
          "emoji": "👍",
          "userId": 2
        }
      ],
      "replyTo": null
    },
    {
      "id": 2,
      "content": "I'm good, thanks!",
      "type": "TEXT",
      "sender": {
        "id": 2,
        "name": "Jane Smith",
        "avatar": "https://example.com/jane.jpg"
      },
      "receiver": {
        "id": 1,
        "name": "John Doe",
        "avatar": "https://example.com/john.jpg"
      },
      "timestamp": "2026-01-14T09:01:00Z",
      "fileName": null,
      "edited": false,
      "reactions": [],
      "replyTo": null
    }
  ],
  "message": "Messages retrieved successfully"
}
```

**Requirements:**
- Return all messages between two users
- Sort by timestamp (oldest first)
- Include sender and receiver user objects
- Include reactions array
- Include replyTo message if exists
- Mark messages as read for current user

---

### 7. POST `/messages`
**Description:** Send a new message (REST fallback, prefer WebSocket)

**Headers:**
```
Authorization: Bearer {accessToken}
```

**Request Body:**
```json
{
  "receiverId": 2,
  "content": "Hello there!",
  "type": "TEXT",
  "fileName": null
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": 3,
    "content": "Hello there!",
    "type": "TEXT",
    "sender": {
      "id": 1,
      "name": "John Doe",
      "avatar": "https://example.com/john.jpg"
    },
    "receiver": {
      "id": 2,
      "name": "Jane Smith",
      "avatar": "https://example.com/jane.jpg"
    },
    "timestamp": "2026-01-14T10:30:00Z",
    "fileName": null,
    "edited": false,
    "reactions": [],
    "replyTo": null
  },
  "message": "Message sent successfully"
}
```

**Requirements:**
- Validate sender is authenticated user
- Validate receiver exists
- Create message in database
- Broadcast to receiver via WebSocket (if online)
- Return created message with full user objects

---

## 🔌 WebSocket Implementation

### WebSocket Endpoint: `ws://YOUR_SERVER:8080/ws`

**Connection:**
```swift
// Client connects with query parameter
ws://YOUR_SERVER:8080/ws?token={JWT_TOKEN}
```

**Authentication:**
- Validate JWT token from query parameter
- Reject connection if invalid token
- Store user ID with WebSocket connection

---

### WebSocket Message Types

#### 1. Chat Message (Client → Server)
```json
{
  "type": "chat_message",
  "data": {
    "senderId": 1,
    "receiverId": 2,
    "content": "Hello via WebSocket!",
    "type": "TEXT",
    "fileName": null
  }
}
```

**Server Actions:**
1. Validate sender is authenticated user
2. Save message to database
3. Send to receiver if online
4. Send confirmation to sender

---

#### 2. Chat Message (Server → Client)
```json
{
  "type": "chat_message",
  "data": {
    "id": 5,
    "content": "Hello via WebSocket!",
    "type": "TEXT",
    "sender": {
      "id": 1,
      "name": "John Doe",
      "avatar": "https://example.com/john.jpg"
    },
    "receiver": {
      "id": 2,
      "name": "Jane Smith",
      "avatar": "https://example.com/jane.jpg"
    },
    "timestamp": "2026-01-14T10:35:00Z",
    "fileName": null,
    "edited": false,
    "reactions": [],
    "replyTo": null
  }
}
```

---

#### 3. Typing Indicator (Client → Server)
```json
{
  "type": "typing",
  "data": {
    "userId": 1,
    "receiverId": 2,
    "isTyping": true
  }
}
```

**Server Actions:**
1. Forward to receiver if online
2. Don't save to database

---

#### 4. Typing Indicator (Server → Client)
```json
{
  "type": "typing",
  "data": {
    "userId": 1,
    "isTyping": true
  }
}
```

---

#### 5. User Online Status (Server → All Clients)
```json
{
  "type": "user_status",
  "data": {
    "userId": 3,
    "online": true,
    "lastActive": "2026-01-14T10:40:00Z"
  }
}
```

**Broadcast when:**
- User connects to WebSocket
- User disconnects from WebSocket
- User explicitly changes status

---

#### 6. Message Read Receipt (Client → Server)
```json
{
  "type": "message_read",
  "data": {
    "messageId": 5,
    "userId": 2
  }
}
```

**Server Actions:**
1. Mark message as read in database
2. Send confirmation to sender

---

#### 7. Message Reaction (Client → Server)
```json
{
  "type": "reaction",
  "data": {
    "messageId": 5,
    "emoji": "❤️",
    "userId": 2
  }
}
```

**Server Actions:**
1. Add reaction to database
2. Broadcast to both users

---

## 🔒 Authentication & Authorization

### JWT Token Structure
```json
{
  "userId": 1,
  "email": "user@example.com",
  "role": "USER",
  "exp": 1705228800
}
```

**Requirements:**
- Use HS256 algorithm
- Secret key stored in environment variable
- Token expires in 7 days
- Include in Authorization header: `Bearer {token}`

---

### Protected Routes
All routes except `/auth/signup` and `/auth/login` require authentication:
- Validate JWT token
- Return 401 if invalid/expired
- Return 403 if insufficient permissions

---

## 📁 File Upload (Future Feature)

### POST `/upload`
**Description:** Upload file (image, audio, video, document)

**Headers:**
```
Authorization: Bearer {accessToken}
Content-Type: multipart/form-data
```

**Request Body:**
```
file: [binary data]
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "url": "https://example.com/uploads/abc123.jpg",
    "fileName": "photo.jpg",
    "fileSize": 1024000,
    "mimeType": "image/jpeg"
  },
  "message": "File uploaded successfully"
}
```

**Requirements:**
- Store files in cloud storage (AWS S3, DigitalOcean Spaces, etc.)
- Generate unique filename
- Validate file type and size
- Return public URL

---

## 🗃️ Database Schema Summary

### Tables Required:
1. **users**
   - id (UUID, primary key)
   - name (String)
   - email (String, unique)
   - password (String, hashed)
   - avatar (String?, nullable)
   - user_role (Enum: USER, ADMIN)
   - status (String?, nullable)
   - bio (String?, nullable)
   - last_active (Timestamp?, nullable)
   - created_at (Timestamp)
   - online (Boolean, default: false)

2. **messages**
   - id (UUID, primary key)
   - content (String)
   - type (Enum: TEXT, IMAGE, AUDIO, VIDEO, FILE)
   - sender_id (UUID, foreign key → users.id)
   - receiver_id (UUID, foreign key → users.id)
   - timestamp (Timestamp)
   - file_name (String?, nullable)
   - edited (Boolean, default: false)
   - reply_to_id (UUID?, nullable, foreign key → messages.id)

3. **reactions**
   - id (UUID, primary key)
   - emoji (String)
   - user_id (UUID, foreign key → users.id)
   - message_id (UUID, foreign key → messages.id)
   - created_at (Timestamp)

---

## 🚀 Deployment Requirements

### Environment Variables
```bash
DATABASE_URL=postgres://user:password@localhost:5432/vynqtalk
JWT_SECRET=your-super-secret-key-change-this
PORT=8080
ENVIRONMENT=production
```

### Database
- PostgreSQL 14+
- Run migrations on startup
- Enable UUID extension

### Server
- Vapor 4.x
- Swift 5.9+
- Support WebSocket connections
- CORS enabled for iOS app

---

## 📊 API Response Format

All API responses follow this structure:

**Success:**
```json
{
  "success": true,
  "data": { /* response data */ },
  "message": "Operation successful"
}
```

**Error:**
```json
{
  "success": false,
  "data": null,
  "message": "Error description"
}
```

---

## 🔄 WebSocket Connection Management

### Connection Lifecycle:
1. **Connect:** Client connects with JWT token
2. **Authenticate:** Server validates token
3. **Register:** Server stores user ID → WebSocket mapping
4. **Broadcast:** Server updates online status to all users
5. **Disconnect:** Server removes mapping, broadcasts offline status

### Heartbeat:
- Client sends ping every 30 seconds
- Server responds with pong
- Disconnect if no ping for 60 seconds

---

## 📝 Additional Notes

### Date Format:
- All dates in ISO 8601 format
- Example: `2026-01-14T10:30:00Z`
- Use UTC timezone

### Error Codes:
- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 500: Internal Server Error

### Rate Limiting:
- 100 requests per minute per user
- 1000 WebSocket messages per minute per user

---

## ✅ Implementation Checklist

### Phase 1: Core Features
- [ ] User registration and login
- [ ] JWT authentication
- [ ] Get all users
- [ ] Get user profile
- [ ] Get conversation messages
- [ ] Send message (REST)

### Phase 2: Real-time Features
- [ ] WebSocket connection
- [ ] Real-time message delivery
- [ ] Typing indicators
- [ ] Online status updates

### Phase 3: Enhanced Features
- [ ] Message reactions
- [ ] Message editing
- [ ] Message replies
- [ ] Read receipts
- [ ] File uploads

### Phase 4: Polish
- [ ] Rate limiting
- [ ] Error handling
- [ ] Logging
- [ ] Performance optimization
- [ ] Database indexing

---

## 🎯 Priority Order

1. **High Priority (MVP):**
   - Authentication (signup, login)
   - User list
   - Message history
   - Send message via REST
   - WebSocket basic connection

2. **Medium Priority:**
   - Real-time message delivery
   - Online status
   - Typing indicators

3. **Low Priority (Future):**
   - Reactions
   - File uploads
   - Message editing
   - Read receipts

---

**Document Version:** 1.0  
**Last Updated:** January 14, 2026  
**iOS App Version:** Compatible with current VynqTalk iOS app

# Requirements Document: API Integration Fixes

## Introduction

This document outlines the requirements for fixing API integration issues between the VynqTalk iOS app and the backend server. The backend API documentation specifies endpoints and response formats that differ from the current implementation.

## Glossary

- **API_Client**: The Swift service responsible for making HTTP requests to the backend
- **Backend_Server**: The Vapor server running at `http://localhost:8080`
- **Auth_Token**: JWT token used for authentication
- **API_Response**: Standard response wrapper containing success, data, and message fields
- **Message_Endpoint**: Backend endpoint for retrieving conversation messages
- **User_Endpoint**: Backend endpoint for retrieving user list

## Requirements

### Requirement 1: Fix Base URL Configuration

**User Story:** As a developer, I want the app to connect to the correct backend server, so that API requests reach the intended destination.

#### Acceptance Criteria

1. WHEN the app is configured THEN the System SHALL use `http://localhost:8080` as the base URL for local development
2. WHEN deploying to production THEN the System SHALL support environment-based URL configuration
3. THE API_Client SHALL validate the base URL format before making requests

### Requirement 2: Fix Message Conversation Endpoint

**User Story:** As a user, I want to view my conversation history with another user, so that I can see our message exchange.

#### Acceptance Criteria

1. WHEN loading a conversation THEN the System SHALL call `GET /messages/conversation/:user1ID/:user2ID`
2. WHEN the endpoint returns data THEN the System SHALL parse the response as `APIResponse<[Message]>`
3. IF the current endpoint `/messages/all/:user1ID/:user2ID` fails THEN the System SHALL use the correct endpoint
4. THE Message_Endpoint SHALL include reactions in the response

### Requirement 3: Fix User List Endpoint

**User Story:** As a user, I want to see a list of available users, so that I can start conversations.

#### Acceptance Criteria

1. WHEN loading the user list THEN the System SHALL call `GET /users/search?query=` for search functionality
2. WHEN no search query is provided THEN the System SHALL call `GET /users` or equivalent endpoint
3. THE User_Endpoint SHALL return an array of User objects
4. WHEN the response is received THEN the System SHALL handle both empty and populated user lists

### Requirement 4: Validate API Response Structure

**User Story:** As a developer, I want consistent API response handling, so that errors are caught early and data is properly parsed.

#### Acceptance Criteria

1. WHEN any API call is made THEN the System SHALL expect the standard response format with success, data, and message fields
2. WHEN success is false THEN the System SHALL display the message field to the user
3. WHEN data is null THEN the System SHALL handle it gracefully without crashing
4. THE API_Client SHALL log response errors for debugging

### Requirement 5: Fix Authentication Flow

**User Story:** As a user, I want to log in and register successfully, so that I can access the app features.

#### Acceptance Criteria

1. WHEN signing up THEN the System SHALL call `POST /auth/signup` with name, email, and password
2. WHEN logging in THEN the System SHALL call `POST /auth/login` with email and password
3. WHEN authentication succeeds THEN the System SHALL receive an accessToken and user object
4. THE Auth_Token SHALL be stored securely and included in subsequent requests
5. WHEN the token expires (401/403) THEN the System SHALL log the user out automatically

### Requirement 6: Add User ID Type Consistency

**User Story:** As a developer, I want consistent user ID types across the app, so that API calls work correctly.

#### Acceptance Criteria

1. WHEN the backend uses UUID for user IDs THEN the System SHALL update models to use String instead of Int
2. WHEN the backend uses Int for user IDs THEN the System SHALL keep the current Int type
3. THE System SHALL validate user ID format before making API calls
4. WHEN user IDs are invalid THEN the System SHALL show appropriate error messages

### Requirement 7: Improve Error Handling

**User Story:** As a user, I want clear error messages when something goes wrong, so that I understand what happened.

#### Acceptance Criteria

1. WHEN a network error occurs THEN the System SHALL display a user-friendly message
2. WHEN authentication fails THEN the System SHALL show "Invalid email or password"
3. WHEN the server is unreachable THEN the System SHALL show "Cannot connect to server"
4. WHEN a 500 error occurs THEN the System SHALL show "Server error, please try again"
5. THE System SHALL log detailed errors for debugging purposes

### Requirement 8: Add Request/Response Logging

**User Story:** As a developer, I want to see API requests and responses in debug mode, so that I can troubleshoot issues.

#### Acceptance Criteria

1. WHEN running in debug mode THEN the System SHALL log all API requests with method, URL, and headers
2. WHEN receiving responses THEN the System SHALL log status code, headers, and body
3. WHEN errors occur THEN the System SHALL log the full error details
4. THE logging SHALL be disabled in production builds
5. THE logging SHALL not expose sensitive data like passwords

### Requirement 9: Support WebSocket Authentication

**User Story:** As a user, I want real-time messaging to work, so that I can chat instantly.

#### Acceptance Criteria

1. WHEN connecting to WebSocket THEN the System SHALL include the auth token in the URL query parameter
2. THE WebSocket URL SHALL be `ws://localhost:8080/ws?token=<auth_token>`
3. WHEN the token is invalid THEN the System SHALL handle connection rejection gracefully
4. WHEN disconnected THEN the System SHALL attempt to reconnect with a valid token

### Requirement 10: Add Message Sending via REST

**User Story:** As a user, I want to send messages even if WebSocket is unavailable, so that I can always communicate.

#### Acceptance Criteria

1. WHEN WebSocket is unavailable THEN the System SHALL fall back to REST API
2. THE System SHALL call `POST /messages` with receiverId, content, and type
3. WHEN the message is sent THEN the System SHALL add it to the local message list
4. THE System SHALL support all message types: TEXT, IMAGE, AUDIO, VIDEO, FILE

### Requirement 11: Validate Message Type Enum

**User Story:** As a developer, I want message types to match the backend, so that messages are properly categorized.

#### Acceptance Criteria

1. THE MessageType enum SHALL include: TEXT, IMAGE, AUDIO, VIDEO, FILE
2. WHEN encoding messages THEN the System SHALL use uppercase string values
3. WHEN decoding messages THEN the System SHALL handle both uppercase and lowercase values
4. THE System SHALL default to TEXT type if type is missing

### Requirement 12: Add User Status Updates

**User Story:** As a user, I want to see when other users are online, so that I know who is available to chat.

#### Acceptance Criteria

1. WHEN a user's status changes THEN the System SHALL call `PATCH /users/:userID/status`
2. THE request SHALL include status and online fields
3. WHEN receiving WebSocket status updates THEN the System SHALL update the user list
4. THE System SHALL show online indicators on user avatars

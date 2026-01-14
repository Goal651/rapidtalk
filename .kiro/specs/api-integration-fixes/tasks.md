# Implementation Plan: API Integration Fixes

## Overview

This plan implements critical API integration fixes to enable proper communication between the iOS app and the Vapor backend server.

## Tasks

- [x] 1. Add Environment Configuration
  - Create APIEnvironment enum with development, staging, production cases
  - Add baseURL and wsURL computed properties
  - Update APIClient to use environment-based URLs
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 2. Create Endpoint Constants
  - Create APIEndpoint enum with all endpoint cases
  - Add path computed property for each endpoint
  - Update ViewModels to use endpoint constants
  - _Requirements: 2.1, 3.1, 5.1, 5.2_

- [x] 3. Fix Message Conversation Endpoint
  - Update MessageViewModel to use correct endpoint
  - Change `/messages/all/` to `/messages/conversation/`
  - Use APIEndpoint.conversation(user1:user2:)
  - _Requirements: 2.1, 2.2_

- [x] 4. Add Enhanced Error Handling
  - [x] 4.1 Create APIError enum
    - Add cases: networkError, serverError, authenticationRequired, etc.
    - Add errorDescription for user-friendly messages
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [x] 4.2 Update APIClient error handling
    - Add handleError method
    - Map URLError to APIError
    - Handle 401/403 with auto-logout
    - _Requirements: 5.5, 7.1_

- [x] 5. Add Request/Response Logging
  - [x] 5.1 Add logging methods to APIClient
    - Create logRequest method
    - Create logResponse method
    - Create sanitizeLog method for sensitive data
    - _Requirements: 8.1, 8.2, 8.3, 8.5_

  - [x] 5.2 Integrate logging into makeRequest
    - Log before sending request
    - Log after receiving response
    - Only log in DEBUG builds
    - _Requirements: 8.1, 8.2, 8.4_

- [x] 6. Checkpoint - Test Critical Fixes
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Update ViewModels with Error Handling
  - [ ] 7.1 Update AuthViewModel
    - Use APIError for error handling
    - Show user-friendly error messages
    - _Requirements: 5.1, 5.2, 7.2_

  - [ ] 7.2 Update UserViewModel
    - Use APIError for error handling
    - Handle empty user lists gracefully
    - _Requirements: 3.2, 3.3, 7.1_

  - [ ] 7.3 Update MessageViewModel
    - Use APIError for error handling
    - Handle empty conversations gracefully
    - _Requirements: 2.2, 2.3, 7.1_

- [ ] 8. Add Message Sending via REST
  - [ ] 8.1 Create SendMessageRequest model
    - Add receiverId, content, type fields
    - _Requirements: 10.2_

  - [ ] 8.2 Implement sendMessage in MessageViewModel
    - Call POST /messages endpoint
    - Add sent message to local list
    - Handle errors gracefully
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

- [x] 9. Enhance WebSocket Manager
  - [x] 9.1 Update WebSocket connection with token
    - Add token to URL query parameter
    - Use environment-based WebSocket URL
    - _Requirements: 9.1, 9.2_

  - [x] 9.2 Add WebSocket message models
    - Create WebSocketMessage for sending
    - Create WebSocketResponse for receiving
    - Create WebSocketData enum for different data types
    - _Requirements: 9.1_

  - [x] 9.3 Implement message sending via WebSocket
    - Encode message as JSON
    - Send via WebSocket
    - Handle send errors
    - _Requirements: 9.1_

  - [x] 9.4 Add reconnection logic
    - Detect connection failures
    - Attempt reconnection after delay
    - Handle auth failures
    - _Requirements: 9.3, 9.4_

- [x] 10. Update ChatScreen with Message Sending
  - [x] 10.1 Wire up send button
    - Call messageVM.sendMessage or wsM.sendChatMessage
    - Clear input field on success
    - Show error on failure
    - _Requirements: 10.1, 10.2_

  - [x] 10.2 Add REST fallback
    - Try WebSocket first
    - Fall back to REST if WebSocket unavailable
    - _Requirements: 10.1_

- [ ] 11. Checkpoint - Test All Features
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 12. Manual Testing with Backend
  - Test authentication flow (signup, login, invalid credentials)
  - Test user list loading
  - Test conversation loading
  - Test message sending via REST
  - Test message sending via WebSocket
  - Test WebSocket connection and reconnection
  - Test error handling for all scenarios
  - _Requirements: All_

- [ ] 13. Final Checkpoint - Production Ready
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Critical fixes (tasks 1-6) should be completed first
- WebSocket enhancements (task 9) can be done in parallel with other tasks
- Manual testing (task 12) validates all features work with actual backend

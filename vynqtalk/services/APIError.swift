//
//  APIError.swift
//  vynqtalk
//
//  Created by Kiro AI
//

import Foundation

enum APIError: LocalizedError {
    case networkError
    case serverError(statusCode: Int)
    case authenticationRequired
    case invalidResponse
    case decodingError(Error)
    case timeout
    case noConnection
    case unknown(Error)
    
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
        case .unknown(let error):
            return "An error occurred: \(error.localizedDescription)"
        }
    }
}

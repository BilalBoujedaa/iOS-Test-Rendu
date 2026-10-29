//
//  NetworkError.swift
//  TheGoodCorner
//
//  Created by MacBook on 28/10/2026.
//

import Foundation

enum NetworkError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingFailed
    case transport(String)

    /// User-facing, recoverable message shown in the error state view.
    var userMessage: String {
        switch self {
        case .invalidURL:
            return "Couldn't build the request."
        case .invalidResponse:
            return "Received an unexpected response from the server."
        case .serverError(let statusCode):
            return "The server returned an error (code \(statusCode))."
        case .decodingFailed:
            return "The data from the server couldn't be read."
        case .transport:
            return "Couldn't reach the server. Check that it's running and try again."
        }
    }
}

//
//  NetworkError.swift
//  Networking
//
//  Created by Tal talspektor on 5/17/25.
//

import Foundation

public enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case httpError(Int, Data)
    case unknownError

    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL provided."
        case .requestFailed(let error):
            return "Network request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response received from the server."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .httpError(let statusCode, let data):
            return "Http error, status code: \(statusCode), Data: \(data)"
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}

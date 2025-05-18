//
//  NetworkClient.swift
//  Networking
//
//  Created by Tal talspektor on 5/17/25.
//

import Foundation
import Combine

public protocol NetworkClient {
    /// more generic, no decoding
    func performRequest<Request: NetworkRequest>(_ request: Request) -> AnyPublisher<(Data, HTTPURLResponse), NetworkError>
    /// less generic, with decoding
    func performRequest<Request: NetworkRequest>(_ request: Request) -> AnyPublisher<(Request.Response, HTTPURLResponse), NetworkError>
}

extension NetworkClient {
    
    var session: URLSession { .shared }
    
    /// Performs a network request and returns a Combine publisher with raw data and response.
    /// The caller is responsible for checking the status code and decoding the data.
    /// - Parameter request: The NetworkRequest to perform.
    /// - Returns: A publisher that emits a tuple of Data and HTTPURLResponse, or a NetworkError.
    public func performRequest<Request: NetworkRequest>(_ request: Request) -> AnyPublisher<(Data, HTTPURLResponse), NetworkError> {
        guard let url = request.url else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.allHTTPHeaderFields = request.headers
        urlRequest.httpBody = request.body

        // Use URLSession's dataTaskPublisher for Combine integration
        return session.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                // Ensure the response is an HTTPURLResponse
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse // Still throw if it's not an HTTP response
                }
                // Pass both data and response through, regardless of status code
                return (data, httpResponse)
            }
            .mapError { error in
                // Map potential URLSession errors to our custom NetworkError type
                if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.requestFailed(error)
                }
            }
            .eraseToAnyPublisher() // Erase the publisher type for flexibility
    }
}

// Generic Network Client using Combine
public class NetworkClientImp: NetworkClient {

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Performs a network request and returns a Combine publisher with raw data and response.
    /// The caller is responsible for checking the status code and decoding the data.
    /// - Parameter request: The NetworkRequest to perform.
    /// - Returns: A publisher that emits a tuple of Decodable response, and HTTPURLResponse, or a NetworkError.
    public func performRequest<Request: NetworkRequest>(_ request: Request) -> AnyPublisher<(Request.Response, HTTPURLResponse), NetworkError> {
        guard let url = request.url else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.allHTTPHeaderFields = request.headers
        urlRequest.httpBody = request.body

        // Use URLSession's dataTaskPublisher for Combine integration
        return session.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                // Ensure the response is an HTTPURLResponse
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse // Still throw if it's not an HTTP response
                }
                let statusCode = httpResponse.statusCode
                print("Received response with status code: \(statusCode)")
                
                if (200...299).contains(statusCode) {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let response = try decoder.decode(Request.Response.self, from: data)
                    return (response, httpResponse)
                } else {
                    // Handle server-side errors or other non-2xx status codes
                    // Attempt to decode a custom server error if expected
                    do {
                        let serverError = try JSONDecoder().decode(Request.ServerError.self, from: data)
                        throw serverError // Throw the custom server error
                    } catch {
                        // If decoding the custom error fails, or it's a generic non-2xx,
                        // throw a more general error including the status code.
                        // You might want a more specific error type here.
                        throw NSError(domain: "ServerError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(statusCode)"])
                    }
                }
            }
            .mapError { error in
                // Map potential URLSession errors to our custom NetworkError type
                if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.requestFailed(error)
                }
            }
            .eraseToAnyPublisher() // Erase the publisher type for flexibility
    }
}


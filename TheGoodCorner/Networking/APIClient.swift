//
//  APIClient.swift
//  TheGoodCorner
//
//  Created by MacBook on 28/10/2026.
//

import Foundation

final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    
    /// Initializes a new instance of `APIClient`.
    /// - Parameters:
    ///   - session: The URL session to use. Defaults to `.shared`.
    ///   - baseURL: The base URL for the API. Defaults to `AppConfig.baseURL`.
    init(session: URLSession = .shared, baseURL: URL = AppConfig.baseURL) {
        self.session = session
        self.baseURL = baseURL
        self.decoder = JSONDecoder()
    }

    func fetchListings(page: Int, limit: Int, query: String? = nil) async throws -> ProductsResponse {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "query", value: query))
        }
        let url = try buildURL(path: Endpoint.listings.rawValue, queryItems: queryItems)
        return try await performRequest(url: url)
    }
     
    func fetchCategories() async throws -> [Category] {
        let url = try buildURL(path: Endpoint.categories.rawValue, queryItems: [])
        return try await performRequest(url: url)
    }

    // MARK: - Private Helper Methods
    
    /// Constructs a valid URL by appending a path and query items to the base URL.
    /// - Parameters:
    ///   - path: The endpoint path (e.g., "/listings").
    ///   - queryItems: An array of URL query parameters.
    /// - Throws: `NetworkError.invalidURL` if the URL cannot be constructed.
    /// - Returns: A fully constructed `URL`.
    private func buildURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        return url
    }

    /// Executes a network request and decodes the response into the requested generic type.
    /// - Parameter url: The `URL` to request data from.
    /// - Throws: Various `NetworkError` cases depending on the failure point.
    /// - Returns: A decoded object of type `T`.
    private func performRequest<T: Decodable>(url: URL) async throws -> T {
         
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw NetworkError.transport(error.localizedDescription)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
         
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }
}

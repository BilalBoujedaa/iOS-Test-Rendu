//
//  ProductRepositoryProtocol.swift
//  TheGoodCorner
//
//  Created by MacBook on 24/10/2026.
//

import Foundation

/// Abstraction over the network layer so view models can be tested without
/// a running server.
protocol APIClientProtocol {
    func fetchProducts(page: Int, limit: Int, query: String?) async throws -> ProductsResponse
    func fetchCategories() async throws -> [Category]
}

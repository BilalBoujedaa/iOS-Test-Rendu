//
//  ProductsResponse.swift
//  TheGoodCorner
//
//  Created by MacBook on 24/10/2026.
//

import Foundation

struct ProductsResponse: Decodable, Equatable {
    let items: [Product]
    let total: Int
    let page: Int
    let limit: Int
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case items, total, page, limit
        case hasMore = "has_more"
    }
}

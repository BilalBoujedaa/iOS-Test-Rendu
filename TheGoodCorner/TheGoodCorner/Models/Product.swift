//
//  Product.swift
//  TheGoodCorner
//
//  Created by MacBook on 24/10/2026.
//

import Foundation

struct ImagesURL: Decodable, Equatable {
    let small: String?
    let thumb: String?
}

struct Product: Identifiable, Decodable, Equatable {
    let id: Int
    let price: Int
    let categoryId: Int
    let imagesUrl: ImagesURL?
    let description: String
    let creationDate: Date?
    let title: String
    let isUrgent: Bool

    enum CodingKeys: String, CodingKey {
        case id, price, description, title
        case categoryId = "category_id"
        case imagesUrl = "images_url"
        case creationDate = "creation_date"
        case isUrgent = "is_urgent"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        price = try container.decode(Int.self, forKey: .price)
        categoryId = try container.decode(Int.self, forKey: .categoryId)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Untitled product"
        // Assumption: is_urgent is not guaranteed on every item, default to false when absent.
        isUrgent = try container.decodeIfPresent(Bool.self, forKey: .isUrgent) ?? false
        // Assumption: images_url may be entirely absent; treat as "no image" rather than failing decode.
        imagesUrl = try container.decodeIfPresent(ImagesURL.self, forKey: .imagesUrl)
        // Assumption: a malformed/absent date should not fail the whole decode; the UI can just omit it.
        if let dateString = try container.decodeIfPresent(String.self, forKey: .creationDate) {
            creationDate = Product.dateFormatter.date(from: dateString)
        } else {
            creationDate = nil
        }
    }

    // Memberwise init kept for tests / previews.
    init(id: Int, price: Int, categoryId: Int, imagesUrl: ImagesURL?, description: String, creationDate: Date?, title: String, isUrgent: Bool) {
        self.id = id
        self.price = price
        self.categoryId = categoryId
        self.imagesUrl = imagesUrl
        self.description = description
        self.creationDate = creationDate
        self.title = title
        self.isUrgent = isUrgent
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

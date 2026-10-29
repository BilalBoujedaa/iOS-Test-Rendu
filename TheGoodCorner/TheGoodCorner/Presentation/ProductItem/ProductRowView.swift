//
//  ProductRowView.swift
//  TheGoodCorner
//
//  Created by MacBook on 29/10/2026.
//

import SwiftUI

struct ProductRowView: View {
    let product: Product
    let categoryName: String
    let imageURL: URL?
    
    let isiPad: Bool = UIDevice.current.userInterfaceIdiom == .pad

    private var priceText: String {
        product.price.formatted(.currency(code: "EUR"))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RemoteImageView(url: imageURL, size: isiPad ? 170 : 84)
                .padding(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(categoryName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(product.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)

                Spacer(minLength: 2)

                HStack(spacing: 8) {
                    Text(priceText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                Spacer()

                    if product.isUrgent {
                        Label("Urgent", systemImage: "bolt.fill")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .foregroundStyle(Color.red)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [product.title, categoryName, priceText]
        if product.isUrgent {
            parts.append("Urgent")
        }
        return parts.joined(separator: ", ")
    }
}
 
 

//
//  ListingItemDetailView.swift
//  TheGoodCorner
//
//  Created by MacBook on 30/10/2026.
//

import SwiftUI

struct ListingItemDetailView: View {
    let listing: Listing
    let categoryName: String
    let imageURL: URL?
    
    private var priceText: String {
        listing.price.formatted(.currency(code: "EUR"))
    }
    
    private var dateText: String? {
        guard let date = listing.creationDate else { return nil }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RemoteImageView(url: imageURL, cornerRadius: 12)
                    .padding(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(categoryName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        if listing.isUrgent {
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
                    
                    Text(listing.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(priceText)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    
                    if let dateText {
                        Text("Posted \(dateText)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    Text("Description")
                        .font(.headline)
                    
                    Text(listing.description.isEmpty ? "No description provided." : listing.description)
                        .font(.body)
                        .foregroundStyle(listing.description.isEmpty ? .secondary : .primary)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        } 
        .navigationBarTitleDisplayMode(.inline)
    }
}

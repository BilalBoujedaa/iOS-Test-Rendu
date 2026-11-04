//
//  ListingsListView.swift
//  TheGoodCorner
//
//  Created by MacBook on 29/10/2026.
//

import SwiftUI

struct ListingsListView: View {
    
    @ObservedObject var viewModel: ListingsViewModel
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 0) {
      
                if !viewModel.categories.isEmpty {
                    CategoryFilterBar(
                        categories: viewModel.categories,
                        selectedCategoryId: viewModel.selectedCategoryId,
                        onSelect: { viewModel.selectCategory($0) }
                    )
                }
                
                content
                    .navigationBarTitleDisplayMode(.inline)
                
            }
            .navigationTitle("Listings")
            
            .searchable(
                text: Binding(
                    get: { viewModel.searchQuery },
                    set: { viewModel.updateSearchQuery($0) }
                ),
                prompt: "Search listings"
            )
            
            .task {
                if viewModel.state == .idle {
                    await viewModel.loadInitialData()
                }
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingStateView()
        case .failed(let message):
            ErrorStateView(message: message) {
                Task { await viewModel.retry() }
            }
        case .empty:
            EmptyStateView()
        case .loaded:
            List {
                ForEach(viewModel.filteredListings) { listing in
                    NavigationLink {
                        ListingItemDetailView(
                            listing: listing,
                            categoryName: viewModel.categoryName(for: listing.categoryId),
                            imageURL: viewModel.imageURL(for: listing.imagesUrl?.thumb)
                        )
                    } label: {
                        ListingRowView(
                            listing: listing,
                            categoryName: viewModel.categoryName(for: listing.categoryId),
                            imageURL: viewModel.imageURL(for: listing.imagesUrl?.small)
                        )
                    }
                    .onAppear {
                        guard viewModel.selectedCategoryId == nil else { return }
                        Task { await viewModel.loadMoreIfNeeded(currentItem: listing) }
                    }
                    
                }
                
                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                }
                
            }
            .listStyle(.plain)
            
        }
    }
}

#Preview {
    ListingsListView(viewModel: ListingsViewModel())
}

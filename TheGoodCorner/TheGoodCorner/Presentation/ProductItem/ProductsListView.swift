//
//  ProductsListView.swift
//  TheGoodCorner
//
//  Created by MacBook on 29/10/2026.
//

import SwiftUI

struct ProductsListView: View {
    
    @ObservedObject var viewModel: ProductsViewModel
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 0) {
                
                Text("Products")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.bar)
                    .accessibilityAddTraits(.isHeader)
                
                if !viewModel.categories.isEmpty {
                    CategoryFilterBar(
                        categories: viewModel.categories,
                        selectedCategoryId: viewModel.selectedCategoryId,
                        onSelect: { viewModel.selectCategory($0) }
                    )
                }
                
                content
                
            } 
            
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
                ForEach(viewModel.filteredProducts) { product in
                    NavigationLink {
                        ProductItemDetailView(
                            product: product,
                            categoryName: viewModel.categoryName(for: product.categoryId),
                            imageURL: viewModel.imageURL(for: product.imagesUrl?.thumb)
                        )
                    } label: {
                        ProductRowView(
                            product: product,
                            categoryName: viewModel.categoryName(for: product.categoryId),
                            imageURL: viewModel.imageURL(for: product.imagesUrl?.small)
                        )
                    }
                    
                }
                
            }
            .listStyle(.plain)
            
        }
    }
}

#Preview {
    ProductsListView(viewModel: ProductsViewModel())
}

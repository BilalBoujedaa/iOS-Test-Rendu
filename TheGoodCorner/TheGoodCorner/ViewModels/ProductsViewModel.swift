//
//  ProductsViewModel.swift
//  TheGoodCorner
//
//  Created by MacBook on 28/10/2026.
//

import Foundation
internal import Combine
  
enum ProductsViewState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failed(String)
}

@MainActor
final class ProductsViewModel: ObservableObject {
    private let pageSize = 10

    @Published private(set) var state: ProductsViewState = .idle
    @Published private(set) var filteredProducts: [Product] = []
    @Published private(set) var categories: [Category] = []
    @Published private(set) var selectedCategoryId: Int?
    @Published private(set) var isLoadingMore: Bool = false

    @Published private(set) var searchQuery: String = ""
    @Published private(set) var isSearchActive: Bool = false

    private var browseProducts: [Product] = []
    private var browsePage = 1
 
    private let apiClient: APIClientProtocol
    private let baseURL: URL

    init(
        apiClient: APIClientProtocol = APIClient(),
        baseURL: URL = AppConfig.baseURL
    ) {
        self.apiClient = apiClient
        self.baseURL = baseURL
    }

    // MARK: - Initial load

    func loadInitialData() async {
        state = .loading
        browsePage = 1
        do {
            async let productsResponse = apiClient.fetchProducts(page: 1, limit: pageSize, query: nil)
            async let categoriesResponse = apiClient.fetchCategories()
            let (productsResult, categoriesResult) = try await (productsResponse, categoriesResponse)
            browseProducts = productsResult.items 
            categories = categoriesResult
            applyFilter()
        } catch {
            state = .failed(Self.message(for: error))
        }
    }
    
    func retry() async {
        await loadInitialData()
    }
     
    // MARK: - Category filter

    /// Restarts pagination from page 1 whenever the category filter changes.
    func selectCategory(_ id: Int?) {
        guard selectedCategoryId != id else { return }
        selectedCategoryId = id

        browsePage = 1
        Task { await loadInitialData() }
    }
    
    // MARK: - Shared helpers

    func imageURL(for path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: path, relativeTo: baseURL)?.absoluteURL
    }

    func categoryName(for id: Int) -> String {
        categories.first(where: { $0.id == id })?.name ?? "Uncategorized"
    }

    private func applyFilter() {
        let source = browseProducts
        if let selectedCategoryId {
            filteredProducts = source.filter { $0.categoryId == selectedCategoryId }
        } else {
            filteredProducts = source
        }
        state = filteredProducts.isEmpty ? .empty : .loaded
    }
    
    static func message(for error: Error) -> String {
        (error as? NetworkError)?.userMessage ?? "Something went wrong. Please try again."
    }
 
}

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
    @Published var selectedCategoryId: Int?
    @Published private(set) var isLoadingMore: Bool = false

    @Published private(set) var searchQuery: String = ""
    @Published private(set) var isSearchActive: Bool = false

    private var browseProducts: [Product] = []
    private var browsePage = 1
    private var browseHasMore = true
 
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
 
    func selectCategory(_ id: Int?) {
        guard selectedCategoryId != id else { return }
        selectedCategoryId = id
 
        applyFilter()
    }
    
    // MARK: - Pagination (infinite scroll)

    /// Call when a row appears. Loads the next page once the user nears the
    /// end of the currently visible (filtered) list.
    func loadMoreIfNeeded(currentItem: Product) async {
        guard !isLoadingMore else { return }
        guard let index = filteredProducts.firstIndex(where: { $0.id == currentItem.id }) else { return }
        guard index >= filteredProducts.count - 3 else { return } // near the end

        guard browseHasMore else { return }
        await loadMoreBrowseListings()
    }

    private func loadMoreBrowseListings() async {
        isLoadingMore = true
        defer { isLoadingMore = false }
        let nextPage = browsePage + 1
        do {
            let response = try await apiClient.fetchProducts(page: nextPage, limit: pageSize, query: nil)
            let existingIds = Set(browseProducts.map(\.id))
            let newItems = response.items.filter { !existingIds.contains($0.id) }
            browseProducts.append(contentsOf: newItems)
            browsePage = nextPage
            browseHasMore = response.hasMore
            applyFilter()
        } catch {
            // Best-effort: keep the current list, just stop trying this page.
        }
    }
    
    // MARK: - Shared helpers

    func imageURL(for path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: path, relativeTo: baseURL)?.absoluteURL
    }

    func categoryName(for id: Int) -> String {
        categories.first(where: { $0.id == id })?.name ?? "Uncategorized"
    }

    func applyFilter() {
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

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
    
    private var searchResults: [Product] = []
    private var searchPage = 1
    private var searchHasMore = true
    
    private var searchTask: Task<Void, Never>?
    private let debounceNanoseconds: UInt64
 
    private let apiClient: APIClientProtocol
    private let baseURL: URL

    init(
        apiClient: APIClientProtocol = APIClient(),
        baseURL: URL = AppConfig.baseURL,
        debounceNanoseconds: UInt64 = 350_000_000
    ) {
        self.apiClient = apiClient
        self.baseURL = baseURL
        self.debounceNanoseconds = debounceNanoseconds
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

        if isSearchActive {
            guard searchHasMore else { return }
            await loadMoreSearchResults()
        } else {
            guard browseHasMore else { return }
            await loadMoreBrowseListings()
        }
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
    
    private func loadMoreSearchResults() async {
        isLoadingMore = true
        defer { isLoadingMore = false }
        let query = currentTrimmedQuery
        let nextPage = searchPage + 1
        do {
            let response = try await apiClient.fetchProducts(page: nextPage, limit: pageSize, query: query)
            guard currentTrimmedQuery == query else { return }
            let existingIds = Set(searchResults.map(\.id))
            let newItems = response.items.filter { !existingIds.contains($0.id) }
            searchResults.append(contentsOf: newItems)
            searchPage = nextPage
            searchHasMore = response.hasMore
            applyFilter()
        } catch {
            // Best-effort: keep the current results.
        }
    }
    
    // MARK: - Search

    func updateSearchQuery(_ query: String) {
        searchQuery = query
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isSearchActive = false
            searchResults = []
            searchPage = 1
            searchHasMore = true
            applyFilter()
            return
        }

        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: self.debounceNanoseconds)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await self.performSearch(query: trimmed)
        }
    }

    /// A new search query always restarts pagination from page 1.
    private func performSearch(query: String) async {
        state = .loading
        searchPage = 1
        searchHasMore = true
        do {
            let response = try await apiClient.fetchProducts(page: 1, limit: pageSize, query: query)
            guard !Task.isCancelled, currentTrimmedQuery == query else { return }
            isSearchActive = true
            searchResults = response.items
            searchHasMore = response.hasMore
            applyFilter()
        } catch is CancellationError {
            // Superseded by a newer query.
        } catch {
            guard !Task.isCancelled, currentTrimmedQuery == query else { return }
            state = .failed(Self.message(for: error))
        }
    }

    private var currentTrimmedQuery: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Shared helpers
 
    func categoryName(for id: Int) -> String {
        categories.first(where: { $0.id == id })?.name ?? "Uncategorized"
    }

    func applyFilter() {
        let source = isSearchActive ? searchResults : browseProducts
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

//
//  ListingsViewModel.swift
//  TheGoodCorner
//
//  Created by MacBook on 28/10/2026.
//

import Foundation
internal import Combine
  
enum ListingsViewState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failed(String)
}

@MainActor
final class ListingsViewModel: ObservableObject {
    private let pageSize = 10

    @Published private(set) var state: ListingsViewState = .idle
    @Published private(set) var filteredListings: [Listing] = []
    @Published private(set) var categories: [Category] = []
    @Published var selectedCategoryId: Int?
    @Published private(set) var isLoadingMore: Bool = false

    @Published private(set) var searchQuery: String = ""
    @Published private(set) var isSearchActive: Bool = false

    private var browseListings: [Listing] = []
    private var browsePage = 1
    private var browseHasMore = true
    
    private var searchResults: [Listing] = []
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
            async let listingsResponse = apiClient.fetchListings(page: 1, limit: pageSize, query: nil)
            async let categoriesResponse = apiClient.fetchCategories()
            let (listingsResult, categoriesResult) = try await (listingsResponse, categoriesResponse)
            browseListings = listingsResult.items
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
    func loadMoreIfNeeded(currentItem: Listing) async {
        guard !isLoadingMore else { return }
        guard let index = filteredListings.firstIndex(where: { $0.id == currentItem.id }) else { return }
        guard index >= filteredListings.count - 3 else { return } // near the end

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
            let response = try await apiClient.fetchListings(page: nextPage, limit: pageSize, query: nil)
            let existingIds = Set(browseListings.map(\.id))
            let newItems = response.items.filter { !existingIds.contains($0.id) }
            browseListings.append(contentsOf: newItems)
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
            let response = try await apiClient.fetchListings(page: nextPage, limit: pageSize, query: query)
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
            let response = try await apiClient.fetchListings(page: 1, limit: pageSize, query: query)
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
    
    func imageURL(for path: String?) -> URL? {
            guard let path, !path.isEmpty else { return nil }
            return URL(string: path, relativeTo: baseURL)?.absoluteURL
        }
 
    func categoryName(for id: Int) -> String {
        categories.first(where: { $0.id == id })?.name ?? "Uncategorized"
    }

    func applyFilter() {
        let source = isSearchActive ? searchResults : browseListings
        if let selectedCategoryId {
            filteredListings = source.filter { $0.categoryId == selectedCategoryId }
        } else {
            filteredListings = source
        }
        state = filteredListings.isEmpty ? .empty : .loaded
    }
    
    static func message(for error: Error) -> String {
        (error as? NetworkError)?.userMessage ?? "Something went wrong. Please try again."
    }
 
}

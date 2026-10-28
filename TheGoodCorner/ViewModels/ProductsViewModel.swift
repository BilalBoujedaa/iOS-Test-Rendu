//
//  ProductsViewModel.swift
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
    @Published private(set) var filteredListings: [Product] = []
    @Published private(set) var categories: [Category] = []
    @Published private(set) var selectedCategoryId: Int?
    @Published private(set) var isLoadingMore: Bool = false

    @Published private(set) var searchQuery: String = ""
    @Published private(set) var isSearchActive: Bool = false

    private var browseListings: [Product] = []
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
            async let listingsResponse = apiClient.fetchListings(page: 1, limit: pageSize, query: nil)
            async let categoriesResponse = apiClient.fetchCategories()
            let (listingsResult, categoriesResult) = try await (listingsResponse, categoriesResponse)
            browseListings = listingsResult.items 
            categories = categoriesResult
        } catch {
            state = .failed(Self.message(for: error))
        }
    }
    
    static func message(for error: Error) -> String {
        (error as? NetworkError)?.userMessage ?? "Something went wrong. Please try again."
    }
 
}

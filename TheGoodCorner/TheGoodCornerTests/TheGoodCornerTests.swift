//
//  TheGoodCornerTests.swift
//  TheGoodCornerTests
//
//  Created by MacBook on 23/10/2026.
//

import XCTest
@testable import TheGoodCorner

final class TheGoodCornerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    // MARK: - Request building

    /// Verifies that `APIClient.fetchProducts` encodes page, limit and query
    /// into the request URL's query string, without hitting the real network.
    func test_fetchProducts_buildsCorrectQueryItems() async throws {
        // 1. Intercept the outgoing request and capture it so we can inspect the URL.
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            // Minimal valid envelope so decoding succeeds and the call returns normally.
            let body = """
            {"page":2,"limit":10,"items":[],"has_more":false,"total":0}
            """.data(using: .utf8)!
            return (response, body)
        }

        // 2. Build an APIClient backed by a session whose traffic is stubbed by MockURLProtocol.
        let client = await APIClient(session: MockURLProtocol.makeSession(), baseURL: URL(string: "http://127.0.0.1:8080")!)
        _ = try await client.fetchProducts(page: 2, limit: 10, query: "vinyle")

        // 3. Extract the query items from the captured request URL.
        let url = try XCTUnwrap(capturedRequest?.url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = try XCTUnwrap(components?.queryItems)

        // 4. Assert each expected parameter is present with the correct value.
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "page", value: "2")))
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "limit", value: "10")))
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "query", value: "vinyle")))
    }
    
    // MARK: - Full listing

    /// Decodes a listing with every API field present and checks each value maps correctly.
    func test_decodesFullListing_withAllFieldsPresent() throws {
        let json = """
        {
            "price": 10,
            "category_id": 7,
            "images_url": {
                "small": "/images/ad-small/abc.jpg",
                "thumb": "/images/ad-thumb/abc.jpg"
            },
            "description": "A nice item",
            "creation_date": "2019-11-06T11:22:35Z",
            "id": 1547408955,
            "title": "Vinyle Elliott Murphy",
            "is_urgent": true
        }
        """.data(using: .utf8)!

        let listing = try JSONDecoder().decode(Product.self, from: json)

        XCTAssertEqual(listing.id, 1547408955)
        XCTAssertEqual(listing.price, 10)
        XCTAssertEqual(listing.categoryId, 7)
        XCTAssertEqual(listing.title, "Vinyle Elliott Murphy")
        XCTAssertTrue(listing.isUrgent)
        XCTAssertEqual(listing.imagesUrl?.small, "/images/ad-small/abc.jpg")
        XCTAssertNotNil(listing.creationDate)
    }

    // MARK: - Missing optional fields

    /// Confirms a listing still decodes when optional fields are absent, using safe defaults.
    func test_decodesListing_gracefullyWhenOptionalFieldsAreMissing() throws {
        // Assumption under test: is_urgent and images_url are not guaranteed
        // on every listing, so decoding must not fail when they're absent.
        let json = """
        {
            "price": 5,
            "category_id": 2,
            "description": "No image, no urgency flag",
            "id": 42,
            "title": "Plain item"
        }
        """.data(using: .utf8)!

        let listing = try JSONDecoder().decode(Product.self, from: json)

        XCTAssertEqual(listing.id, 42)
        XCTAssertFalse(listing.isUrgent)
        XCTAssertNil(listing.imagesUrl)
        XCTAssertNil(listing.creationDate)
    }
  
}
 

// MARK: - Test double

/// Intercepts URLSession traffic so APIClient tests never touch the real
/// network or require the local server to be running.
final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: -1))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}


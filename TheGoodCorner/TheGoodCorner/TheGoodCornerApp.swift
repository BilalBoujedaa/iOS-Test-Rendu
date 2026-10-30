//
//  TheGoodCornerApp.swift
//  TheGoodCorner
//
//  Created by MacBook on 23/10/2026.
//

import SwiftUI

@main
struct TheGoodCornerApp: App {
    var body: some Scene {
        WindowGroup {
            ProductsListView(viewModel: ProductsViewModel())
        }
    }
}

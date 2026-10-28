//
//  ContentView.swift
//  TheGoodCorner
//
//  Created by MacBook on 23/10/2026.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var viewModel: ListingsViewModel
    
    var body: some View {
        
        VStack(spacing: 0) {
            
        }
        
        .task {
            if viewModel.state == .idle {
                await viewModel.loadInitialData()
            }
        }
        
    }
}
 
#Preview {
    ContentView(viewModel: ListingsViewModel())
}

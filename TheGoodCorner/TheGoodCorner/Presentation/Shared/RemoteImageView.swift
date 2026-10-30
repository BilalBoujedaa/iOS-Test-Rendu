//
//  RemoteImageView.swift
//  TheGoodCorner
//
//  Created by MacBook on 29/10/2026.
//

import SwiftUI

/// Wraps AsyncImage so missing URLs and failed loads both fall back to a
/// consistent placeholder instead of a blank/broken cell.
 
struct RemoteImageView: View {
    let url: URL?
    var size: CGFloat?
    var cornerRadius: CGFloat = 8

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        content
            .frame(
                width: size,
                height: size ?? UIScreen.main.bounds.height / 3
            )
            .clipShape(shape)
            .contentShape(shape)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)  
                case .failure:
                    placeholder
                case .empty:
                    skeleton
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.secondary.opacity(0.15)
            Image(systemName: "photo")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
        }
    }

    private var skeleton: some View {
        ZStack {
            Color.secondary.opacity(0.15)
            ProgressView()
        }
    }
}

//
//  RemoteImageView.swift
//  TheGoodCorner
//
//  Created by MacBook on 29/10/2026.
//

import SwiftUI

/// Wraps AsyncImage so missing URLs and failed loads both fall back to a
/// consistent placeholder instead of a blank/broken cell.
//struct RemoteImageView: View {
 
struct RemoteImageView: View {
    let url: URL?
    var size: CGFloat?
    var cornerRadius: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            let imageWidth = size ?? geometry.size.width
            let imageHeight = size ?? UIScreen.main.bounds.height / 3

            Group {
                if let url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)

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
            .frame(width: imageWidth, height: imageHeight)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
            )
        }
        .frame(
            width: size,
            height: size == nil ? UIScreen.main.bounds.height / 3 : size
        )
        .accessibilityHidden(true)
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


//
//  imageURL.swift
//  TheGoodCorner
//
//  Created by MacBook on 03/11/2026.
//

import Foundation

func imageURL(for path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: path, relativeTo: baseURL)?.absoluteURL
    }

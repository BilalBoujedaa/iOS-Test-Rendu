//
//  AppConfig.swift
//  TheGoodCorner
//
//  Created by MacBook on 28/10/2026.
//

import Foundation

/// Central place for the API base URL. Kept configurable so a physical device
/// (or a different host/port) can be supported without touching call sites.
enum AppConfig {
    static var baseURL: URL { URL(string: "http://127.0.0.1:8080")! }
}

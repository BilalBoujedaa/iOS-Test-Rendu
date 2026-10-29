//
//  Typography.swift
//  TheGoodCorner
//
//  Created by MacBook on 29/10/2026.
//

import Foundation
import SwiftUI

// MARK: - Device-based typography

struct ChipStyle {
    let isiPad: Bool
 
    // Fonts
    var title: Font { isiPad ? .title3 : .subheadline }
 
    // Sizes & spacing
    var chipSpacing: CGFloat { isiPad ? 14 : 8 }
    var chipHPadding: CGFloat { isiPad ? 22 : 14 }
    var chipVPadding: CGFloat { isiPad ? 12 : 8 }
    var barHPadding: CGFloat { isiPad ? 24 : 16 }
    var barVPadding: CGFloat { isiPad ? 12 : 8 }
}

struct RowStyle {
    let isiPad: Bool

    // Fonts
    var category: Font { isiPad ? .title3 : .caption }
    var title: Font { isiPad ? .title2 : .body }
    var price: Font { isiPad ? .title3 : .subheadline }
    var badge: Font { isiPad ? .callout : .caption2 }

    // Sizes & spacing
    var imageSize: CGFloat { isiPad ? 170 : 84 }
    var contentSpacing: CGFloat { isiPad ? 8 : 4 }
    var rowSpacing: CGFloat { isiPad ? 20 : 12 }
    var badgeHPadding: CGFloat { isiPad ? 10 : 6 }
    var badgeVPadding: CGFloat { isiPad ? 4 : 2 }
    var verticalPadding: CGFloat { isiPad ? 8 : 4 }
}

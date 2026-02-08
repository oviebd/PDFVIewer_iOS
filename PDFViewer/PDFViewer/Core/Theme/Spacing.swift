//
//  Spacing.swift
//  PDFViewer
//
//  Core Design System - Spacing & Sizing
//

import SwiftUI

/// App-wide spacing, sizing, and dimension constants.
/// Use these instead of hardcoded numeric values.
enum AppSpacing {
    
    // MARK: - Spacing Scale
    
    /// 4pt - Extra extra small spacing
    static let xxs: CGFloat = 4
    
    /// 8pt - Extra small spacing
    static let xs: CGFloat = 8
    
    /// 12pt - Small spacing
    static let sm: CGFloat = 12
    
    /// 16pt - Medium spacing (default)
    static let md: CGFloat = 16
    
    /// 20pt - Large spacing
    static let lg: CGFloat = 20
    
    /// 24pt - Extra large spacing
    static let xl: CGFloat = 24
    
    /// 30pt - Extra extra large spacing
    static let xxl: CGFloat = 30
    
    /// 40pt - Huge spacing
    static let xxxl: CGFloat = 40
    
    // MARK: - Corner Radii
    
    /// 4pt - Extra small corner radius
    static let cornerRadiusXS: CGFloat = 4
    
    /// 6pt - Small corner radius
    static let cornerRadiusSM: CGFloat = 6
    
    /// 10pt - Medium corner radius
    static let cornerRadiusMD: CGFloat = 10
    
    /// 16pt - Large corner radius
    static let cornerRadiusLG: CGFloat = 16
    
    // MARK: - Component Sizes
    
    /// PDF thumbnail width
    static let thumbnailWidth: CGFloat = 55
    
    /// PDF thumbnail height
    static let thumbnailHeight: CGFloat = 75
    
    /// Floating action button size
    static let fabSize: CGFloat = 60
    
    /// Toolbar height
    static let toolbarHeight: CGFloat = 56
    
    /// Color indicator size (small)
    static let colorIndicatorSmall: CGFloat = 25
    
    /// Color indicator size (medium)
    static let colorIndicatorMedium: CGFloat = 36
    
    /// Color indicator container
    static let colorIndicatorContainer: CGFloat = 48
    
    /// Favorite button size
    static let favoriteButtonSize: CGFloat = 20
    
    /// Selection indicator size
    static let selectionIndicatorSize: CGFloat = 24
    
    // MARK: - Shadow Values
    
    /// Light shadow radius
    static let shadowRadiusLight: CGFloat = 4
    
    /// Medium shadow radius
    static let shadowRadiusMedium: CGFloat = 8
    
    /// Heavy shadow radius
    static let shadowRadiusHeavy: CGFloat = 20
    
    // MARK: - Line Widths
    
    /// Thin border/stroke
    static let borderThin: CGFloat = 0.5
    
    /// Normal border/stroke
    static let borderNormal: CGFloat = 1
    
    /// Thick border/stroke
    static let borderThick: CGFloat = 1.5
    
    /// Circle stroke width
    static let circleStroke: CGFloat = 2
}

// MARK: - Padding Convenience Extensions
extension View {
    /// Apply standard horizontal padding
    func horizontalPadding(_ size: CGFloat = AppSpacing.md) -> some View {
        self.padding(.horizontal, size)
    }
    
    /// Apply standard vertical padding
    func verticalPadding(_ size: CGFloat = AppSpacing.md) -> some View {
        self.padding(.vertical, size)
    }
    
    /// Apply card-style padding
    func cardPadding() -> some View {
        self.padding(AppSpacing.md)
    }
    
    /// Apply list row padding
    func listRowPadding() -> some View {
        self.padding(.vertical, AppSpacing.xs)
    }
}

//
//  Fonts.swift
//  PDFViewer
//
//  Core Design System - Typography
//

import SwiftUI

/// App-wide typography definitions.
/// Use these instead of inline `.font()` modifiers.
enum AppFonts {
    
    // MARK: - Standard Text Styles
    
    /// Large title for main headers
    static var largeTitle: Font {
        .largeTitle
    }
    
    /// Title for section headers
    static var title: Font {
        .title
    }
    
    /// Secondary title
    static var title2: Font {
        .title2
    }
    
    /// Headline for card titles, list items
    static var headline: Font {
        .headline
    }
    
    /// Body text for content
    static var body: Font {
        .body
    }
    
    /// Subheadline for secondary info
    static var subheadline: Font {
        .subheadline
    }
    
    /// Caption for timestamps, metadata
    static var caption: Font {
        .caption
    }
    
    /// Footnote for legal text, very small info
    static var footnote: Font {
        .footnote
    }
    
    // MARK: - Custom Icon Fonts
    
    /// Small icons (filter pills, etc.)
    static var iconSmall: Font {
        .system(size: 14, weight: .semibold)
    }
    
    /// Medium icons (toolbar buttons)
    static var iconMedium: Font {
        .system(size: 18, weight: .semibold)
    }
    
    /// Large icons (FAB, main actions)
    static var iconLarge: Font {
        .system(size: 24, weight: .bold)
    }
    
    /// Extra large icons (empty state)
    static var iconXLarge: Font {
        .system(size: 64)
    }
    
    // MARK: - Custom Sized Fonts
    
    /// Selection indicator icon
    static var selectionIcon: Font {
        .system(size: 24)
    }
    
    /// Control button icon
    static var controlButton: Font {
        .title
    }
    
    /// Page progress text
    static var pageProgress: Font {
        .system(size: 14, weight: .medium)
    }
    
    /// Undo/Redo buttons
    static var undoRedo: Font {
        .system(size: 20, weight: .bold)
    }
    
    /// Favorite button icon
    static var favoriteIcon: Font {
        .system(size: 20, weight: .medium)
    }
}

// MARK: - Text Style Modifiers
extension View {
    /// Apply headline style with primary color
    func headlineStyle() -> some View {
        self
            .font(AppFonts.headline)
            .foregroundColor(AppColors.textPrimary)
    }
    
    /// Apply subheadline style with secondary color
    func subheadlineStyle() -> some View {
        self
            .font(AppFonts.subheadline)
            .foregroundColor(AppColors.textSecondary)
    }
    
    /// Apply caption style with tertiary color
    func captionStyle() -> some View {
        self
            .font(AppFonts.caption)
            .foregroundColor(AppColors.textTertiary)
    }
    
    /// Apply title style for empty states
    func emptyStateTitleStyle() -> some View {
        self
            .font(AppFonts.title2)
            .fontWeight(.semibold)
            .foregroundColor(AppColors.textPrimary)
    }
}

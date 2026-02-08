//
//  Colors.swift
//  PDFViewer
//
//  Core Design System - Color Definitions
//

import SwiftUI

/// App-wide color definitions with automatic dark/light mode support.
/// Use these semantic colors instead of hardcoded Color values.
enum AppColors {
    
    // MARK: - Backgrounds
    
    /// Main background color (white/dark gray)
    static var background: Color {
        Color(.systemBackground)
    }
    
    /// Secondary background for cards, surfaces
    static var surface: Color {
        Color(.secondarySystemBackground)
    }
    
    /// Tertiary background for grouped content
    static var surfaceSecondary: Color {
        Color(.tertiarySystemBackground)
    }
    
    /// Custom light gray surface (for toolbars, etc.)
    static var surfaceLight: Color {
        Color(light: Color(red: 0.96, green: 0.97, blue: 0.98),
              dark: Color(red: 0.15, green: 0.15, blue: 0.18))
    }
    
    // MARK: - Brand Colors
    
    /// Primary brand color
    static var primary: Color {
        Color(.systemBlue)
    }
    
    /// Secondary/accent color
    static var accent: Color {
        Color.blue
    }
    
    /// Success color
    static var success: Color {
        Color.green
    }
    
    /// Warning color
    static var warning: Color {
        Color.orange
    }
    
    /// Error/destructive color
    static var error: Color {
        Color(.systemRed)
    }
    
    // MARK: - Text Colors
    
    /// Primary label color
    static var textPrimary: Color {
        Color(.label)
    }
    
    /// Secondary label color
    static var textSecondary: Color {
        Color(.secondaryLabel)
    }
    
    /// Tertiary label color
    static var textTertiary: Color {
        Color(.tertiaryLabel)
    }
    
    /// Text on primary color (for buttons, etc.)
    static var onPrimary: Color {
        Color.white
    }
    
    // MARK: - Semantic Colors
    
    /// Favorite heart color
    static var favorite: Color {
        Color(.systemRed)
    }
    
    /// Inactive/disabled color
    static var inactive: Color {
        Color(.systemGray3)
    }
    
    /// Separator/divider color
    static var separator: Color {
        Color(.separator)
    }
    
    /// Placeholder color
    static var placeholder: Color {
        Color(.systemGray3)
    }
    
    // MARK: - Filter/Folder Colors
    
    static var filterAll: Color { .blue }
    static var filterFavorite: Color { .red }
    static var filterRecent: Color { .green }
    
    /// Colors for custom folders (cycles through)
    static let folderColors: [Color] = [
        .purple, .orange, .teal, .pink, .indigo, .cyan
    ]
    
    static func folderColor(for index: Int) -> Color {
        folderColors[index % folderColors.count]
    }
    
    // MARK: - Shadow Colors
    
    static var shadowLight: Color {
        Color.black.opacity(0.08)
    }
    
    static var shadowMedium: Color {
        Color.black.opacity(0.15)
    }
    
    static var shadowHeavy: Color {
        Color.black.opacity(0.3)
    }
    
    // MARK: - Toast/Overlay
    
    static var toastBackground: Color {
        Color.black.opacity(0.8)
    }
    
    /// Overlay background (adapts to theme)
    static var overlayBackground: Color {
        Color(.systemBackground)
    }
    
    /// Card background for list items
    static var cardBackground: Color {
        Color(.secondarySystemBackground)
    }
    
    /// Favorite button background
    static var buttonBackground: Color {
        Color(.tertiarySystemBackground)
    }
    
    // MARK: - Gradient Colors
    
    static var primaryGradient: [Color] {
        [Color.blue, Color.blue.opacity(0.8)]
    }
    
    static var thumbnailGradient: [Color] {
        [Color(.systemGray6), Color(.systemGray5)]
    }
    
    // MARK: - Annotation Colors
    
    static let annotationColors: [UIColor] = [
        .red, .green, .blue, .yellow, .orange, .purple, .black, .gray
    ]
    
    // MARK: - Disabled state
    
    static var disabledToolColor: Color {
        Color(red: 0.2, green: 0.25, blue: 0.35).opacity(0.3)
    }
}

// MARK: - Color Extension for Theme Support
extension Color {
    /// Creates a color that adapts to light/dark mode
    init(light: Color, dark: Color) {
        self = Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

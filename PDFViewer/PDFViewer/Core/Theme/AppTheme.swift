//
//  AppTheme.swift
//  PDFViewer
//
//  Core Design System - Theme Manager
//

import SwiftUI

/// Main theme manager that provides access to all design tokens.
/// Use as an `@EnvironmentObject` throughout the app.
final class AppTheme: ObservableObject {
    @Published var colorScheme: ColorScheme = .light
    
    static let shared = AppTheme()
    
    init() {
        // Detect system appearance on init
        if UITraitCollection.current.userInterfaceStyle == .dark {
            colorScheme = .dark
        }
    }
    
    var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    /// Toggle between light and dark mode
    func toggleTheme() {
        colorScheme = colorScheme == .light ? .dark : .light
    }
    
    /// Set specific color scheme
    func setTheme(_ scheme: ColorScheme) {
        colorScheme = scheme
    }
}

// MARK: - Environment Key
private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme()
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

// MARK: - View Extension
extension View {
    /// Applies the app theme environment object
    func withAppTheme(_ theme: AppTheme = .shared) -> some View {
        self.environmentObject(theme)
    }
}

//
//  Images.swift
//  PDFViewer
//
//  Core Design System - Image/Icon Names
//

import SwiftUI

/// Centralized SF Symbol names used throughout the app.
/// Use these instead of hardcoded string literals.
enum AppImages {
    
    // MARK: - Navigation & Actions
    
    /// Back chevron
    static let back = "chevron.left"
    
    /// Close/dismiss
    static let close = "xmark"
    
    /// More options (ellipsis)
    static let more = "ellipsis.circle"
    
    /// Download/import
    static let download = "square.and.arrow.down"
    
    // MARK: - Documents
    
    /// Document icon
    static let document = "doc.fill"
    
    /// Book icon
    static let book = "book.fill"
    
    // MARK: - Favorites
    
    /// Heart outline (not favorite)
    static let heart = "heart"
    
    /// Heart filled (favorite)
    static let heartFill = "heart.fill"
    
    // MARK: - Folders & Organization
    
    /// Folder with plus badge
    static let folderAdd = "folder.badge.plus"
    
    /// Plus in circle (add action)
    static let addCircle = "plus.circle.fill"
    
    /// Trash/delete
    static let trash = "trash"
    
    // MARK: - Selection
    
    /// Checkmark in circle (selected)
    static let checkCircle = "checkmark.circle.fill"
    
    /// Empty circle (unselected)
    static let circle = "circle"
    
    // MARK: - Editing & Annotations
    
    /// Undo action
    static let undo = "arrow.uturn.backward"
    
    /// Redo action
    static let redo = "arrow.uturn.forward"
    
    /// Line/stroke settings
    static let lineSettings = "line.3.horizontal"
    
    // MARK: - Zoom & View
    
    /// Zoom in
    static let zoomIn = "plus.magnifyingglass"
    
    /// Zoom out
    static let zoomOut = "minus.magnifyingglass"
    
    /// Brightness/sun
    static let brightness = "sun.max.fill"
    
    // MARK: - Labels & Menu
    
    /// Delete label
    static let deleteLabel = "Delete"
    
    /// Move label (for swipe action)
    static let moveLabel = "Move"
}

// MARK: - Icon View Helpers
extension Image {
    /// Creates an SF Symbol image with standard styling
    static func icon(_ name: String) -> Image {
        Image(systemName: name)
    }
}

// MARK: - Convenience View Modifier
extension View {
    /// Apply standard icon styling
    func iconStyle(size: Font = AppFonts.iconMedium, color: Color = AppColors.textPrimary) -> some View {
        self
            .font(size)
            .foregroundColor(color)
    }
}

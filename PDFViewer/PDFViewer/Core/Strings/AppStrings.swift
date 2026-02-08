//
//  AppStrings.swift
//  PDFViewer
//
//  Core Design System - UI Text Strings
//

import Foundation

/// Centralized UI text strings for the app.
/// Designed for easy localization in the future.
enum AppStrings {
    
    // MARK: - Navigation
    
    enum Navigation {
        static let library = "Library"
        static let cancel = "Cancel"
        static let close = "Close"
        static let ok = "Ok"
        static let create = "Create"
        static let done = "Done"
    }
    
    // MARK: - PDF List
    
    enum PDFList {
        static let searchPrompt = "Search by title or author"
        static let selectAll = "Select All"
        static let deselectAll = "Deselect All"
    }
    
    // MARK: - Empty State
    
    enum EmptyState {
        static let title = "No PDFs yet"
        static let subtitle = "Import your first PDF to start reading"
        static let importButton = "Import PDF"
    }
    
    // MARK: - Filters
    
    enum Filters {
        static let all = "All"
        static let favorites = "Favorites"
        static let recent = "Recent"
        static let new = "New"
    }
    
    // MARK: - Folders
    
    enum Folders {
        static let newFolderTitle = "New Folder"
        static let folderNamePlaceholder = "Folder Name"
        static let moveToFolder = "Move to Folder"
        static let noFolder = "No Folder"
    }
    
    // MARK: - Actions
    
    enum Actions {
        static let delete = "Delete"
        static let move = "Move"
        static let deletePDF = "Delete PDF?"
        static let deleteSelectedPDFs = "Delete Selected PDFs?"
    }
    
    // MARK: - Confirmation Messages
    
    enum Confirmation {
        static func deleteConfirmation(title: String?) -> String {
            "Are you sure you want to delete '\(title ?? "this PDF")'? This action cannot be undone."
        }
        
        static func deleteMultipleConfirmation(count: Int) -> String {
            "Are you sure you want to delete \(count) selected PDFs? This action cannot be undone."
        }
    }
    
    // MARK: - PDF Info
    
    enum PDFInfo {
        static let untitledDocument = "Untitled Document"
        static let unknownAuthor = "Unknown"
        static let unknownFile = "Unknown file"
        static let pages = "Pages"
        static let opened = "Opened"
        static let noData = "No data"
        
        static func pageCount(_ count: Int) -> String {
            "\(count) Pages"
        }
    }
    
    // MARK: - Reading Mode
    
    enum ReadingMode {
        static let title = "Reading Mode"
        static let normal = "Normal"
        static let sepia = "Sepia"
        static let night = "Night"
        static let eyeComfort = "Eye Comfort"
    }
    
    // MARK: - Annotation
    
    enum Annotation {
        static let setWidth = "Set Width"
    }
    
    // MARK: - Errors
    
    enum Errors {
        static let bookmarkCreationFailed = "Bookmark creation failed"
        static let couldNotAccessResource = "Could not access security scoped resource."
        static let pickerCancelled = "Picker was cancelled."
    }
}

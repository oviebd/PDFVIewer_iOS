//
//  FolderPickerView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 4/4/25.
//

import SwiftUI
import UniformTypeIdentifiers

enum PickerMode {
    case file
    case folder
}

struct BookmarkDataClass {
    var data : Data
    var key : String
}

struct DocumentPickerRepresentable: UIViewControllerRepresentable {
    let mode: PickerMode
    var onPick: ([BookmarkDataClass]) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = (mode == .file) ? [.pdf] : [.folder]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: false)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = (mode == .file) // allow selecting multiple files
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPickerRepresentable
        
        init(_ parent: DocumentPickerRepresentable) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            var bookmarks: [BookmarkDataClass] = []
            let dispatchGroup = DispatchGroup()

            for url in urls {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    dispatchGroup.enter()
                    DispatchQueue.global(qos: .userInitiated).async {
                        defer { dispatchGroup.leave() }
                        
                        do {
                            // Create bookmark data
                            let bookmark = try url.bookmarkData()

                            // Generate stable key using PDFKeyGenerator
                            let key = PDFKeyGenerator.shared.computeKey(url: url, maxPages: 10) ?? UUID().uuidString
                            print("U>> Key generated: \(key) for Url -> \(url)")
                            let bookmarkDataClass = BookmarkDataClass(data: bookmark, key: key)
                            
                            // Sync access to bookmarks array
                            DispatchQueue.main.async {
                                bookmarks.append(bookmarkDataClass)
                            }
                        } catch {
                            print("Bookmark creation failed: \(error)")
                        }
                    }
                } else {
                    print("Could not access security scoped resource.")
                }
            }

            // Notify when all background work is complete
            dispatchGroup.notify(queue: .main) {
                self.parent.onPick(bookmarks)
            }
            
            func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
                print("Picker was cancelled.")
            }
        }

    }
    
//    class Coordinator: NSObject, UIDocumentPickerDelegate {
//        var parent: DocumentPickerRepresentable
//        
//        init(_ parent: DocumentPickerRepresentable) {
//            self.parent = parent
//        }
//        
//        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//            var bookMarks: [BookmarkDataClass] = []
//            
//            for url in urls {
//                if url.startAccessingSecurityScopedResource() {
//                    defer { url.stopAccessingSecurityScopedResource() }
//                    
//                    do {
//                        // ⬅️ Create bookmark while access is active
//                        let bookmark = try url.bookmarkData()
//                        
//                        let key = UUID().uuidString
//                        let bookmarklDataClass = BookmarkDataClass(data: bookmark, key: key)
//                        
//                        bookMarks.append(bookmarklDataClass)
//                    } catch {
//                        print("Bookmark creation failed: \(error)")
//                    }
//                } else {
//                    print("Could not access security scoped resource.")
//                }
//                
//                parent.onPick(bookMarks)
//            }
//            
//            func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
//                print("Picker was cancelled.")
//            }
//        }
//    }
}

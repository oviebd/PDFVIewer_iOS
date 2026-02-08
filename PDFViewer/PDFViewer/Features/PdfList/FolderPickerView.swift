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
            var bookMarks: [BookmarkDataClass] = []
            
            for url in urls {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    do {
                        // ⬅️ Create bookmark while access is active
                        let bookmark = try url.bookmarkData()
                        
                        let key = url.generatePDFKey()//UUID().uuidString
                        let bookmarklDataClass = BookmarkDataClass(data: bookmark, key: key)
                        
                        bookMarks.append(bookmarklDataClass)
                    } catch {
                        print("Bookmark creation failed: \(error)")
                    }
                } else {
                    print("Could not access security scoped resource.")
                }
                
                parent.onPick(bookMarks)
                
                //            for url in urls {
                //                _ = url.startAccessingSecurityScopedResource()
                //            }
                // parent.onPick(urls)
            }
            
            func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
                print("Picker was cancelled.")
            }
        }
    }
}

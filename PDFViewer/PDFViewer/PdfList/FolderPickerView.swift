//
//  FolderPickerView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 4/4/25.
//

import SwiftUI
import UniformTypeIdentifiers

//struct FolderPickerView: UIViewControllerRepresentable {
//    var onPick: (URL) -> Void
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
//        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
//        picker.delegate = context.coordinator
//        picker.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
//        picker.allowsMultipleSelection = false
//        picker.shouldShowFileExtensions = true
//        return picker
//    }
//
//    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
//
//    class Coordinator: NSObject, UIDocumentPickerDelegate {
//        var parent: FolderPickerView
//
//        init(_ parent: FolderPickerView) {
//            self.parent = parent
//        }
//
//        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//            guard let folderURL = urls.first else { return }
//
//            // ✅ Ask for permission
//            if folderURL.startAccessingSecurityScopedResource() {
//                parent.onPick(folderURL)
//                // Do NOT stop access here — PDFManager will stop it after work is done.
//            } else {
//                print("❌ Couldn't access security-scoped folder.")
//            }
//        }
//
//        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
//            print("Folder picker cancelled")
//        }
//    }
//}

enum PickerMode {
    case file
    case folder
}

struct FileOrFolderPickerView: UIViewControllerRepresentable {
    let mode: PickerMode
    var onPick: ([URL]) -> Void

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
        var parent: FileOrFolderPickerView

        init(_ parent: FileOrFolderPickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                _ = url.startAccessingSecurityScopedResource()
            }
            parent.onPick(urls)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("Picker was cancelled.")
        }
    }
}

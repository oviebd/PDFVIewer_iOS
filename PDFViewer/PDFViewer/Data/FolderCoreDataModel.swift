//
//  FolderCoreDataModel.swift
//  PDFViewer
//
//  Created by Antigravity on 7/2/26.
//

import Foundation
import CoreData

class FolderCoreDataModel {
    let id: String
    let title: String
    let pdfIds: [String]
    let createdAt: Date
    let updatedAt: Date

    init(id: String,
         title: String,
         pdfIds: [String],
         createdAt: Date,
         updatedAt: Date) {
        self.id = id
        self.title = title
        self.pdfIds = pdfIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension FolderCoreDataModel {
    func toFolderModelData() -> FolderModelData {
        return FolderModelData(id: id,
                               title: title,
                               pdfIds: pdfIds,
                               createdAt: createdAt,
                               updatedAt: updatedAt)
    }

    // Helper to convert pdfIds array to comma-separated string for Core Data
    var pdfIdsString: String {
        return pdfIds.joined(separator: ",")
    }

    // Helper to initialize from comma-separated string
    static func parsePdfIds(_ string: String?) -> [String] {
        guard let string = string, !string.isEmpty else { return [] }
        return string.components(separatedBy: ",")
    }
}

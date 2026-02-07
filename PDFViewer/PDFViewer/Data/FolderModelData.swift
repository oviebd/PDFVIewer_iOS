//
//  FolderModelData.swift
//  PDFViewer
//
//  Created by Antigravity on 7/2/26.
//

import Foundation

class FolderModelData: Identifiable {
    let id: String
    var title: String
    var pdfIds: [String]
    let createdAt: Date
    var updatedAt: Date

    init(id: String = UUID().uuidString,
         title: String,
         pdfIds: [String] = [],
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.pdfIds = pdfIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension FolderModelData: Equatable, Hashable {
    static func == (lhs: FolderModelData, rhs: FolderModelData) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension FolderModelData {
    func toCoreDataModel() -> FolderCoreDataModel {
        return FolderCoreDataModel(id: id,
                                   title: title,
                                   pdfIds: pdfIds,
                                   createdAt: createdAt,
                                   updatedAt: updatedAt)
    }
}

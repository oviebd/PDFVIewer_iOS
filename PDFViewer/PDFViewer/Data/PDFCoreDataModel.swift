//
//  PDFCoreDataModel.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 4/5/25.
//

import Foundation

class PDFCoreDataModel {
    let key: String
    let bookmarkData: Data?
    var isFavourite: Bool
    let lastOpenedPage: Int
    let lastOpenTime: Date?

    init(key: String, bookmarkData: Data?,
         isFavourite: Bool,
         lastOpenPage: Int,
         lastOpenTime: Date?) {
        self.key = key
        self.isFavourite = isFavourite
        self.bookmarkData = bookmarkData
        self.lastOpenTime = lastOpenTime
        lastOpenedPage = lastOpenPage
    }
}

extension PDFCoreDataModel {
    func toPDfModelData() -> PDFModelData {
        let modelData = PDFModelData(key: key, bookmarkData: bookmarkData, isFavorite: isFavourite, lastOpenedPage: lastOpenedPage, lastOpenTime: lastOpenTime)

        return modelData
    }

    func toPDFEntity() -> PDFEntity {
        var entityData = PDFEntity()

        entityData.key = key
        entityData.isFavourite = isFavourite
        entityData.lastOpenedPage = Int16(lastOpenedPage)
        entityData.lastOpenTime = lastOpenTime
        entityData.bookmarkData = bookmarkData

        return entityData
    }
}

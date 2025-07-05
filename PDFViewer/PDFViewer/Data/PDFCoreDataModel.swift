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
    var annotationData : Data?
    var isFavourite: Bool
    let lastOpenedPage: Int
    let lastOpenTime: Date?

    init(key: String, bookmarkData: Data?,
         isFavourite: Bool,
         lastOpenPage: Int,
         lastOpenTime: Date?,
         annotationData : Data?) {
        self.key = key
        self.isFavourite = isFavourite
        self.bookmarkData = bookmarkData
        self.lastOpenTime = lastOpenTime
        self.annotationData = annotationData
        lastOpenedPage = lastOpenPage
    }
}

extension PDFCoreDataModel {
    func toPDfModelData() -> PDFModelData {
        let modelData = PDFModelData(key: key, bookmarkData: bookmarkData, annotationData: annotationData, isFavorite: isFavourite, lastOpenedPage: lastOpenedPage, lastOpenTime: lastOpenTime)

        return modelData
    }

    func toPDFEntity() -> PDFEntity {
        let entityData = PDFEntity()

        entityData.key = key
        entityData.isFavourite = isFavourite
        entityData.lastOpenedPage = Int16(lastOpenedPage)
        entityData.lastOpenTime = lastOpenTime
        entityData.bookmarkData = bookmarkData
        entityData.annotationData = annotationData

        return entityData
    }
}

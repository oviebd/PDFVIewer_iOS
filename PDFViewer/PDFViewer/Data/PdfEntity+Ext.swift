//
//  PdfEntity+Ext.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 9/5/25.
//

import Foundation
import CoreData

extension PDFEntity {
    
    func convertFromCoreDataModel(coreData : PDFCoreDataModel )   {
        self.key = coreData.key
        self.isFavourite = coreData.isFavourite
        self.lastOpenedPage = Int16(coreData.lastOpenedPage)
        self.lastOpenTime = coreData.lastOpenTime
        self.bookmarkData = coreData.bookmarkData
        self.annotationData = coreData.annotationdata
    }
}

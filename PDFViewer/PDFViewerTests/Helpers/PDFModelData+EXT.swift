//
//  PDFModelData+EXT.swift
//  PDFViewerTests
//
//  Created by Habibur Rahman on 11/5/25.
//

import Foundation
@testable import PDFViewer

func createPDFModelData(key : String,
                        bookmarkData : Data? = nil,
                        isFavorite : Bool = false,
                        lastOenedPage : Int = 0,
                        lastOpenTime : Date? = nil
) -> PDFModelData {
    return PDFModelData(key: key, bookmarkData: bookmarkData, annotationData: nil, isFavorite: isFavorite, lastOpenedPage: lastOenedPage, lastOpenTime: lastOpenTime)
}

extension PDFModelData {
    
}

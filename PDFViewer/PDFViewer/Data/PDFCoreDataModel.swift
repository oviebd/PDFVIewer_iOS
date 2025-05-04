//
//  PDFCoreDataModel.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 4/5/25.
//

import Foundation

struct PDFCoreDataModel {
    let id : String
    let bookmarkData : Data?
    let isFavorite : Bool = false
    let lastOpenedPage : Int = 0
    let lastOpenTime : Date?
}


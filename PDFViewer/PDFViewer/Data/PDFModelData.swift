//
//  PDFModelData.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 4/5/25.
//

import Foundation

struct PDFModelData {
    let id : String
    let title : String?
    let author : String?
    let bookmarkData : Data?
    let isFavorite : Bool = false
    let lastOpenedPage : Int = 0
    let lastOpenTime : Date? 
}


//
//let samplePDFFile = PDFFile(
//    name: "Sample Document",
//    url: URL(fileURLWithPath: "/path/to/sample.pdf"), data: nil,
//    metadata: PDFMetadata(
//        image: nil, author: "Sample author", title: "Sample title"
//    ),
//    pdfKey: "sample_pdf_001", isFavorite: false
//)

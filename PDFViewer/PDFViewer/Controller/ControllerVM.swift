//
//  ControllerVM.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 2/4/25.
//

import Foundation
import PDFKit
import PencilKit
import SwiftUI

struct PDFColorView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        if let path = Bundle.main.url(forResource: "sample", withExtension: "pdf") {
            pdfView.document = PDFDocument(url: path)
        }
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
}


//
//  PDFViewerApp.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 25/3/25.
//

import SwiftUI


@main
struct PDFViewerApp: App {
    @StateObject private var drawingToolManager: DrawingToolManager

    init() {
        let pdfSettings: [PDFAnnotationSetting] = [
            PDFAnnotationSetting(annotationTool: .none, lineWidth: 0.0, color: .clear, isExpandable: false),
            PDFAnnotationSetting(annotationTool: .pen, lineWidth: 1.0, color: .red, isExpandable: true),
            PDFAnnotationSetting(annotationTool: .highlighter, lineWidth: 10.0, color: .blue, isExpandable: true),
            PDFAnnotationSetting(annotationTool: .eraser, lineWidth: 1.0, color: .yellow, isExpandable: false),
        ]

        let selectePdfdSetting: PDFAnnotationSetting = PDFAnnotationSetting.noneData()
        _drawingToolManager = StateObject(wrappedValue: DrawingToolManager(pdfSettings: pdfSettings, selectePdfdSetting: selectePdfdSetting))
    }

    var body: some Scene {
        WindowGroup {
            PDFListView()
            .environmentObject(drawingToolManager)
        }
    }
}

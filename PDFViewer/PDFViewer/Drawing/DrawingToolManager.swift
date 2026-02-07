//
//  DrawingToolManager.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 14/6/25.
//

import Foundation

class DrawingToolManager: ObservableObject {
    @Published var pdfSettings: [PDFAnnotationSetting]
    @Published var selectePdfdSetting: PDFAnnotationSetting

    init(pdfSettings: [PDFAnnotationSetting], selectePdfdSetting: PDFAnnotationSetting) {
        self.pdfSettings = pdfSettings
        self.selectePdfdSetting = selectePdfdSetting
    }

    func updatePdfSettingData(newSetting: PDFAnnotationSetting) {
        if let index = pdfSettings.firstIndex(where: { $0.annotationTool == newSetting.annotationTool }) {
            pdfSettings[index] = newSetting
        }
    }

    func getSettingFrom(drawingTool: AnnotationTool) -> PDFAnnotationSetting? {
        pdfSettings.first(where: { $0.annotationTool == drawingTool })
    }
}

extension DrawingToolManager {
    static func dummyData() -> DrawingToolManager {
        DrawingToolManager(pdfSettings: [PDFAnnotationSetting(annotationTool: .none, lineWidth: 0.0, color: .clear, isExpandable: false),
                                         PDFAnnotationSetting(annotationTool: .pen, lineWidth: 2.0, color: .red, isExpandable: true),
                                         PDFAnnotationSetting(annotationTool: .pencil, lineWidth: 1.0, color: .gray, isExpandable: true),
                                         PDFAnnotationSetting(annotationTool: .highlighter, lineWidth: 15.0, color: .blue, isExpandable: true),
                                         PDFAnnotationSetting(annotationTool: .text, lineWidth: 1.0, color: .black, isExpandable: false),
                                         PDFAnnotationSetting(annotationTool: .eraser, lineWidth: 1.0, color: .yellow, isExpandable: false)],
                           selectePdfdSetting: .noneData())
    }
}

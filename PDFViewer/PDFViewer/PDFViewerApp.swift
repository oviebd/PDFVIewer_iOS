//
//  PDFViewerApp.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 25/3/25.
//

import SwiftUI

class DrawingToolManager: ObservableObject {
    @Published var pdfSettings: [PDFSettingData]
    @Published var selectePdfdSetting: PDFSettingData

    init(pdfSettings: [PDFSettingData], selectePdfdSetting: PDFSettingData) {
        self.pdfSettings = pdfSettings
        self.selectePdfdSetting = selectePdfdSetting
    }

    func updatePdfSettingData(newSetting: PDFSettingData) {
        if let index = pdfSettings.firstIndex(where: { $0.drawingTool == newSetting.drawingTool }) {
            pdfSettings[index] = newSetting
        }
    }
    
    func getSettingFrom(drawingTool: DrawingTool) -> PDFSettingData? {
        pdfSettings.first(where: { $0.drawingTool == drawingTool })
    }
}

extension DrawingToolManager {
    static func dummyData() -> DrawingToolManager {
        DrawingToolManager(pdfSettings: [PDFSettingData(drawingTool: .none, lineWidth: 0.0, color: .clear, isExpandable: false),
                                         PDFSettingData(drawingTool: .pen, lineWidth: 1.0, color: .red, isExpandable: true),
                                         PDFSettingData(drawingTool: .highlighter, lineWidth: 10.0, color: .blue, isExpandable: true),
                                         PDFSettingData(drawingTool: .eraser, lineWidth: 1.0, color: .yellow, isExpandable: false)],
                           selectePdfdSetting: .noneData())
    }
}

@main
struct PDFViewerApp: App {
    @StateObject private var drawingToolManager: DrawingToolManager

    init() {
        let pdfSettings: [PDFSettingData] = [
            PDFSettingData(drawingTool: .none, lineWidth: 0.0, color: .clear, isExpandable: false),
            PDFSettingData(drawingTool: .pen, lineWidth: 1.0, color: .red, isExpandable: true),
            PDFSettingData(drawingTool: .highlighter, lineWidth: 10.0, color: .blue, isExpandable: true),
            PDFSettingData(drawingTool: .eraser, lineWidth: 1.0, color: .yellow, isExpandable: false),
        ]

        let selectePdfdSetting: PDFSettingData = PDFSettingData.noneData()
        _drawingToolManager = StateObject(wrappedValue: DrawingToolManager(pdfSettings: pdfSettings, selectePdfdSetting: selectePdfdSetting))
    }

    var body: some Scene {
        WindowGroup {
            // PDFViewerView()
            PDFListView()
                .environmentObject(drawingToolManager)
        }
    }
}

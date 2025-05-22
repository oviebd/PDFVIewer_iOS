//
//  PDFViewerApp.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 25/3/25.
//

import SwiftUI

class DrawingToolManager: ObservableObject {
  
    @Published var toolColors: [DrawingTool: UIColor] = [
        .pen: .red,
        .highlighter: .blue,
        .eraser: .gray
    ]
    
    @Published var selectedTool: DrawingTool = .none
    
    func getSelectedColor() -> UIColor {
        return toolColors[selectedTool] ?? .cyan
    }
    
}


@main
struct PDFViewerApp: App {
    
    @StateObject private var drawingToolManager = DrawingToolManager()
    
    var body: some Scene {
        WindowGroup {
            //PDFViewerView()
            PDFListView()
                .environmentObject(drawingToolManager)
        }
    }
}

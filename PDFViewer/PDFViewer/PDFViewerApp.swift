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
        .pencil: .blue,
        .highlighter: .yellow
    ]
    
    
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

//
//  PDFViewerView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 25/3/25.
//

import PDFKit
import SwiftUI



struct PDFViewerView: View {
    @State private var currentPDF: URL
    @StateObject private var pdfSettings = PDFSettings()
    @State private var drawingTool: DrawingTool = .none
    @State private var color: UIColor = .red
    @State private var lineWidth: CGFloat = 5
    @State private var zoomScale: CGFloat = 1.0
    @State private var actions = PDFKitViewActions()

    init(pdfFile: PDFModelData) {
        
        
        
        currentPDF = URL(string: pdfFile.urlPath ?? "")!  // pdfUrl
//        if let startURL = Bundle.main.url(forResource: "sample1", withExtension: "pdf") {
//            _currentPDF = State(initialValue: startURL)
//        } else {
//            _currentPDF = State(initialValue: URL(fileURLWithPath: ""))
//        }
    }

    var body: some View {
        VStack {
            PDFKitView(pdfURL: $currentPDF, settings: pdfSettings, mode: $drawingTool,
                       lineColor: $color,
                       lineWidth: $lineWidth,
                   //    zoomScale: $zoomScale,
                       actions: actions)
                .edgesIgnoringSafeArea(.all)

            HStack {
                Button("Zoom -") {
                    zoomScale = max(zoomScale - 0.2, 0.5)
                    actions.setZoomScale(scaleFactor: zoomScale)
                }
                Button("Zoom +") {
                    zoomScale = min(zoomScale + 0.2, 5.0)
                    actions.setZoomScale(scaleFactor: zoomScale)
                }
            }
            .padding()

            HStack {
                Button("Save Annotations") {
                   _ = actions.saveAnnotedPdf(url: currentPDF)
                }
            }
            .padding()

            HStack {
                Button("Switch to Horizontal") {
                    pdfSettings.displayDirection = .horizontal
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Enable Auto Scale") {
                    pdfSettings.autoScales = true
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Load New PDF") {
                    if let newURL = Bundle.main.url(forResource: "sample2", withExtension: "pdf") {
                        currentPDF = newURL
                    }
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()

            HStack {
                Button("None") { drawingTool = .none }
                Button("Pen") { drawingTool = .pen
                    //actions.setZoomScale(scaleFactor: zoomScale)
                }
                Button("Highlighter") { drawingTool = .highlighter
                    //actions.setZoomScale(scaleFactor: zoomScale)
                }
                Button("Eraser") { drawingTool = .eraser }
            }

            HStack {
                Button("Red") { color = .red }
                Button("Blue") { color = .blue }
                Button("Yellow") { color = .yellow }
            }

            Slider(value: $lineWidth, in: 1 ... 20, step: 1) {
                Text("Line Width")
            }
        }
    }
    

}

#Preview {
    PDFViewerView(pdfFile: samplePDFModelData)
}

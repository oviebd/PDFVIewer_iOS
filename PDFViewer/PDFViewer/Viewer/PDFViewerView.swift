//
//  PDFViewerView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 25/3/25.
//

import PDFKit
import SwiftUI

let sampleUrl : URL = Bundle.main.url(forResource: "sample1", withExtension: "pdf")!


let samplePDFFile = PDFFile(
    name: "Sample Document",
    url: URL(fileURLWithPath: "/path/to/sample.pdf"),
    metadata: PDFMetadata(
        image: nil, author: "Sample author", title: "Sample title"
    ),
    pdfKey: "sample_pdf_001"
)

struct PDFViewerView: View {
    @State private var currentPDF: URL
    @StateObject private var pdfSettings = PDFSettings()
    @State private var drawingTool: DrawingTool = .none
    @State private var color: UIColor = .red
    @State private var lineWidth: CGFloat = 5
    @State private var zoomScale: CGFloat = 1.0

    init(pdfFile : PDFFile) {
        currentPDF = pdfFile.url//pdfUrl
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
                       zoomScale: $zoomScale)
                .edgesIgnoringSafeArea(.all)
            
            HStack {
                           Button("Zoom -") {
                               zoomScale = max(zoomScale - 0.2, 0.5)
                           }
                           Button("Zoom +") {
                               zoomScale = min(zoomScale + 0.2, 5.0)
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
                Button("Pen") { drawingTool = .pen }
                Button("Highlighter") { drawingTool = .highlighter }
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

//            HStack {
//                Button(action: { drawingTool = .pen }) {
//                    Label("Pen", systemImage: "pencil.tip")
//                        .padding()
//                        .background(drawingTool == .pen ? Color.blue : Color.gray.opacity(0.3))
//                        .cornerRadius(10)
//                }
//
//                Button(action: { drawingTool = .highlighter }) {
//                    Label("Highlight", systemImage: "highlighter")
//                        .padding()
//                        .background(drawingTool == .highlighter ? Color.yellow : Color.gray.opacity(0.3))
//                        .cornerRadius(10)
//                }
//
//                Button(action: { drawingTool = .eraser }) {
//                    Label("Eraser", systemImage: "eraser")
//                        .padding()
//                        .background(drawingTool == .eraser ? Color.red : Color.gray.opacity(0.3))
//                        .cornerRadius(10)
//                }
//            }
        }
    }
}

#Preview {
    PDFViewerView(pdfFile: samplePDFFile)
}

//
//  PDFViewerView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 25/3/25.
//

import PDFKit
import SwiftUI

let sampleUrl: URL = Bundle.main.url(forResource: "sample1", withExtension: "pdf")!

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
    @State private var actions = PDFKitViewActions()
    @State private var savedAnnotations: Data?

    init(pdfFile: PDFFile) {
        currentPDF = pdfFile.url // pdfUrl
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
                       zoomScale: $zoomScale,
                       actions: actions)
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
                Button("Save Annotations") {
                  //  savedAnnotations = actions.saveAnnotations()
                    actions.saveAnnotedPdf(url: currentPDF)
                }

                Button("Restore Annotations") {
                    if let data = savedAnnotations {
                        actions.restoreAnnotations(from: data)
                    }
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
        }
    }
    
//    func saveAnnotatedPDF(to url: URL, pdfView: PDFView) -> Bool {
//        guard let document = pdfView.document else {
//            print("No PDF document found in PDFView")
//            return false
//        }
//        
//        let success = document.write(to: url)
//        if success {
//            print("PDF saved successfully to \(url)")
//        } else {
//            print("Failed to save PDF")
//        }
//        
//        return success
//    }
}

#Preview {
    PDFViewerView(pdfFile: samplePDFFile)
}

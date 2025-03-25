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
    @State private var annotationMode: AnnotationMode = .none

    init() {
        if let startURL = Bundle.main.url(forResource: "sample1", withExtension: "pdf") {
            _currentPDF = State(initialValue: startURL)
        } else {
            _currentPDF = State(initialValue: URL(fileURLWithPath: ""))
        }
    }

    var body: some View {
        VStack {
            PDFKitView(pdfURL: $currentPDF, settings: pdfSettings, mode: $annotationMode)
                .edgesIgnoringSafeArea(.all)

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
                Button(action: {
                    annotationMode = .highlight
                }) {
                    Image(systemName: "highlighter")
                        .padding()
                        .background(annotationMode == .highlight ? Color.yellow : Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }

                Button(action: {
                    annotationMode = .erase
                }) {
                    Image(systemName: "eraser")
                        .padding()
                        .background(annotationMode == .erase ? Color.red.opacity(0.7) : Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }

                Button(action: {
                    annotationMode = .none
                }) {
                    Image(systemName: "hand.point.up.left")
                        .padding()
                        .background(annotationMode == .none ? Color.blue.opacity(0.7) : Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
    }
}

#Preview {
    PDFViewerView()
}

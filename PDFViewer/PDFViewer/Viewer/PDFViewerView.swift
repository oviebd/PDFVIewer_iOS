//
//  PDFViewerView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 25/3/25.
//


import SwiftUI
import PDFKit

struct PDFViewerView: View {
    @Environment(\.dismiss) var dismiss

    @State private var currentPDF: URL
    @StateObject private var pdfSettings = PDFSettings()
    @State private var drawingTool: DrawingTool = .none
    @State private var color: UIColor = .red
    @State private var lineWidth: CGFloat = 5
    @State private var zoomScale: CGFloat = 1.0
    @State private var actions = PDFKitViewActions()
  
    @State private var readingMode: ReadingMode = .normal
    @State private var brightness: Double = 1.0 // 1.0 = normal, 0.0 = black
    
    @State private var showPalette = false
    @State private var showControls = true

    init(pdfFile: PDFModelData) {
        _currentPDF = State(initialValue: URL(string: pdfFile.urlPath ?? "")!)
    }

    var body: some View {
        ZStack {
            // PDF Viewer with tap to toggle controls
            PDFKitView(pdfURL: $currentPDF,
                       settings: pdfSettings,
                       mode: $drawingTool,
                       lineColor: $color,
                       lineWidth: $lineWidth,
                       actions: actions)
                .edgesIgnoringSafeArea(.all)
                .contentShape(Rectangle()) // Allows tap on empty area
                .onTapGesture {
                    // Toggle controls only if not drawing
                    if drawingTool == .none {
                        withAnimation {
                            showControls.toggle()
                        }
                    }
                }
            
            // 🌓 Reading Mode Overlay
               if let overlay = readingMode.overlayColor {
                   overlay
                       .edgesIgnoringSafeArea(.all)
                       .allowsHitTesting(false)
               }
            
            // 🌗 Brightness Overlay
            Color.black
                .opacity(1.0 - brightness)
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(false)


//            VStack(spacing: 8) {
//                Text("Brightness")
//                    .font(.caption2)
//                    .foregroundColor(.black)
//                
//                Slider(value: $brightness, in: 0...1)
//                    .frame(width: 120)
//            }
//            .padding()
//            .background(Color.white.opacity(0.9))
//            .cornerRadius(12)
            
            // Show all controls if showControls is true
            
            Button(action: { drawingTool = .text }) {
                Image(systemName: "textformat")
                    .padding()
                    .background(drawingTool == .text ? Color.blue : Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            
            if showControls {
                VStack(spacing: 0) {
                    toolbar
                    annotationView
                    Spacer()
                }

                // Floating bottom-right buttons
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Button(action: {
                                zoomScale = max(zoomScale - 0.2, 0.5)
                                actions.setZoomScale(scaleFactor: zoomScale)
                            }) {
                                Image(systemName: "minus.magnifyingglass")
                                    .font(.title)
                                    .padding()
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Circle())
                            }

                            Button(action: {
                                zoomScale = min(zoomScale + 0.2, 5.0)
                                actions.setZoomScale(scaleFactor: zoomScale)
                            }) {
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.title)
                                    .padding()
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Circle())
                            }

                            Button(action: {
                                _ = actions.saveAnnotedPdf(url: currentPDF)
                            }) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.title2)
                                    .padding()
                                    .background(Color.green.opacity(0.9))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showControls {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("PDF Viewer")
                        .font(.headline)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        
                        
                        Divider()

                              // Reading modes
                              Menu("Reading Mode") {
                                  Button("Normal") { readingMode = .normal }
                                  Button("Sepia") { readingMode = .sepia }
                                  Button("Night") { readingMode = .night }
                                  Button("Eye Comfort") { readingMode = .eyeComfort }
                              }
                        
                                Divider()
                        
                        
                        Slider(value: $brightness, in: 0...1)
                        
                        Button("Horizontal Scroll") {
                            pdfSettings.displayDirection = .horizontal
                        }
                        Button("Auto Scale") {
                            pdfSettings.autoScales = true
                        }
                        Button("Load New PDF") {
                            if let newURL = Bundle.main.url(forResource: "sample2", withExtension: "pdf") {
                                currentPDF = newURL
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .imageScale(.large)
                    }
                }
            }
        }
        .sheet(isPresented: $showPalette) {
            AnnotationDetailsView(
                thickness: $lineWidth, selectedColor: $color,
                showPalette: $showPalette
            )
            .presentationDetents([.height(250)])
            .presentationDragIndicator(.visible)
        }
    }

    var annotationView: some View {
        HStack {
            Spacer()
            AnnotationControllerView { selectedTool in
                drawingTool = selectedTool
                if selectedTool != .none {
                    withAnimation {
                        showControls = true
                    }
                    showPalette = true
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
    }

    var toolbar: some View {
        Color.clear.frame(height: 0) // keeps layout if needed
    }
}

#Preview {
    NavigationStack {
        PDFViewerView(pdfFile: samplePDFModelData)
    }
}





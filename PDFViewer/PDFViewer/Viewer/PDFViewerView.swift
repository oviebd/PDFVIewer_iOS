//
//  PDFViewerView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 25/3/25.
//



import PDFKit
import SwiftUI


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

            // Show all controls if showControls is true
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


//struct PDFViewerView: View {
//    @Environment(\.dismiss) var dismiss
//
//    @State private var currentPDF: URL
//    @StateObject private var pdfSettings = PDFSettings()
//    @State private var drawingTool: DrawingTool = .none
//    @State private var color: UIColor = .red
//    @State private var lineWidth: CGFloat = 5
//    @State private var zoomScale: CGFloat = 1.0
//    @State private var actions = PDFKitViewActions()
//    
//    @State private var showPalette = false
//
//    init(pdfFile: PDFModelData) {
//        _currentPDF = State(initialValue: URL(string: pdfFile.urlPath ?? "")!)
//    }
//
//    var body: some View {
//        ZStack(alignment: .bottom) {
//            VStack(spacing: 0) {
//                annotationView
//                    .padding(.vertical, 6)
//                    .background(Color(.systemGray6))
//
//                PDFKitView(
//                    pdfURL: $currentPDF,
//                    settings: pdfSettings,
//                    mode: $drawingTool,
//                    lineColor: $color,
//                    lineWidth: $lineWidth,
//                    actions: actions
//                )
//            }
//
//            // Floating overlay buttons
//            overlayControls
//        }
//        .navigationBarBackButtonHidden(true)
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button(action: {
//                    dismiss()
//                }) {
//                    Image(systemName: "chevron.left")
//                    Text("Back")
//                }
//            }
//
//            ToolbarItem(placement: .principal) {
//                Text("PDF Viewer")
//                    .font(.headline)
//            }
//
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Menu {
//                    Button("Horizontal Scroll") {
//                        pdfSettings.displayDirection = .horizontal
//                    }
//                    Button("Auto Scale") {
//                        pdfSettings.autoScales = true
//                    }
//                    Button("Load New PDF") {
//                        if let newURL = Bundle.main.url(forResource: "sample2", withExtension: "pdf") {
//                            currentPDF = newURL
//                        }
//                    }
//                } label: {
//                    Image(systemName: "ellipsis.circle")
//                        .imageScale(.large)
//                }
//            }
//        }
//        .sheet(isPresented: $showPalette) {
//            AnnotationDetailsView(
//                selectedColor: $color,
//                showPalette: $showPalette
//            )
//            .presentationDetents([.height(250)])
//            .presentationDragIndicator(.visible)
//        }
//    }
//
//
//    var annotationView: some View {
//        HStack {
//            Spacer()
//            AnnotationControllerView { selectedTool in
//                self.drawingTool = selectedTool
//                if selectedTool != .none {
//                    showPalette = true
//                }
//            }
//            Spacer()
//        }
//    }
//
//    var overlayControls: some View {
//        HStack {
//            // Save Annotation Floating Button (Bottom Left)
//            Button(action: {
//                _ = actions.saveAnnotedPdf(url: currentPDF)
//            }) {
//                Image(systemName: "square.and.arrow.down")
//                    .font(.system(size: 22, weight: .bold))
//                    .padding()
//                    .background(Color.blue.opacity(0.9))
//                    .foregroundColor(.white)
//                    .clipShape(Circle())
//                    .shadow(radius: 4)
//            }
//            .padding(.leading, 20)
//
//            Spacer()
//
//            // Zoom Buttons (Bottom Right)
//            VStack(spacing: 12) {
//                Button(action: {
//                    zoomScale = min(zoomScale + 0.2, 5.0)
//                    actions.setZoomScale(scaleFactor: zoomScale)
//                }) {
//                    Image(systemName: "plus.magnifyingglass")
//                        .font(.system(size: 22, weight: .none))
//                        .padding(5)
//                        .background(Color.gray.opacity(0.5))
//                        .foregroundColor(.white)
//                        .clipShape(Circle())
//                        .shadow(radius: 4)
//                }
//
//                Button(action: {
//                    zoomScale = max(zoomScale - 0.2, 0.5)
//                    actions.setZoomScale(scaleFactor: zoomScale)
//                }) {
//                    Image(systemName: "minus.magnifyingglass")
//                        .font(.system(size: 22, weight: .none))
//                        .padding(5)
//                        .background(Color.gray.opacity(0.5))
//                        .foregroundColor(.white)
//                        .clipShape(Circle())
//                        .shadow(radius: 4)
//                }
//            }
//            .padding(.trailing, 20)
//        }
//        .padding(.bottom, 30)
//    }
//}

#Preview {
    NavigationStack {
        PDFViewerView(pdfFile: samplePDFModelData)
    }
}





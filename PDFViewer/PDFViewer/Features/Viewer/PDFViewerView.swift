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
    @EnvironmentObject var drawingToolManager: DrawingToolManager

    
    @State var pdfData : PDFModelData
    @State private var currentPDF: URL
    @StateObject private var pdfSettings = PDFSettings()
    
    @State private var drawingTool: PDFAnnotationSetting = PDFAnnotationSetting.noneData()

    @State private var zoomScale: CGFloat = 1.0
    @State private var actions = PDFKitViewActions()
  
    @State private var readingMode: ReadingMode = .normal
    
    
    @State private var showPalette = false
    @State private var showControls = true


    init(pdfFile: PDFModelData) {
        self.pdfData = pdfFile
        _currentPDF = State(initialValue: URL(string: pdfFile.urlPath ?? "")!)
    }

    var body: some View {
        ZStack {
            
            Color(.systemGray6)
            
                
            
            // PDF Viewer with tap to toggle controls
            PDFKitView(pdfURL: $currentPDF,
                       settings: pdfSettings,
                       mode: $drawingTool,
                       actions: actions)
          //  .id(pdfSettings.annotationSetting)
                .edgesIgnoringSafeArea(.all)
                .contentShape(Rectangle()) // Allows tap on empty area
                .onTapGesture {
                    // Toggle controls only if not drawing
                    if drawingTool.annotationTool == .none {
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


            // Show all controls if showControls is true
            if showControls {
                VStack(spacing: 0) {
                    toolbar
                    annotationView
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
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
        
        
     //   .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showControls {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button(action: {
//                        dismiss()
//                    }) {
//                        Image(systemName: "chevron.left")
//                    }
//                }

                
                ToolbarItem(placement: .principal) {
                    Text(pdfData.title ?? "Unknown file")
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
            AnnotationSettingsView(
                showPalette: $showPalette, annotationSetting: $drawingTool
                ,onDataChanged: {
                    onAnnotationDataChanged(annotationSettingData: drawingTool)
                })
            .presentationDetents([.height(250)])
            .presentationDragIndicator(.visible)
        }
    }

    var annotationView: some View {
        HStack {
            Spacer()
            AnnotationControllerView( annotationSettingItems: drawingToolManager.pdfSettings,
                                      onDrawingToolSelected: { tool in
                onAnnotationDataChanged(annotationSettingData: tool)
            }, onPalettePressed: { tool in
//                drawingTool = tool
//                drawingToolManager.selectePdfdSetting = drawingTool
                onAnnotationDataChanged(annotationSettingData: tool)
                if drawingToolManager.selectePdfdSetting.annotationTool != .none {
                    showControls = true
                    showPalette = true
                }
            })
            Spacer()
        }
     //   .padding(.vertical, 6)
        .padding()
        .background(Color(.white))
//        .background(Color(.systemGray6))
       // .padding()
    }

    var toolbar: some View {
        Color.clear.frame(height: 0) // keeps layout if needed
    }
    
    func onAnnotationDataChanged(annotationSettingData: PDFAnnotationSetting){
        drawingTool = annotationSettingData
        drawingToolManager.selectePdfdSetting = drawingTool
        drawingToolManager.updatePdfSettingData(newSetting: drawingTool)
    }
}

#Preview {
    NavigationStack {
        PDFViewerView(pdfFile: samplePDFModelData)
            .environmentObject(DrawingToolManager.dummyData())
    }
}





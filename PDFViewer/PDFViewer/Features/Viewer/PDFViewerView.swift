//
//  PDFViewerView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 25/3/25.
//

import Combine
import PDFKit
import SwiftUI

struct PDFViewerView: View {
   
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var drawingToolManager: DrawingToolManager
    @StateObject private var viewModel: PDFViewerViewModel
    

    init(pdfFile: PDFModelData) {
        let store = try? PDFLocalDataStore()
        let repo = PDFLocalRepositoryImpl(store: store!)

        _viewModel = StateObject(wrappedValue: PDFViewerViewModel(pdfFile: pdfFile, repository: repo))

    }

    var body: some View {
        ZStack {
            Color(.systemGray6).edgesIgnoringSafeArea(.all)

            pdfContent
            readingOverlay

            Color.black
                .opacity(viewModel.getBrightnessOpacity())
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(false)

            if viewModel.showControls {
                overlayControls
            }
        }
        .onDisappear {
            viewModel.stopTrackingProgress()
            viewModel.updatePdfDataInDb()
        }
        .onAppear{
            viewModel.startTrackingProgress()
            viewModel.goToPage()
        }

        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(!viewModel.showControls)
        .toolbar { toolbarContent() }

        .sheet(isPresented: $viewModel.showPalette) {
            annotationSettingsSheet
        }

        .sheet(isPresented: $viewModel.showBrightnessControls) {
            brightnessSettingsSheet
        }
    }
    
    
}



#Preview {
    NavigationStack {
        PDFViewerView(pdfFile: samplePDFModelData)
            .environmentObject(DrawingToolManager.dummyData())
    }
}

extension PDFViewerView {
    var pdfContent: some View {
        PDFKitView(
            pdfURL: $viewModel.currentPDF,
            settings: viewModel.settings,
            mode: $viewModel.annotationSettingData,
            actions: viewModel.actions
        )
        .onTapGesture {
            if viewModel.annotationSettingData.annotationTool == .none {
                withAnimation { viewModel.showControls.toggle() }
            }
        }
    }

    var readingOverlay: some View {
        Group {
            if let overlay = viewModel.readingMode.overlayColor {
                overlay.edgesIgnoringSafeArea(.all).allowsHitTesting(false)
            }
        }
    }

    var overlayControls: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 0)
            annotationControls
            Spacer()
            floatingButtons
        }
    }
}

extension PDFViewerView {
    var annotationControls: some View {
        HStack {
            Spacer()
            AnnotationListControllerView(
                annotationSettingItems: drawingToolManager.pdfSettings,
                onDrawingToolSelected: {
                    viewModel.updateAnnotationSetting($0, manager: drawingToolManager)
                },
                onPalettePressed: {
                    viewModel.updateAnnotationSetting($0, manager: drawingToolManager)
                    if $0.annotationTool != .none {
                        viewModel.showControls = true
                        viewModel.showPalette = true
                    }
                }
            )

            Button {
                viewModel.showBrightnessControls = true

            } label: {
                Image(systemName: "sun.max.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    // .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.gray.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .shadow(radius: 4)
    }

    var floatingButtons: some View {
        HStack {
            Spacer()
            VStack(spacing: 16) {
                ControlButton(systemName: "minus.magnifyingglass", action: viewModel.zoomOut)
                ControlButton(systemName: "plus.magnifyingglass", action: viewModel.zoomIn)
                ControlButton(systemName: "square.and.arrow.down", color: .green, foreground: .white, action: viewModel.savePDF)
            }
            .padding()
        }
    }

    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(viewModel.pdfData.title ?? "Unknown file").font(.headline)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Menu("Reading Mode") {
                    Button("Normal") { viewModel.readingMode = .normal }
                    Button("Sepia") { viewModel.readingMode = .sepia }
                    Button("Night") { viewModel.readingMode = .night }
                    Button("Eye Comfort") { viewModel.readingMode = .eyeComfort }
                }
                Divider()
                Button("Horizontal Scroll") { viewModel.settings.displayDirection = .horizontal }
                Button("Auto Scale") { viewModel.settings.autoScales = true }
                Button("Load New PDF") {
                    if let newURL = Bundle.main.url(forResource: "sample2", withExtension: "pdf") {
                        viewModel.currentPDF = newURL
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle").imageScale(.large)
            }
        }
    }
}

extension PDFViewerView {
    var annotationSettingsSheet: some View {
        AnnotationSettingsView(
            showPalette: $viewModel.showPalette,
            annotationSetting: $viewModel.annotationSettingData,
            onDataChanged: {
                viewModel.updateAnnotationSetting(viewModel.annotationSettingData, manager: drawingToolManager)
            }
        )
        .presentationDetents([.height(250)])
        .presentationDragIndicator(.visible)
    }

    var brightnessSettingsSheet: some View {
        BrightnessSettingPopupView(showPalette: $viewModel.showBrightnessControls,
                                   value: viewModel.displayBrightness) {
            newValue in
            viewModel.displayBrightness = newValue
        }
        .presentationDetents([.height(250)])
        .presentationDragIndicator(.visible)
    }
}

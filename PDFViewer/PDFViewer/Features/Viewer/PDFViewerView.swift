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
            Color(.systemGray6).ignoresSafeArea()

            VStack(spacing: 0) {
                pdfContent
            }

            readingOverlay

            overlayControls

            Color.black
                .opacity(viewModel.getBrightnessOpacity())
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(false)

            //pageProgressText
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showControls)

        .onAppear {
            viewModel.updateLastOpenedtime()
            viewModel.startTrackingProgress()
            viewModel.goToPage()
        }
        .onDisappear {
            viewModel.unloadPdfData()
            drawingToolManager.selectePdfdSetting = .noneData()
        }

        .navigationBarHidden(true)

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
        Group {
            if let currentPDFURL = viewModel.currentPDF {
                PDFKitView(
                    pdfURL: currentPDFURL,
                    settings: viewModel.settings,
                    mode: $viewModel.annotationSettingData,
                    actions: viewModel.actions
                )
                .ignoresSafeArea()
                .onTapGesture {
                    if viewModel.annotationSettingData.annotationTool == .none {
                        withAnimation {
                            viewModel.showControls.toggle()
                        }
                    }
                }
            } else {
                Text("No data")
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
            if viewModel.showControls {
                topBarOverlay
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Spacer()
            
            floatingButtons
            
            if viewModel.showControls {
                bottomAnnotationBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

extension PDFViewerView {
    var bottomAnnotationBar: some View {
        HStack(spacing: 8) {
            // Undo/Redo Group
            HStack(spacing: 20) {
                Button(action: viewModel.undo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(viewModel.canUndo ? .blue : Color(red: 0.2, green: 0.25, blue: 0.35).opacity(0.3))
                }
                .disabled(!viewModel.canUndo)

                Button(action: viewModel.redo) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(viewModel.canRedo ? .blue : Color(red: 0.2, green: 0.25, blue: 0.35).opacity(0.3))
                }
                .disabled(!viewModel.canRedo)
            }
            .padding(.horizontal, 24)
            .frame(height: 56)
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            .cornerRadius(16)

            // Tools Group
            HStack(spacing: 0) {
                AnnotationListControllerView(
                    annotationSettingItems: drawingToolManager.pdfSettings,
                    onDrawingToolSelected: {
                        viewModel.selectTool($0, manager: drawingToolManager)
                    },
                    onPalettePressed: { _ in }
                )
            }
            .padding(.horizontal, 12)
            .frame(height: 56)
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            .cornerRadius(16)

            // Color Indicator Group
            HStack {
                Button(action: {
                    if viewModel.annotationSettingData.annotationTool != .none && viewModel.annotationSettingData.annotationTool != .eraser {
                        viewModel.showPalette = true
                    }
                }) {
                    ZStack {
                        let isInactive = viewModel.annotationSettingData.annotationTool == .none || viewModel.annotationSettingData.annotationTool == .eraser
                        Circle()
                            .fill(isInactive ? Color(viewModel.lastDrawingColor) : Color(viewModel.annotationSettingData.color))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(isInactive ? 0 : 0.1), radius: 4, x: 0, y: 2)
                    }
                    .frame(width: 48, height: 48)
                    .background(Color(red: 0.96, green: 0.97, blue: 0.98).opacity((viewModel.annotationSettingData.annotationTool == .none || viewModel.annotationSettingData.annotationTool == .eraser) ? 0.5 : 1.0))
                    .cornerRadius(16)
                    .opacity((viewModel.annotationSettingData.annotationTool == .none || viewModel.annotationSettingData.annotationTool == .eraser) ? 0.6 : 1.0)
                }
                .disabled(viewModel.annotationSettingData.annotationTool == .none || viewModel.annotationSettingData.annotationTool == .eraser)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    var floatingButtons: some View {
        HStack {
            Spacer()
            VStack(spacing: 16) {
                ControlButton(systemName: "minus.magnifyingglass", action: viewModel.zoomOut)
                ControlButton(systemName: "plus.magnifyingglass", action: viewModel.zoomIn)
                ControlButton(systemName: "square.and.arrow.down", color: .green, foreground: .white, action: viewModel.savePDFWithAnnotation)
            }
            .padding()
        }
    }

    var topBarOverlay: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(viewModel.pdfData.title ?? "Unknown file")
                        .font(.headline)
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    Text(viewModel.pageProgressText)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button {
                        viewModel.showBrightnessControls = true
                    } label: {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.black)
                    }

                    Menu {
                        Menu("Reading Mode") {
                            Button("Normal") { viewModel.onReadingModeChanged(readingMode: .normal) }
                            Button("Sepia") { viewModel.onReadingModeChanged(readingMode: .sepia) }
                            Button("Night") { viewModel.onReadingModeChanged(readingMode: .night) }
                            Button("Eye Comfort") { viewModel.onReadingModeChanged(readingMode: .eyeComfort) }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.black)
                    }
                }
            }
            .padding()
            .background(
                Color.white
                    .ignoresSafeArea(edges: .top)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
    }
}

extension PDFViewerView {
    var pageProgressText: some View {
        VStack {
            Spacer()
            HStack {
                Text(viewModel.pageProgressText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(6)
                    .shadow(radius: 3)

                Spacer()
            }
            .padding([.leading, .bottom], 12)
        }
    }
}

extension PDFViewerView {
    var annotationSettingsSheet: some View {
        AnnotationSettingsView(
            showPalette: $viewModel.showPalette,
            annotationSetting: $viewModel.annotationSettingData,
            onDataChanged: {
                viewModel.updateAnnotationData(viewModel.annotationSettingData, manager: drawingToolManager)
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

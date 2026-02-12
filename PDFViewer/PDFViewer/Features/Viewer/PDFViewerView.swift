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
            AppColors.surfaceSecondary.ignoresSafeArea()

            VStack(spacing: 0) {
                pdfContent
            }

            readingOverlay

            overlayControls

            Color.black
                .opacity(viewModel.getBrightnessOpacity())
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(false)

            if viewModel.isSavingPDF {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: AppSpacing.md) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Saving PDF...")
                            .font(AppFonts.headline)
                            .foregroundColor(.white)
                    }
                    .padding(AppSpacing.xl)
                    .background(Color(.systemGray6).opacity(0.8))
                    .cornerRadius(AppSpacing.cornerRadiusLG)
                }
                .zIndex(300)
            }

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
        
        .overlay {
            if viewModel.showSaveSuccess {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            viewModel.showSaveSuccess = false
                        }
                    
                    SaveSuccessModalView(
                        fileName: viewModel.successFileName,
                        fileLocation: viewModel.successFileLocation,
                        onOpenLocation: {
                            viewModel.openSavedLocation()
                            viewModel.showSaveSuccess = false
                        },
                        onShare: {
                            viewModel.showSaveSuccess = false
                            viewModel.showShareSheet = true
                        },
                        onClose: {
                            viewModel.showSaveSuccess = false
                            viewModel.shareURL = nil
                            viewModel.showShareSheet = false
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                .zIndex(200)
            }
        }
        .animation(.spring(), value: viewModel.showSaveSuccess)
        
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = viewModel.shareURL {
                ActivityView(activityItems: [url])
            }
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
                Text(AppStrings.PDFInfo.noData)
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
        HStack(spacing: AppSpacing.xs) {
            // Undo/Redo Group
            HStack(spacing: AppSpacing.lg) {
                Button(action: viewModel.undo) {
                    Image(systemName: AppImages.undo)
                        .font(AppFonts.undoRedo)
                        .foregroundColor(viewModel.canUndo ? AppColors.primary : AppColors.disabledToolColor)
                }
                .disabled(!viewModel.canUndo)

                Button(action: viewModel.redo) {
                    Image(systemName: AppImages.redo)
                        .font(AppFonts.undoRedo)
                        .foregroundColor(viewModel.canRedo ? AppColors.primary : AppColors.disabledToolColor)
                }
                .disabled(!viewModel.canRedo)
            }
            .padding(.horizontal, AppSpacing.xl)
            .frame(height: AppSpacing.toolbarHeight)
            .background(AppColors.surfaceLight)
            .cornerRadius(AppSpacing.cornerRadiusLG)

            HStack(spacing: 0) {
                AnnotationListControllerView(
                    annotationSettingItems: drawingToolManager.pdfSettings,
                    onDrawingToolSelected: {
                        viewModel.selectTool($0, manager: drawingToolManager)
                    },
                    onPalettePressed: { _ in }
                )
            }
            .padding(.horizontal, AppSpacing.sm)
            .frame(height: AppSpacing.toolbarHeight)
            .background(AppColors.surfaceLight)
            .cornerRadius(AppSpacing.cornerRadiusLG)

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
                            .frame(width: AppSpacing.colorIndicatorMedium, height: AppSpacing.colorIndicatorMedium)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.onPrimary.opacity(0.8), lineWidth: AppSpacing.circleStroke)
                            )
                            .shadow(color: AppColors.shadowLight.opacity(isInactive ? 0 : 1), radius: AppSpacing.shadowRadiusLight, x: 0, y: 2)
                    }
                    .frame(width: AppSpacing.colorIndicatorContainer, height: AppSpacing.colorIndicatorContainer)
                    .background(AppColors.surfaceLight.opacity((viewModel.annotationSettingData.annotationTool == .none || viewModel.annotationSettingData.annotationTool == .eraser) ? 0.5 : 1.0))
                    .cornerRadius(AppSpacing.cornerRadiusLG)
                    .opacity((viewModel.annotationSettingData.annotationTool == .none || viewModel.annotationSettingData.annotationTool == .eraser) ? 0.6 : 1.0)
                }
                .disabled(viewModel.annotationSettingData.annotationTool == .none || viewModel.annotationSettingData.annotationTool == .eraser)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(
            Capsule()
                .fill(AppColors.overlayBackground)
                .shadow(color: AppColors.shadowLight, radius: AppSpacing.shadowRadiusHeavy, x: 0, y: 10)
        )
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.lg)
    }

    var floatingButtons: some View {
        HStack {
            Spacer()
            VStack(spacing: AppSpacing.md) {
                ControlButton(systemName: AppImages.zoomOut, action: viewModel.zoomOut)
                ControlButton(systemName: AppImages.zoomIn, action: viewModel.zoomIn)
                ControlButton(systemName: AppImages.download, color: AppColors.success, foreground: AppColors.onPrimary, action: viewModel.savePDFWithAnnotation)
            }
            .padding()
        }
    }

    var topBarOverlay: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: AppImages.back)
                        .font(AppFonts.iconMedium)
                        .foregroundColor(AppColors.primary)
                }
                
                Spacer()
                
                VStack(spacing: AppSpacing.xxs) {
                    Text(viewModel.pdfData.title ?? AppStrings.PDFInfo.unknownFile)
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(viewModel.pageProgressText)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(.horizontal, AppSpacing.xxxl)
                
                Spacer()
                
                HStack(spacing: AppSpacing.md) {
                    Button {
                        viewModel.showBrightnessControls = true
                    } label: {
                        Image(systemName: AppImages.brightness)
                            .font(AppFonts.iconMedium)
                            .foregroundColor(AppColors.textPrimary)
                    }

                    Menu {
                        Menu(AppStrings.ReadingMode.title) {
                            Button(AppStrings.ReadingMode.normal) { viewModel.onReadingModeChanged(readingMode: .normal) }
                            Button(AppStrings.ReadingMode.sepia) { viewModel.onReadingModeChanged(readingMode: .sepia) }
                            Button(AppStrings.ReadingMode.night) { viewModel.onReadingModeChanged(readingMode: .night) }
                            Button(AppStrings.ReadingMode.eyeComfort) { viewModel.onReadingModeChanged(readingMode: .eyeComfort) }
                        }
                    } label: {
                        Image(systemName: AppImages.more)
                            .font(AppFonts.iconMedium)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .padding()
            .background(
                AppColors.overlayBackground
                    .ignoresSafeArea(edges: .top)
                    .shadow(color: AppColors.shadowLight, radius: 2, x: 0, y: 1)
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
                    .font(AppFonts.pageProgress)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.xs)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(AppColors.overlayBackground.opacity(0.9))
                    .cornerRadius(AppSpacing.cornerRadiusSM)
                    .shadow(radius: 3)

                Spacer()
            }
            .padding([.leading, .bottom], AppSpacing.sm)
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

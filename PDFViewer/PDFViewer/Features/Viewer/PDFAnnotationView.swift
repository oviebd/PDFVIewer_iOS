//
//  PDFAnnotationView.swift
//  PDFViewer
//
//  Created by Antigravity on 12/2/26.
//

import SwiftUI

struct PDFAnnotationView: View {
    @ObservedObject var viewModel: AnnotationViewModel
    @EnvironmentObject var drawingToolManager: DrawingToolManager
    var showControls: Bool
    
    var body: some View {
        ZStack {
            if showControls {
                VStack {
                    Spacer()
                    bottomAnnotationBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            if viewModel.isExportingPDF {
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
        }
        .sheet(isPresented: $viewModel.showPalette) {
            annotationSettingsSheet
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
    
    var bottomAnnotationBar: some View {
        HStack(spacing: AppSpacing.xs) {
            // Undo/Redo Group
            HStack(spacing: AppSpacing.lg) {
                Button(action: viewModel.undo) {
                    Image(systemName: AppImages.undo)
                        .font(AppFonts.undoRedo)
                        .foregroundColor(viewModel.canUndo ? AppColors.primary : AppColors.disabledToolColor)
                }
                .disabled(!viewModel.canUndo && SubscriptionManager.shared.isAnnotationHistoryAllowed)

                Button(action: viewModel.redo) {
                    Image(systemName: AppImages.redo)
                        .font(AppFonts.undoRedo)
                        .foregroundColor(viewModel.canRedo ? AppColors.primary : AppColors.disabledToolColor)
                }
                .disabled(!viewModel.canRedo && SubscriptionManager.shared.isAnnotationHistoryAllowed)
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
}

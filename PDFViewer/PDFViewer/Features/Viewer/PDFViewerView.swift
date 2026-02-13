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
    @StateObject private var subscriptionVM = SubscriptionPlanViewModel()

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

            PDFAnnotationView(viewModel: viewModel.annotationViewModel, showControls: viewModel.showControls)
                .zIndex(200)

            if viewModel.showGoToPageDialog {
                GoToPageDialog(
                    isPresented: $viewModel.showGoToPageDialog,
                    totalPages: viewModel.getTotalPages(),
                    onGo: { page in
                        viewModel.jumpToPage(page)
                    }
                )
                .zIndex(300)
            }

            // pageProgressText
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showControls)

        .onAppear {
            viewModel.updateLastOpenedtime()
            viewModel.startTrackingProgress()
            viewModel.goToPage()
            
            viewModel.annotationViewModel.onPremiumRestricted = { message in
                subscriptionVM.showPremiumAlert(message: message)
            }
        }
        .onDisappear {
            viewModel.unloadPdfData()
            drawingToolManager.selectePdfdSetting = .noneData()
        }

        .navigationBarHidden(true)

        .sheet(isPresented: $viewModel.showBrightnessControls) {
            brightnessSettingsSheet
        }
        .premiumFeatureAlert(
            isPresented: $subscriptionVM.isShowingPremiumAlert,
            title: subscriptionVM.premiumAlertTitle,
            message: subscriptionVM.premiumAlertMessage
        ) {
            subscriptionVM.isShowingPaywall = true
        }
        .fullScreenCover(isPresented: $subscriptionVM.isShowingPaywall) {
            PlanPage()
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
                    mode: $viewModel.annotationViewModel.annotationSettingData,
                    actions: viewModel.actions
                )
                .ignoresSafeArea()
                .onTapGesture {
                    if viewModel.annotationViewModel.annotationSettingData.annotationTool == .none {
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

                Spacer()

                floatingButtons
            }
        }
    }
}

extension PDFViewerView {
    var floatingButtons: some View {
        HStack {
            Spacer()
            VStack(spacing: AppSpacing.md) {
                ControlButton(systemName: AppImages.zoomOut, action: viewModel.zoomOut)
                ControlButton(systemName: AppImages.zoomIn, action: viewModel.zoomIn)
            }
        }
        .padding()
        .padding(.bottom, 100)
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

                    Button {
                        if SubscriptionManager.shared.isGoToPageAllowed {
                            viewModel.showGoToPageDialog = true
                        } else {
                            subscriptionVM.showPremiumAlert(message: subscriptionVM.goToPageRestrictedMessage)
                        }
                    } label: {
                        Text(viewModel.pageProgressText)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .padding(.horizontal, AppSpacing.xxxl)

                Spacer()

                HStack(spacing: AppSpacing.md) {
                    Button {
                        viewModel.annotationViewModel.exportPdf()
                    } label: {
                        Image(systemName: AppImages.download)
                            .font(AppFonts.iconMedium)
                            .foregroundColor(AppColors.textPrimary)
                    }

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
                Button {
                    viewModel.showGoToPageDialog = true
                } label: {
                    Text(viewModel.pageProgressText)
                        .font(AppFonts.pageProgress)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(AppColors.overlayBackground.opacity(0.9))
                        .cornerRadius(AppSpacing.cornerRadiusSM)
                        .shadow(radius: 3)
                }

                Spacer()
            }
            .padding([.leading, .bottom], AppSpacing.sm)
        }
    }
}

extension PDFViewerView {
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

//
//  AnnotationDetailsView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI

struct AnnotationSettingsView: View {
    @Binding var showPalette: Bool

    @Binding var annotationSetting: PDFAnnotationSetting
    var onDataChanged: (() -> Void)?
   
    let colors: [UIColor] = AppColors.annotationColors

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            
            CustomSliderView(
                title: AppStrings.Annotation.setWidth,
                startValue: 2,
                endValue: 50,
                currentValue: annotationSetting.lineWidth,
                iconName: AppImages.lineSettings,
                iconColor: annotationSetting.color
            ) { newValue in
                annotationSetting.lineWidth = newValue
            }

            HStack {
                ForEach(colors, id: \.self) { color in
                    Button(action: {
                        annotationSetting.color = color
                        onDataChanged?()
                    }) {
                        Circle()
                            .fill(Color(color))
                            .frame(width: AppSpacing.colorIndicatorSmall, height: AppSpacing.colorIndicatorSmall)
                            .shadow(radius: 2)
                    }
                }

                Spacer()
            }

            Button(action: {
                withAnimation {
                    onDataChanged?()
                    showPalette = false
                }
            }) {
                Text(AppStrings.Navigation.ok)
                    .foregroundColor(AppColors.onPrimary)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, 5)
                    .background(AppColors.primary)
                    .cornerRadius(AppSpacing.cornerRadiusXS)
            }
        }
        .padding()
    }
}

 #Preview {
     AnnotationSettingsView(showPalette: .constant(true), annotationSetting: .constant(.dummyData()))
 }

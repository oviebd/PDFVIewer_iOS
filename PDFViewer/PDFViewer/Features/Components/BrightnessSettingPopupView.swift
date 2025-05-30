//
//  BrightnessSettingPopupView.swift
//  PDFViewer
//
//  Created by Habibur_Periscope on 29/5/25.
//

import SwiftUI

struct BrightnessSettingPopupView: View {
    @Binding var showPalette: Bool
    @State var value: CGFloat

    var onDataChanged: ((CGFloat) -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            CustomSliderView(title: "Set Brightness", startValue: 20, endValue: 100, currentValue: value, iconName: "sun.max.fill", iconColor: UIColor.blue) { newValue in
                value = newValue
                onDataChanged?(value)
            }
        }.padding()
    }
}

#Preview {
    BrightnessSettingPopupView(showPalette: .constant(false), value: 50)
}

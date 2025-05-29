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
            LineWidthSliderView(title: "Set Brightness", startValue: 20, endValue: 100, currentValue: value, iconName: "sun.max.fill", iconColor: UIColor.blue) { newValue in
                value = newValue
                onDataChanged?(value)
            }

//            Button(action: {
//                withAnimation {
//                    onDataChanged?(value)
//                    showPalette = false
//                }
//            }) {
//                Text("Ok")
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 20)
//                    .padding(.vertical, 5)
//                    .background(Color.blue)
//                    .cornerRadius(4)
//            }
            // .padding(.bottom)
        }.padding()
    }
}

#Preview {
    BrightnessSettingPopupView(showPalette: .constant(false), value: 50)
}

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
   
    let colors: [UIColor] = [.red, .green, .blue, .yellow, .orange, .purple, .black, .gray]

    var body: some View {
        VStack(spacing: 16) {
            
            LineWidthSliderView(title: "Set Width", startValue: 2, endValue: 50, currentValue:  annotationSetting.lineWidth, iconName: "line.3.horizontal", iconColor: annotationSetting.color){ newValue in
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
                            .frame(width: 25, height: 25)
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
                Text("Ok")
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .cornerRadius(4)
            }
            // .padding(.bottom)
        }.padding()
    }
}

 #Preview {
     AnnotationSettingsView( showPalette: .constant(true), annotationSetting: .constant(.dummyData()))
 }

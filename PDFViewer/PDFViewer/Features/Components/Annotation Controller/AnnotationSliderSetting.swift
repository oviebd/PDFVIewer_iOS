//
//  Extra.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 14/4/25.
//

import SwiftUI


struct AnnotationSliderSetting: View {
    @Binding var annotationSetting: PDFAnnotationSetting
    
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Set Line Width")
                .font(.headline)

            HStack {
                ZStack(alignment: .bottom) {
                    // Base icon in gray
                    Image(systemName: "line.3.horizontal")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)

                    // Filled icon in selected color with bottom-to-top masking
                    Image(systemName: "line.3.horizontal")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(Color(annotationSetting.color))
                        .mask(
                            Rectangle()
                                .frame(height: CGFloat((annotationSetting.lineWidth - 2) / 48) * 30)
                                .offset(y: (1 - CGFloat((annotationSetting.lineWidth - 2) / 48)) * 15)
                        )
                }

                Slider(value: $annotationSetting.lineWidth, in: 2...50, step: 1)
                    .accentColor(Color(annotationSetting.color))

                Text("\(Int(annotationSetting.lineWidth)) pt")
                    .frame(width: 60, alignment: .trailing)
            }
        }
        .padding()
    }
}

#Preview {
    AnnotationSliderSetting(annotationSetting: .constant(PDFAnnotationSetting.dummyData()))
}

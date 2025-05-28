//
//  Extra.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 14/4/25.
//

import SwiftUI

struct Extra: View {
   
    @Binding var annotationSetting : PDFAnnotationSetting

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Thickness")
                .font(.subheadline)

            HStack(spacing: 0) {
                Group{
                    Circle()
                        .fill(Color(annotationSetting.color))
                        .frame(width: getThickness() / 2, height: getThickness() / 2)
                        .overlay(Circle().stroke(Color.primary.opacity(0.3), lineWidth: 1))
                        .animation(.easeInOut, value: getThickness())
                }.frame(width: 50, height: 50)
              

                Slider(value: $annotationSetting.lineWidth, in: 1 ... 70, step: 1)
                    .accentColor(Color(annotationSetting.color))

                Text("\(Int(getThickness()))")
                    .font(.caption)
                    .padding(.leading,15)

            }.frame(height: 30)

        }
        
        
    }
    
    func getThickness() -> CGFloat {
        return annotationSetting.lineWidth
    }
}

#Preview {
    Extra(annotationSetting: .constant(PDFAnnotationSetting.dummyData()))
}

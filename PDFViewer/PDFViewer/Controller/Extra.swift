//
//  Extra.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 14/4/25.
//

import SwiftUI

struct Extra: View {
   
    @Binding var thickness: CGFloat
    @Binding var selectedColor: UIColor

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Thickness")
                .font(.subheadline)

            HStack(spacing: 0) {
                Group{
                    Circle()
                        .fill(Color(selectedColor))
                        .frame(width: thickness / 2, height: thickness / 2)
                        .overlay(Circle().stroke(Color.primary.opacity(0.3), lineWidth: 1))
                        .animation(.easeInOut, value: thickness)
                }.frame(width: 50, height: 50)
              

                Slider(value: $thickness, in: 1 ... 70, step: 1)
                    .accentColor(Color(selectedColor))

                Text("\(Int(thickness))")
                    .font(.caption)
                    .padding(.leading,15)

            }.frame(height: 30)

        }
    }
}

#Preview {
    Extra(thickness: .constant(10.0), selectedColor: .constant(UIColor.black))
}

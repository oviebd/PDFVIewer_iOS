//
//  AnnotationDetailsView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI

struct AnnotationDetailsView: View {
    @Binding var thickness : CGFloat
    @Binding var selectedColor: UIColor
    @Binding var showPalette: Bool

    let colors: [UIColor] = [.red, .green, .blue, .yellow, .orange, .purple, .black, .gray]

    var body: some View {
        VStack(spacing: 16) {
            
            Extra(thickness: $thickness, selectedColor: $selectedColor)
                
            HStack {
                ForEach(colors, id: \.self) { color in
                    Button(action: {
                        selectedColor = color
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
        }  .padding()
    }
}

#Preview {
    AnnotationDetailsView(thickness: .constant(10.0), selectedColor: .constant(.red), showPalette: .constant(true))
}

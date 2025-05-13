//
//  AnnotationDetailsView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI

struct AnnotationDetailsView: View {
    @Binding var selectedColor: UIColor
    @Binding var showPalette: Bool

//    let colors: [Color] = [.red, .green, .blue, .yellow, .orange, .purple, .pink, .black, .gray]
    let colors: [UIColor] = [.red, .green, .blue, .yellow, .orange, .purple]

    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Color")
                .font(.headline)
                .padding(.top)

            HStack {
                ForEach(colors, id: \.self) { color in
                    Button(action: {
                        selectedColor = color
                        withAnimation {
                            showPalette = false
                        }
                    }) {
                        Circle()
                            .fill(Color(color))
                            .frame(width: 25, height: 25)
                            .shadow(radius: 2)
                    }
                }
            }
            .padding()

            Button(action: {
                withAnimation {
                    showPalette = false
                }
            }) {
                Text("Close")
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray)
                    .cornerRadius(10)
            }
            .padding(.bottom)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}

#Preview {
    AnnotationDetailsView(selectedColor: .constant(.red), showPalette: .constant(true))
}

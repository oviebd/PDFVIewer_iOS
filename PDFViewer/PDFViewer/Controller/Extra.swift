//
//  Extra.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 14/4/25.
//

import SwiftUI

struct Extra: View {
  
        @State private var thickness: Double = 10.0

        // You can change this to your selected color
        let selectedColor: Color = .blue

        var body: some View {
            VStack(spacing: 30) {
                // Live preview: circle that changes size with the slider
                Circle()
                    .fill(selectedColor)
                    .frame(width: thickness, height: thickness)
                    .overlay(Circle().stroke(Color.primary.opacity(0.3), lineWidth: 1))
                    .animation(.easeInOut, value: thickness)

                // Thickness slider
                VStack(alignment: .leading) {
                    Text("Thickness")
                        .font(.caption)
                    Slider(value: $thickness, in: 1...50, step: 1)
                        .accentColor(selectedColor)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
        }
    }

   

#Preview {
    Extra()
}

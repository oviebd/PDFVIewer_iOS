//
//  Dummy.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 18/5/25.
//

import SwiftUI

struct Dummy: View {
  
        @State private var selectedColor: Color = .blue
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .black]
        
        var body: some View {
            VStack(spacing: 30) {
                
                // Button with inner stroke in selected color
                ZStack {
                    // Black circular base
                    Circle()
                        .fill(Color.white)
                        .frame(width: 30, height: 30)
                        .overlay(
                            // Inner stroke by overlaying a smaller filled circle
                            Circle()
                               // .inset(by: 4) // Make the stroke *inside*
                                .stroke(selectedColor, lineWidth: 8)
                        )
                        .overlay(
                            Image(systemName: "pencil")
                                .foregroundColor(.black)
                                .font(.system(size: 15))
                        )
                }
                .shadow(radius: 4)
                
                // Color palette
                HStack(spacing: 15) {
                    ForEach(colors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                            )
                            .onTapGesture {
                                selectedColor = color
                            }
                    }
                }
            }
            .padding()
        }
    }

#Preview {
    Dummy()
}

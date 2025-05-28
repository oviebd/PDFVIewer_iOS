//
//  ControlButton.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 28/5/25.
//

import SwiftUI

import SwiftUI

struct ControlButton: View {
    var systemName: String
    var color: Color = .white
    var foreground: Color = .black
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title)
                .padding()
                .background(color.opacity(0.9))
                .foregroundColor(foreground)
                .clipShape(Circle())
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ControlButton(systemName: "plus") {
        }
        ControlButton(systemName: "minus", color: .blue, foreground: .white) {
            print("Minus tapped")
        }
        ControlButton(systemName: "square.and.arrow.down", color: .green, foreground: .white) {
        }
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}

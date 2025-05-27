//
//  AnnotationDetailsView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI

struct AnnotationDetailsView: View {

    @Binding var showPalette: Bool

    @Binding var drawingTool: PDFSettingData
    var onDataChanged: (() -> Void)?
   
    let colors: [UIColor] = [.red, .green, .blue, .yellow, .orange, .purple, .black, .gray]

    var body: some View {
        VStack(spacing: 16) {
            Extra(annotationSetting: $drawingTool)

            HStack {
                ForEach(colors, id: \.self) { color in
                    Button(action: {
                        drawingTool.color = color
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
     AnnotationDetailsView( showPalette: .constant(true), drawingTool: .constant(.dummyData()))
 }

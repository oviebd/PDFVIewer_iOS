//
//  SingleAnnotationItemView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI

struct SingleAnnotationItemView: View {
    
    @State var isExpanded : Bool = false
    
    var drawingToolType : DrawingTool
    private var onItemButtonPresesd : ((DrawingTool) -> Void)?
    
    init(drawingToolType : DrawingTool, onItemButtonPresesd : ((DrawingTool) -> Void)?) {
        self.drawingToolType = drawingToolType
        self.onItemButtonPresesd = onItemButtonPresesd
    }
    
    var body: some View {
        HStack {
            // Main Expand Button
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                    if isExpanded == false {
                        onItemButtonPresesd?(.none)
                    }
                }
            }) {
                Circle()
                    .fill(Color.black)
                    .frame(width: 25, height: 25)

                    .overlay(Image(systemName: "pencil.tip")
                        .font(.system(size: 18))
                        .rotationEffect(.init(degrees: -120))
                        .foregroundColor(.white))
            }

            if isExpanded {
                HStack(spacing: 10) {
                    Button(action: {
                        withAnimation(.spring()) {
                           // vm.showColorPalette.toggle()
                        }
                        
                        onItemButtonPresesd?(drawingToolType)

                    }) {
                        Circle()
                            //.fill(vm.selectedColor)
                            .frame(width: 25, height: 25)

                            .overlay(Image(systemName: "paintpalette.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .cornerRadius(5)
    }
}

#Preview {
    SingleAnnotationItemView(drawingToolType: .pen, onItemButtonPresesd: nil)
}

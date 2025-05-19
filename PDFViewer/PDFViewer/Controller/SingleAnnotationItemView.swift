//
//  SingleAnnotationItemView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI

struct SingleAnnotationItemView: View {
   
    @EnvironmentObject var drawingToolManager: DrawingToolManager
   
    @State var isExpanded: Bool = false
    var drawingToolType: DrawingTool
    private var onItemButtonPressed: ((DrawingTool) -> Void)?

    
   var selectedColor : Color = .blue
   
    init(drawingToolType: DrawingTool,
         onItemButtonPressed: ((DrawingTool) -> Void)?) {
        self.drawingToolType = drawingToolType
        self.onItemButtonPressed = onItemButtonPressed
    }

    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                    if !isExpanded {
                        onItemButtonPressed?(.none)
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(getSelectedColor(), lineWidth: 4)
                        )
                        .overlay(
                            Image(systemName: drawingToolType.iconName)
                                .font(.system(size: 14))
                                .foregroundColor(getSelectedColor())
                        )
                }
            }

            if isExpanded {
                HStack(spacing: 10) {
                    Button(action: {
                        onItemButtonPressed?(drawingToolType)
                    }) {
                        Circle()
                            .frame(width: 25, height: 25)
                            .overlay(
                                Image(systemName: "paintpalette.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    func getSelectedColor() -> Color {
        return Color(drawingToolManager.toolColors[drawingToolType] ?? .cyan)
    }
}


#Preview {
    SingleAnnotationItemView(drawingToolType: .pen, onItemButtonPressed: nil)
}

extension DrawingTool {
    var iconName: String {
        switch self {
        case .none:
            return "nosign" // A clear, universal "disable" symbol
        case .pen, .pencil:
            return "pencil.tip" // Represents a precise drawing pen
        case .highlighter:
            return "highlighter" // SF Symbol specifically for highlighters (introduced in iOS 16+)
        case .eraser:
            return "eraser" // Commonly used eraser icon
        }
    }
}

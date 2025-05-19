//
//  SingleAnnotationItemView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI

struct SingleAnnotationItemView: View {
    @EnvironmentObject var drawingToolManager: DrawingToolManager

    var drawingToolType: DrawingTool
    var isExpanded: Bool
   
    var onDrawingToolSelected: ((DrawingTool) -> Void)?
    var onPalettePressed: ((DrawingTool) -> Void)?


    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                onDrawingToolSelected?(drawingToolType)
            }) {
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 35, height: 35)
                        .overlay(
                            Circle()
                                .stroke(getSelectedColor(), lineWidth: 4)
                        )
                        .overlay(
                            Image(systemName: drawingToolType.iconName)
                                .font(.system(size: 16))
                                .foregroundColor(getSelectedColor())
                        )
                }
            }

            if isExpanded {
                Button(action: {
                    onPalettePressed?(drawingToolType)
                }) {
                    Circle()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                        .overlay(
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.default, value: isExpanded) // Important!
    }

    func getSelectedColor() -> Color {
        Color(drawingToolManager.toolColors[drawingToolType] ?? .cyan)
    }
}

#Preview {
    SingleAnnotationItemView(drawingToolType: .pen, isExpanded: true)
        .environmentObject(DrawingToolManager())
        .background(Color.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

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

    var isSelected: Bool {
        drawingToolManager.selectedTool == drawingToolType
    }

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                drawingToolManager.selectedTool = drawingToolType
                onDrawingToolSelected?(drawingToolType)
            }) {
                ZStack {
                    Circle()
                        .fill(isSelected ? getSelectedColor().opacity(0.3) : Color.clear)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(getSelectedColor(), lineWidth: isSelected ? 3 : 1)
                        )
                        .overlay(
                            Image(systemName: drawingToolType.iconName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(getSelectedColor())
                        )
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                }
            }

            if isExpanded && isExpandable() {
                Button(action: {
                    onPalettePressed?(drawingToolType)
                }) {
                    Circle()
                        .frame(width: 28, height: 28)
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
        .padding(4)
    }
    
    func isExpandable() -> Bool {
        drawingToolType == .pen || drawingToolType == .highlighter
    }

    func getSelectedColor() -> Color {
        Color(drawingToolManager.toolColors[drawingToolType] ?? .cyan)
    }
}

//struct SingleAnnotationItemView: View {
//    @EnvironmentObject var drawingToolManager: DrawingToolManager
//
//    var drawingToolType: DrawingTool
//    var isExpanded: Bool
//   
//    var onDrawingToolSelected: ((DrawingTool) -> Void)?
//    var onPalettePressed: ((DrawingTool) -> Void)?
//
//
//    var body: some View {
//        HStack(spacing: 8) {
//            Button(action: {
//                drawingToolManager.selectedTool = drawingToolType
//                onDrawingToolSelected?(drawingToolType)
//            }) {
//                ZStack {
//                    Circle()
//                        .fill(Color.clear)
//                        .frame(width: 20, height: 20)
//                        .overlay(
//                            Circle()
//                                .stroke(getSelectedColor(), lineWidth: 2)
//                        )
//                        .overlay(
//                            Image(systemName: drawingToolType.iconName)
//                                .font(.system(size: 12))
//                                .foregroundColor(getSelectedColor())
//                        )
//                }
//            }
//
//            if isExpanded && isExpandable() {
//                Button(action: {
//                    onPalettePressed?(drawingToolType)
//                }) {
//                    Circle()
//                        .frame(width: 20, height: 20)
//                        .foregroundColor(.blue)
//                        .overlay(
//                            Image(systemName: "paintpalette.fill")
//                                .font(.system(size: 12))
//                                .foregroundColor(.white)
//                        )
//                }
//                .transition(.scale.combined(with: .opacity))
//            }
//        }
//        .animation(.default, value: isExpanded) // Important!
//    }
//    
//    func isExpandable () -> Bool {
//        return drawingToolType == .pen || drawingToolType == .highlighter
//    }
//
//    func getSelectedColor() -> Color {
//        Color(drawingToolManager.toolColors[drawingToolType] ?? .cyan)
//    }
//}

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
        case .pen:
            return "pencil.tip" // Represents a precise drawing pen
        case .highlighter:
            return "highlighter" // SF Symbol specifically for highlighters (introduced in iOS 16+)
        case .eraser:
            return "eraser.fill" // Commonly used eraser icon
        }
    }
}

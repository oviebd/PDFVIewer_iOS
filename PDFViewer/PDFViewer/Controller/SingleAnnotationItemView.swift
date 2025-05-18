//
//  SingleAnnotationItemView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI

//struct SingleAnnotationItemView: View {
//    @State var isExpanded: Bool = false
//
//    @State private var selectedColor: Color = .red
//
//    var drawingToolType: DrawingTool
//    private var onItemButtonPresesd: ((DrawingTool) -> Void)?
//
//    init(drawingToolType: DrawingTool, onItemButtonPresesd: ((DrawingTool) -> Void)?) {
//        self.drawingToolType = drawingToolType
//        self.onItemButtonPresesd = onItemButtonPresesd
//    }
//
//    var body: some View {
//        HStack {
//            // Main Expand Button
//            Button(action: {
//                withAnimation {
//                    isExpanded.toggle()
//                    if isExpanded == false {
//                        onItemButtonPresesd?(.none)
//                    }
//                }
//            }) {
//                ZStack {
//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: 30, height: 30)
//                        .overlay(
//                            // Inner stroke by overlaying a smaller filled circle
//                            Circle()
//                                // .inset(by: 4) // Make the stroke *inside*
//                                .stroke(selectedColor, lineWidth: 4)
//                        )
//
//                        .overlay(Image(systemName: drawingToolType.iconName)
//                            .font(.system(size: 14))
//                            // .rotationEffect(.init(degrees: -120))
//                            .foregroundColor(selectedColor))
//                }
//            }
//
//            if isExpanded {
//                HStack(spacing: 10) {
//                    Button(action: {
//                        withAnimation(.spring()) {
//                            // vm.showColorPalette.toggle()
//                        }
//
//                        onItemButtonPresesd?(drawingToolType)
//
//                    }) {
//                        Circle()
//                            // .fill(vm.selectedColor)
//                            .frame(width: 25, height: 25)
//
//                            .overlay(Image(systemName: "paintpalette.fill")
//                                .font(.system(size: 12))
//                                .foregroundColor(.white))
//                    }
//                    .transition(.scale.combined(with: .opacity))
//                }
//            }
//        }
//        // .cornerRadius(5)
//    }
//}

struct SingleAnnotationItemView: View {
    @State var isExpanded: Bool = false
    var selectedColor: Color // 👈 Injected from parent
    var drawingToolType: DrawingTool
    private var onItemButtonPressed: ((DrawingTool) -> Void)?

    init(drawingToolType: DrawingTool,
         selectedColor: Color,
         onItemButtonPressed: ((DrawingTool) -> Void)?) {
        self.drawingToolType = drawingToolType
        self.selectedColor = selectedColor
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
                                .stroke(selectedColor, lineWidth: 4)
                        )
                        .overlay(
                            Image(systemName: drawingToolType.iconName)
                                .font(.system(size: 14))
                                .foregroundColor(selectedColor)
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
}


#Preview {
    SingleAnnotationItemView(drawingToolType: .pen, selectedColor: .brown, onItemButtonPressed: nil)
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

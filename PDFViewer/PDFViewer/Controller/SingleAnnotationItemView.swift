//
//  SingleAnnotationItemView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI


struct SingleAnnotationItemView: View {

    var itemAnnotationSetting: PDFAnnotationSetting
    var selectedAnnotationSetting: PDFAnnotationSetting
   
    var onDrawingToolSelected: ((PDFAnnotationSetting) -> Void)?
    var onPalettePressed: ((PDFAnnotationSetting) -> Void)?

    var isSelected: Bool {
        selectedAnnotationSetting == itemAnnotationSetting
    }

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                onDrawingToolSelected?(itemAnnotationSetting)
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
                            Image(systemName: itemAnnotationSetting.annotationTool.iconName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(getSelectedColor())
                        )
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                }
            }

            if isExpandedView() && isExpandable() {
                Button(action: {
                    onPalettePressed?(itemAnnotationSetting)
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
    func isExpandedView() -> Bool {
        selectedAnnotationSetting == itemAnnotationSetting
    }
    
    func isExpandable() -> Bool {
        itemAnnotationSetting.isExpandable
    }

    func getSelectedColor() -> Color {
        Color(itemAnnotationSetting.color)
    }
}

#Preview {
 
    SingleAnnotationItemView(itemAnnotationSetting: .dummyData(), selectedAnnotationSetting: .dummyData())
        .environmentObject(DrawingToolManager.dummyData())
        .background(Color.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
}

extension AnnotationTool {
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

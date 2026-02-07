//
//  SingleAnnotationItemView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI

struct SingleAnnotationItemView: View {
    @EnvironmentObject var drawingToolManager: DrawingToolManager

    var itemAnnotationSetting: PDFAnnotationSetting

    var onDrawingToolSelected: ((PDFAnnotationSetting) -> Void)?
    var onPalettePressed: ((PDFAnnotationSetting) -> Void)?

    var isSelected: Bool {
        drawingToolManager.selectePdfdSetting == itemAnnotationSetting
    }

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                onDrawingToolSelected?(itemAnnotationSetting)
            }) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 255/255, green: 87/255, blue: 34/255)) // Orange-red color from image
                            .frame(width: 44, height: 44)
                            .shadow(color: Color(red: 255/255, green: 87/255, blue: 34/255).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Image(systemName: itemAnnotationSetting.annotationTool.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .white : Color(red: 0.2, green: 0.25, blue: 0.35))
                }
                .frame(width: 44, height: 44)
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
        }
        .padding(2)
    }

    func isExpandable() -> Bool {
        itemAnnotationSetting.isExpandable
    }

    func getSelectedColor() -> Color {
        Color(itemAnnotationSetting.color)
    }
}

//
#Preview {
    SingleAnnotationItemView(itemAnnotationSetting: .dummyData())
        .environmentObject(DrawingToolManager.dummyData())
        .background(Color.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
}

extension AnnotationTool {
    var iconName: String {
        switch self {
        case .none:
            return "nosign"
        case .pen:
            return "pencil.tip"
        case .pencil:
            return "pencil"
        case .highlighter:
            return "highlighter"
        case .text:
            return "textformat"
        case .eraser:
            return "eraser.line.dashed"
        }
    }
}

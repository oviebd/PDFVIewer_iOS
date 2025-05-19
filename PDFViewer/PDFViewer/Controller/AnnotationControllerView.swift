//
//  AnnotationControllerView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI

struct AnnotationControllerView: View {
    @EnvironmentObject var drawingToolManager: DrawingToolManager

    var onItemButtonPressed: ((DrawingTool) -> Void)?

    init(onItemButtonPressed: ((DrawingTool) -> Void)?) {
        self.onItemButtonPressed = onItemButtonPressed
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach([DrawingTool.pen, .highlighter, .pencil], id: \.self) { tool in

                SingleAnnotationItemView(
                    drawingToolType: tool) { selectedTool in
                        onItemButtonPressed?(selectedTool)
                    }
            }
        }
    }
}

#Preview {
    AnnotationControllerView(onItemButtonPressed: nil)
}

//
//  AnnotationControllerView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI




struct AnnotationControllerView: View {
   
    @EnvironmentObject var drawingToolManager: DrawingToolManager
   
    @State private var expandedTool: DrawingTool? = nil
    
    var onDrawingToolSelected: ((DrawingTool) -> Void)?
    var onPalettePressed: ((DrawingTool) -> Void)?
    
    init(onDrawingToolSelected: ((DrawingTool) -> Void)?,
         onPalettePressed: ((DrawingTool) -> Void)?) {
        self.onPalettePressed = onPalettePressed
        self.onDrawingToolSelected = onDrawingToolSelected
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach([DrawingTool.pen, .highlighter,.eraser], id: \.self) { tool in
                
                SingleAnnotationItemView(
                    drawingToolType: tool,
                    isExpanded: expandedTool == tool,
                    onDrawingToolSelected: { tool in
                        withAnimation {
                            expandedTool = (expandedTool == tool) ? .none : tool
                            onDrawingToolSelected?(expandedTool!)
                            drawingToolManager.selectedTool = expandedTool!
                           
                        }
                    },
                    onPalettePressed: onPalettePressed
                )
            }
        }
    }
}


#Preview {
    AnnotationControllerView(onDrawingToolSelected: nil, onPalettePressed: nil)
        .environmentObject(DrawingToolManager())
}

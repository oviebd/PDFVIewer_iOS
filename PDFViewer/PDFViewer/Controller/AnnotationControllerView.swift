//
//  AnnotationControllerView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI


struct AnnotationControllerView: View {
   
    @EnvironmentObject var drawingToolManager: DrawingToolManager
   
    @State private var expandedTool: PDFSettingData? = nil
    
    var onDrawingToolSelected: ((PDFSettingData) -> Void)?
    var onPalettePressed: ((PDFSettingData) -> Void)?
    
    init(onDrawingToolSelected: ((PDFSettingData) -> Void)?,
         onPalettePressed: ((PDFSettingData) -> Void)?) {
        self.onPalettePressed = onPalettePressed
        self.onDrawingToolSelected = onDrawingToolSelected
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(drawingToolManager.pdfSettings, id: \.self) { tool in
                if tool.drawingTool  != .none {
                    
                SingleAnnotationItemView(
                    drawingToolType: tool,
                    isExpanded: expandedTool == tool,
                    onDrawingToolSelected: { tool in
                        withAnimation {
                            expandedTool = (expandedTool == tool) ? PDFSettingData.noneData() : tool
                            onDrawingToolSelected?(expandedTool!)
                            
                            drawingToolManager.selectePdfdSetting = expandedTool!
                         //   drawingToolManager.updatePdfSettingData(newSetting: expandedTool!)
                            
                        }
                    },
                    onPalettePressed: onPalettePressed
                )
            }
            }
            
//            ForEach([DrawingTool.pen, .highlighter,.eraser], id: \.self) { tool in
//                
//                SingleAnnotationItemView(
//                    drawingToolType: tool,
//                    isExpanded: expandedTool == tool,
//                    onDrawingToolSelected: { tool in
//                        withAnimation {
//                            expandedTool = (expandedTool == tool) ? .none : tool
//                            onDrawingToolSelected?(expandedTool!)
//                            drawingToolManager.selectedTool = expandedTool!
//                           
//                        }
//                    },
//                    onPalettePressed: onPalettePressed
//                )
//            }
        }
    }
}


#Preview {
    AnnotationControllerView(onDrawingToolSelected: nil, onPalettePressed: nil)
        .environmentObject(DrawingToolManager.dummyData())
}

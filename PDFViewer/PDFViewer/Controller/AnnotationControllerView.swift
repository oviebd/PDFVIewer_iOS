//
//  AnnotationControllerView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI


struct AnnotationControllerView: View {
   
   // @EnvironmentObject var drawingToolManager: DrawingToolManager
   
    var annotationSettingItems : [PDFSettingData]
    
    @State private var itemAnnotationSetting: PDFSettingData? = .dummyData()
    @State private var selectedAnnotationSetting : PDFSettingData = .dummyData()
    
    var onDrawingToolSelected: ((PDFSettingData) -> Void)?
    var onPalettePressed: ((PDFSettingData) -> Void)?
    
    init(annotationSettingItems : [PDFSettingData],
         onDrawingToolSelected: ((PDFSettingData) -> Void)?,
         onPalettePressed: ((PDFSettingData) -> Void)?) {
        self.annotationSettingItems = annotationSettingItems
        self.onPalettePressed = onPalettePressed
        self.onDrawingToolSelected = onDrawingToolSelected
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(annotationSettingItems, id: \.self) { tool in
                if tool.drawingTool  != .none {
                    
                SingleAnnotationItemView(
                    drawingToolType: tool,
                    selectedAnnotationType: selectedAnnotationSetting,
                    onDrawingToolSelected: { tool in
                        withAnimation {
                            itemAnnotationSetting = (itemAnnotationSetting == tool) ? PDFSettingData.noneData() : tool
                            onDrawingToolSelected?(itemAnnotationSetting!)
                            
                            selectedAnnotationSetting = itemAnnotationSetting!
                            //drawingToolManager.selectePdfdSetting = expandedTool!
                            
                        }
                    },
                    onPalettePressed: onPalettePressed
                )
            }
            }
        
        }
    }
}

//
//#Preview {
//    AnnotationControllerView(onDrawingToolSelected: nil, onPalettePressed: nil)
//        .environmentObject(DrawingToolManager.dummyData())
//}

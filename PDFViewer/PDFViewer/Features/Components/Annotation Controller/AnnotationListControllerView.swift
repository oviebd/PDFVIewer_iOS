//
//  AnnotationControllerView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI


struct AnnotationListControllerView: View {
   
    var annotationSettingItems : [PDFAnnotationSetting]
    
    @State private var itemAnnotationSetting: PDFAnnotationSetting? = .dummyData()
  
    
    var onDrawingToolSelected: ((PDFAnnotationSetting) -> Void)?
    var onPalettePressed: ((PDFAnnotationSetting) -> Void)?
    
    init(annotationSettingItems : [PDFAnnotationSetting],
         onDrawingToolSelected: ((PDFAnnotationSetting) -> Void)?,
         onPalettePressed: ((PDFAnnotationSetting) -> Void)?) {
        self.annotationSettingItems = annotationSettingItems
        self.onPalettePressed = onPalettePressed
        self.onDrawingToolSelected = onDrawingToolSelected
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(annotationSettingItems, id: \.self) { tool in
                if tool.annotationTool  != .none {
                    
                SingleAnnotationItemView(
                    itemAnnotationSetting: tool,
                    onDrawingToolSelected: { tool in
                        withAnimation {
                            itemAnnotationSetting = (itemAnnotationSetting == tool) ? PDFAnnotationSetting.noneData() : tool
                            onDrawingToolSelected?(itemAnnotationSetting!)
                        }
                    },
                    onPalettePressed: onPalettePressed
                )
            }
            }
        
        }
    }
}


#Preview {
    AnnotationListControllerView(annotationSettingItems: [],
                             onDrawingToolSelected: nil,
                             onPalettePressed: nil)
        .environmentObject(DrawingToolManager.dummyData())
}

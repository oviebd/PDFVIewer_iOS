//
//  AnnotationControllerView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI

struct AnnotationControllerView: View {
    
    
    var onItemButtonPressed : ((DrawingTool) -> Void)?
    
    var toolColors: [DrawingTool: UIColor] // 👈 NEW
   
    init(toolColors: [DrawingTool: UIColor],
            onItemButtonPressed: ((DrawingTool) -> Void)?) {
           self.toolColors = toolColors
           self.onItemButtonPressed = onItemButtonPressed
       }

    
  
    var body: some View {
           HStack(spacing: 10) {
               ForEach([DrawingTool.pen, .highlighter, .pencil], id: \.self) { tool in
                   SingleAnnotationItemView(
                       drawingToolType: tool,
                       selectedColor: Color(toolColors[tool] ?? .black)) { selectedTool in
                           onItemButtonPressed?(selectedTool)
                       }
               }
           }
       }
    
//    var body: some View {
//        HStack (spacing : 10){
//            
//            SingleAnnotationItemView(drawingToolType: .pen){ drwaingTool in
//                onItemButtonPresesd?(drwaingTool)
//            }
//            SingleAnnotationItemView(drawingToolType: .highlighter){ drwaingTool in
//                onItemButtonPresesd?(drwaingTool)
//            }
//            
//            SingleAnnotationItemView(drawingToolType: .pencil){ drwaingTool in
//                onItemButtonPresesd?(drwaingTool)
//            }
//        }
//    }
}

#Preview {
    AnnotationControllerView(toolColors: [.pen: .yellow], onItemButtonPressed: nil)
}

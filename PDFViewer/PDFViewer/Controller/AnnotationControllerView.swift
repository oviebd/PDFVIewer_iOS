//
//  AnnotationControllerView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 13/5/25.
//

import SwiftUI

struct AnnotationControllerView: View {
    
    
    var onItemButtonPresesd : ((DrawingTool) -> Void)?
   
    init(onItemButtonPresesd : ((DrawingTool) -> Void)?) {
        self.onItemButtonPresesd = onItemButtonPresesd
    }
    
    var body: some View {
        HStack (spacing : 10){
            
            SingleAnnotationItemView(drawingToolType: .pen){ drwaingTool in
                onItemButtonPresesd?(drwaingTool)
            }
            SingleAnnotationItemView(drawingToolType: .highlighter){ drwaingTool in
                onItemButtonPresesd?(drwaingTool)
            }
            
            SingleAnnotationItemView(drawingToolType: .pencil){ drwaingTool in
                onItemButtonPresesd?(drwaingTool)
            }
        }
    }
}

#Preview {
    AnnotationControllerView(onItemButtonPresesd: nil)
}

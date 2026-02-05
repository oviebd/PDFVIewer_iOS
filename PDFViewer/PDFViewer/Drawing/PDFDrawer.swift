//
//  PDFDrawer.swift
//  PDFKit Demo
//
//  Created by Tim on 31/01/2019.
//  Copyright © 2019 Tim. All rights reserved.
//

import Foundation
import PDFKit

enum AnnotationTool : Int {
    case none = -1
    case eraser = 0
    case pen = 2
    case highlighter = 3
    
    var alpha: CGFloat {
        switch self {
        case .highlighter:
            return 0.3
        default:
            return 1
        }
    }
}



struct PDFAnnotationSetting : Hashable {
    var annotationTool : AnnotationTool
    var lineWidth : CGFloat
    
    var color : UIColor
    var isExpandable : Bool
    
    init(annotationTool: AnnotationTool, lineWidth: CGFloat, color: UIColor, isExpandable: Bool) {
        self.annotationTool = annotationTool
        self.lineWidth = lineWidth
        self.color = color
        self.isExpandable = isExpandable
    }
    
    static func == (lhs: PDFAnnotationSetting, rhs: PDFAnnotationSetting) -> Bool {
         return lhs.annotationTool == rhs.annotationTool &&
                lhs.lineWidth == rhs.lineWidth &&
                lhs.color.isEqual(rhs.color) && // UIColor doesn't conform to Hashable
                lhs.isExpandable == rhs.isExpandable
     }

     func hash(into hasher: inout Hasher) {
         hasher.combine(annotationTool)
         hasher.combine(lineWidth)
         hasher.combine(color.hashValue)
         hasher.combine(isExpandable)
     }
    
    
}
//
extension PDFAnnotationSetting {
    static func dummyData () -> PDFAnnotationSetting {
        return PDFAnnotationSetting(annotationTool: .pen, lineWidth: 2.0, color: .red, isExpandable: true)
    }
    
    static func noneData () -> PDFAnnotationSetting {
        return PDFAnnotationSetting(annotationTool: .none, lineWidth: 0.0, color: .red, isExpandable: false)
    }
}



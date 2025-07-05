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

extension PDFAnnotationSetting {
    static func dummyData () -> PDFAnnotationSetting {
        return PDFAnnotationSetting(annotationTool: .pen, lineWidth: 2.0, color: .red, isExpandable: true)
    }
    
    static func noneData () -> PDFAnnotationSetting {
        return PDFAnnotationSetting(annotationTool: .none, lineWidth: 0.0, color: .red, isExpandable: false)
    }
}


class PDFDrawer {
    weak var pdfView: PDFView!
    private var path: UIBezierPath?
    private var currentAnnotation : DrawingAnnotation?
    private var currentPage: PDFPage?
    
    var annotationSetting : PDFAnnotationSetting = .dummyData()

    func getAnnotationType() -> AnnotationTool {
        return annotationSetting.annotationTool
    }
    
    var onAnnotationDrawingCompleted : (() -> Void)?
}

extension PDFDrawer: DrawingGestureRecognizerDelegate {
    func gestureRecognizerBegan(_ location: CGPoint) {
        guard let page = pdfView.page(for: location, nearest: true) else { return }
        currentPage = page
        let convertedPoint = pdfView.convert(location, to: currentPage!)
        path = UIBezierPath()
        path?.move(to: convertedPoint)
    }
    
    func gestureRecognizerMoved(_ location: CGPoint) {
        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)
        
    //    print(convertedPoint)
        
        if getAnnotationType() == .eraser {
            removeAnnotationAtPoint(point: convertedPoint, page: page)
            return
        }
        
        path?.addLine(to: convertedPoint)
        path?.move(to: convertedPoint)
        drawAnnotation(onPage: page)
    }
    
    func gestureRecognizerEnded(_ location: CGPoint) {
        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)
        
        // Erasing
        if getAnnotationType() == .eraser {
            removeAnnotationAtPoint(point: convertedPoint, page: page)
            onAnnotationDrawingCompleted?()
            return
        }
        
        // Drawing
        guard let _ = currentAnnotation else { return }
        
        path?.addLine(to: convertedPoint)
        path?.move(to: convertedPoint)
        
        // Final annotation
        page.removeAnnotation(currentAnnotation!)
        _ = createFinalAnnotation(path: path!, page: page)
        currentAnnotation = nil
        onAnnotationDrawingCompleted?()
        
        
    }
    
    private func createAnnotation(path: UIBezierPath, page: PDFPage) -> DrawingAnnotation {
        let border = PDFBorder()
        border.lineWidth = annotationSetting.lineWidth//drawingTool.width
        
        let annotation = DrawingAnnotation(bounds: page.bounds(for: pdfView.displayBox), forType: .ink, withProperties: nil)
        annotation.color = annotationSetting.color.withAlphaComponent(annotationSetting.annotationTool.alpha)
        annotation.border = border
        return annotation
    }
    
    private func drawAnnotation(onPage: PDFPage) {
        guard let path = path else { return }
        
        if currentAnnotation == nil {
            currentAnnotation = createAnnotation(path: path, page: onPage)
        }
        
        currentAnnotation?.path = path
        forceRedraw(annotation: currentAnnotation!, onPage: onPage)
    }

    
    
    
    private func createFinalAnnotation(path: UIBezierPath, page: PDFPage) -> PDFAnnotation {
        let border = PDFBorder()
        border.lineWidth = annotationSetting.lineWidth//drawingTool.width

        // Expand the bounds based on the drawing tool width
//        let padding = drawingTool.width / 2 + 2  // Add extra padding just to be safe
        let padding = annotationSetting.lineWidth / 2 + 2  // Add extra padding just to be safe
        let bounds = path.bounds.insetBy(dx: -padding, dy: -padding)
        
        // Create a copy of the path to center inside the bounds
        let centeredPath = UIBezierPath()
        centeredPath.cgPath = path.cgPath
        centeredPath.moveCenter(to: bounds.center)

        // Create annotation
        let annotation = PDFAnnotation(bounds: bounds, forType: .ink, withProperties: nil)
        annotation.color = annotationSetting.color.withAlphaComponent(annotationSetting.annotationTool.alpha)
        annotation.border = border
        annotation.add(centeredPath)

        // Add to page
        page.addAnnotation(annotation)

        return annotation
    }

    
    private func removeAnnotationAtPoint(point: CGPoint, page: PDFPage) {
        let hitTestRect = CGRect(x: point.x - 10,
                                 y: point.y - 10,
                                 width: 20,
                                 height: 20)
        
        for annotation in page.annotations {
            if annotation.bounds.intersects(hitTestRect) {
                page.removeAnnotation(annotation)
                break // stop after first match
            }
        }
    }
    private func forceRedraw(annotation: PDFAnnotation, onPage: PDFPage) {
        onPage.removeAnnotation(annotation)
        onPage.addAnnotation(annotation)
    }
}

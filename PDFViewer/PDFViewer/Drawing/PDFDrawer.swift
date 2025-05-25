//
//  PDFDrawer.swift
//  PDFKit Demo
//
//  Created by Tim on 31/01/2019.
//  Copyright © 2019 Tim. All rights reserved.
//

import Foundation
import PDFKit

enum DrawingTool: Int {
    case none = -1
    case eraser = 0
    case pencil = 1
    case pen = 2
    case highlighter = 3
    case text = 4
    
    var alpha: CGFloat {
        switch self {
        case .highlighter:
            return 0.3 //0,5
        default:
            return 1
        }
    }
}

class PDFDrawer {
    weak var pdfView: PDFView!
    private var path: UIBezierPath?
    private var currentAnnotation : DrawingAnnotation?
    private var currentPage: PDFPage?
    var color = UIColor.red // default color is red
    var drawingTool: DrawingTool = .pen {
        didSet {
            if drawingTool == .text {
                enableTextToolRecognizer()
            } else {
                removeTextToolRecognizer()
            }
        }
    }
    var lineWidth : CGFloat = 2.0
    
    private var movableAnnotation: PDFAnnotation?
    private var dragOffset: CGPoint?
    
    private var tapRecognizer: UITapGestureRecognizer?
    
}

extension PDFDrawer{
    func enableTextToolRecognizer() {
        removeTextToolRecognizer() // remove if already added
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTextToolTap(_:)))
        pdfView.addGestureRecognizer(tap)
        tapRecognizer = tap
    }

    func removeTextToolRecognizer() {
        if let recognizer = tapRecognizer {
            pdfView.removeGestureRecognizer(recognizer)
            tapRecognizer = nil
        }
    }
    
    @objc private func handleTextToolTap(_ sender: UITapGestureRecognizer) {
        guard drawingTool == .text else { return }
        let point = sender.location(in: pdfView)
        if let page = pdfView.page(for: point, nearest: true) {
            let converted = pdfView.convert(point, to: page)
            showTextInput(at: converted, on: page)
        }
    }
}

extension PDFDrawer {
//    func gestureRecognizerBegan(_ location: CGPoint) {
//        guard let page = pdfView.page(for: location, nearest: true) else { return }
//        currentPage = page
//        let convertedPoint = pdfView.convert(location, to: currentPage!)
//        path = UIBezierPath()
//        path?.move(to: convertedPoint)
//    }
//    
//    func gestureRecognizerMoved(_ location: CGPoint) {
//        guard let page = currentPage else { return }
//        let convertedPoint = pdfView.convert(location, to: page)
//        
//    //    print(convertedPoint)
//        
//        if drawingTool == .eraser {
//            removeAnnotationAtPoint(point: convertedPoint, page: page)
//            return
//        }
//        
//        path?.addLine(to: convertedPoint)
//        path?.move(to: convertedPoint)
//        drawAnnotation(onPage: page)
//    }
//    
//    func gestureRecognizerEnded(_ location: CGPoint) {
//        guard let page = currentPage else { return }
//        let convertedPoint = pdfView.convert(location, to: page)
//        
//        // Erasing
//        if drawingTool == .eraser {
//            removeAnnotationAtPoint(point: convertedPoint, page: page)
//            return
//        }
//        
//        if drawingTool == .text {
//            presentTextInput(at: convertedPoint, page: page)
//            return
//        }
//        
//        // Drawing
//        guard let _ = currentAnnotation else { return }
//        
//        path?.addLine(to: convertedPoint)
//        path?.move(to: convertedPoint)
//        
//        // Final annotation
//        page.removeAnnotation(currentAnnotation!)
//        _ = createFinalAnnotation(path: path!, page: page)
//        currentAnnotation = nil
//    }
    
//    func presentTextInput(at point: CGPoint, page: PDFPage) {
//        let alert = UIAlertController(title: "Add Text", message: nil, preferredStyle: .alert)
//        alert.addTextField { textField in
//            textField.placeholder = "Enter text"
//        }
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
//            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
//            self?.addTextAnnotation(text: text, at: point, page: page)
//        }))
//        
//        // Present the alert using the topmost view controller
//        if let topVC = UIApplication.shared.windows.first(where: \.isKeyWindow)?.rootViewController {
//            topVC.present(alert, animated: true)
//        }
//    }
//    
//    func addTextAnnotation(text: String, at point: CGPoint, page: PDFPage) {
//        let width: CGFloat = 200
//        let height: CGFloat = 40
//        let bounds = CGRect(x: point.x, y: point.y, width: width, height: height)
//        
//        let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
//        annotation.contents = text
//        annotation.font = UIFont.systemFont(ofSize: 16)
//        annotation.fontColor = color
//        annotation.color = .clear // Makes the background transparent
//        annotation.alignment = .left
//
//        page.addAnnotation(annotation)
//    }
    
    func createAnnotation(path: UIBezierPath, page: PDFPage) -> DrawingAnnotation {
        let border = PDFBorder()
        border.lineWidth = lineWidth//drawingTool.width
        
        let annotation = DrawingAnnotation(bounds: page.bounds(for: pdfView.displayBox), forType: .ink, withProperties: nil)
        annotation.color = color.withAlphaComponent(drawingTool.alpha)
        annotation.border = border
        return annotation
    }
    
    func drawAnnotation(onPage: PDFPage) {
        guard let path = path else { return }
        
        if currentAnnotation == nil {
            currentAnnotation = createAnnotation(path: path, page: onPage)
        }
        
        currentAnnotation?.path = path
        forceRedraw(annotation: currentAnnotation!, onPage: onPage)
    }

    
    
    
    private func createFinalAnnotation(path: UIBezierPath, page: PDFPage) -> PDFAnnotation {
        let border = PDFBorder()
        border.lineWidth = lineWidth//drawingTool.width

        // Expand the bounds based on the drawing tool width
//        let padding = drawingTool.width / 2 + 2  // Add extra padding just to be safe
        let padding = lineWidth / 2 + 2  // Add extra padding just to be safe
        let bounds = path.bounds.insetBy(dx: -padding, dy: -padding)
        
        // Create a copy of the path to center inside the bounds
        let centeredPath = UIBezierPath()
        centeredPath.cgPath = path.cgPath
        centeredPath.moveCenter(to: bounds.center)

        // Create annotation
        let annotation = PDFAnnotation(bounds: bounds, forType: .ink, withProperties: nil)
        annotation.color = color.withAlphaComponent(drawingTool.alpha)
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

extension PDFDrawer: DrawingGestureRecognizerDelegate {
    func gestureRecognizerBegan(_ location: CGPoint) {
        guard let page = pdfView.page(for: location, nearest: true) else { return }
        currentPage = page
        let convertedPoint = pdfView.convert(location, to: currentPage!)
        
//        if drawingTool == .text {
//            showTextInput(at: convertedPoint, on: page)
//            return
//        }
        
        if drawingTool == .eraser {
            removeAnnotationAtPoint(point: convertedPoint, page: page)
            return
        }
        
        if let annotation = page.annotation(at: convertedPoint), isMovable(annotation: annotation) == nil {
            movableAnnotation = annotation
            dragOffset = convertedPoint
            return
        }
        
        path = UIBezierPath()
        path?.move(to: convertedPoint)
    }
    
    func isMovable(annotation: PDFAnnotation) -> Bool {
        return annotation.type == PDFAnnotationSubtype.freeText.rawValue ||
               annotation.type == PDFAnnotationSubtype.ink.rawValue
    }

    func gestureRecognizerMoved(_ location: CGPoint) {
        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)
        
        if drawingTool == .eraser {
            removeAnnotationAtPoint(point: convertedPoint, page: page)
            return
        }

        if let annotation = movableAnnotation, let dragOffset = dragOffset {
            let dx = convertedPoint.x - dragOffset.x
            let dy = convertedPoint.y - dragOffset.y
            var newBounds = annotation.bounds
            newBounds.origin.x += dx
            newBounds.origin.y += dy
            annotation.bounds = newBounds
            page.removeAnnotation(annotation)
            page.addAnnotation(annotation)
            self.dragOffset = convertedPoint
            return
        }

        path?.addLine(to: convertedPoint)
        path?.move(to: convertedPoint)
        drawAnnotation(onPage: page)
    }

    func gestureRecognizerEnded(_ location: CGPoint) {
        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)

        if drawingTool == .eraser {
            removeAnnotationAtPoint(point: convertedPoint, page: page)
            return
        }

        if movableAnnotation != nil {
            movableAnnotation = nil
            dragOffset = nil
            return
        }

        if path != nil && drawingTool != .none, currentAnnotation != nil {
            path?.addLine(to: convertedPoint)
            path?.move(to: convertedPoint)
            page.removeAnnotation(currentAnnotation!)
            _ = createFinalAnnotation(path: path!, page: page)
            currentAnnotation = nil
        }
    }
}

extension PDFDrawer {
    func showTextInput(at point: CGPoint, on page: PDFPage) {
        let alert = UIAlertController(title: "Add Text", message: "Enter text to add to PDF", preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                self.addTextAnnotation(text: text, at: point, on: page)
            }
        }))
        
        if let viewController = self.pdfView.window?.rootViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
    }

    func addTextAnnotation(text: String, at point: CGPoint, on page: PDFPage) {
        let font = UIFont.systemFont(ofSize: 14)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        let attrString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attrString.size()
        let rect = CGRect(origin: point, size: textSize)

        let annotation = PDFAnnotation(bounds: rect, forType: .freeText, withProperties: nil)
        annotation.contents = text
        annotation.font = font
        annotation.color = .clear
        annotation.fontColor = color
        annotation.alignment = .left

        page.addAnnotation(annotation)
    }
}


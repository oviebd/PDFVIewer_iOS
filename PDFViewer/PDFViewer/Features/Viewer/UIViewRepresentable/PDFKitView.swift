//
//  PDFKitView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 25/3/25.
//

import Combine
import PDFKit
import SwiftUI

class PDFKitViewActions: ObservableObject {
    fileprivate weak var coordinator: PDFKitView.Coordinator?
    fileprivate let annotationEditFinishedPublisher = PassthroughSubject<Data?, Never>()
    private var cancellables = Set<AnyCancellable>()

    var onPageChanged: ((Int) -> Void)?
    var onAnnotationEditFinished: ((Data?) -> Void)?

    init() {
        annotationEditFinishedPublisher
            .debounce(for: .milliseconds(2000), scheduler: RunLoop.main)
            .sink { [weak self] annotationData in
                self?.onAnnotationEditFinished?(annotationData)
            }
            .store(in: &cancellables)
    }

    func saveAnnotatedPDFInBackground(to url: URL, completion: @escaping (Bool) -> Void) {
        coordinator?.saveAnnotatedPDF(to: url, completion: completion)
    }

    func setZoomScale(scaleFactor: CGFloat) {
        coordinator?.setZoomSscale(scaleFactor: scaleFactor)
    }

    func goPage(pageNumber: Int) {
        coordinator?.goToPage(pageNumber)
    }

    func getCurrentPageNumber() -> Int? {
        return coordinator?.getCurrentPageNumber()
    }

    func getTotalPageNumber() -> Int? {
        return coordinator?.getTotalPageNumber()
    }

    func notifyPageChange(_ page: Int) {
        onPageChanged?(page)
    }

    func notifyAnnotationEditingFinished(annotationdata : Data?) {
        annotationEditFinishedPublisher.send(annotationdata)
    }

    deinit {
        cancellables.removeAll()
    }
}

struct PDFKitView: UIViewRepresentable {
    var pdfURL: URL
    var pdfDataModel: PDFModelData
    @ObservedObject var settings: PDFSettings
    @Binding var mode: PDFAnnotationSetting

    @ObservedObject var actions: PDFKitViewActions

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: pdfURL)
        applySettings(to: pdfView)

        if let jsonData = pdfDataModel.annotationdata {
            context.coordinator.applyAnnotations(from: jsonData, to:  pdfView.document!)
        }
       
        context.coordinator.drawer?.pdfView = pdfView
        context.coordinator.gestureRecognizer = DrawingGestureRecognizer()
        context.coordinator.gestureRecognizer?.drawingDelegate = context.coordinator.drawer
        pdfView.addGestureRecognizer(context.coordinator.gestureRecognizer!)
        context.coordinator.pdfView = pdfView

        context.coordinator.drawer?.onAnnotationDrawingCompleted = { [weak coordinator = context.coordinator] in
            let annotationdata = coordinator?.extractAnnotationData(from: pdfView.document!)
            coordinator?.actions?.notifyAnnotationEditingFinished(annotationdata: annotationdata)
        }

        // ✅ Connect the coordinator to actions
        actions.coordinator = context.coordinator
        context.coordinator.actions = actions

        // Start polling and assign the callback
        context.coordinator.startPollingPageChanges()

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // print("P>> Update Ui View ")
        // If the PDF has changed, reload it
        if pdfView.document?.documentURL != pdfURL {
            pdfView.document = PDFDocument(url: pdfURL)
        }

        // Reapply settings
        applySettings(to: pdfView)

        if let gesture = context.coordinator.gestureRecognizer {
            gesture.isEnabled = mode.annotationTool != .none
        }

        // ✅ Update the drawing tool and color here
        context.coordinator.drawer?.annotationSetting = mode
    }

    private func applySettings(to pdfView: PDFView) {
        pdfView.autoScales = settings.autoScales
        pdfView.displayMode = settings.displayMode
        pdfView.displayDirection = settings.displayDirection
    }

    // MARK: - Coordinator Keeps Objects Alive

    class Coordinator: NSObject {
        var drawer: PDFDrawer?
        var gestureRecognizer: DrawingGestureRecognizer?
        var pdfView: PDFView?
        weak var actions: PDFKitViewActions?

        var lastPageIndex: Int?
        //  private var pageRefreshTimer: RepeatingTimer?
        private var timerPublisher: AnyCancellable?

        private let pdfSaveQueue = DispatchQueue(label: "com.yourapp.pdfSaveQueue")

        override init() {
            super.init()
            drawer = PDFDrawer()
        }

        func startPollingPageChanges() {
            // Cancel existing timer
            timerPublisher?.cancel()

            // Start a new Combine timer
            timerPublisher = Timer.publish(every: 0.1, on: .main, in: .common)
                .autoconnect()
                .map { [weak self] _ -> Int? in
                    guard let self = self else { return nil }
                    return self.getCurrentPageNumber()
                }
                .compactMap { $0 } // Remove nils
                .removeDuplicates() // Only emit when the page changes
                .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                .sink { [weak self] currentIndex in
                    guard let self = self else { return }
                    self.lastPageIndex = currentIndex
                    self.actions?.notifyPageChange(currentIndex)
                }
        }

        func stopPolling() {
            timerPublisher?.cancel()
            print("U>> timer deinit")
        }

        deinit {
            stopPolling()
            drawer = nil
        }

        func extractAnnotationData(from document: PDFDocument) -> Data? {
            var annotationsArray: [[String: Any]] = []

            for pageIndex in 0 ..< document.pageCount {
                guard let page = document.page(at: pageIndex) else { continue }

                for annotation in page.annotations {
                    var annotationDict: [String: Any] = [:]
                    annotationDict["page"] = pageIndex
                    annotationDict["type"] = annotation.type
                    annotationDict["bounds"] = [
                        "x": annotation.bounds.origin.x,
                        "y": annotation.bounds.origin.y,
                        "width": annotation.bounds.size.width,
                        "height": annotation.bounds.size.height,
                    ]

                    // Color and alpha
                    if let color = annotation.color.cgColor.components {
                        annotationDict["color"] = color
                        annotationDict["alpha"] = annotation.color.cgColor.alpha ?? 1.0
                    }

                    // Line width (for border)
                    if let lineWidth = annotation.border?.lineWidth {
                        annotationDict["lineWidth"] = lineWidth
                    }

                    // Handle ink paths
                    if annotation.type == "Ink" {
                        if let bezierPaths = annotation.value(forKey: "paths") as? [UIBezierPath] {
                            let serializedPaths = bezierPaths.map { path in
                                path.cgPath.elements().map { element in
                                    [
                                        "type": element.type.rawValue,
                                        "points": element.points.map { ["x": $0.x, "y": $0.y] },
                                    ]
                                }
                            }
                            annotationDict["inkPaths"] = serializedPaths
                        }
                    }

                    annotationsArray.append(annotationDict)
                }
            }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: annotationsArray, options: .prettyPrinted)
                return jsonData
            } catch {
                print("U>> Error encoding annotation data: \(error)")
                return nil
            }
        }

        public func applyAnnotations(from jsonData: Data, to document: PDFDocument) {
            guard let annotationsArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
                print("❌ Failed to decode annotation JSON")
                return
            }

            for annotationDict in annotationsArray {
                guard
                    let pageIndex = annotationDict["page"] as? Int,
                    let type = annotationDict["type"] as? String,
                    let boundsDict = annotationDict["bounds"] as? [String: CGFloat],
                    let page = document.page(at: pageIndex)
                else { continue }

                let bounds = CGRect(
                    x: boundsDict["x"] ?? 0,
                    y: boundsDict["y"] ?? 0,
                    width: boundsDict["width"] ?? 0,
                    height: boundsDict["height"] ?? 0
                )

                // Create the annotation
                let annotation = PDFAnnotation(bounds: bounds, forType: PDFAnnotationSubtype(rawValue: type), withProperties: nil)

                // Color
                if let colorComponents = annotationDict["color"] as? [CGFloat] {
                    let alpha = annotationDict["alpha"] as? CGFloat ?? 1.0
                    if colorComponents.count >= 3 {
                        annotation.color = UIColor(
                            red: colorComponents[0],
                            green: colorComponents[1],
                            blue: colorComponents[2],
                            alpha: alpha
                        )
                    }
                }

                // Line width
                if let lineWidth = annotationDict["lineWidth"] as? CGFloat {
                    let border = PDFBorder()
                    border.lineWidth = lineWidth
                    annotation.border = border
                }

                // Ink path reconstruction
                if type == "Ink",//PDFAnnotationSubtype.ink.rawValue,
                   let inkPathsArray = annotationDict["inkPaths"] as? [[[String: Any]]] {
                    for pathElementArray in inkPathsArray {
                        let path = UIBezierPath()
                        for (i, elementDict) in pathElementArray.enumerated() {
                            guard let typeRaw = elementDict["type"] as? Int,
                                  let type = CGPathElementType(rawValue: Int32(typeRaw)),
                                  let pointsArray = elementDict["points"] as? [[String: CGFloat]]
                            else { continue }

                            let points: [CGPoint] = pointsArray.compactMap { (pt: [String: CGFloat]) -> CGPoint? in
                                guard let x = pt["x"], let y = pt["y"] else { return nil }
                                return CGPoint(x: x, y: y)
                            }

                            switch type {
                            case .moveToPoint:
                                if let pt = points.first { path.move(to: pt) }
                            case .addLineToPoint:
                                if let pt = points.first { path.addLine(to: pt) }
                            case .addQuadCurveToPoint:
                                if points.count == 2 { path.addQuadCurve(to: points[1], controlPoint: points[0]) }
                            case .addCurveToPoint:
                                if points.count == 3 { path.addCurve(to: points[2], controlPoint1: points[0], controlPoint2: points[1]) }
                            case .closeSubpath:
                                path.close()
                            @unknown default:
                                break
                            }
                        }
                        annotation.add(path)
                    }
                }

                page.addAnnotation(annotation)
            }
        }

        func saveAnnotatedPDF(to url: URL, completion: @escaping (Bool) -> Void) {
//            let data = extractAnnotationData(from:  pdfView!.document!)

//            if let pdfDocument = pdfView?.document,
//               let jsonData = extractAnnotationData(from: pdfDocument) {
//               // StoredData.annotationData = jsonData
//
//                if let jsonString = String(data: jsonData, encoding: .utf8) {
//                    print("U>> \(jsonString)") // 👈 Pretty-printed JSON string
//                } else {
//                    print("U>> Failed to convert Data to String")
//                }
//            } else {
//                print("U>> Failed to extract annotation data")
//            }
//            pdfSaveQueue.async {
//                guard let pdfView = self.pdfView,
//                      let document = pdfView.document else {
//                    DispatchQueue.main.async {
//                        completion(false)
//                    }
//                    return
//                }
//
//                let success = document.write(to: url)
//
//                DispatchQueue.main.async {
//                    completion(success)
//                }
//            }
        }

//        func saveAnnotatedPDF(to url: URL, completion: @escaping (Bool) -> Void) {
//            DispatchQueue.global(qos: .userInitiated).async {
//                guard let document = self.pdfView?.document else {
//                    // print("No PDF document found in PDFView")
//                    DispatchQueue.main.async {
//                        completion(false)
//                    }
//                    return
//                }
//
//                let success = document.write(to: url)
//
//                DispatchQueue.main.async {
//                    if success {
//                        // print("PDF saved successfully to \(url)")
//                    } else {
//                        // print("Failed to save PDF")
//                    }
//                    completion(success)
//                }
//            }
//        }

        func setZoomSscale(scaleFactor: CGFloat) {
            pdfView?.scaleFactor = scaleFactor
        }

        func goToPage(_ number: Int) {
            guard let pdfView = pdfView,
                  let document = pdfView.document,
                  number > 0, number <= document.pageCount,
                  let page = document.page(at: number - 1) else { return }

            pdfView.go(to: page)
        }

        func getTotalPageNumber() -> Int? {
            guard let pdfView = pdfView,
                  let document = pdfView.document else { return nil }
            return document.pageCount
        }

        func getCurrentPageNumber() -> Int? {
            guard let pdfView = pdfView, let currentPage = pdfView.currentPage,
                  let index = pdfView.document?.index(for: currentPage) else {
                return nil
            }
            return index + 1
        }
    }
}

struct PathElement {
    let type: CGPathElementType
    let points: [CGPoint]
}

extension CGPath {
    func elements() -> [PathElement] {
        var elements: [PathElement] = []
        applyWithBlock { elementPtr in
            let element = elementPtr.pointee
            let type = element.type
            var points: [CGPoint] = []
            for i in 0 ..< numberOfPoints(for: type) {
                points.append(element.points[i])
            }
            elements.append(PathElement(type: type, points: points))
        }
        return elements
    }

    private func numberOfPoints(for type: CGPathElementType) -> Int {
        switch type {
        case .moveToPoint, .addLineToPoint: return 1
        case .addQuadCurveToPoint: return 2
        case .addCurveToPoint: return 3
        case .closeSubpath: return 0
        @unknown default: return 0
        }
    }
}

class StoredData {
    static var annotationData: Data?
}

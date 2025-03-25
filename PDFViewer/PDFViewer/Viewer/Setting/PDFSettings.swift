//
//  PDFSettings.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 25/3/25.
//

import SwiftUI
import PDFKit

class PDFSettings: ObservableObject {
    @Published var displayMode: PDFDisplayMode = .singlePageContinuous
    @Published var displayDirection: PDFDisplayDirection = .vertical
    @Published var autoScales: Bool = true
}

//
//  ControllerVM.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 2/4/25.
//

import Foundation
import PDFKit
import PencilKit
import SwiftUI

class ControllerVM: ObservableObject {
    @Published var selectedColor: Color = .black
    @Published var isExpanded = false
    @Published var showColorPalette = false
}

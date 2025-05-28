//
//  ReadingMode.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 18/5/25.
//


import SwiftUICore

enum ReadingMode: String, CaseIterable, Identifiable {
    case normal
    case night
    case sepia
    case eyeComfort

    var id: String { rawValue }

    var overlayColor: Color? {
        switch self {
        case .normal:
            return nil
        case .night:
            return Color.black.opacity(0.2)
        case .sepia:
            return Color(red: 244/255, green: 232/255, blue: 201/255).opacity(0.4)
        case .eyeComfort:
            return Color.yellow.opacity(0.2)
        }
    }
}

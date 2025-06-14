//
//  UserDefaultsHelper.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 14/6/25.
//

import Foundation
import CoreGraphics

final class UserDefaultsHelper {
    
    // MARK: - Singleton
    static let shared = UserDefaultsHelper()
    private init() {}
    
    // MARK: - Keys
    private let readingModeKey = "savedReadingMode"
    private let brightnessKey = "savedBrightness"

    // MARK: - Reading Mode (String)
    var savedReadingMode: String? {
        get {
            return UserDefaults.standard.string(forKey: readingModeKey)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: readingModeKey)
        }
    }

    // MARK: - Brightness (CGFloat)
    var savedBrightness: CGFloat {
        get {
            let value = UserDefaults.standard.object(forKey: brightnessKey) as? Double
            return CGFloat(value ?? 100.0) // Default to 1.0 if not set
        }
        set {
            UserDefaults.standard.set(Double(newValue), forKey: brightnessKey)
        }
    }
}

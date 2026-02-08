//
//  URL+Extentions.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 5/5/25.
//

import Foundation
import CryptoKit

extension URL {
    func toBookmarData() -> Data? {
        let bookmark = try? bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        return bookmark
    }
    
    
    func generatePDFKey() -> String {
        do {
            let resourceValues = try self.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
            let fileSize = resourceValues.fileSize ?? 0
            let creationDate = resourceValues.creationDate?.timeIntervalSince1970 ?? 0
            let combinedString = "\(fileSize)-\(creationDate)"
            let hash = SHA256.hash(data: Data(combinedString.utf8))
            return hash.map { String(format: "%02x", $0) }.joined()
        } catch {
            return UUID().uuidString
        }
    }
}

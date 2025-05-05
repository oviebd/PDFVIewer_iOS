//
//  URL+Extentions.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 5/5/25.
//

import Foundation

extension URL {
    func toBookmarData() -> Data? {
        let bookmark = try? bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        return bookmark
    }
}

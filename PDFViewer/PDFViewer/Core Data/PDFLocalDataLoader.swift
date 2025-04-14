//
//  PDFLocalDataLoader.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 14/4/25.
//

import Foundation

class PDFLocalDataLoader {
    public typealias CreationCompletion = (Bool) -> Void
    private let store: PDFLocalDataStore

    public init(store: PDFLocalDataStore) {
        self.store = store
    }

    public func insertPDFDatas(
        pdfDatas: [PDFCoreDataModel],
        completion: @escaping CreationCompletion
    ) {
        store.insert(pdfDatas: pdfDatas) { result in
            switch result {
            case let .success(datas):
                debugPrint("U>> Inserted \(String(describing: datas?.count)) files")
                completion(true)
                break
            case let .failure(error):
                debugPrint("U>> Fail insert error - \(error)")
                completion(false)
                break
            }
        }
    }
}

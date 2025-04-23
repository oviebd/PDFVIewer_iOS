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
        store.insert(pdfDatas: pdfDatas) { [weak self] result in
            guard let self = self else { return }
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
    
    public func retrieve(completion: @escaping ([PDFCoreDataModel]?) -> Void) {
        store.retrieve { [weak self] result in
            guard let _ = self else { return }
            switch result {
            case let .success(inspectiondata):
                completion(inspectiondata)
            default:
                completion(nil)
            }
        }
    }

    public func toggleFavorite( pdfItem : PDFCoreDataModel,
                                completion: @escaping (_ updatedData : PDFCoreDataModel? , _ isSuccess : Bool)  -> Void) {
        let parameters = ["key": pdfItem.key]
        
        let isFavourite = !pdfItem.isFavourite
        let newItem = PDFCoreDataModel(key: pdfItem.key, data: pdfItem.data, isFavourite: isFavourite)
        
        store.update(updatedData: newItem, completion: { result in
            switch result {
            case .success(let isSuccess):
                completion(newItem, isSuccess)
            default:
                completion(nil, false)
            }
        })
    }
    
   
    
    
}

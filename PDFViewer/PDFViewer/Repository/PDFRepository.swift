//
//  PDFRepository.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 27/4/25.
//

import Combine
import CryptoKit
import Foundation
import PDFKit

protocol PDFRepositoryProtocol {
    func insert(pdfDatas: [PDFModelData]) -> AnyPublisher<Bool, Error>
    func retrieve() -> AnyPublisher<[PDFModelData], Error>
    func getSingleData(pdfKey: String) -> AnyPublisher<PDFModelData, Error>
    func update(updatedPdfData: PDFModelData) -> AnyPublisher<PDFModelData, Error>
    func delete(pdfKey: String) -> AnyPublisher<Bool, Error>
    func insertFolders(folders: [FolderModelData]) -> AnyPublisher<Bool, Error>
    func retrieveFolders() -> AnyPublisher<[FolderModelData], Error>
    func updateFolder(updatedFolder: FolderModelData) -> AnyPublisher<FolderModelData, Error>
    func deleteFolder(folderId: String) -> AnyPublisher<Bool, Error>
}

final class PDFLocalRepositoryImpl: PDFRepositoryProtocol {
    
    private let store: PDFLocalDataStore

    init(store: PDFLocalDataStore) {
        self.store = store
    }

    func insert(pdfDatas: [PDFModelData]) -> AnyPublisher<Bool, Error> {
        var coreDataModels = [PDFCoreDataModel]()
        for pdfData in pdfDatas {
            let coreDataModel = pdfData.toCoereDataModel()
            coreDataModels.append(coreDataModel)
        }

        return store.insert(pdfDatas: coreDataModels)
    }

    func retrieve() -> AnyPublisher<[PDFModelData], Error> {
        store.retrieve()
            .tryMap { pdfCoreDataList in
                pdfCoreDataList.compactMap { singlePDfCoreData in
                    singlePDfCoreData.toPDfModelData()
                }
            }
            .eraseToAnyPublisher()
    }
    
    func delete(pdfKey: String) -> AnyPublisher<Bool, any Error> {
        store.delete(pdfKey: pdfKey)
    }

    func getSingleData(pdfKey: String) -> AnyPublisher<PDFModelData, any Error> {
        store.filter(parameters: ["key": pdfKey])
            .tryMap { entities in
                guard let singleEntity = entities.first else {
                    throw NSError(domain: "Repository", code: 404, userInfo: [NSLocalizedDescriptionKey: "PDF Item not found"])
                }
                return singleEntity.toCoreDataModel().toPDfModelData()
            }
            .eraseToAnyPublisher()
    }

    func update(updatedPdfData: PDFModelData) -> AnyPublisher<PDFModelData, any Error> {
        store.update(updatedData: updatedPdfData.toCoereDataModel())
            .tryMap {
                $0.toPDfModelData()
            }.eraseToAnyPublisher()
    }

    func insertFolders(folders: [FolderModelData]) -> AnyPublisher<Bool, Error> {
        let coreDataModels = folders.map { $0.toCoreDataModel() }
        return store.insertFolders(folders: coreDataModels)
    }

    func retrieveFolders() -> AnyPublisher<[FolderModelData], Error> {
        return store.retrieveFolders()
            .map { coreDataList in
                coreDataList.map { $0.toFolderModelData() }
            }
            .eraseToAnyPublisher()
    }

    func updateFolder(updatedFolder: FolderModelData) -> AnyPublisher<FolderModelData, Error> {
        return store.updateFolder(updatedData: updatedFolder.toCoreDataModel())
            .map { $0.toFolderModelData() }
            .eraseToAnyPublisher()
    }

    func deleteFolder(folderId: String) -> AnyPublisher<Bool, Error> {
        return store.deleteFolder(folderId: folderId)
    }
}

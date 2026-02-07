//
//  PDFLocalDataStore.swift
//  FoodBook
//
//  Created by Habibur Rahman on 21/10/24.
//

import Combine
import CoreData
import Foundation

class PDFLocalDataStore {
    public struct ModelNotFound: Error {
        public let modelName: String
    }

    public struct DataAlreadyExistError: Error {
        public let description: String
    }

    static let modelName = "PDFDataContainer"
    static let model = NSManagedObjectModel(name: modelName, in: Bundle(for: PDFLocalDataStore.self))

    private let container: NSPersistentContainer
    let context: NSManagedObjectContext

    public init(storeURL: URL? = nil) throws {
        if let storeURL = storeURL {
            // Test
            guard let model = PDFLocalDataStore.model else {
                throw ModelNotFound(modelName: PDFLocalDataStore.modelName)
            }
            container = try NSPersistentContainer.load(name: Self.modelName, model: model, url: storeURL)
            debugPrint("DB>> Stored DB in \(storeURL.absoluteString)")
        } else {
            container = NSPersistentContainer(name: Self.modelName)
            container.loadPersistentStores { _, error in
                if let error = error {
                    debugPrint("Error Loading Core Data - \(error)")
                }
            }
        }
        context = container.newBackgroundContext()
        whereIsMySQLite()
    }

    deinit { cleanUpReferencesToPersistentStores() }

    func insert(pdfDatas: [PDFCoreDataModel]) -> AnyPublisher<Bool, Error> {
        perform { context in
            let fetchRequest: NSFetchRequest<PDFEntity> = PDFEntity.fetchRequest()
            let existingKeys = try context.fetch(fetchRequest).compactMap(\.key)

            let newPDFs = pdfDatas.filter { !existingKeys.contains($0.key) }
            newPDFs.forEach { model in
                let entity = PDFEntity(context: context)
                entity.key = model.key
                entity.bookmarkData = model.bookmarkData
                entity.isFavourite = model.isFavourite
                entity.annotationData = model.annotationdata
            }
            do {
                try context.save()
                return true
            }catch{
                return false
            }
        }
    }

    func retrieve() -> AnyPublisher<[PDFCoreDataModel], Error> {
        perform { context in
            let request: NSFetchRequest<PDFEntity> = PDFEntity.fetchRequest()
            let results = try context.fetch(request)
            return results.map { entityData in
                entityData.toCoreDataModel()
            }
        }
    }

    func update(updatedData: PDFCoreDataModel) -> AnyPublisher<PDFCoreDataModel, Error> {
        filter(parameters: ["key": updatedData.key])
            .tryMap { [weak self] entities in
                guard let self,  let singleEntity = entities.first else { throw NSError(domain: "UpdateError", code: 404) }
               
                singleEntity.convertFromCoreDataModel(coreData: updatedData)

                do {
                    try context.save()
                    return updatedData
                }catch{
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }
//
    func delete(pdfKey: String) -> AnyPublisher<Bool, Error> {
        filter(parameters: ["key": pdfKey])
            .tryMap { [weak self] entities in
                guard let self, let object = entities.first else { throw NSError(domain: "DeleteError", code: 404) }
                context.delete(object)
                try self.context.save()
                return true
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Folder Operations

    func insertFolders(folders: [FolderCoreDataModel]) -> AnyPublisher<Bool, Error> {
        perform { context in
            folders.forEach { model in
                let entity = FolderEntity(context: context)
                entity.convertFromCoreDataModel(coreData: model)
            }
            do {
                try context.save()
                return true
            } catch {
                return false
            }
        }
    }

    func retrieveFolders() -> AnyPublisher<[FolderCoreDataModel], Error> {
        perform { context in
            let request: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
            let results = try context.fetch(request)
            return results.map { $0.toCoreDataModel() }
        }
    }

    func updateFolder(updatedData: FolderCoreDataModel) -> AnyPublisher<FolderCoreDataModel, Error> {
        filterFolders(parameters: ["id": updatedData.id])
            .tryMap { [weak self] entities in
                guard let self, let singleEntity = entities.first else { throw NSError(domain: "UpdateError", code: 404) }
                singleEntity.convertFromCoreDataModel(coreData: updatedData)
                try context.save()
                return updatedData
            }
            .eraseToAnyPublisher()
    }

    func deleteFolder(folderId: String) -> AnyPublisher<Bool, Error> {
        filterFolders(parameters: ["id": folderId])
            .tryMap { [weak self] entities in
                guard let self, let object = entities.first else { throw NSError(domain: "DeleteError", code: 404) }
                context.delete(object)
                try context.save()
                return true
            }
            .eraseToAnyPublisher()
    }

    func filterFolders(parameters: [String: Any]) -> AnyPublisher<[FolderEntity], Error> {
        perform { context in
            let request: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
            let predicates = parameters.map { NSPredicate(format: "%K == %@", $0.key, $0.value as! CVarArg) }
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            let results = try context.fetch(request)
            return results
        }
    }

    func filter(parameters: [String: Any]) -> AnyPublisher<[PDFEntity], Error> {
        perform { context in
            let request: NSFetchRequest<PDFEntity> = PDFEntity.fetchRequest()
            let predicates = parameters.map { NSPredicate(format: "%K == %@", $0.key, $0.value as! CVarArg) }
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.fetchLimit = 1
            let results = try context.fetch(request)
            if results.isEmpty {
                print("⚠️ DB Filter: No results for \(parameters)")
            }
            return results
        }
    }

//    func deleteAllRecordsBatch(for entityName: String) {
//        context.perform {
//            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
//            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//            do {
//                try self.context.execute(deleteRequest)
//                try self.context.save()
//            } catch {
//                debugPrint("Failed to batch delete \(entityName): \(error.localizedDescription)")
//            }
//        }
//    }

//    private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
//        context.perform { [context] in
//            action(context)
//        }
//    }

    private func cleanUpReferencesToPersistentStores() {
        context.performAndWait {
            let coordinator = self.container.persistentStoreCoordinator
            try? coordinator.persistentStores.forEach(coordinator.remove)
        }
    }

    // MARK: - Private Helpers

    private func perform<T>(_ action: @escaping (NSManagedObjectContext) throws -> T) -> AnyPublisher<T, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "PDFLocalDataStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self deallocated"])))
                return
            }

            self.context.perform {
                do {
                    let result = try action(self.context)
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func whereIsMySQLite() {
        if let path = NSPersistentContainer.defaultDirectoryURL().path.removingPercentEncoding {
            debugPrint("DB Location: \(path)")
        }
    }
}

extension PDFEntity {
    static func find(in context: NSManagedObjectContext) throws -> PDFEntity? {
        let request = NSFetchRequest<PDFEntity>(entityName: entity().name!)
        return try context.fetch(request).first
    }

    static func getInstance(in context: NSManagedObjectContext) throws -> PDFEntity {
        let instance = try find(in: context)
        return instance ?? PDFEntity(context: context)
    }
    
    func toCoreDataModel() -> PDFCoreDataModel {
        return PDFCoreDataModel(key: key ?? "",
                                bookmarkData: bookmarkData,
                                annotationdata: annotationData,
                                isFavourite: isFavourite,
                                lastOpenPage: Int(lastOpenedPage),
                                lastOpenTime: lastOpenTime)
    }
}

extension FolderEntity {
    func toCoreDataModel() -> FolderCoreDataModel {
        return FolderCoreDataModel(id: id ?? "",
                                   title: title ?? "",
                                   pdfIds: FolderCoreDataModel.parsePdfIds(pdfIds),
                                   createdAt: createdAt ?? Date(),
                                   updatedAt: updatedAt ?? Date())
    }

    func convertFromCoreDataModel(coreData: FolderCoreDataModel) {
        self.id = coreData.id
        self.title = coreData.title
        self.pdfIds = coreData.pdfIdsString
        self.createdAt = coreData.createdAt
        self.updatedAt = coreData.updatedAt
    }
}

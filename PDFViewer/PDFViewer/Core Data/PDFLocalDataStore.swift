//
//  PDFLocalDataStore.swift
//  FoodBook
//
//  Created by Habibur Rahman on 21/10/24.
//

import Combine
import CoreData
import Foundation

struct PDFCoreDataModel {
    var key: String
    var data: Data
    var isFavourite: Bool
    var lastReadTime: Date?
    var lastReadPageNumber: Int?
    
    func togglingFavorite() -> PDFCoreDataModel {
            PDFCoreDataModel(
                key: key,
                data: data,
                isFavourite: !isFavourite,
                lastReadTime: lastReadTime,
                lastReadPageNumber: lastReadPageNumber
            )
        }
}

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

    func insert(pdfDatas: [PDFCoreDataModel]) -> AnyPublisher<[PDFCoreDataModel], Error> {
        perform { context in
            let fetchRequest: NSFetchRequest<PDFEntity> = PDFEntity.fetchRequest()
            let existingKeys = try context.fetch(fetchRequest).compactMap(\.key)

            let newPDFs = pdfDatas.filter { !existingKeys.contains($0.key) }
            newPDFs.forEach { model in
                let entity = PDFEntity(context: context)
                entity.key = model.key
                entity.bookmarkData = model.data
                entity.isFavourite = model.isFavourite
            }
            try context.save()
            return newPDFs
        }
    }

    func retrieve() -> AnyPublisher<[PDFCoreDataModel], Error> {
        perform { context in
            let request: NSFetchRequest<PDFEntity> = PDFEntity.fetchRequest()
            let results = try context.fetch(request)
            return results.map { PDFCoreDataModel(key: $0.key ?? "", data: $0.bookmarkData ?? Data(), isFavourite: $0.isFavourite) }
        }
    }

    func update(updatedData: PDFCoreDataModel) -> AnyPublisher<Bool, Error> {
        filter(parameters: ["key": updatedData.key])
            .tryMap { [weak self] entities in
                guard let self, let object = entities.first else { throw NSError(domain: "UpdateError", code: 404) }
                object.key = updatedData.key
                object.bookmarkData = updatedData.data
                object.isFavourite = updatedData.isFavourite
                try self.context.save()
                return true
            }
            .eraseToAnyPublisher()
    }

    func delete(updatedData: PDFCoreDataModel) -> AnyPublisher<Bool, Error> {
        filter(parameters: ["key": updatedData.key])
            .tryMap { [weak self] entities in
                guard let self, let object = entities.first else { throw NSError(domain: "DeleteError", code: 404) }
                context.delete(object)
                try self.context.save()
                return true
            }
            .eraseToAnyPublisher()
    }

    func filter(parameters: [String: Any]) -> AnyPublisher<[PDFEntity], Error> {
        perform { context in
            let request: NSFetchRequest<PDFEntity> = PDFEntity.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:
                parameters.map { NSPredicate(format: "%K == %@", $0.key, "\($0.value)") }
            )
            request.fetchLimit = 1
            return try context.fetch(request)
        }
    }

    func deleteAllRecordsBatch(for entityName: String) {
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try self.context.execute(deleteRequest)
                try self.context.save()
            } catch {
                debugPrint("Failed to batch delete \(entityName): \(error.localizedDescription)")
            }
        }
    }

    private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        context.perform { [context] in
            action(context)
        }
    }

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
}

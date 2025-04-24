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
}

class PDFLocalDataStore {
    // static let instance = PDFDataStore()

    public struct ModelNotFound: Error {
        public let modelName: String
    }

    public struct DataAlreadyExistError: Error {
        public let description: String
    }

    public static let modelName = "PDFDataContainer"
    public static let model = NSManagedObjectModel(name: modelName, in: Bundle(for: PDFLocalDataStore.self))

    public typealias InsertionResult = Result<[PDFCoreDataModel]?, Error>
    public typealias InsertionCompletion = (InsertionResult) -> Void

    public typealias RetrievalResult = Result<[PDFCoreDataModel]?, Error>
    public typealias RetrievalCompletion = (RetrievalResult) -> Void

    public typealias FilterResultEntity = Result<[PDFEntity]?, Error>
    public typealias FilterCompletionEntity = (FilterResultEntity) -> Void

    public typealias SingleRetrievalResult = Result<PDFCoreDataModel?, Error>
    public typealias SingleRetrievalCompletion = (SingleRetrievalResult) -> Void

    private let container: NSPersistentContainer
    let context: NSManagedObjectContext

    public init(storeURL: URL? = nil) throws {
        if let storeURL = storeURL {
            // Test
            guard let model = PDFLocalDataStore.model else {
                throw ModelNotFound(modelName: PDFLocalDataStore.modelName)
            }

            container = try NSPersistentContainer.load(
                name: PDFLocalDataStore.modelName,
                model: model,
                url: storeURL
            )
            debugPrint("DB>> Stored DB in \(storeURL.absoluteString)")
            context = container.newBackgroundContext()

        } else {
            container = NSPersistentContainer(name: PDFLocalDataStore.modelName)
            container.loadPersistentStores { _, error in
                if let error = error {
                    debugPrint("Error Loading Core Data - \(error)")
                }
            }
            context = container.newBackgroundContext()

            whereIsMySQLite()
        }
    }

    func save() -> Bool {
        do {
            try context.save()
            debugPrint("Save SuccessFully")
            return true

        } catch {
            debugPrint("Error Saving Corae Data - \(error.localizedDescription)")
            return false
        }
    }

//    public func insert(pdfDatas: [PDFCoreDataModel], completion: @escaping InsertionCompletion) {
//        perform {[weak self] context in
//            guard let self = self else { return }
//            do {
//                let fetchRequest: NSFetchRequest<PDFEntity> = PDFEntity.fetchRequest()
//                var existingKeys = try context.fetch(fetchRequest).compactMap { $0.key }
//
//                // Filter out duplicates based on `key`
//                let newPDFs = pdfDatas.filter { !existingKeys.contains($0.key) }
//
//                for pdf in newPDFs {
//                    let key = pdf.key
//                    if existingKeys.contains(key) {
//                        continue
//                    }
//                    let newData = PDFEntity(context: self.context)
//
//                    newData.key = key
//                    newData.bookmarkData = pdf.data
//                    newData.isFavourite = pdf.isFavourite
//                    existingKeys.append(key)
//                    try context.save()
//                }
//                completion(.success(newPDFs))
//            } catch {
//                context.rollback()
//                completion(.failure(error))
//            }
//        }
//    }

    public func insert(pdfDatas: [PDFCoreDataModel]) -> AnyPublisher<[PDFCoreDataModel], Error> {
        return Future { [weak self] promise in
            self?.perform { context in
                guard let self = self else { return }

                do {
                    let fetchRequest: NSFetchRequest<PDFEntity> = PDFEntity.fetchRequest()
                    var existingKeys = try context.fetch(fetchRequest).compactMap { $0.key }

                    let newPDFs = pdfDatas.filter { !existingKeys.contains($0.key) }

                    for pdf in newPDFs {
                        let key = pdf.key
                        if existingKeys.contains(key) { continue }

                        let newData = PDFEntity(context: self.context)
                        newData.key = key
                        newData.bookmarkData = pdf.data
                        newData.isFavourite = pdf.isFavourite
                        existingKeys.append(key)
                    }

                    try context.save()
                    promise(.success(newPDFs))
                } catch {
                    context.rollback()
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func retrieve() -> AnyPublisher<[PDFCoreDataModel], Error> {
        return Future { [weak self] promise in
            self?.perform { context in
                do {
                    let fetchRequest: NSFetchRequest<PDFEntity> = PDFEntity.fetchRequest()
                    let results = try context.fetch(fetchRequest)

                    let models = results.map {
                        PDFCoreDataModel(
                            key: $0.key ?? "",
                            data: $0.bookmarkData ?? Data(),
                            isFavourite: $0.isFavourite
                        )
                    }

                    promise(.success(models))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

//    public func retrieve(completion: @escaping RetrievalCompletion) {
//        perform { context in
//
//            do {
//                let fetchRequest: NSFetchRequest<PDFEntity> = PDFEntity.fetchRequest()
//                let results = try context.fetch(fetchRequest)
//
//                let models = results.map {
//                    PDFCoreDataModel(key: $0.key ?? "", data: $0.bookmarkData ?? Data(), isFavourite: false)
//                }
//
//                completion(.success(models))
//
//            } catch {
//                completion(.failure(error))
//            }
//        }
//    }

//    public func update(updatedData: PDFCoreDataModel,
//                       completion: @escaping (Result<Bool, Error>) -> Void
//    ) {
//        perform { [weak self] _ in
//            guard let self = self else { return }
//            do {
//                let key = updatedData.key
//
//                self.filter(parameters: ["key": key]) { [weak self] result in
//                    guard let self = self else { return }
//                    switch result {
//                    case let .success(entityList):
//                        if let object = entityList?.first {
//                            object.key = updatedData.key
//                            object.bookmarkData = updatedData.data
//
//                            object.isFavourite = updatedData.isFavourite
//
//                            do {
//                                try self.context.save()
//                                completion(.success(true))
//                            } catch {
//                                completion(.failure(error))
//                            }
//                        }
//                        break
//
//                    case let .failure(error):
//
//                        print("Error fetching data: \(error)")
//                        completion(.failure(error))
//                        break
//                    }
//                }
//            }
//        }
//    }

//    public func filter(parameters: [String: Any], completion: @escaping FilterCompletionEntity) {
//        perform { context in
//            do {
//                let request: NSFetchRequest<PDFEntity> = PDFEntity.fetchRequest()
//                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:
//                    parameters.map { NSPredicate(format: "%K == %@", $0.key, "\($0.value)") }
//                )
//                request.fetchLimit = 1
//
//                let results = try context.fetch(request)
//
//                completion(.success(results))
//            } catch {
//                completion(.failure(error))
//            }
//        }
//    }

    public func update(updatedData: PDFCoreDataModel) -> AnyPublisher<Bool, Error> {
        filter(parameters: ["key": updatedData.key])
            .tryMap { [weak self] entityList in
                guard let self = self else {
                    throw NSError(domain: "PDFLocalDataLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self was deallocated"])
                }

                guard let object = entityList.first else {
                    throw NSError(domain: "PDFLocalDataLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "No entity found with matching key"])
                }

                object.key = updatedData.key
                object.bookmarkData = updatedData.data
                object.isFavourite = updatedData.isFavourite

                try self.context.save()

                return true
            }
            .eraseToAnyPublisher()
    }

    public func filter(parameters: [String: Any]) -> AnyPublisher<[PDFEntity], Error> {
        return Future { [weak self] promise in
            self?.perform { context in
                do {
                    let request: NSFetchRequest<PDFEntity> = PDFEntity.fetchRequest()
                    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:
                        parameters.map { NSPredicate(format: "%K == %@", $0.key, "\($0.value)") }
                    )
                    request.fetchLimit = 1

                    let results = try context.fetch(request)
                    promise(.success(results))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
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

    deinit {
        cleanUpReferencesToPersistentStores()
    }

    private func whereIsMySQLite() {
        let path = NSPersistentContainer
            .defaultDirectoryURL()
            .absoluteString
            .replacingOccurrences(of: "file://", with: "")
            .removingPercentEncoding

        debugPrint("D>> \(String(describing: path))")
    }

//
//    func deleteFullDB(){
//        deleteAllRecordsBatch(for: Constants.CORE_DATA.CurrencyEntity)
//        deleteAllRecordsBatch(for: Constants.CORE_DATA.CategoryEntity)
//        deleteAllRecordsBatch(for: Constants.CORE_DATA.AccountEntity)
//        deleteAllRecordsBatch(for: Constants.CORE_DATA.RecordEntity)
//    }

    private func deleteAllRecordsBatch(for entityName: String) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try context.save() // Save the context to persist changes
        } catch let error {
            print("Failed to batch delete all records for \(entityName): \(error.localizedDescription)")
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

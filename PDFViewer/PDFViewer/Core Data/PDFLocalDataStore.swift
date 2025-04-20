//
//  PDFLocalDataStore.swift
//  FoodBook
//
//  Created by Habibur Rahman on 21/10/24.
//

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

    public typealias SingleRetrievalResult = Result<PDFCoreDataModel?, Error>
    public typealias SingleRetrievalCompletion = (SingleRetrievalResult) -> Void

    private let container: NSPersistentContainer
    let context: NSManagedObjectContext

//    private init() {
//        container = NSPersistentContainer(name: Constants.CORE_DATA.dataContainer)
//        container.loadPersistentStores { (description, error) in
//            if let error = error {
//                print("Error Loading Core Data - \(error)")
//            }
//        }
//        context = container.viewContext
//
//        whereIsMySQLite()
//
//      //  deleteFullDB()
//    }

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

//    func addData(pdfDatas: [PDFCoreDataModel]) -> Bool {
//        context.perform {
//
//            for pdf in pdfDatas {
//                let newData = PDFEntity(context: self.context)
//                newData.key = pdf.key
//                newData.bookmarkData = pdf.data
//                self.save()
//            }
//        }
//
//        return save()
//    }

    public func insert(pdfDatas: [PDFCoreDataModel], completion: @escaping InsertionCompletion) {
        perform { context in
            do {
                let fetchRequest: NSFetchRequest<PDFEntity> = PDFEntity.fetchRequest()
                var existingKeys = try context.fetch(fetchRequest).compactMap { $0.key }

                // Filter out duplicates based on `key`
                let newPDFs = pdfDatas.filter { !existingKeys.contains($0.key) }

                for pdf in newPDFs {
                    let key = pdf.key
                    if existingKeys.contains(key) {
                        continue
                    }
                    let newData = PDFEntity(context: self.context)

                    newData.key = key
                    newData.bookmarkData = pdf.data
                    newData.isFavourite = pdf.isFavourite
                    existingKeys.append(key)
                    try context.save()
                }

                // If there's nothing to insert
//                guard !newPDFs.isEmpty else {
//                    completion(.failure(DataAlreadyExistError(description: "Selected data already exist")))
//                    return
//                }

                completion(.success(newPDFs))
            } catch {
                context.rollback()
                completion(.failure(error))
            }
        }
    }

    public func retrieve(completion: @escaping RetrievalCompletion) {
        perform { context in

            do {
                let fetchRequest: NSFetchRequest<PDFEntity> = PDFEntity.fetchRequest()
                let results = try context.fetch(fetchRequest)

                let models = results.map {
                    PDFCoreDataModel(key: $0.key ?? "", data: $0.bookmarkData ?? Data(), isFavourite: false)
                }

                completion(.success(models))

            } catch {
                completion(.failure(error))
            }
        }
    }

    public func filter(parameters: [String: Any], completion: @escaping RetrievalCompletion) {
        perform { context in
            do {
                let request: NSFetchRequest<PDFEntity> = PDFEntity.fetchRequest()
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:
                    parameters.map { NSPredicate(format: "%K == %@", $0.key, "\($0.value)") }
                )
                request.fetchLimit = 1

                let results = try context.fetch(request)

                let models = results.map {
                    PDFCoreDataModel(key: $0.key ?? "", data: $0.bookmarkData ?? Data(), isFavourite: false)
                }

                completion(.success(models))
            } catch {
                completion(.failure(error))
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

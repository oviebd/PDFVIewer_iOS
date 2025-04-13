//
//  PDFDataStore.swift
//  FoodBook
//
//  Created by Habibur Rahman on 21/10/24.
//


import CoreData
import Foundation

class PDFDataStore {
    
   // static let instance = PDFDataStore()
   
    public struct ModelNotFound: Error {
        public let modelName: String
    }

    public static let modelName = "PDFDataContainer"
    public static let model = NSManagedObjectModel(name: modelName, in: Bundle(for: PDFDataStore.self))


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
            guard let model = PDFDataStore.model else {
                throw ModelNotFound(modelName: PDFDataStore.modelName)
            }

            container = try NSPersistentContainer.load(
                name: PDFDataStore.modelName,
                model: model,
                url: storeURL
            )
            debugPrint("DB>> Stored DB in \(storeURL.absoluteString)")
            context = container.newBackgroundContext()

        } else {
            container = NSPersistentContainer(name: PDFDataStore.modelName)
            container.loadPersistentStores { _, error in
                if let error = error {
                    debugPrint("Error Loading Core Data - \(error)")
                }
            }
            context = container.newBackgroundContext()

            whereIsMySQLite()
        }
    }
    
    func save() -> Bool{
        do{
            try context.save()
            debugPrint("Save SuccessFully")
            return true
           
        }catch{
            debugPrint("Error Saving Corae Data - \(error.localizedDescription)")
            return false
        }
    }
    
    func addData(pdfDatas: [PDFCoreDataModel]) -> Bool {
        
        context.perform {
            for pdf in pdfDatas {
                let newData = PDFEntity(context: self.context)
                newData.key = pdf.key
                newData.bookmarkData = pdf.data
                self.save()
            }
        }

        return save()
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

  

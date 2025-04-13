//
//  CoreDataManager.swift
//  FoodBook
//
//  Created by Habibur Rahman on 21/10/24.
//


import CoreData
import Foundation

class PDFDataStore {
    
    static let instance = PDFDataStore()
    public struct ModelNotFound: Error {
        public let modelName: String
    }

    public static let modelName = "InspectionContainer"
    public static let model = NSManagedObjectModel(name: modelName, in: Bundle(for: PDFDataStore.self))

    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    private init() {
        container = NSPersistentContainer(name: Constants.CORE_DATA.dataContainer)
        container.loadPersistentStores { (description, error) in
            if let error = error {
                print("Error Loading Core Data - \(error)")
            }
        }
        context = container.viewContext
  
        whereIsMySQLite()
        
      //  deleteFullDB()
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

  

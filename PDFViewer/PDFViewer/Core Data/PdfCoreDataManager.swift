//
//  PdfCoreDataManager.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 12/4/25.
//

import Foundation
import CoreData

class PdfCoreDataManager {
    
    
//    let manager = CoreDataManager(storeURL: nil)
//
//    func addPdfBookmarkData(pdfDatas: [PDFCoreDataModel]) -> Bool {
//        
//        manager.context.perform {
//            for pdf in pdfDatas {
//                let newData = PDFEntity(context: self.manager.context)
//                newData.key = pdf.key
//                newData.bookmarkData = pdf.data
//                self.manager.save()
//            }
//        }
//        
//        
//        
////        newRecipe.name = recipe.name
////        newRecipe.category = recipe.category
////        newRecipe.ingridients = recipe.ingredients
////        newRecipe.id = recipe.id
////        newRecipe.duration = recipe.duration
////        newRecipe.fileName = recipe.image ?? ""
//
//        return manager.save()
//    }
    
//
//    func updateRecipe(recipe: Recipe) -> Bool {
//        guard let updateEntity = getRecipeEntity(from: recipe.id) else {
//            return true
//        }
//
//        updateEntity.name = recipe.name
//        updateEntity.category = recipe.category
//        updateEntity.id = recipe.ingredients
//        updateEntity.duration = recipe.duration
//        updateEntity.ingridients = recipe.ingredients
//
//        let isSuccess = manager.save()
//
//        return isSuccess
//    }
//    
//    
//    private func getRecipeEntity(from id: String) -> RecipeEntity? {
//        let request = RecipeEntity.fetchRequest()
//        let idPredicate = NSPredicate(format: "id = %@", id)
//        request.predicate = idPredicate
//        do {
//            let datas = try manager.context.fetch(request) // returns array of recipe entity
//            return datas.first
//        } catch {
//            print("Error Fetching.. \(error.localizedDescription)")
//            return nil
//        }
//    }
//
//    func fetchRecipe(from id: String) -> Recipe? {
//        let recipeEntity = getRecipeEntity(from: id)
//        return recipeEntity?.toRecipe()
//    }
//
//    func fetchRecipes() -> [Recipe] {
//        let request = NSFetchRequest<RecipeEntity>(entityName: "RecipeEntity")
//        var recipies: [Recipe] = []
//        do {
//            let savedEntities = try manager.context.fetch(request)
//            for singleEntity in savedEntities {
//                let singleRecipe = singleEntity.toRecipe()
//                recipies.append(singleRecipe)
//            }
//        } catch let error {
//            print("Error fetching, \(error)")
//        }
//        return recipies
//    }
//
//    func deleteRecipe(for id : String) -> Bool {
//        if let entity = getRecipeEntity(from: id) {
//            manager.context.delete(entity)
//            let isSuccess = manager.save()
//            if isSuccess {
//                return true
//            }
//        }
//        return false
//    }

    
}

//private extension PdfCoreDataManager {
//    func toRecipe() -> Recipe {
//        return Recipe(name: name ?? "",
//                      details: NSAttributedString(),
//                      ingredients: ingridients ?? "",
//                      duration: duration ?? "",
//                      image: fileName,
//                      category: category ?? "",
//                      id: id ?? "")
//    }
//}

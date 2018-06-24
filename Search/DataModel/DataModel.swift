//
//  File.swift
//  Core-Data
//
//  Created by vlad on 6/23/18.
//  Copyright © 2018 vlad. All rights reserved.
//

import Foundation
import CoreData

class DataModel {
    static let shared = DataModel()
    
    private init() {
    }
    
    // MARK: Core Data Stack setup
    private lazy var managedObjectContext: NSManagedObjectContext = {
        
        var managedObjectContext: NSManagedObjectContext?
        if #available(iOS 10.0, *){
            
            managedObjectContext = self.persistentContainer.viewContext
        } else {
            // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
            let coordinator = self.persistentStoreCoordinator
            managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            managedObjectContext?.persistentStoreCoordinator = coordinator
            
        }
        return managedObjectContext!
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "DataModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("DataModel.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            // Configure automatic migration.
            let options = [ NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true ]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        } catch {
            do {
                try FileManager.default.removeItem(at: url)
                try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
            } catch {
                // Report any error we got.
                var dict = [String: AnyObject]()
                dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
                dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
                
                dict[NSUnderlyingErrorKey] = error as NSError
                let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
                // Replace this with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
                abort()
            }
        }
        
        return coordinator
    }()
    
    // iOS-10
    @available(iOS 10.0, *)
    private lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "DataModel")
        
        let url = self.applicationDocumentsDirectory.appendingPathComponent("DataModel.sqlite")
        let description = NSPersistentStoreDescription(url: url)
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                do {
                    let url = self.applicationDocumentsDirectory.appendingPathComponent("DataModel.sqlite")
                    try FileManager.default.removeItem(at: url)
                    let container = NSPersistentContainer(name: "DataModel")
                    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                        if let error = error as NSError? {
                            // Replace this implementation with code to handle the error appropriately.
                            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                            
                            /*
                             Typical reasons for an error here include:
                             * The parent directory does not exist, cannot be created, or disallows writing.
                             * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                             * The device is out of space.
                             * The store could not be migrated to the current model version.
                             Check the error message to determine what the actual problem was.
                             */
                            fatalError("Unresolved error \(error), \(error.userInfo)")
                        }
                    })
                } catch let error {
                    fatalError("Unresolved error \(error)")
                }
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    // MARK: private
    private lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    private func emptyObject(name: String) -> NSManagedObject {
        let entity = NSEntityDescription.entity(forEntityName: name, in: managedObjectContext)!
        return NSManagedObject(entity:entity, insertInto:managedObjectContext)
    }
    
    private func fetchUniqueEntity(request: NSFetchRequest<NSFetchRequestResult>) -> Any? {
        let fetchedObjects = fetchEntities(request: request)
        assert(fetchedObjects.count <= 1, "only one object can exist with specified id")
        
        if fetchedObjects.count > 1 {
            // try to recover by deleting all objects with given id
            for fetchedObject in fetchedObjects {
                managedObjectContext.delete(fetchedObject as! NSManagedObject)
            }
            
            return nil
        } else if fetchedObjects.count == 1 {
            return fetchedObjects[0]
        }
        
        return nil
    }
    
    private func recycleUniqueEntity(entity: ModelMapper.Type, id: String) -> Any? {
        guard let fetchedEntity = fetchUniqueEntity(request: entity.fetchRequest(stringId: id)) else {
            return emptyObject(name: entity.entityName)
        }
        
        return fetchedEntity
    }
    
    private func recycleUniqueEntity(entity: ModelMapper.Type, id: Int32) -> Any? {
        guard let fetchedEntity = fetchUniqueEntity(request: entity.fetchRequest(id: id)) else {
            return emptyObject(name: entity.entityName)
        }
        
        return fetchedEntity
    }
    
    private func remove(object: NSManagedObject)  {
        managedObjectContext.delete(object)
    }
    
    private func remove(entity: ModelMapper.Type){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            if #available(iOS 10.0, *) {
                try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: managedObjectContext)
            } else {
                _ = try persistentStoreCoordinator.execute(deleteRequest, with: managedObjectContext)
            }
        } catch _ as NSError {
            // TODO: handle the error
        }
    }
    
    // MARK: public
    func fetchEntities(request: NSFetchRequest<NSFetchRequestResult>) -> [Any] {
        do {
            let fetchedObjects = try managedObjectContext.fetch(request)
            return fetchedObjects
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
    }
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                if #available(iOS 10.0, *) {
                    try persistentContainer.viewContext.save()
                } else {
                    try managedObjectContext.save()
                }
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    // MARK: parsing
    func parseListOfReposytorys(data: [[String : Any]]) -> [Repository] {
        var repositorys: [Repository] = []
        for node in data {
            guard let repository = parseRepository(data: node) else { continue }
            repositorys.append(repository)
        }
        return repositorys
    }
    
    func parseRepository(data: [String : Any]) -> Repository? {
        
        if let id = data["id"] as? Int32 {
            guard let fetchedRepository = recycleUniqueEntity(entity: Repository.self,
                                                              id: id) as? Repository else { return nil }
            fetchedRepository.parse(node: data)
            return fetchedRepository
        }
        return nil
    }
    
    // MARK: Fetching
    func getHistoryList() -> [String]? {
        guard let request = NSFetchRequest<Repository>(entityName: "Repository") as? NSFetchRequest<NSFetchRequestResult> else { return nil }
        let fetchedRepositories = fetchEntities(request: request) as? [Repository]
        
        guard let results = fetchedRepositories?.compactMap({$0.searchName}) else { return nil }
        return Array(Set(results))
    }
    
    func getResultBySearchName(_ searchName: String) -> [Repository]? {
        guard let request = NSFetchRequest<Repository>(entityName: "Repository") as? NSFetchRequest<NSFetchRequestResult> else { return nil }
        request.predicate = NSPredicate(format: "searchName == [cd] '\(searchName)'", argumentArray: [])
        request.sortDescriptors = [NSSortDescriptor(key: "stars", ascending: false)]
        return fetchEntities(request: request) as? [Repository]
    }
}

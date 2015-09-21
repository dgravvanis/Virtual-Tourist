//
//  CoreDataStack.swift
//  Virtual Tourist
//
//  Created by Dimitrios Gravvanis on 25/8/15.
//  Copyright (c) 2015 dgravvanis. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    // MARK: Properties
    // Singleton
    static let sharedInstance = CoreDataStack()
    static let moduleName = "Virtual_Tourist"
    
    // MARK: Core Data stack
    lazy var managedObjectModel: NSManagedObjectModel = {
        
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource(moduleName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    lazy var applicationDocumentsDirectory: NSURL = {
        
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.dgravvanis.Virtual_Tourist" in the application's documents Application Support directory.
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let persistentStoreURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent("\(moduleName).sqlite")
        
        do {
            try coordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: persistentStoreURL, options: nil)
        }catch{
            fatalError("Persistent store error! \(error)")
        }
        
        return coordinator
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        guard let coordinator = self.persistentStoreCoordinator else {
            return nil
        }
        
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    func saveMainContext() {
        
        guard let moc = self.managedObjectContext else {
            // Handle error
            return
        }
        
        if moc.hasChanges {
            do {
                try moc.save()
            } catch {
                fatalError("Error saving main managed object context! \(error)")
            }
        }
    }
}
//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Dimitrios Gravvanis on 30/8/15.
//  Copyright (c) 2015 dgravvanis. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)

class Photo: NSManagedObject {
    
    // MARK: Core Data attributes
    @NSManaged var farm: String
    @NSManaged var server: String
    @NSManaged var id: String
    @NSManaged var secret: String
    @NSManaged var urlString: String
    @NSManaged var filename: String
    @NSManaged var pin: Pin
    @NSManaged var saved: Bool
    
    // MARK: Core Data init method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // MARK: Initializer
    init(farm: String, server: String, id: String, secret: String, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.farm = farm
        self.server = server
        self.id = id
        self.secret = secret
        self.urlString = "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_t.jpg"
        self.filename = "\(id)_\(secret)_t.jpg"
        self.saved = false
    }
}

// MARK: Delete underlying file
extension Photo {

    override func prepareForDeletion() {
        
        deleteUnderlyingFile(filename)
    }
    
    // Delete the underlying photo file
    func deleteUnderlyingFile(filename: String) {
        
        // Get path for documents directory
        if let documentsPath = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first {
            
            // Create file path
            let filePath = documentsPath.URLByAppendingPathComponent(filename)
            
            // Instantiate file manager
            let fileManager = NSFileManager.defaultManager()
            
            do{
                // Remove file
                try fileManager.removeItemAtURL(filePath)
            }
            catch{
                // Handle error
                print("deleteUnderlyingFile(): \(error)")
            }
        }
    }
}
//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Dimitrios Gravvanis on 25/8/15.
//  Copyright (c) 2015 dgravvanis. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Pin)

class Pin: NSManagedObject, MKAnnotation {
    
    // Core Data attributes
    @NSManaged var title: String?
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]
    
    var coordinate: CLLocationCoordinate2D {
        set (newValue) {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }

        get{
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

    // Core Data init method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // Initializer
    init(title: String, coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.title = title
        self.coordinate = coordinate
    }
}
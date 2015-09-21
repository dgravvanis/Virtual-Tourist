//
//  CoordinateToNSDataTransformer.swift
//  Virtual Tourist
//
//  Created by Dimitrios Gravvanis on 12/9/15.
//  Copyright (c) 2015 dgravvanis. All rights reserved.
//

import Foundation
import MapKit

@objc(CoordinateToNSDataTransformer)

class CoordinateToNSDataTransformer: NSValueTransformer {
    
    override class func transformedValueClass() -> AnyClass{
        return NSData.classForCoder()
    }
    
    override class func allowsReverseTransformation() -> Bool {
        
        return true
    }
    
    override func transformedValue(value: AnyObject!) -> AnyObject {
        
        let coordinates = value as! CLLocationCoordinate2D
        let dic = [coordinates.latitude, coordinates.longitude]
        let a = NSKeyedArchiver.archivedDataWithRootObject(dic)
        
        return a
    }
}
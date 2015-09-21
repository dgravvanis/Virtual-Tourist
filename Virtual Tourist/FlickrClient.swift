//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Dimitrios Gravvanis on 27/8/15.
//  Copyright (c) 2015 dgravvanis. All rights reserved.
//

import Foundation
import CoreData
import UIKit

// flickr API Client
class FlickrClient: NSObject {
    
    // Singleton
    static let sharedInstance = FlickrClient()
    
    // MARK: Variables
    private var session: NSURLSession = NSURLSession.sharedSession()
    
    // Core data main context
    lazy var sharedContext: NSManagedObjectContext =  {
        CoreDataStack.sharedInstance.managedObjectContext!
        }()
    
    // MARK: Methods
    // Generate the url for the search request based on pin coordinates
    private func generateSearchURLFromPin(latitude: Double, longitude: Double) -> NSURL? {
        
        // Unix time stamp. One year old pictures
        let date = NSDate().dateByAddingTimeInterval(-60.0 * 60 * 24 * 365).timeIntervalSince1970
        
        let components = NSURLComponents()
        components.scheme = Constants.scheme
        components.host = Constants.host
        components.path = Constants.path
        
        components.queryItems = [
            NSURLQueryItem(name: URLKeys.method, value: Methods.searchPhotos),
            NSURLQueryItem(name: URLKeys.apiKey, value: Constants.apiKey),
            NSURLQueryItem(name: URLKeys.responseFormat, value: URLValues.responseFormatValue),
            NSURLQueryItem(name: URLKeys.noJsonCallBack, value: URLValues.noJsonCallBackValue),
            NSURLQueryItem(name: URLKeys.photosPerPage, value: URLValues.photosPerPageValue),
            NSURLQueryItem(name: URLKeys.minUploadDate, value: date.description),
            NSURLQueryItem(name: URLKeys.latitude, value: latitude.description),
            NSURLQueryItem(name: URLKeys.longitude, value: longitude.description)
        ]
        
        return components.URL
    }
    
    // Make http get request
     private func httpGetRequest(url: NSURL, completionHandler: (success: Bool, data: NSData?, error: NSError?) -> Void) {
        
        let task = session.dataTaskWithURL(url) { data, response, error in
            
            if let error = error {
                completionHandler(success: false, data: data, error: error)
            }
            completionHandler(success: true, data: data, error: error)
        }
        
        // Start the request
        task.resume()
    }
    
    // Save the photo
    func savePhoto(dictionary: [String: AnyObject], pin: Pin) {
        
        //let pin = privateMOC.objectWithID(pinId) as! Pin
        
        if let farm = dictionary[JSONResponseKeys.farm] as? Int,
            let server = dictionary[JSONResponseKeys.server] as? String,
            let id = dictionary[JSONResponseKeys.id] as? String,
            let secret = dictionary[JSONResponseKeys.secret] as? String {
        
                // Create a new photo, using the shared context
                let photoToBeAdded = Photo(farm: farm.description, server: server, id: id, secret: secret, context: sharedContext)
                
                photoToBeAdded.pin = pin
                
                // Download and save the image
                saveImageFromPhotoObject(photoToBeAdded)
        }
    }
    
    func getPhotosFromPinLocation(pin: Pin){
        
        var parsedPhotos = [[String: AnyObject]]()
        var randomPhotos = [[String: AnyObject]]()
        
        // Generate the url
        guard let url = generateSearchURLFromPin(pin.latitude, longitude: pin.longitude) else {
            // Handle error
            print("getPhotosFromPinLocation: url is Nil")
            return
        }
        
        // Make http get request
        httpGetRequest(url) { success, rawJSON, error in
        
            guard let rawJSON = rawJSON else {
                // Handle error
                print("getPhotosFromPinLocation: \(error)")
                return
            }
            
            // Parse JSON
            do {
                let parsedResult = try NSJSONSerialization.JSONObjectWithData(rawJSON, options: .AllowFragments)
                
                // Check parsed result for key photos
                guard let photos = parsedResult.valueForKey(JSONResponseKeys.photos) as? [String: AnyObject] else {
                    // Handle error
                    print("getPhotosFromPinLocation: photos key not found in results")
                    return
                }
                
                // Store the photos in an array
                parsedPhotos = photos["photo"] as! [[String: AnyObject]]
                
            } catch {
                // Handle error
                print("getPhotosFromPinLocation,: \(error)")
                return
            }
            
            // Select 21 random photos
            if parsedPhotos.count > 21 {
                
                let randomNumbers = self.generateXRandomUniqueInts(21, max: parsedPhotos.count)
                for number in randomNumbers {
                    randomPhotos.append(parsedPhotos[number])
                }
            } else {
                randomPhotos = parsedPhotos
            }
            
            // Create Photo objects
            for photo in randomPhotos {
                self.savePhoto(photo, pin: pin)
            }
            
        }
    }
    
    // MARK: Helpers
    func saveImageFromPhotoObject(photo: Photo) {
        
        // Convert urlString to NSURL
        guard let url = NSURL(string: photo.urlString) else {
            // Handle error
            print("saveImageFromPhotoObject: url is Nil")
            return
        }
        
        let request = NSURLRequest(URL: url)
        
        // Download the file asynchronously
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { response, data, error in
        
            guard let data = data else {
                // Handle error
                print("saveImageFromPhotoObject: \(error)")
                return
            }
            
            // Get image as JPEG
            if let image = UIImage(data: data),
                let imageJPEG =  UIImageJPEGRepresentation(image,1.0),
            // Get documents directory path
                let documentsPath = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first {
                    
                    // Create file path
                    let filePath = documentsPath.URLByAppendingPathComponent(photo.filename)
                    
                    do {
                        // Save file and update photo saved property
                        try imageJPEG.writeToFile(filePath.path!, options: NSDataWritingOptions.DataWritingAtomic)
                        photo.saved = true
                    }catch{
                        //Handle errror
                        print("saveImageFromPhotoObject: \(error)")
                    }
                    
            } else {
                // Handle error
                print("saveImageFromPhotoObject: image file was not saved")
            }
        }
    }
    
    func generateXRandomUniqueInts(x: Int, max: Int) -> [Int] {
        
        var randomNumbers = [Int]()
        
        repeat {
            // Create random number
            let randomNumber = Int(arc4random_uniform(UInt32(max)))
            if !randomNumbers.contains(randomNumber) {
                randomNumbers.append(randomNumber)
            }
        } while randomNumbers.count < x
        
        return randomNumbers
    }
}
//
//  TravelLocationsMapView.swift
//  Virtual Tourist
//
//  Created by Dimitrios Gravvanis on 30/7/15.
//  Copyright (c) 2015 dgravvanis. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

class TravelLocationsMapView: UIViewController, MKMapViewDelegate, UISearchBarDelegate {
    
    // MARK: Properties
    var selectedPinId: NSManagedObjectID?
    
    // Core data context
    lazy var sharedContext: NSManagedObjectContext = {
        CoreDataStack.sharedInstance.managedObjectContext!
        }()
    
    // Map's region filepath
    lazy var mapRegionFilePath: String = {
        let documentsPath = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        return documentsPath!.URLByAppendingPathComponent("mapRegionArchive").path!
        }()
    
    // MARK: - Fetched Results Controller
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        // Create the fetch request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Add a sort descriptor.
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: false)]
        
        // Create the Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Return the fetched results controller. It will be the value of the lazy variable
        return fetchedResultsController
        }()
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the delegate
        mapView.delegate = self
        searchBar.delegate = self
        
        // Fetch pins from core data.
        do {
            try fetchedResultsController.performFetch()
        } catch {
             print("Unresolved error \(error)")
        }
        
        // Initialize map
        restoreMapRegion(false)
        mapView.addAnnotations(fetchedResultsController.fetchedObjects as! [Pin])
        searchBar.hidden = true
    }
    
    // MARK: Search Bar Delegate Methods
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        
        // Make local request from the string in the search bar
        let localSearchRequest = MKLocalSearchRequest()
        localSearchRequest.naturalLanguageQuery = searchBar.text
        let localSearch = MKLocalSearch(request: localSearchRequest)
        
        localSearch.startWithCompletionHandler { localSearchResponse, error in
            
            // If there is an error, show error message
            if let error = error {
                
                self.presentErrorAlertView("Location not found")
                return
            }
            
            // If location found, go to that location
            if let response = localSearchResponse {
                
                let location = response.mapItems.first
                let placemark = location!.placemark
                
                if let pmCircularRegion = placemark.region as? CLCircularRegion {
                    
                    let metersAcross = pmCircularRegion.radius * 2
                    let region = MKCoordinateRegionMakeWithDistance(pmCircularRegion.center, metersAcross, metersAcross)
                    self.mapView.setRegion(region, animated: true)
                    
                    // Hide search bar
                    self.searchBar.resignFirstResponder()
                    searchBar.text = ""
                    searchBar.hidden = true
                }
            }
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        
        // Hide the search bar
        searchBar.resignFirstResponder()
        searchBar.text = ""
        searchBar.hidden = true
    }
    
    // MARK: Map View Delegate Methods
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        // Save the map region every time the region changes
        saveMapRegion()
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        // Configure annotation view
        var view: MKPinAnnotationView
        
        if let annotation = annotation as? Pin,
            let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier("pin") as? MKPinAnnotationView {
            
                dequeuedView.annotation = annotation
                view = dequeuedView
        }else{
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            view.canShowCallout = true
            view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
            view.draggable = true
            view.animatesDrop = true
        }
        return view
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let pinSelected = view.annotation as? Pin {
            
            // Get the selected pin
            self.selectedPinId = pinSelected.objectID
            
            // Perform segue
            performSegueWithIdentifier("ShowPhotoAlbum", sender: self)
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        switch (newState) {
        case .Starting:
            
            if let oldPin = view.annotation as? Pin {
                for photo in oldPin.photos {
                    
                    // Delete old pictures
                   sharedContext.deleteObject(photo)
                }
            }
            
        case .Ending:

            if let pinToBeUpdated = view.annotation as? Pin {
                
                // Get location name
                getLocationNameFromCoordinate(pinToBeUpdated.coordinate) { location, error in
                    
                    if let title = location {
                        // Update the title
                        pinToBeUpdated.title = title
                        
                        // Add annotation to map
                        self.mapView.addAnnotation(pinToBeUpdated)
                        
                        // Save the context
                        CoreDataStack.sharedInstance.saveMainContext()
                        
                        // Get photos from pin location
                        FlickrClient.sharedInstance.getPhotosFromPinLocation(pinToBeUpdated)
                    }
                }
            }
            
        default: break
        }
    }
    
    // MARK: Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "ShowPhotoAlbum" {
            
            // Get destination controller
            if let destinationVC = segue.destinationViewController as? PhotoAlbumView {
                
                // Pass the pin to the destination controller
                destinationVC.pinId = sender?.selectedPinId
                // Pass the map span
                destinationVC.mapSpan = self.mapView.region.span
            }
        }
    }
    
    // MARK: Actions
    @IBAction func showSearchBar(sender: UIBarButtonItem) {
        
        searchBar.hidden = false
    }
    
    @IBAction func longPressGesture(sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Began {
            
            // Get the spot that was touched and
            // convert it to coordinates
            let tapPoint = sender.locationInView(mapView)
            let coordinate = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
            
            // Get location name
            getLocationNameFromCoordinate(coordinate) { location, error in
                
                if let title = location {
                    
                    // Create a new pin, using the private context
                    let pinToBeAdded = Pin(title: title, coordinate: coordinate, context: self.sharedContext)
                    
                    // Add annotation to map
                    self.mapView.addAnnotation(pinToBeAdded)
                    
                    // Save the context
                    CoreDataStack.sharedInstance.saveMainContext()
                    
                    // Get photos from pin location
                    FlickrClient.sharedInstance.getPhotosFromPinLocation(pinToBeAdded)
                }
            }
        }
    }
    
    // MARK: Helpers
    // Save the Map Region and Zoom Level
    func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: mapRegionFilePath)
    }
    
    // Restore the Map Region and Zoom Level
    func restoreMapRegion(animated: Bool) {
        
        // Unarchive the dictionary from the filePath
        // Restore the map from saved state
        
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(mapRegionFilePath) as? [String : AnyObject] {
            
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
    
    // Get location name from the pin on the map
    func getLocationNameFromCoordinate(coordinate: CLLocationCoordinate2D, completionHandler: (location: String!, error: NSError!) -> Void) {
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Make reverse GeocodeLocation from the coordinates
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            
            ///if let placemarks = placemarks as! [CLPlacemark],
            if let placemark = placemarks!.first,
                let city = placemark.locality {
                
                    completionHandler(location: city, error: error)
            }
            completionHandler(location: nil, error: error)
        }
    }
    
    // Present alert messages to the user
    func presentErrorAlertView(error: String) {
        
        let alertController = UIAlertController(title: "Alert", message: error, preferredStyle: UIAlertControllerStyle.Alert)
        let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alertController.addAction(defaultAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}


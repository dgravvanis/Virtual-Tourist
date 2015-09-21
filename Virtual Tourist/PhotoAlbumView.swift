//
//  PhotoAlbumView.swift
//  Virtual Tourist
//
//  Created by Dimitrios Gravvanis on 31/8/15.
//  Copyright (c) 2015 dgravvanis. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumView: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate, UICollectionViewDelegate {
    
    // MARK: Properties
    var pin: Pin?
    var pinId: NSManagedObjectID?
    var mapSpan: MKCoordinateSpan?
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected".
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    // Core data context
    lazy var sharedContext: NSManagedObjectContext =  {
        CoreDataStack.sharedInstance.managedObjectContext!
        }()
    
    // MARK: - Fetched Results Controller
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        // Create the fetch request
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        // Add a sort descriptor.
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "filename", ascending: false)]
        
        // Add predicate
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)
        
        // Create the Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        // Return the fetched results controller. It will be the value of the lazy variable
        return fetchedResultsController
        }()
    
    // MARK: Outlets
    @IBOutlet weak var mapView: CustomMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var latLabel: UILabel!
    @IBOutlet weak var longLabel: UILabel!
    
    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the delegates
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        if let pinId = pinId {
            pin = sharedContext.objectRegisteredForID(pinId) as? Pin
        }
        
        initializeMap()
        
        // Fetch pins from core data.
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Unresolved error \(error)")
        }
        
        // Make room in the collection view to accommodate the map view
        collectionView.contentInset = UIEdgeInsetsMake(mapView.bounds.height, 0, 0, 0)
        topLabel.text = pin?.title
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Save the private context
        CoreDataStack.sharedInstance.saveMainContext()
    }
    
    // MARK: - Fetched Results Controller Delegate
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    // The second method may be called multiple times, once for each Photo object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            print("Insert an item")
            // Here we are noting that a new Photo instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            // Here we are noting that a Photo instance has been deleted from Core Data. We keep remember its index path
            // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
            // value that we want in this case.
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            // Here we are noting that a Photo instance has been changed after they are created. Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded.
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
        //default:
            //break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    
    // MARK: Collection View Methods
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let sectionInfo = fetchedResultsController.sections![section] 
        
        // Return number of photos
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // Dequeue the reusable cell as custom cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionCell", forIndexPath: indexPath) as! CustomCell
        
        // Get photo
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if !photo.saved {
            
            cell.imageView.image = UIImage(named: "CellPlaceholderImage")
            cell.activityIndicator.startAnimating()
        }
        
        if photo.saved {
            
            // Get filepath
            if let documentsPath = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first {
                
                // Create file path
                let filePath = documentsPath.URLByAppendingPathComponent(photo.filename)
                if let image = UIImage(contentsOfFile: filePath.path!) {
                    
                    cell.imageView.image = image
                    cell.activityIndicator.stopAnimating()
                }
            }
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        // Get photo
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        return photo.saved
    }
    
    // MARK: Helpers
    // Initialize the map
    func initializeMap() {
        
        // Add the annotation to the map
        // Center the map
        if let pin = pin,
        let span = mapSpan {
            
            mapView.addAnnotation(pin)
            let region = MKCoordinateRegion(center: pin.coordinate, span: span)
            mapView.setRegion(region, animated: false)
        }
    }
    
    // MARK: Actions
    // Get new collection of photos
    @IBAction func longPressGesture(sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Began {
        
            // Get the spot that was touched and
            // get the indexPath from the tap point
            let tapPoint = sender.locationInView(collectionView)
            let indexPath = collectionView.indexPathForItemAtPoint(tapPoint)
            
            if let indexPath = indexPath {
                
                let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CustomCell
                
                // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
                if let index = selectedIndexes.indexOf(indexPath) {
                    selectedIndexes.removeAtIndex(index)
                    cell.imageView.alpha = 1
                } else {
                    selectedIndexes.append(indexPath)
                    cell.imageView.alpha = 0.5
                }
            }
        }
    }
    
    @IBAction func deleteButtonPress(sender: UIButton) {
        
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        
        selectedIndexes = [NSIndexPath]()
    }
    
    @IBAction func refreshButtonPress(sender: UIButton) {
        
        
        for indexPath in selectedIndexes {
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CustomCell
            cell.imageView.alpha = 1
        }
        
        selectedIndexes = [NSIndexPath]()
        
        for photo in self.fetchedResultsController.fetchedObjects as! [Photo] {
            self.sharedContext.deleteObject(photo)
        }
            
        FlickrClient.sharedInstance.getPhotosFromPinLocation(pin!)
    }
}

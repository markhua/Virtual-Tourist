//
//  ColorViewController.swift
//

import Foundation
import CoreData
import MapKit

/**
 * The color collection demonstrates two techniques that will be useful in the Virtual Tourist app
 * 
 * - Selecting and deselecting cells in a collection
 * - Using NSFecthedResultsController with a collection
 *
 * Before you proceed, take a minute to run the app, and then read the Readme file. It gives a brief introduction to these
 * two topics. 
 */

class PictureViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
   
    @IBOutlet weak var picturecollection: UICollectionView!
    var pin: Pin!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates. 
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var downloadCounter = AlbumClient.Constants.maxNum
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    var cancelButton: UIBarButtonItem!
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start the fetched results controller
        var error: NSError?
        
        AlbumClient.sharedInstance().lat = pin.lat
        AlbumClient.sharedInstance().long = pin.long
        
        fetchedResultsController.performFetch(&error)
    
        if pin.pictures.isEmpty {
            self.bottomButton.enabled = false
            var i = 0
            while i < AlbumClient.Constants.maxNum {
                let pic = Picture(url: "empty", context: self.sharedContext)
                pic.pin = self.pin
                dispatch_async(dispatch_get_main_queue()){
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                i++
            }
            
        }
        updateBottomButton()
    }
    
    // Layout the collection view
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0 , left: 1, bottom: 0, right: 0)
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3-6)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    
    // MARK: - Configure Cell
    
    func configureCell(cell: PictureCell, atIndexPath indexPath: NSIndexPath) {

        
        let picture = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Picture
        
        let queue:dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        println("Configure Cell")
        
        
        dispatch_async(queue, { () -> Void in
            
            if picture.imageURL == "empty" {
                
                //cell.image.image = UIImage(named: "Placeholder")
                cell.activityIndicator.hidden = false
                AlbumClient.sharedInstance().getImageFromFlickrBySearch(){ success, result in
                    if success {
                        let imageURL = NSURL(string: result!)
                        if let imageData = NSData(contentsOfURL: imageURL!) {
                            dispatch_async(dispatch_get_main_queue()){
                                picture.updateImage(result!)
                                CoreDataStackManager.sharedInstance().saveContext()
                                cell.activityIndicator.hidden = true
                            }
                        }
                    }
                    
                }

            } else {
                
                let url = NSURL(string: picture.imageURL)!
                let imageData = NSData(contentsOfURL: url)
                
                let filename = picture.imageURL.lastPathComponent
                let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
                let pathArray = [dirPath, filename]
                let fileURL =  NSURL.fileURLWithPathComponents(pathArray)!
                dispatch_async(dispatch_get_main_queue()){
                    cell.image.image = UIImage(contentsOfFile: fileURL.path!)
                }
                
                self.downloadCounter--
                println(self.downloadCounter)
                if self.downloadCounter == 0 {
                    dispatch_async(dispatch_get_main_queue()){
                        self.bottomButton.enabled = true
                    }
                }

            }

        })
        
        if let index = find(self.selectedIndexes, indexPath) {
            cell.image.alpha = 0.05
        } else {
            cell.image.alpha = 1.0
        }
    }
    
    

    
    
    // MARK: - UICollectionView
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        //println("number Of Cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PictureCell", forIndexPath: indexPath) as! PictureCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PictureCell
        
        // If the cell is "selected" it's color panel is grayed out
        // we use the Swift `find` function to see if the indexPath is in the array
        //dispatch_async(dispatch_get_main_queue()){
        
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = find(selectedIndexes, indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        configureCell(cell, atIndexPath: indexPath)
        
        // And update the buttom button
        updateBottomButton()
    }
    
    
    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Picture")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    
    // MARK: - Fetched Results Controller Delegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create 
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()

    }
    
    // The second method may be called multiple times, once for each Color object that is added, deleted, or changed. 
    // We store the incex paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            println("Insert an item")
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            println("Delete an item")
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            println("Update an item.")
            updatedIndexPaths.append(indexPath!)
            break
        default:
            break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the 
    // arrays and perform the changes.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        //println("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
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
    
    
    @IBAction func buttonButtonClicked() {

        if selectedIndexes.isEmpty {
            //deleteAllColors()
            loadNewCollection()
        } else {
            deleteSelectedColors()
        }
        CoreDataStackManager.sharedInstance().saveContext()
        updateBottomButton()
    }
    
    func loadNewCollection(){
        
        self.deleteAllColors()
        self.downloadCounter = AlbumClient.Constants.maxNum
        
        self.bottomButton.enabled = false
        var i = 0
        while i < AlbumClient.Constants.maxNum {
            let pic = Picture(url: "empty", context: self.sharedContext)
            pic.pin = self.pin
            dispatch_async(dispatch_get_main_queue()){
                self.collectionView.reloadData()
                CoreDataStackManager.sharedInstance().saveContext()
            }
            i++
        }
        
    }
    
    func deleteAllColors() {
        
        for picture in fetchedResultsController.fetchedObjects as! [Picture] {
            sharedContext.deleteObject(picture)
            deleteFileFromPath(picture.imageURL)
        }
        dispatch_async(dispatch_get_main_queue()){
            self.selectedIndexes = [NSIndexPath]()
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    func deleteSelectedColors() {
        var colorsToDelete = [Picture]()
        
        for indexPath in selectedIndexes {
            colorsToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Picture)
        }
        
        for picture in colorsToDelete {
            sharedContext.deleteObject(picture)
            deleteFileFromPath(picture.imageURL)
        }
        
        dispatch_async(dispatch_get_main_queue()){
            CoreDataStackManager.sharedInstance().saveContext()
            self.selectedIndexes = [NSIndexPath]()
            self.updateBottomButton()
        }
        
    }
    
    func updateBottomButton() {
        
        if selectedIndexes.count > 0 {
            bottomButton.title = "Remove Selected Pictures"
        } else {
            bottomButton.title = "New Collection"
        }
    }
    
    
    func deleteFileFromPath(imageURL: String){
        let filename = imageURL.lastPathComponent
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let pathArray = [dirPath, filename]
        let fileURL =  NSURL.fileURLWithPathComponents(pathArray)!

        var fileManager: NSFileManager = NSFileManager.defaultManager()
        var error: NSErrorPointer = NSErrorPointer()
        fileManager.removeItemAtPath(fileURL.path!, error: error)
    }

}
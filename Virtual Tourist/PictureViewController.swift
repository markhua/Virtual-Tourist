
import Foundation
import CoreData
import MapKit


class PictureViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
   
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var picturecollection: UICollectionView!
    var pin: Pin!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected".
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    // The downloadCounter is used to track when all downloads are completed
    var downloadCounter = AlbumClient.Constants.maxNum
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    var cancelButton: UIBarButtonItem!
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the mapView on the top and add the pin
        var center =  CLLocationCoordinate2D(latitude: pin.lat, longitude: pin.long)
        var span = MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.lat, longitude: pin.long)
        mapView.addAnnotation(annotation)
        
        // Start the fetched results controller
        var error: NSError?
        
        AlbumClient.sharedInstance().lat = pin.lat
        AlbumClient.sharedInstance().long = pin.long
        
        fetchedResultsController.performFetch(&error)
        
        // If there is no image fetched, download new photos
        if pin.pictures.isEmpty {
            self.bottomButton.enabled = false
            var i = 0
            while i < AlbumClient.Constants.maxNum {
                
                // Each picture has a default url so that they will appear as placeholder and then download image
                let pic = Picture(url: "Placeholder", context: self.sharedContext)
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
        
        // Lay out the collection view so that cells take up 1/3 of the width
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
        
        dispatch_async(queue, { () -> Void in
            
            if picture.imageURL == "Placeholder" {
                
                cell.activityIndicator.hidden = false
                AlbumClient.sharedInstance().getImageFromFlickrBySearch(){ success, result in
                    if success {
                        let imageURL = NSURL(string: result!)
                        if let imageData = NSData(contentsOfURL: imageURL!) {
                            dispatch_async(dispatch_get_main_queue()){
                                
                                // Update the URL after search, it will trigger the Core Data and collection update
                                picture.updateImage(result!)
                                CoreDataStackManager.sharedInstance().saveContext()
                                cell.activityIndicator.hidden = true
                            }
                        }
                    } else {
                        self.notificationmsg(result!)
                    }
                    
                }

            } else {
                
                // Display image if its path is already set in Core Data
                let url = NSURL(string: picture.imageURL)!
                let imageData = NSData(contentsOfURL: url)
                
                // Build the filepath again because the document path in iOS simulator is likely to change in every run
                let filename = picture.imageURL.lastPathComponent
                let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
                let pathArray = [dirPath, filename]
                let fileURL =  NSURL.fileURLWithPathComponents(pathArray)!
                dispatch_async(dispatch_get_main_queue()){
                    cell.image.image = UIImage(contentsOfFile: fileURL.path!)
                }
                
                // Decrease downloadCounter by 1, enable the New Collection button when the counter is 0
                self.downloadCounter--

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
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PictureCell", forIndexPath: indexPath) as! PictureCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PictureCell
        
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
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()

    }

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
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
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

        // Load new collection if no pictures are selected, otherwise, delete selected picutures
        if selectedIndexes.isEmpty {
            loadNewCollection()
        } else {
            deleteSelectedItems()
        }
        CoreDataStackManager.sharedInstance().saveContext()
        updateBottomButton()
    }
    
    // Load New Collection
    func loadNewCollection(){
        
        self.deleteAllItems()
        self.downloadCounter = AlbumClient.Constants.maxNum
        
        self.bottomButton.enabled = false
        var i = 0
        
        // Add new pictures like the way in ViewDidLoad
        while i < AlbumClient.Constants.maxNum {
            let pic = Picture(url: "Placeholder", context: self.sharedContext)
            pic.pin = self.pin
            dispatch_async(dispatch_get_main_queue()){
                self.collectionView.reloadData()
                CoreDataStackManager.sharedInstance().saveContext()
            }
            i++
        }
        
    }
    
    func deleteAllItems() {
        
        for picture in fetchedResultsController.fetchedObjects as! [Picture] {
            sharedContext.deleteObject(picture)
            deleteFileFromPath(picture.imageURL)
        }
        dispatch_async(dispatch_get_main_queue()){
            self.selectedIndexes = [NSIndexPath]()
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    func deleteSelectedItems() {
        var itemsToDelete = [Picture]()
        
        for indexPath in selectedIndexes {
            itemsToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Picture)
        }
        
        for picture in itemsToDelete {
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
    
    
    // Helper function: Delete file from the path in parameter
    func deleteFileFromPath(imageURL: String){
        let filename = imageURL.lastPathComponent
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let pathArray = [dirPath, filename]
        let fileURL =  NSURL.fileURLWithPathComponents(pathArray)!

        var fileManager: NSFileManager = NSFileManager.defaultManager()
        var error: NSErrorPointer = NSErrorPointer()
        fileManager.removeItemAtPath(fileURL.path!, error: error)
    }
    
    //Display notification with message string
    func notificationmsg (msgstring: String)
    {
        dispatch_async(dispatch_get_main_queue()){
            let controller = UIAlertController(title: "Notification", message: msgstring, preferredStyle: .Alert)
            controller.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }

}
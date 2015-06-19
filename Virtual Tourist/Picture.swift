
import UIKit
import CoreData

@objc(Picture)

class Picture: NSManagedObject {

    // The imageURL is the path in document directory
    @NSManaged var imageURL: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    
    init(url: String, context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Picture", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        updateImage(url)
    }
    
    // Update the imageURL
    func updateImage(url: String) {
        
        let imageurl = NSURL(string: url)!
        if let imageData = NSData(contentsOfURL: imageurl) {
            imageData.writeToURL(imageFileURL(url), atomically: true)
            imageURL = imageFileURL(url).path!
            //println(imageURL)
            
        }else{
            imageURL = url
        }
    }
    
    func imageFileURL(url: String) ->  NSURL {
        let filename = url.lastPathComponent
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let pathArray = [dirPath, filename]
        let fileURL =  NSURL.fileURLWithPathComponents(pathArray)!
        return fileURL
    }
    
}

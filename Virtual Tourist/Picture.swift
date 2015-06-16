//
//  Color.swift
//  ColorCollection
//
//  Created by Jason on 4/7/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit
import CoreData

@objc(Picture)

class Picture: NSManagedObject {

    // We will store UIColor values in this value attribute
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
    
    func updateImage(url: String) {
        
        let imageurl = NSURL(string: url)!
        if let imageData = NSData(contentsOfURL: imageurl) {
            imageData.writeToURL(audioFileURL(url), atomically: true)
            imageURL = audioFileURL(url).path!
            println(imageURL)
            
        }else{
            imageURL = url
        }
    }
    
    func audioFileURL(url: String) ->  NSURL {
        let filename = url.lastPathComponent
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let pathArray = [dirPath, filename]
        let fileURL =  NSURL.fileURLWithPathComponents(pathArray)!
        
        return fileURL
    }
    
}

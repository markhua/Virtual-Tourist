//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Mark Zhang on 15/6/15.
//  Copyright (c) 2015年 Mark Zhang. All rights reserved.
//

import Foundation


import UIKit
import CoreData

@objc(Pin)

class Pin: NSManagedObject {
    
    // We will store UIColor values in this value attribute
    @NSManaged var long: Double
    @NSManaged var lat: Double
    @NSManaged var pictures: [Picture]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    
    init(longitude: Double, latitude: Double, context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        long = longitude
        lat = latitude
    }
    
}

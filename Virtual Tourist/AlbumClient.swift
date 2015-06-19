//
//  AlbumClient.swift
//  Virtual Tourist
//
//  Created by Mark Zhang on 15/6/17.
//  Copyright (c) 2015年 Mark Zhang. All rights reserved.
//

import Foundation

class AlbumClient: NSObject {
    
    var lat: Double?
    var long: Double?
    
    struct Constants {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
        static let API_KEY = "74b4631959ffd555071080099c41364a"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
        // The maxNum determines how many cells will be downloaded in each album
        static let maxNum = 12
    }
    
    class func sharedInstance() -> AlbumClient {
        
        struct Singleton {
            static var sharedInstance = AlbumClient()
        }
        
        return Singleton.sharedInstance
    }
    
}
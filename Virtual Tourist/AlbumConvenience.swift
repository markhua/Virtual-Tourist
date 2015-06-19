//
//  AlbumConvenience.swift
//  Virtual Tourist
//
//  Created by Mark Zhang on 15/6/17.
//  Copyright (c) 2015年 Mark Zhang. All rights reserved.
//

import Foundation

extension AlbumClient{

    
    // Get image from Flickr and return the image URL in the completionHandler
    func getImageFromFlickrBySearch(completionHandler: (success: Bool, Result: String?)->Void) {
        
        let methodArguments = [
            "method": AlbumClient.Constants.METHOD_NAME,
            "api_key": AlbumClient.Constants.API_KEY,
            "bbox": createBoundingBoxString(AlbumClient.sharedInstance().lat!, long: AlbumClient.sharedInstance().long!),
            "safe_search": AlbumClient.Constants.SAFE_SEARCH,
            "extras": AlbumClient.Constants.EXTRAS,
            "format": AlbumClient.Constants.DATA_FORMAT,
            "nojsoncallback": AlbumClient.Constants.NO_JSON_CALLBACK
        ]
        
        let session = NSURLSession.sharedSession()
        let urlString = AlbumClient.Constants.BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                completionHandler(success: false, Result: "Could not complete the request \(error)")
            } else {
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    if let totalPages = photosDictionary["pages"] as? Int {
                        
                        /* Flickr API - will only return up the 4000 images (100 per page * 40 page max) */
                        let pageLimit = min(totalPages, 40)
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                        
                        self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage) { (success, result) in
                            if success { completionHandler(success: true, Result: result) }
                        }
                        
                    } else {
                        completionHandler(success: false, Result: "Cant find key 'pages' in \(photosDictionary)")
                    }
                } else {
                    completionHandler(success: false, Result: "Cant find key 'photos' in \(parsedResult)")
                }
            }
        }
        
        task.resume()
        

        
    }
    
    // Get a random image from the witin single page, return the image URL in the completionHandler
    func getImageFromFlickrBySearchWithPage (methodArguments: [String: AnyObject], pageNumber: Int, completionHandler: (success: Bool, Result: String?)->Void) {
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = AlbumClient.Constants.BASE_URL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                completionHandler(success: false, Result: "Could not complete the request \(error)")
            } else {
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    var totalPhotosVal = 0
                    if let totalPhotos = photosDictionary["total"] as? String {
                        totalPhotosVal = (totalPhotos as NSString).integerValue
                    }
                    
                    if totalPhotosVal > 0 {
                        if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                            
                            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                            let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                            
                            let imageUrlString = photoDictionary["url_m"] as! String
                            
                            completionHandler(success: true, Result: imageUrlString)
                            
                        } else {
                            completionHandler(success: false, Result: "Cant find key 'photo' in \(photosDictionary)")
                        }
                    }
                } else {
                    completionHandler(success: false, Result: "Cant find key 'photos' in \(parsedResult)")
                }
            }
        }
        
        task.resume()
    
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    /* Helper function: Given latitude and longitude, convert to a bounding box */
    func createBoundingBoxString(lat: Double, long: Double) -> String {
        
        let latitude = lat
        let longitude = long
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - AlbumClient.Constants.BOUNDING_BOX_HALF_WIDTH, AlbumClient.Constants.LON_MIN)
        let bottom_left_lat = max(latitude - AlbumClient.Constants.BOUNDING_BOX_HALF_HEIGHT, AlbumClient.Constants.LAT_MIN)
        let top_right_lon = min(longitude + AlbumClient.Constants.BOUNDING_BOX_HALF_HEIGHT, AlbumClient.Constants.LON_MAX)
        let top_right_lat = min(latitude + AlbumClient.Constants.BOUNDING_BOX_HALF_HEIGHT, AlbumClient.Constants.LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
}
//
//  FlickrClientConstants.swift
//  Virtual Tourist
//
//  Created by Dimitrios Gravvanis on 27/8/15.
//  Copyright (c) 2015 dgravvanis. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    struct Constants {
        
        static let apiKey: String = ""
        static let secret = ""
        static let scheme = "https"
        static let host = "api.flickr.com"
        static let path = "/services/rest/"
    }
    
    struct Methods {
        
        static let searchPhotos = "flickr.photos.search"
    }
    
    struct URLKeys {
        
        static let method = "method"
        static let apiKey = "api_key"
        static let latitude = "lat"
        static let longitude = "lon"
        static let responseFormat = "format"
        static let extras = "extras"
        static let noJsonCallBack = "nojsoncallback"
        static let photosPerPage = "per_page"
        static let pageNumber = "page"
        static let minUploadDate = "min_upload_date"
    }
    
    struct URLValues {
        
        static let responseFormatValue = "json"
        static let noJsonCallBackValue = "1"
        static let photosPerPageValue = "500"
    }
    
    struct JSONResponseKeys {
        
        static let photos = "photos"
        static let farm = "farm"
        static let server = "server"
        static let id = "id"
        static let secret = "secret"
    }
}
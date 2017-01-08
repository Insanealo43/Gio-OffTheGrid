//
//  OTGManager.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/8/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import Foundation

public enum OffTheGridUrls: String {
    case OTGVendors = "https://www.offthegridmarkets.com/api/v1.0/vendors.json"
    case FBGraphOTGEvents = "https://graph.facebook.com/v2.8/OffTheGridSF/events"
}

class OTGManager {
    static let sharedInstance = OTGManager()
    
    internal enum Constants {
        static let FBAppId = "211025409359530"
        static let FBAppSecret = "87a273cbaaf2364e16652a4d6a0b2111"
        static let FBAccessToken = "\(Constants.FBAppId)|\(Constants.FBAppSecret)"
    }
    
    internal enum Keys {
        static let accessToken = "access_token"
        static let sortOrder = "sort-order"
        static let nameAscending = "name-asc"
    }
    
    internal enum JSON {
        static let data = "data"
        static let vendors = "Vendors"
    }
    
    func fetchEvents() {
        let eventsUrl = OffTheGridUrls.FBGraphOTGEvents.rawValue
        let params = [Keys.accessToken: Constants.FBAccessToken as AnyObject]
        
        NetworkManager.sharedInstance.request(url: eventsUrl, parameters: params, handler: { response in
            if let eventsJSON = response?[JSON.data] as? [AnyObject] {
                print("OTG Events JSON --> \(eventsJSON)")
            }
        })
    }
    
    func fetchVendors() {
        let vendorsUrl = OffTheGridUrls.OTGVendors.rawValue
        let params = [Keys.sortOrder: Keys.nameAscending as AnyObject]
        
        NetworkManager.sharedInstance.request(url: vendorsUrl, parameters: params, handler: { response in
            if let vendorsJSON = response?[JSON.vendors] as? [AnyObject] {
                print("OTG Vendors JSON --> \(vendorsJSON)")
            }
        })
    }
}

//
//  OTGManager.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/8/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import Foundation

public enum OffTheGrid {
    enum Urls: String {
        case OTGVendors = "https://www.offthegridmarkets.com/api/v1.0/vendors.json"
        case FBGraphOTGEvents = "https://graph.facebook.com/v2.8/OffTheGridSF/events"
    }
    
    enum Facebook {
        static let AppId = "211025409359530"
        static let AppSecret = "87a273cbaaf2364e16652a4d6a0b2111"
        static let AccessToken = "\(Facebook.AppId)|\(Facebook.AppSecret)"
    }
}

class OTGManager {
    static let sharedInstance = OTGManager()
    
    internal enum QueryParams {
        enum Keys {
            static let accessToken = "access_token"
            static let sortOrder = "sort-order"
        }
        
        enum Values {
            static let nameAscending = "name-asc"
        }
    }
    
    internal enum JSONKeys {
        static let data = "data"
        static let vendors = "Vendors"
    }
    
    // MARK - Events
    func fetchEvents() {
        let eventsUrl = OffTheGrid.Urls.FBGraphOTGEvents.rawValue
        let params = [QueryParams.Keys.accessToken: OffTheGrid.Facebook.AccessToken as AnyObject]
        
        NetworkManager.sharedInstance.request(url: eventsUrl, parameters: params, handler: { response in
            if let eventsJSON = response?[JSONKeys.data] as? [AnyObject] {
                print("OTG Events(\(eventsJSON.count)) JSON --> \(eventsJSON)")
            }
        })
    }
    
    func fetchUpcomingEvents() {
        
    }
    
    // MARK - Vendors
    func fetchVendors() {
        let vendorsUrl = OffTheGrid.Urls.OTGVendors.rawValue
        let params = [QueryParams.Keys.sortOrder: QueryParams.Values.nameAscending as AnyObject]
        
        NetworkManager.sharedInstance.request(url: vendorsUrl, parameters: params, handler: { response in
            if let vendorsJSON = response?[JSONKeys.vendors] as? [AnyObject] {
                print("OTG Vendors(\(vendorsJSON.count)) JSON --> \(vendorsJSON)")
            }
        })
    }
}

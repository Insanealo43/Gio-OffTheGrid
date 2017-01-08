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
        static let OTG_FBAccessToken = "211025409359530|87a273cbaaf2364e16652a4d6a0b2111"
        static let Key_access_token = "access_token"
    }
    
    func fetchEvents() {
        let eventsUrl = OffTheGridUrls.FBGraphOTGEvents.rawValue
        let parameters = [Constants.Key_access_token: Constants.OTG_FBAccessToken as AnyObject]
        
        NetworkManager.sharedInstance.request(url: eventsUrl, parameters: parameters)
    }
    
    func fetchVendors() {
        
    }
}

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
        case Vendors = "https://www.offthegridmarkets.com/api/v1.0/vendors.json"
        case Events = "https://graph.facebook.com/v2.8/OffTheGridSF/events"
        case VendorDetailsPartial = "https://www.offthegrid.com/otg-api/passthrough/vendors/"
        case Market
    }
    
    enum Facebook {
        static let AppId = "211025409359530"
        static let AppSecret = "87a273cbaaf2364e16652a4d6a0b2111"
        static let AccessToken = "\(Facebook.AppId)|\(Facebook.AppSecret)"
    }
}

class OTGManager {
    static let sharedInstance = OTGManager()
    
    internal enum Constants {
        enum Keys {
            static let accessToken = "access_token"
            static let sortOrder = "sort-order"
            static let data = "data"
            static let vendors = "Vendors"
            static let paging = "paging"
            static let cursors = "cursors"
            static let after = "after"
            static let next = "next"
            static let startTime = "start_time"
            static let endTime = "end_time"
        }
        
        enum Values {
            static let nameAscending = "name-asc"
        }
    }
    
    // MARK - Events
    func fetchEvents(nextPagingCursor:String? = nil, handler: @escaping (_ events:JSONObjectArray, _ afterPagingCursor:String?) -> Void) {
        let eventsUrl = OffTheGrid.Urls.Events.rawValue
        var params = [Constants.Keys.accessToken: OffTheGrid.Facebook.AccessToken as AnyObject]
        if let after = nextPagingCursor {
            params[Constants.Keys.after] = after as AnyObject
        }
        
        NetworkManager.sharedInstance.request(url: eventsUrl, parameters: params, handler: { response in
            let eventsJSON = response?[Constants.Keys.data] as? JSONObjectArray ?? []
            var after: String?
            
            if let paging = response?[Constants.Keys.paging] as? JSONObject,
                let cursors = paging[Constants.Keys.cursors] as? JSONObject {
                after = cursors[Constants.Keys.after] as? String
            }
            
            handler(eventsJSON, after)
        })
    }
    
    /* Technical Notes:
         - "Upcoming" is interpreted to be all events whose 'start_time' is in the future, -OR-
            if the current time is between the 'start_time' and 'end_time' of the event
         - Cannot assume that all upcoming events are returned in the first page of results
         - Events are returned in order of most current to futherest away
     */
    func fetchUpcomingEvents(upcomingEvents:JSONObjectArray = JSONObjectArray(),
                             afterPageCursor:String? = nil,
                             handler: @escaping (JSONObjectArray) -> Void) {
        
        // Store events in mutable collection
        var aggreatedEvents = upcomingEvents
        
        self.fetchEvents(nextPagingCursor: afterPageCursor) { events, after in
            // Check if no events
            guard events.count > 0 else {
                handler(aggreatedEvents.reversed())
                return
            }
            
            // Save upcoming events
            events.forEach({ event in
                if event[Constants.Keys.startTime] is String && event[Constants.Keys.endTime] is String {
                    // TODO: Datetime comparison logic for recursion termination
                    aggreatedEvents.append(event)
                }
            })
            
            // Check if there isn't another page of events
            guard after != nil else {
                handler(aggreatedEvents.reversed())
                return
            }
            
            // TEST: Remove this!!!
            guard aggreatedEvents.count < 25 else {
                handler(aggreatedEvents.reversed())
                return
            }
            
            // Recursively fetch the next events
            self.fetchUpcomingEvents(upcomingEvents: aggreatedEvents, afterPageCursor: after, handler: handler)
        }
    }
    
    // MARK - Vendors
    func fetchVendors() {
        let vendorsUrl = OffTheGrid.Urls.Vendors.rawValue
        let params = [Constants.Keys.sortOrder: Constants.Values.nameAscending as AnyObject]
        
        NetworkManager.sharedInstance.request(url: vendorsUrl, parameters: params, handler: { response in
            if let vendorsJSON = response?[Constants.Keys.vendors] as? JSONObjectArray {
                print("OTG Vendors(\(vendorsJSON.count)) JSON --> \(vendorsJSON)")
            }
        })
    }
    
    func fetchVendorDetails(id: Int, handler: (JSONObject) -> Void) {
        let vendorDetailsUrl = OffTheGrid.Urls.VendorDetailsPartial.rawValue + "\(id).json"
        
        NetworkManager.sharedInstance.request(url: vendorDetailsUrl, handler: { response in
            if let vendorsJSON = response?[Constants.Keys.vendors] as? JSONObjectArray {
                print("OTG Vendors(\(vendorsJSON.count)) JSON --> \(vendorsJSON)")
            }
        })
    }
}

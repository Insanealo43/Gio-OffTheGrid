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
        let eventsUrl = OffTheGrid.Urls.FBGraphOTGEvents.rawValue
        var params = [Constants.Keys.accessToken: OffTheGrid.Facebook.AccessToken as AnyObject]
        if let after = nextPagingCursor {
            //print("Fetching OTG Events using 'after' cursor >>> \(after)")
            params[Constants.Keys.after] = after as AnyObject
        }
        
        NetworkManager.sharedInstance.request(url: eventsUrl, parameters: params, handler: { response in
            let eventsJSON = response?[Constants.Keys.data] as? JSONObjectArray ?? []
            var after: String?
            
            if let paging = response?[Constants.Keys.paging] as? [String:AnyObject],
                let cursors = paging[Constants.Keys.cursors] as? [String:AnyObject] {
                after = cursors[Constants.Keys.after] as? String
                /*let before = cursors["before"] as? String
                print("OTG Events Fetched! \nAfter: \(after ?? "<NULL>"), Before: \(before ?? "<NULL>")")*/
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
        
        var aggreatedEvents = upcomingEvents
        var pageAfter = afterPageCursor
        
        self.fetchEvents(nextPagingCursor: pageAfter) { events, after in
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
            
            // Set the next events page to fetch
            pageAfter = after
            
            // TEST: Remove this!!!
            guard aggreatedEvents.count < 25 else {
                handler(aggreatedEvents.reversed())
                return
            }
            
            // Recursively
            self.fetchUpcomingEvents(upcomingEvents: aggreatedEvents, afterPageCursor: pageAfter, handler: handler)
        }
    }
    
    // MARK - Vendors
    func fetchVendors() {
        let vendorsUrl = OffTheGrid.Urls.OTGVendors.rawValue
        let params = [Constants.Keys.sortOrder: Constants.Values.nameAscending as AnyObject]
        
        NetworkManager.sharedInstance.request(url: vendorsUrl, parameters: params, handler: { response in
            if let vendorsJSON = response?[Constants.Keys.vendors] as? [AnyObject] {
                print("OTG Vendors(\(vendorsJSON.count)) JSON --> \(vendorsJSON)")
            }
        })
    }
}

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
        case Markets = "https://offthegrid.com/otg-api/passthrough/markets.json"
        
        enum Partial {
            static let VendorDetails = "https://www.offthegrid.com/otg-api/passthrough/vendors/"
            static let MarketDetails = "https://www.offthegrid.com/otg-api/passthrough/markets/"
        }
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
            static let markets = "Markets"
            static let latitude = "latitude"
            static let longitude = "longitude"
            static let event = "Event"
            static let monthDay = "month_day"
            static let marketDetail = "MarketDetail"
            static let market = "Market"
        }
        
        enum Values {
            static let nameAscending = "name-asc"
            static let distanceAscending = "distance-asc"
            static let latGingerIO = "37.790841"
            static let lngGingerIO = "-122.401280"
        }
    }
    
    var eventMarketMap = [String:JSONObject]()
    var upcomingEvents = JSONObjectArray() {
        willSet {
            print("Upcoming Events(\(newValue.count)): \(newValue)")
            print("Dates: \(newValue.map({ $0[Constants.Keys.monthDay]! }))")
            print("Times: \(newValue.map({ $0[Constants.Keys.startTime]! }))")
        }
    }
    
    var marketDetailsMap = [String:JSONObject]()
    var markets = JSONObjectArray() {
        willSet {
            var events = JSONObjectArray()
            var mapping = [String:JSONObject]()
            
            newValue.forEach({ market in
                if let marketEvents = market[Constants.Keys.event] as? JSONObjectArray {
                    marketEvents.forEach({ event in
                        events.append(event)
                        if let id = event["id"] as? String {
                            mapping[id] = market
                        }
                    })
                }
            })
            
            // Sort events by 'month_day', and then 'start_time'
            events = events.sorted(by: { first, second in
                if let firstDate = first[Constants.Keys.monthDay] as? String,
                    let secondDate = second[Constants.Keys.monthDay] as? String {
                    if firstDate != secondDate {
                        return firstDate < secondDate
                        
                    } else if let firstStart = first[Constants.Keys.startTime] as? String,
                        let secondStart = second[Constants.Keys.startTime] as? String {
                        if firstStart != secondStart {
                            return firstStart < secondStart
                        }
                    }
                }
                
                return true
            })
            
            self.upcomingEvents = events
            self.eventMarketMap = mapping
        }
    }
    
    var vendors = JSONObjectArray()
    
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
    func fetchFBEvents(upcomingEvents:JSONObjectArray = JSONObjectArray(),
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
            
            // Check if a next page exists after
            guard after != nil else {
                handler(aggreatedEvents.reversed())
                return
            }
            
            // TEST: Remove this!!!
            /*guard aggreatedEvents.count < 25 else {
                handler(aggreatedEvents.reversed())
                return
            }*/
            
            // Recursively fetch the next events
            self.fetchFBEvents(upcomingEvents: aggreatedEvents, afterPageCursor: after, handler: handler)
        }
    }
    
    // MARK - Vendors
    func fetchVendors(handler: ((JSONObjectArray) -> Void)? = nil) {
        let vendorsUrl = OffTheGrid.Urls.Vendors.rawValue
        let params = [Constants.Keys.sortOrder: Constants.Values.nameAscending as AnyObject]
        
        NetworkManager.sharedInstance.request(url: vendorsUrl, parameters: params, handler: { response in
            // Keep local copy of the vendors
            if let vendorsJSON = response?[Constants.Keys.vendors] as? JSONObjectArray {
                let vendors = Array(vendorsJSON.filter({ $0["Vendor"] is JSONObject}).map({ $0["Vendor"] as! JSONObject}))
                self.vendors = vendors
                
                // Cache the vendors
                PersistanceManager.sharedInstance.saveJSON(json: [CacheKeys.vendors: vendors as AnyObject], with: CacheKeys.vendors)
            }
            handler?(self.vendors)
        })
    }
    
    /*func fetchVendorDetails(id: Int, handler: (JSONObject) -> Void) {
        let vendorDetailsUrl = OffTheGrid.Urls.VendorDetailsPartial.rawValue + "\(id).json"
        
        NetworkManager.sharedInstance.request(url: vendorDetailsUrl, handler: { response in
            if let vendorsJSON = response?[Constants.Keys.vendors] as? JSONObjectArray {
                print("OTG Vendors(\(vendorsJSON.count)) JSON --> \(vendorsJSON)")
            }
        })
    }*/
    
    // MARK - Markets
    func fetchMarkets(handler: ((JSONObjectArray) -> Void)? = nil) {
        let marketsUrl = OffTheGrid.Urls.Markets.rawValue
        let params = [Constants.Keys.latitude: Constants.Values.latGingerIO as AnyObject,
                      Constants.Keys.longitude: Constants.Values.lngGingerIO as AnyObject,
                      Constants.Keys.sortOrder: Constants.Values.distanceAscending as AnyObject]
        
        NetworkManager.sharedInstance.request(url: marketsUrl, parameters: params, handler: { response in
            // Keep local copy of the markets
            let markets = (response?[Constants.Keys.markets] as? JSONObjectArray) ?? JSONObjectArray()
            self.markets = markets
            
            // Cache the markets
            PersistanceManager.sharedInstance.saveJSON(json: [CacheKeys.markets: markets as AnyObject], with: CacheKeys.markets)
            
            handler?(markets)
        })
    }
    
    func fetchMarketDetails(id: String, handler: @escaping ((JSONObject?) -> Void)) {
        let marketUrl = OffTheGrid.Urls.Partial.MarketDetails + "/\(id).json"
        
        NetworkManager.sharedInstance.request(url: marketUrl, handler: { response in
            let details = response?[Constants.Keys.marketDetail] as? JSONObject
            let marketJSON = details?[Constants.Keys.market] as? JSONObject
            
            if let marketInfo = marketJSON?[Constants.Keys.market] as? JSONObject,
                let marketId = marketInfo["id"] as? String {
                self.marketDetailsMap[marketId] = details!
            }
            
            handler(details)
        })
    }
}

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
    internal let bgQueue = DispatchQueue.global(qos: .default)
    
    enum Constants {
        enum Notifications {
            static let MarketsFetched = "OTGMarketsNotification"
            static let DetailedMarketsFetched = "OTGDetailedMarketsNotification"
            static let VendorsFetched = "OTGVendorsNotification"
        }
        
        enum Keys {
            static let id = "id"
            static let accessToken = "access_token"
            static let sortOrder = "sort-order"
            static let data = "data"
            static let vendor = "Vendor"
            static let vendors = "Vendors"
            static let vendorDetail = "VendorDetail"
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
            static let events = "Events"
            static let monthDay = "month_day"
            static let marketDetail = "MarketDetail"
            static let market = "Market"
            static let marketId = "market_id"
            static let amenitities = "Amenities"
            static let media = "Media"
            static let news = "News"
            static let hours = "hours"
            static let amPm = "am_pm"
        }
        
        enum CustomKeys {
            static let eventIdEventJSONMapKey = "EventId_to_EventJSON_Map"
        }
        
        enum Values {
            static let nameAscending = "name-asc"
            static let distanceAscending = "distance-asc"
            static let latGingerIO = "37.790841"
            static let lngGingerIO = "-122.401280"
        }
    }
    
    var markets = JSONObjectArray()
    var detailedMarkets = JSONObjectArray()
    var detailedMarketsMap = JSONObjectMapping()
    var vendors = JSONObjectArray()
    var vendorEventsMap = JSONObjectArrayMapping()
    
    var allEvents: JSONObjectArray {
        get { return Array(self.vendorEventsMap.values).reduce([], +) }
    }

    // MARK - Markets
    func fetchMarkets(handler: @escaping (JSONObjectArray) -> Void) {
        let marketsUrl = OffTheGrid.Urls.Markets.rawValue
        let params = [Constants.Keys.latitude: Constants.Values.latGingerIO as AnyObject,
                      Constants.Keys.longitude: Constants.Values.lngGingerIO as AnyObject,
                      Constants.Keys.sortOrder: Constants.Values.distanceAscending as AnyObject]
        
        NetworkManager.sharedInstance.request(url: marketsUrl, parameters: params, handler: { response in
            var markets = ((response?[Constants.Keys.markets] as? JSONObjectArray) ?? JSONObjectArray())
            
            // Normalize the Markets' JSON
            markets = markets.flatMap({
                var json:JSONObject = $0
                if let eventsJSON = $0[Constants.Keys.event] {
                    json.removeValue(forKey: Constants.Keys.event)
                    json[Constants.Keys.events] = eventsJSON
                }
                return json
            })
            
            // Save markets locally
            self.markets = markets
            
            // Post MarketsFetched Notification
            let notificationName = Notification.Name(Constants.Notifications.MarketsFetched)
            NotificationCenter.default.post(name: notificationName, object: self, userInfo: [Constants.Keys.markets: markets])
            
            handler(markets)
        })
    }
    
    func fetchDetailedMarket(id: String, handler: @escaping ((JSONObject?) -> Void)) {
        let marketUrl = OffTheGrid.Urls.Partial.MarketDetails + "/\(id).json"
        
        NetworkManager.sharedInstance.request(url: marketUrl, handler: { response in
            let detailedMarket = self.transposeMarketDetail(json: response)
            handler(detailedMarket)
        })
    }
    
    func fetchDetailedMarkets(handler: @escaping (_ marketsJSON:JSONObjectArray, _ marketsJSONMap:JSONObjectMapping) -> Void) {
        var marketsJSON = JSONObjectArray()
        var marketsJSONMap = JSONObjectMapping()
        
        // Fetch: All Markets
        self.fetchMarkets { markets in
            let marketIds = markets.flatMap({ ($0["Market"] as? JSONObject)?["id"] as? String })
            let marketUrls = marketIds.map({ OffTheGrid.Urls.Partial.MarketDetails + "\($0).json" })
            
            // Batch Fetch: All Market details (including Event/Vendor data)
            NetworkManager.sharedInstance.batchFetchRequest(urls: marketUrls, requestHandler: { url, response in
                
                // Parse the marketId from the requestUrl and extract the market detail object
                if let marketId = url.components(separatedBy: "/").last?.components(separatedBy: ".").first,
                    let marketJSON = self.transposeMarketDetail(json: response) {
                    
                    // Map the Market JSON
                    marketsJSONMap[marketId] = marketJSON
                }
                
            }, completion: {
                // Restore the original Markets' sort order
                marketsJSON = marketIds.flatMap({ marketsJSONMap[$0] })
                
                // Save detailed markets locally
                self.detailedMarkets = marketsJSON
                self.detailedMarketsMap = marketsJSONMap
                
                // Save the vendors to events mapping
                self.vendorEventsMap = self.vendorEventsMapForMarkets(markets: marketsJSON)
                
                // Post DetailedMarketsFetched Notification
                let notificationName = Notification.Name(Constants.Notifications.DetailedMarketsFetched)
                NotificationCenter.default.post(name: notificationName, object: self, userInfo: [Constants.Keys.markets: marketsJSON])
                
                // Return the batched Markets' JSON
                handler(marketsJSON, marketsJSONMap)
            })
        }
    }
    
    internal func transposeMarketDetail(json: JSONObject?) -> JSONObject? {
        if var marketJSON = json?[Constants.Keys.marketDetail] as? JSONObject {
            
            // Extract needed market object JSON and flatten the dictionary
            if let marketObject = marketJSON[Constants.Keys.market] as? JSONObject {
                if let innerMarketJSON = marketObject[Constants.Keys.market] {
                    marketJSON[Constants.Keys.market] = innerMarketJSON
                }
                
                if let mediaJSON = marketObject[Constants.Keys.media] {
                    marketJSON[Constants.Keys.media] = mediaJSON
                }
            }
            
            // Remove unneeded data - reduce memory footprint
            marketJSON.removeValue(forKey: Constants.Keys.amenitities)
            marketJSON.removeValue(forKey: Constants.Keys.news)
            
            // Add relational-mappings to the market JSON
            if let eventsJSON = marketJSON[Constants.Keys.events] as? JSONObjectArray {
                
                // Map all the Market's events
                var eventsJSONMap = JSONObjectMapping()
                eventsJSON.forEach({ json in
                    if let eventId = (json[Constants.Keys.event] as? JSONObject)?[Constants.Keys.id] as? String {
                        eventsJSONMap[eventId] = json
                    }
                })
                
                // Add the custom mapping to the Event's JSON
                marketJSON[Constants.CustomKeys.eventIdEventJSONMapKey] = eventsJSONMap as AnyObject
            }
            
            return marketJSON
            
        } else {
            return nil
        }
    }
    
    // MARK - Vendors
    func fetchVendors(handler: @escaping (JSONObjectArray) -> Void) {
        let vendorsUrl = OffTheGrid.Urls.Vendors.rawValue
        let params = [Constants.Keys.sortOrder: Constants.Values.nameAscending as AnyObject]
        
        NetworkManager.sharedInstance.request(url: vendorsUrl, parameters: params, handler: { response in
            // Flatten all the Vendors' JSON
            let vendors = ((response?[Constants.Keys.vendors] as? JSONObjectArray) ?? JSONObjectArray()).flatMap({
                return $0[Constants.Keys.vendor] as? JSONObject
            })
            
            // Save vendors locally
            self.vendors = vendors
            
            // Post VendorsFetched Notification
            let notificationName = Notification.Name(Constants.Notifications.VendorsFetched)
            NotificationCenter.default.post(name: notificationName, object: self, userInfo: [Constants.Keys.vendors: vendors])
            
            handler(vendors)
        })
    }
    
    func fetchVendorDetails(id: Int, handler: @escaping (JSONObject) -> Void) {
        let vendorDetailsUrl = OffTheGrid.Urls.Partial.VendorDetails + "\(id).json"
        
        NetworkManager.sharedInstance.request(url: vendorDetailsUrl, handler: { response in
            let details = response?[Constants.Keys.vendorDetail] as? JSONObject
            handler(details ?? JSONObject())
        })
    }
    
    // MARK - Caching
    func loadCachedOffTheGridData() {
        let cacheManager = CachingManager.sharedInstance
        
        cacheManager.loadCachedMarkets()
        cacheManager.loadCachedDetailedMarkets()
        cacheManager.loadCachedDetailedMarketsMap()
        cacheManager.loadCachedVendors()
        cacheManager.loadCachedVendorEventsMap()
        
        // Update the cache for events that might be in the past
        cacheManager.refreshEventsCache()
    }
    
    func fetchOffTheGridData(cacheData:Bool = true) {
        print("OTGManager: Began fetching new OffTheGrid Data...")
        let group = DispatchGroup()
        
        group.enter()
        bgQueue.async {
            // Fetch all markets
            OTGManager.sharedInstance.fetchMarkets { markets in
                print("OTGManager: Fetched Markets.")
                group.leave()
            }
        }
        
        group.enter()
        bgQueue.async {
            // Fetch all detailed markets
            OTGManager.sharedInstance.fetchDetailedMarkets { detailedMarkets, marketsMap in
                print("OTGManager: Fetched Detailed Markets.")
                group.leave()
            }
        }
        
        group.enter()
        bgQueue.async {
            // Fetch all vendors
            OTGManager.sharedInstance.fetchVendors { vendors in
                print("OTGManager: Fetched Vendors.")
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main, execute: {
            print("OTGManager: Finished fetching new OffTheGrid Data!")
            if cacheData {
                // Cache the markets
                CachingManager.sharedInstance.saveJSONArray(jsonArray: self.markets, with: CachingManager.CacheKeys.markets)
                
                // Cache the detailed markets and its mapping
                CachingManager.sharedInstance.saveJSONArray(jsonArray: self.detailedMarkets, with: CachingManager.CacheKeys.detailedMarkets)
                CachingManager.sharedInstance.saveJSONMap(jsonMap: self.detailedMarketsMap, with: CachingManager.CacheKeys.detailedMarketsMap)
                
                // Cache the vendors and their event mappings
                CachingManager.sharedInstance.saveJSONArray(jsonArray: self.vendors, with: CachingManager.CacheKeys.vendors)
                CachingManager.sharedInstance.saveJSONObjectArrayMap(jsonObjectArrayMap: self.vendorEventsMap, with: CachingManager.CacheKeys.vendorEventsMap)
                
                print("OTGManager: Cached current OffTheGrid data!")
            }
            
            // Update Cache for new OffTheGrid data
            CachingManager.sharedInstance.syncCacheData()
        })
    }
    
    // MARK - Helpers
    func eventsForMarket(market:JSONObject) -> JSONObjectArray {
        let events = (market[Constants.Keys.events] as? JSONObjectArray) ?? JSONObjectArray()
        return events
    }
    
    func eventsForMarkets(markets:JSONObjectArray) -> JSONObjectArray {
        let allEvents = markets.map({ self.eventsForMarket(market: $0) }).reduce([], +)
        return allEvents
    }
    
    func eventsForVendorId(id:String, markets inMarkets:JSONObjectArray) -> JSONObjectArray {
        let marketEvents = self.eventsForMarkets(markets: markets)
        let vendorEvents:JSONObjectArray = marketEvents.flatMap({ event in
            var eventMatch:JSONObject? = nil
            let eventVendors = event[Constants.Keys.vendors] as? JSONObjectArray
            eventVendors?.forEach({ vendor in
                let vendorId = vendor[Constants.Keys.id] as? String
                if id == vendorId {
                    eventMatch = event
                }
            })
            
            return eventMatch
        })
        
        return vendorEvents
    }
    
    func eventsForVendor(vendorId: String) ->JSONObjectArray {
        let events = self.eventsForVendorId(id: vendorId, markets: self.detailedMarkets)
        return events
    }
    
    func vendorsForEvent(event:JSONObject) -> JSONObjectArray {
        let vendors = event[Constants.Keys.vendors] as? JSONObjectArray
        return vendors ?? JSONObjectArray()
    }
    
    func vendorEventsMapForEvents(events:JSONObjectArray) -> JSONObjectArrayMapping {
        var vendorEventsMap = JSONObjectArrayMapping()
        events.forEach({ event in
            if let eventId = (event[Constants.Keys.event] as? JSONObject)?[Constants.Keys.id] as? String {
                let vendors = self.vendorsForEvent(event: event)
                vendors.forEach({ vendor in
                    if let vendorId = vendor[Constants.Keys.id] as? String {
                        var eventsForVendor = (vendorEventsMap[vendorId]) ?? JSONObjectArray()
                        let eventIds = eventsForVendor.flatMap({ $0[Constants.Keys.id] as? String })
                        if eventIds.index(of: eventId) == nil {
                            // Add new, matching event for current vendor, and update the mapping
                            eventsForVendor.append(event)
                            vendorEventsMap[vendorId] = eventsForVendor
                        }
                    }
                })
            }
        })
        
        return vendorEventsMap
    }
    
    func vendorEventsMapForMarket(market:JSONObject) -> JSONObjectArrayMapping {
        //var vendorEventsMap = JSONObjectArrayMapping()
        let marketEvents = self.eventsForMarket(market: market)
        let vendorEventsMap = self.vendorEventsMapForEvents(events: marketEvents)
        
        /*marketEvents.forEach({ event in
            if let eventId = (event[Constants.Keys.event] as? JSONObject)?[Constants.Keys.id] as? String {
                let vendors = self.vendorsForEvent(event: event)
                vendors.forEach({ vendor in
                    if let vendorId = vendor[Constants.Keys.id] as? String {
                        var eventsForVendor = (vendorEventsMap[vendorId]) ?? JSONObjectArray()
                        let eventIds = eventsForVendor.flatMap({ $0[Constants.Keys.id] as? String })
                        if eventIds.index(of: eventId) == nil {
                            // Add new, matching event for current vendor, and update the mapping
                            eventsForVendor.append(event)
                            vendorEventsMap[vendorId] = eventsForVendor
                        }
                    }
                })
            }
        })*/
        
        return vendorEventsMap
    }
    
    func vendorEventsMapForMarkets(markets:JSONObjectArray) -> JSONObjectArrayMapping {
        var allVendorsEventsMap = JSONObjectArrayMapping()
        
        // Get all the vendor->events maps
        let vendorEventsMaps:[JSONObjectArrayMapping] = markets.flatMap({ market in
            return self.vendorEventsMapForMarket(market: market)
        })
        
        // Get the set of unique vendorIds
        let vendorIds:[String] = Array(Set(vendorEventsMaps.flatMap({ vendorEventsMap in
            return vendorEventsMap.keys
        })))
        
        // Map the events for all the unique vendorIds
        vendorIds.forEach({ id in
            let matchingEvents = vendorEventsMaps.flatMap({ vendorEventsMap in
                return vendorEventsMap[id]
            }).reduce([], +)
            
            // Map the events its vendor
            allVendorsEventsMap[id] = matchingEvents
        })
        
        return allVendorsEventsMap
    }
    
    func constructDateFromEvent(event:JSONObject?) -> Date? {
        let eventData = event?[OTGManager.Constants.Keys.event]
        let monthDay = eventData?[OTGManager.Constants.Keys.monthDay] as? String
        let components = monthDay?.components(separatedBy: ".")
        
        let monthInt = Int(components?.first ?? "") ?? -1
        let dayInt = Int(components?.last ?? "") ?? -1
        let date = DateComponents.localComponents.date(monthInt: monthInt, dayInt: dayInt)
        
        return date
    }
    
    func filterPastVendorEvents(events:JSONObjectArray) -> JSONObjectArray {
        let currentDate = Calendar.current.startOfDay(for: Date())
        
        let pastEvents = events.filter({ event in
            let eventDate = self.constructDateFromEvent(event: event)
            let numDaysSince = eventDate?.numberDaysUpTo(futureDate: currentDate) ?? 1

            return numDaysSince > 0 && numDaysSince <= CachingManager.Constants.maxDayLimit
        })
        
        return pastEvents
    }
}

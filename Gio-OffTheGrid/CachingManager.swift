//
//  CachingManager.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/10/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit
import DataCache

class CachingManager {
    static let sharedInstance = CachingManager()
    internal let pastVendorEventsMap = JSONObjectArrayMapping()
    
    public enum CacheKeys {
        static let markets = "Markets"
        static let detailedMarkets = "DetailedMarkets"
        static let detailedMarketsMap = "DetailedMarketsMapping"
        static let vendors = "Vendors"
        static let vendorEventsMap = "VendorEventsMapping"
    }
    
    internal enum PrivateKeys {
        static let aggregatedEvents = "futurePastAggreatedEvents"
        static let pastEvents = "pastVendorEvents"
    }
    
    public enum Constants {
        static let maxDayLimit = 30
    }
    
    // MARK - Cache Loading
    func loadJSON(from cacheKey:String) -> JSONObject? {
        if let data = DataCache.instance.readData(forKey: cacheKey) {
            return self.convertToJSON(from: data)
        }
        return nil
    }
    
    func loadJSONArray(from cacheKey:String) -> JSONObjectArray? {
        if let data = DataCache.instance.readData(forKey: cacheKey) {
            if let json = self.convertToJSON(from: data) {
                return json[cacheKey] as? JSONObjectArray
            }
        }
        return nil
    }
    
    func loadJSONMap(from cacheKey:String) -> JSONObjectMapping? {
        if let data = DataCache.instance.readData(forKey: cacheKey) {
            if let json = self.convertToJSON(from: data) {
                return json[cacheKey] as? JSONObjectMapping
            }
        }
        return nil
    }
    
    func loadJSONObjectArrayMap(from cacheKey:String) -> JSONObjectArrayMapping? {
        if let data = DataCache.instance.readData(forKey: cacheKey) {
            if let json = self.convertToJSON(from: data) {
                return json[cacheKey] as? JSONObjectArrayMapping
            }
        }
        return nil
    }
    
    func loadFromCache() {
        self.loadCachedMarkets()
        self.loadCachedDetailedMarkets()
        self.loadCachedDetailedMarketsMap()
        self.loadCachedVendors()
    }
    
    func loadCachedMarkets() {
        if let markets = self.loadJSONArray(from: CacheKeys.markets) {
            OTGManager.sharedInstance.markets = markets
        }
    }
    
    func loadCachedDetailedMarkets() {
        if let detailedMarkets = self.loadJSONArray(from: CacheKeys.detailedMarkets) {
            OTGManager.sharedInstance.detailedMarkets = detailedMarkets
        }
    }
    
    func loadCachedDetailedMarketsMap() {
        if let detailedMarketsMap = self.loadJSONMap(from: CacheKeys.detailedMarketsMap) {
            OTGManager.sharedInstance.detailedMarketsMap = detailedMarketsMap
        }
    }
    
    func loadCachedVendorEventsMap() {
        if let vendorEventsMap = self.loadJSONObjectArrayMap(from: CacheKeys.vendorEventsMap) {
            OTGManager.sharedInstance.vendorEventsMap = vendorEventsMap
        }
    }
    
    func loadCachedVendors() {
        if let vendors = self.loadJSONArray(from: CacheKeys.vendors) {
            OTGManager.sharedInstance.vendors = vendors
        }
    }
    
    // MARK - Cache Saving
    func saveJSON(json:JSONObject, with cacheKey:String) {
        if let data = self.convertToData(from: json) {
            DataCache.instance.write(data: data, forKey: cacheKey)
        }
    }
    
    func saveJSONArray(jsonArray:JSONObjectArray, with cacheKey:String) {
        let json = [cacheKey: jsonArray as AnyObject]
        self.saveJSON(json: json, with: cacheKey)
    }
    
    func saveJSONMap(jsonMap:JSONObjectMapping, with cacheKey:String) {
        let json = [cacheKey: jsonMap as AnyObject]
        self.saveJSON(json: json, with: cacheKey)
    }
    
    func saveJSONObjectArrayMap(jsonObjectArrayMap:JSONObjectArrayMapping, with cacheKey:String) {
        let json = [cacheKey: jsonObjectArrayMap as AnyObject]
        self.saveJSON(json: json, with: cacheKey)
    }
    
    // MARK - Cache Updating
    func refreshEventsCache() {
        // Scan the cached upcoming events and move past events into the private cache
        self.scanCachedUpcomingEvents()
    }
    
    internal func scanCachedUpcomingEvents() {
        let localEvents = OTGManager.sharedInstance.allEvents
        let pastEvents = OTGManager.sharedInstance.filterPastVendorEvents(events: localEvents)
        
    }
    
    // MARK - DataCache (JSONObject <-> Data) Conversions
    internal func convertToData(from json: JSONObject) -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        } catch _ {
            return nil
        }
    }
    
    internal func convertToJSON(from data: Data) -> JSONObject? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? JSONObject
        } catch _ {
            return nil
        }
    }
}

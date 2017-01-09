//
//  PersistanceManager.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/9/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit
import DataCache

public enum CacheKeys {
    static let markets = "Markets"
    static let events = "Events"
    static let vendors = "Vendors"
}

class PersistanceManager {
    static let sharedInstance = PersistanceManager()
    var storedMarketsJSON = JSONObject()
    var storedEventsJSON = JSONObject()
    var storedVendorsJSON = JSONObject()
    
    func loadCache() {
        // Load cached markets
        self.loadCachedMarkets()
        
        // Load cached vendors
        self.loadCachedVendors()
    }
    
    internal func loadCachedMarkets() {
        if let cachedMarkets = self.loadJSON(from: CacheKeys.markets) {
            self.storedEventsJSON = cachedMarkets
            if let markets = cachedMarkets[CacheKeys.markets] as? JSONObjectArray {
                OTGManager.sharedInstance.markets = markets
            }
        }
    }
    
    /*internal func loadCachedEvents() {
        if let cachedEvents = self.loadJSON(from: CacheKeys.events) {
            self.storedEventsJSON = cachedEvents
            if let events = cachedEvents[CacheKeys.events] as? JSONObjectArray {
                OTGManager.sharedInstance.upcomingEvents = events
            }
        }
    }*/
    
    internal func loadCachedVendors() {
        if let cachedVendors = self.loadJSON(from: CacheKeys.vendors) {
            self.storedVendorsJSON = cachedVendors
            if let vendors = cachedVendors[CacheKeys.vendors] as? JSONObjectArray {
                OTGManager.sharedInstance.vendors = vendors
            }
        }
    }
    
    // MARK - JSON/Data Conversions
    func convertToData(from json: JSONObject) -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        } catch _ {
            return nil
        }
    }
    
    func convertToJSON(from data: Data) -> JSONObject? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? JSONObject
        } catch _ {
            return nil
        }
    }
    
    // MARK - Save/Load Local Cache
    func saveJSON(json:JSONObject, with cacheKey: String) {
        if let data = self.convertToData(from: json) {
            DataCache.instance.write(data: data, forKey: cacheKey)
        }
    }
    
    func loadJSON(from cacheKey:String) -> JSONObject? {
        if let data = DataCache.instance.readData(forKey: cacheKey) {
            return self.convertToJSON(from: data)
        }
        return nil
    }
}

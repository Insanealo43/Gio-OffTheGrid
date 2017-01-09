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
    internal enum Constants {
        enum Relations {
            static let vendorIdToEventId = "vendorId-->eventId"
            static let eventIdToJSON = "eventId-->eventJSON"
        }
        
        static let maxDayLimit = 30
    }
    internal enum Relations {
        static let vendorIdToEventId = "vendorId-->eventId"
        static let eventIdToJSON = "eventId-->eventJSON"
    }
    
    var vendorIdToEventIdMap = [String:String]()
    var eventIdtoEventJSONMap = [String:JSONObject]()
    
    internal var currentDate = Calendar.current.startOfDay(for: Date())
    internal var storedMarketsJSON = JSONObject()
    internal var storedEventsJSON = JSONObject()
    internal var storedVendorsJSON = JSONObject()
    
    // MARK - Cache Loading
    func loadCache() {
        // Load cached markets
        self.loadCachedMarkets()
        
        // Load cached vendors
        self.loadCachedVendors()
        
        // Cleanup old events
        self.cleanCache()
    }
    
    func loadJSON(from cacheKey:String) -> JSONObject? {
        if let data = DataCache.instance.readData(forKey: cacheKey) {
            return self.convertToJSON(from: data)
        }
        return nil
    }
    
    internal func loadCachedMarkets() {
        if let cachedMarkets = self.loadJSON(from: CacheKeys.markets) {
            self.storedEventsJSON = cachedMarkets
            if let markets = cachedMarkets[CacheKeys.markets] as? JSONObjectArray {
                // Populate the local Markets
                OTGManager.sharedInstance.markets = markets
                
                // Store the computed Events, derived from the local Markets
                self.storedMarketsJSON = [CacheKeys.events: OTGManager.sharedInstance.upcomingEvents as AnyObject]
            }
        }
    }
    
    internal func loadCachedVendors() {
        if let cachedVendors = self.loadJSON(from: CacheKeys.vendors) {
            self.storedVendorsJSON = cachedVendors
            if let vendors = cachedVendors[CacheKeys.vendors] as? JSONObjectArray {
                // Populate the local Vendors
                OTGManager.sharedInstance.vendors = vendors
            }
        }
    }
    
    // MARK - Cache Saving
    func saveJSON(json:JSONObject, with cacheKey: String) {
        if let data = self.convertToData(from: json) {
            DataCache.instance.write(data: data, forKey: cacheKey)
        }
    }
    
    // MARK - (JSONObject <-> Data) Conversions
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
    
    // MARK - Helpers
    internal func cleanCache() {
        Array(self.eventIdtoEventJSONMap.values).forEach({
            if let eventId = $0["id"] as? String {
                if self.shouldClear(event: $0) {
                    // Remove all vendorIds mapped to invalid eventId
                    let vendorIds = self.vendorIdToEventIdMap.keysForValue(value: eventId)
                    
                    vendorIds.forEach({
                        self.vendorIdToEventIdMap.removeValue(forKey: String($0))
                    })
                    
                    // Remove the invalid event
                    self.eventIdtoEventJSONMap.removeValue(forKey: eventId)
                }
            }
        })
    }
    
    internal func shouldClear(event: JSONObject) -> Bool {
        if let monthDay = event["month_day"] as? String {
            let components = monthDay.components(separatedBy: ".")
            if let monthInt = Int(components.first ?? "-1"),
                let dayInt = Int(components.last ?? "-1") {
                
                let startDate = DateComponents.localComponents.date(monthInt: monthInt, dayInt: dayInt)
                if let numDays = startDate?.numberDaysUpTo(futureDate: self.currentDate) {
                    return numDays > 0 && numDays <= Constants.maxDayLimit
                }
            }
        }
        return true
    }
}

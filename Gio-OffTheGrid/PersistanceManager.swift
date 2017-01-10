//
//  PersistanceManager.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/9/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit
import DataCache

/* TODO:
    - Hook into 'applicationSignificantTimeChange' for date change notifications
 */

typealias IdRelationOneToMany = [String:[String]]

public enum CacheKeys {
    static let markets = "Markets"
    static let events = "Events"
    static let vendors = "Vendors"
}

class PersistanceManager {
    static let sharedInstance = PersistanceManager()
    internal enum Constants {
        enum Relations {
            static let vendorIdToEventIds = "vendorId-->[eventId]"
            static let eventIdToVendorIds = "eventId-->[vendorId]"
            static let eventIdToEventJSON = "eventId-->eventJSON"
        }
        
        static let maxDayLimit = 30
    }
    
    internal var eventIdtoEventJSONMap = JSONObjectMapping()
    internal var vendorIdToEventIdsMap = IdRelationOneToMany()
    internal var eventIdToVendorIdsMap = IdRelationOneToMany()
    
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
        
        // Load the relations into memory
        self.loadRelations()
        
        // Refresh the Cache
        self.refreshCache()
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
                //self.storedMarketsJSON = [CacheKeys.events: OTGManager.sharedInstance.upcomingEvents as AnyObject]
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
    
    internal func loadRelations() {
        let vendorEventsRelation = Constants.Relations.vendorIdToEventIds
        if let vendorEvents = self.loadJSON(from: vendorEventsRelation) {
            if let mapping = vendorEvents[vendorEventsRelation] as? IdRelationOneToMany {
                self.vendorIdToEventIdsMap = mapping
            }
        }
        
        let eventVendorsRelation = Constants.Relations.eventIdToVendorIds
        if let eventVendors = self.loadJSON(from: eventVendorsRelation) {
            if let mapping = eventVendors[eventVendorsRelation] as? IdRelationOneToMany {
                self.eventIdToVendorIdsMap = mapping
            }
        }
        
        let idEventRelation = Constants.Relations.eventIdToVendorIds
        if let idEvents = self.loadJSON(from: idEventRelation) {
            if let mapping = idEvents[idEventRelation] as? JSONObjectMapping {
                self.eventIdtoEventJSONMap = mapping
            }
        }
    }
    
    // MARK - Cache Saving
    func saveJSON(json:JSONObject, with cacheKey: String) {
        if let data = self.convertToData(from: json) {
            DataCache.instance.write(data: data, forKey: cacheKey)
        }
    }
    
    internal func saveRelations() {
        let vendorEventsRelation = Constants.Relations.vendorIdToEventIds
        let vendorEventsJSON = [vendorEventsRelation: self.vendorIdToEventIdsMap as AnyObject]
        self.saveJSON(json: vendorEventsJSON, with: vendorEventsRelation)
        
        let eventVendorsRelation = Constants.Relations.eventIdToVendorIds
        let eventVendorsJSON = [eventVendorsRelation: self.eventIdToVendorIdsMap as AnyObject]
        self.saveJSON(json: eventVendorsJSON, with: eventVendorsRelation)
        
        let idEventRelation = Constants.Relations.eventIdToVendorIds
        let idEventJSON = [idEventRelation: self.eventIdtoEventJSONMap as AnyObject]
        self.saveJSON(json: idEventJSON, with: idEventRelation)
    }
    
    // MARK - Cache Sycning
    func syncCache(event: JSONObject, withVendors: JSONObjectArray) {
        
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
    internal func refreshCache() {
        // Cleanup old events
        self.cleanCache()
        
        // Save the relations to disk
        self.saveRelations()
    }
    
    internal func cleanCache() {
        // Aggreate all the cached eventIds
        var invalidEventIds = [String]()
        Array(self.eventIdtoEventJSONMap.values).forEach({
            if let eventId = $0["id"] as? String {
                if self.shouldClear(event: $0) {
                    // Keep track of the invalid eventId
                    invalidEventIds.append(eventId)
                }
            }
        })
        
        var affectedVendorIds = [String]()
        invalidEventIds.forEach({
            if let vendorIds = self.eventIdToVendorIdsMap[$0] {
                // Track the vendorIds that contain the invalid eventIds
                affectedVendorIds.append(contentsOf: vendorIds)
                
                // Remove the invalid (eventId --> [vendorId]) relations
                self.eventIdtoEventJSONMap.removeValue(forKey: $0)
                
                // Remove the invalid eventJSON objects
                self.eventIdtoEventJSONMap.removeValue(forKey: $0)
            }
        })
        
        // Update all the affected vendorId relations
        affectedVendorIds.forEach({
            if var eventIds = self.vendorIdToEventIdsMap[$0] {
                if let invalidEventIndex = eventIds.index(of: $0) {
                    if eventIds.indices.contains(invalidEventIndex) {
                        // Dis-associated the invalid eventId from the vendor
                        eventIds.remove(at: invalidEventIndex)
                        
                        // Update the vendorId relations
                        self.vendorIdToEventIdsMap[$0] = eventIds
                    }
                }
            }
        })
        
        // TODO: Cleanup the local JSON stores
        
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

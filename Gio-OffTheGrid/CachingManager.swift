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
    
    public enum CacheKeys {
        static let markets = "Markets"
        static let detailedMarkets = "DetailedMarkets"
        static let detailedMarketsMap = "DetailedMarketsMapping"
        static let vendors = "Vendors"
    }
    
    internal enum Constants {
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
    
    func loadFromCache() {
        self.loadCachedMarkets()
        self.loadCachedDetailedMarkets()
        self.loadCachedDetailedMarketsMap()
        self.loadCachedVendors()
    }
    
    internal func loadCachedMarkets() {
        if let markets = self.loadJSONArray(from: CacheKeys.markets) {
            OTGManager.sharedInstance.markets = markets
        }
    }
    
    internal func loadCachedDetailedMarkets() {
        if let detailedMarkets = self.loadJSONArray(from: CacheKeys.detailedMarkets) {
            OTGManager.sharedInstance.detailedMarkets = detailedMarkets
        }
    }
    
    internal func loadCachedDetailedMarketsMap() {
        if let detailedMarketsMap = self.loadJSONMap(from: CacheKeys.detailedMarketsMap) {
            OTGManager.sharedInstance.detailedMarketsMap = detailedMarketsMap
        }
    }
    
    internal func loadCachedVendors() {
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
    
    // MARK - (JSONObject <-> Data) Conversions
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

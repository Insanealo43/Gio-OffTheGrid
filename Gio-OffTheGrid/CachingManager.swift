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
    
    // MARK - Cache Saving
    func saveJSON(json:JSONObject, with cacheKey: String) {
        if let data = self.convertToData(from: json) {
            DataCache.instance.write(data: data, forKey: cacheKey)
        }
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

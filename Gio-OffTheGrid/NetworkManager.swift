//
//  NetworkManager.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/7/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit
import Alamofire

typealias JSONObject = [String:AnyObject]
typealias JSONObjectArray = [JSONObject]
typealias JSONObjectMapping = [String:JSONObject]

typealias EmptyClosure = (() -> Void)

class NetworkManager {
    static let sharedInstance = NetworkManager()
    internal let bgQueue = DispatchQueue.global(qos: .default)
    
    func request(url:String, method:HTTPMethod? = .get, parameters:JSONObject? = [:], handler: ((JSONObject?) -> Void)? = nil) {
        bgQueue.async {
            Alamofire.request(url, method: method!, parameters: parameters).validate().responseJSON { response in
                let JSON = (response.result.value as? JSONObject ?? [:])
                switch response.result {
                case .failure(let error):
                    print("NetworkManager: Request Error: \(error)")
                    handler?(nil)
                case .success:
                    handler?(JSON)
                }
            }
        }
    }
    
    func batchFetchRequest(urls:[String], requestHandler: ((_ url: String, _ response: JSONObject?) -> Void)? = nil, completion: EmptyClosure? = nil) {
        if urls.count == 0 {
            completion?()
            return
        }
        
        print("Performing \(urls.count) Batch Request Operations...")
        let group = DispatchGroup()
        urls.forEach({ url in
            group.enter()
            bgQueue.async {
                // Prevent deadlock on Main Thread
                self.request(url: url, handler: { response in
                    requestHandler?(url, response)
                    group.leave()
                })
            }
        })
        
        // Finish and notify on the Main Thread
        group.notify(queue: DispatchQueue.main, execute: {
            completion?()
        })
    }
}

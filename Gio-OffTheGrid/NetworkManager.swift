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

class NetworkManager {
    static let sharedInstance = NetworkManager()
    
    func request(url:String, method:HTTPMethod? = .get, parameters:[String:AnyObject]? = [:], handler: (([String:AnyObject]?) -> Void)? = nil) {
        Alamofire.request(url, method: method!, parameters: parameters).validate().responseJSON { response in
            let JSON = (response.result.value as? [String:AnyObject] ?? [:])
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

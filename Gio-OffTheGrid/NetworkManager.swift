//
//  NetworkManager.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/7/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit
import Alamofire

class NetworkManager {
    static let sharedInstance = NetworkManager()
    
    func testRequest() {
        Alamofire.request("https://httpbin.org/get", method: .get, parameters: [:], headers: [:]).validate().responseJSON { response in
            switch response.result {
            case .success:
                print("Validation Successful! \nJSON: \(response.result.value ?? [:])")
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func request(url:String, method:HTTPMethod? = .get, parameters:[String:AnyObject]? = [:], handler: (([String:AnyObject]) -> Void)? = nil) {
        Alamofire.request(url, method: method!, parameters: parameters).validate().responseJSON { response in
            print("Finished Request: \(response.request)")
            switch response.result {
            case .success:
                print("Validation Successful! \nJSON: \(response.result.value ?? [:])")
            case .failure(let error):
                print(error)
            }
        }
        
        
        /*Alamofire.request(url, method: method, parameters: parameters, headers: headers).validate().responseJSON { response in
            print("Finished Request: \(response.request)")
            switch response.result {
            case .success:
                print("Validation Successful! \nJSON: \(response.result.value ?? [:])")
            case .failure(let error):
                print(error)
            }
        }*/
    }
}

//
//  MarketHeaderTableViewCell.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/9/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit

class MarketHeaderTableViewCell: UITableViewCell {
    @IBOutlet weak var marketLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    var market:JSONObject? {
        willSet {
            let marketInfo = newValue?["Market"] as? JSONObject
            let marketName = marketInfo?["name"] as? String
            marketLabel.text = marketName
            
            var components = [String]()
            if let address = marketInfo?["address"] as? String {
                components.append(address)
            }
            if let city = marketInfo?["city"] as? String {
                components.append(city)
            }
            addressLabel.text = components.joined(separator: ", ")
        }
    }
}

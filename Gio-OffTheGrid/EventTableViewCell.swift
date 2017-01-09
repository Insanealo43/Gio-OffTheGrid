//
//  EventTableViewCell.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/8/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit

class EventTableViewCell: UITableViewCell {
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    
    var event: JSONObject? {
        willSet {
            let dateString = newValue?["start_time"] as? String
            let isoDate = dateString?.isoDate
            
            monthLabel.text = isoDate?.monthAbbrevation
            dayLabel.text = isoDate?.dayNumber
            nameLabel.text = newValue?["name"] as? String
            
            var components = [String]()
            if let timeString = isoDate?.eventTime {
                components.append(timeString)
            }
            if let eventInfo = newValue?["description"] as? String {
                components.append(eventInfo)
            }
            
            infoLabel.text = components.joined(separator: " · ")
        }
    }
}

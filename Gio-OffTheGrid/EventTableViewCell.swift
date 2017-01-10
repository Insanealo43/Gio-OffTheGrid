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
            let eventData = newValue?[OTGManager.Constants.Keys.event]
            let date = OTGManager.sharedInstance.constructDateFromEvent(event: newValue)
            
            self.monthLabel.text = date?.monthAbbrevation
            
            let monthDay = eventData?[OTGManager.Constants.Keys.monthDay] as? String
            let components = monthDay?.components(separatedBy: ".")
            self.dayLabel.text = components?.last
            
            let hours = (eventData?[OTGManager.Constants.Keys.hours] as? String) ?? ""
            let period = ((eventData?[OTGManager.Constants.Keys.amPm]) as? String ?? "").lowercased()
            let timeComponents = [hours, period]
            self.nameLabel.text = timeComponents.joined(separator: " ")
            
            let id = (eventData?[OTGManager.Constants.Keys.id] as? String) ?? ""
            self.infoLabel.text = "Event Id: \(id)"
        }
    }
}

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
            let monthDay = eventData?[OTGManager.Constants.Keys.monthDay] as? String
            let components = monthDay?.components(separatedBy: ".")
            
            let monthInt = Int(components?.first ?? "") ?? -1
            let dayInt = Int(components?.last ?? "") ?? -1
            let date = DateComponents.localComponents.date(monthInt: monthInt, dayInt: dayInt)
            
            self.monthLabel.text = date?.monthAbbrevation
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

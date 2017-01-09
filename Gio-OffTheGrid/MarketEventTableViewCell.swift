//
//  MarketEventTableViewCell.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/9/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit

class MarketEventTableViewCell: UITableViewCell {
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var clockImageView: UIImageView!
    @IBOutlet weak var timeframeLabel: UILabel!

    var marketEvent: JSONObject? {
        willSet {
            dayLabel.text = newValue?["abbreviated_day_of_week"] as? String
            dateLabel.text = (newValue?["month_day"] as? String)?.replacingOccurrences(of: ".", with: "/")
            
            let hours = newValue?["hours"] as? String
            let period = (newValue?["am_pm"] as? String)?.lowercased()
            let timeframe = "\(hours ?? "")\(period ?? "")"
            clockImageView.isHidden = timeframe.characters.count == 0
            timeframeLabel.text = timeframe
        }
    }
    
    /*override func awakeFromNib() {
        super.awakeFromNib()
        marketEvent = nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        marketEvent = nil
    }*/
}

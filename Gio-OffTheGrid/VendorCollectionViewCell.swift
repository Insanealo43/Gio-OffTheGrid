//
//  VendorCollectionViewCell.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/9/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit

class VendorCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var eventsIconImageView: UIImageView!
    @IBOutlet weak var eventCountLabel: UILabel!
    
    var vendor: JSONObject? {
        willSet {
            let logoUrl = newValue?["logo_url"] as? String
            imageView.fetchImageForUrl(urlString: logoUrl, callback: nil)
            nameLabel.text = newValue?["name"] as? String
            
            if let vendorId = newValue?[OTGManager.Constants.Keys.id] as? String {
                if let vendorEvents = OTGManager.sharedInstance.vendorEventsMap[vendorId] {
                    self.eventCountLabel.text = String(vendorEvents.count)
                }
            }

        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let selectionView = UIView()
        selectionView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        self.selectedBackgroundView = selectionView
        
        if let eventImage = eventsIconImageView.image {
            eventsIconImageView.setImageWithTintColor(image: eventImage, tintColor: UIColor.white)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        eventCountLabel.text = String(0)
    }
}

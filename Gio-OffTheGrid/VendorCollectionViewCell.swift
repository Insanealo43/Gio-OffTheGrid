//
//  VendorCollectionViewCell.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/9/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit
import SDWebImage

class VendorCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var vendorImageView: CircularImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var cuisineLabel: UILabel!
    
    var vendor: JSONObject? {
        willSet {
            let logoUrl = newValue?["logo_url"] as? String
            vendorImageView.fetchImageForUrl(urlString: logoUrl, callback: nil)
            
            nameLabel.text = newValue?["name"] as? String
            cuisineLabel.text = newValue?["cuisine"] as? String
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        vendorImageView.image = nil
    }
}

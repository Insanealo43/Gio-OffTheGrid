//
//  CircularImageView.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/9/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit

class CircularImageView: UIImageView {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.clipsToBounds = true
        self.layer.cornerRadius = self.frame.size.height/2
    }
}

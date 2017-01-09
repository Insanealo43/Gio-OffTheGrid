//
//  EventVendorsFlowLayout.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/9/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit

@objc
@IBDesignable
class EventVendorsFlowLayout: UICollectionViewFlowLayout {
    @IBInspectable dynamic var numCols: Int = 3 {
        willSet {
            self.collectionView?.reloadData()
        }
    }
    
    @IBInspectable dynamic var itemSpacing: Int = 2 {
        willSet {
            minimumInteritemSpacing = CGFloat(newValue)
            minimumLineSpacing = CGFloat(newValue)
            
            self.collectionView?.reloadData()
        }
    }
    
    override init() {
        super.init()
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }
    
    func setupLayout() {
        self.scrollDirection = .vertical
        self.numCols = 3
        self.itemSpacing = 2
    }
    
    override var itemSize: CGSize {
        set { }
        get {
            let itemWidth = (self.collectionView!.frame.size.width - (CGFloat(numCols) - 1)*(CGFloat(itemSpacing))) / CGFloat(numCols)
            return CGSize.init(width: itemWidth, height: itemWidth)
        }
    }

}

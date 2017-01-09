//
//  VendorsTabViewController.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/8/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit

class VendorsTabViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    internal var vendors: JSONObjectArray {
        get {
            return OTGManager.sharedInstance.vendors
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showHUD()
        OTGManager.sharedInstance.fetchVendors{ _ in
            self.hideHUD()
            self.collectionView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

extension VendorsTabViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? self.vendors.count : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "vendorCell", for: indexPath) as! VendorCollectionViewCell
        cell.vendor = self.vendors[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
    }
}

//
//  EventVendorsViewController.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/9/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit

class EventVendorsViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    internal var eventId: String?
    var marketEvent: JSONObject? {
        willSet {
            eventId = newValue?["id"] as? String
        }
    }
    
    internal var vendors = JSONObjectArray()
    internal var marketDetails: JSONObject? {
        willSet {
            let events = newValue?["Events"] as? JSONObjectArray
            events?.forEach({ event in
                let eventData = event["Event"] as? JSONObject
                if let currentEventId = eventData?["id"] as? String,
                    let marketEventId = self.eventId {
                    if currentEventId == marketEventId {
                        if let vendors = event["Vendors"] as? JSONObjectArray {
                            self.vendors = vendors
                            return
                        }
                    }
                }
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let marketId = marketEvent?["market_id"] as? String {
            self.showHUD()
            OTGManager.sharedInstance.fetchMarketDetails(id: marketId, handler: { details in
                self.hideHUD()
                self.marketDetails = details
                self.collectionView.reloadData()
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
}

extension EventVendorsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? vendors.count : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "vendorCell", for: indexPath) as! EventVendorCollectionViewCell
        cell.vendor = self.vendors[indexPath.row]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
    }
}

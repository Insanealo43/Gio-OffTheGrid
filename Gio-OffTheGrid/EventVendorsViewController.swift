//
//  EventVendorsViewController.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/9/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit

class EventVendorsViewController: UIViewController {
    internal enum Constants {
        static let vendorCellId = "vendorCell"
        static let vendorEventsSegueId = "showMarketVendorEvents"
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var event:JSONObject?
    var vendors = JSONObjectArray()
    
    internal var eventId:String? {
        get { return event?[OTGManager.Constants.Keys.id] as? String }
    }
    
    internal var marketId:String? {
        get { return event?[OTGManager.Constants.Keys.marketId] as? String }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchDetailedMarket()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    internal func fetchDetailedMarket() {
        if let marketId = self.marketId, vendors.count == 0 {
            self.showHUD()
            OTGManager.sharedInstance.fetchDetailedMarket(id: marketId) { market in
                self.hideHUD()
                
                if let eventId = self.eventId {
                    let eventMap = market?[OTGManager.Constants.CustomKeys.eventIdEventJSONMapKey] as? JSONObjectMapping
                    if let vendors = (eventMap?[eventId]?[OTGManager.Constants.Keys.vendors]) as? JSONObjectArray {
                        self.vendors = vendors
                    }
                }
                
                self.collectionView.reloadData()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.vendorEventsSegueId {
            if let vendorEventsController = segue.destination as? VendorEventsViewController {
                if let indexPath = sender as? IndexPath {
                    let vendor = self.vendors[indexPath.row]
                    if let vendorId = vendor[OTGManager.Constants.Keys.id] as? String {
                        if let vendorEvents = OTGManager.sharedInstance.vendorEventsMap[vendorId] {
                            vendorEventsController.events = vendorEvents
                        }
                    }
                }
            }
        }
    }
}

extension EventVendorsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? vendors.count : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.vendorCellId, for: indexPath) as! EventVendorCollectionViewCell
        cell.vendor = self.vendors[indexPath.row]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        self.performSegue(withIdentifier: Constants.vendorEventsSegueId, sender: indexPath)
    }
}

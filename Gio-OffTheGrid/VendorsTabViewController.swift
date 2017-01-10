//
//  VendorsTabViewController.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/8/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit

class VendorsTabViewController: UIViewController {
    internal enum Constants {
        static let vendorCellId = "vendorCell"
        static let vendorEventsSegueId = "showVendorEvents"
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    internal var vendors: JSONObjectArray {
        get {
            return OTGManager.sharedInstance.vendors
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.vendors.count == 0 {
            self.showHUD()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        if self.vendors.count == 0 {
            let notificationName = Notification.Name(OTGManager.Constants.Notifications.VendorsFetched)
            NotificationCenter.default.addObserver(forName: notificationName, object:OTGManager.sharedInstance, queue:nil) { notification in
                self.hideHUD()
                self.collectionView.reloadData()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
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

extension VendorsTabViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? self.vendors.count : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.vendorCellId, for: indexPath) as! VendorCollectionViewCell
        cell.vendor = self.vendors[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        self.performSegue(withIdentifier: Constants.vendorEventsSegueId, sender: indexPath)
    }
}

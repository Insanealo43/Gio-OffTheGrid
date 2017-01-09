//
//  EventsViewController.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/8/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit

class EventsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.sectionHeaderHeight = 44.0
        OTGManager.sharedInstance.fetchMarkets{ _ in
            self.tableView.reloadData()
        }
    }
}

extension EventsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return OTGManager.sharedInstance.markets.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let marketCell = tableView.dequeueReusableCell(withIdentifier: "marketCell") as! MarketHeaderTableViewCell
        let market = OTGManager.sharedInstance.markets[section]
        marketCell.market = market
        return marketCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let market = OTGManager.sharedInstance.markets[section]
        let events = market["Event"] as? JSONObjectArray ?? []
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let eventCell = tableView.dequeueReusableCell(withIdentifier: "marketEventCell", for: indexPath) as! MarketEventTableViewCell
        
        let market = OTGManager.sharedInstance.markets[indexPath.section]
        let event = (market["Event"] as? JSONObjectArray)?[indexPath.row]
        eventCell.marketEvent = event
        
        return eventCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

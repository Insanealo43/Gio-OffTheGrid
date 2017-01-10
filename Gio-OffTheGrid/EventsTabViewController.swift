//
//  EventsTabViewController.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/8/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit

class EventsTabViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    internal var markets: JSONObjectArray {
        get {
            return OTGManager.sharedInstance.markets
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.sectionHeaderHeight = 44.0
        
        if self.markets.count == 0 {
            self.showHUD()
        }
        
        OTGManager.sharedInstance.fetchMarketsOld{ markets in
            self.hideHUD()
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEventVendors" {
            if let eventVendorsController = segue.destination as? EventVendorsViewController {
                if let marketEvent = sender as? JSONObject {
                    eventVendorsController.marketEvent = marketEvent
                }
            }
        }
    }
}

extension EventsTabViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.markets.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let marketCell = tableView.dequeueReusableCell(withIdentifier: "marketCell") as! MarketHeaderTableViewCell
        let market = self.markets[section]
        marketCell.market = market
        return marketCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let market = self.markets[section]
        let events = market["Event"] as? JSONObjectArray ?? []
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let eventCell = tableView.dequeueReusableCell(withIdentifier: "marketEventCell", for: indexPath) as! MarketEventTableViewCell
        
        let market = self.markets[indexPath.section]
        let event = (market["Event"] as? JSONObjectArray)?[indexPath.row]
        eventCell.marketEvent = event
        
        return eventCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let market = self.markets[indexPath.section]
        let event = (market["Event"] as? JSONObjectArray)?[indexPath.row]
        self.performSegue(withIdentifier: "showEventVendors", sender: event)
    }
}

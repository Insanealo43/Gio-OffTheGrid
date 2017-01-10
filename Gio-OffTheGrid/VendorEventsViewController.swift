//
//  VendorEventsViewController.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/10/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit

class VendorEventsViewController: UIViewController {
    internal enum Constants {
        static let eventCellId = "vendorEventCell"
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var events = JSONObjectArray()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
}

extension VendorEventsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let eventCell = tableView.dequeueReusableCell(withIdentifier: Constants.eventCellId, for: indexPath) as! EventTableViewCell
        eventCell.event = self.events[indexPath.row]
        
        return eventCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

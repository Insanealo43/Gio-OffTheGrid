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
    var upcomingEvents = JSONObjectArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.sectionHeaderHeight = 28.0
        OTGManager.sharedInstance.fetchUpcomingEvents { events in
            self.upcomingEvents = events
            self.tableView.reloadData()
        }
    }
}

extension EventsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return upcomingEvents.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableCell(withIdentifier: "headerCell")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let eventCell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as! EventTableViewCell
        eventCell.event = upcomingEvents[indexPath.row]
        
        return eventCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

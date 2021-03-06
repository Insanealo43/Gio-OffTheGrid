//
//  Extensions.swift
//  Gio-OffTheGrid
//
//  Created by Andrew Lopez-Vass on 1/8/17.
//  Copyright © 2017 Andrew Lopez-Vass. All rights reserved.
//

import UIKit
import SDWebImage
import MBProgressHUD

extension String {
    var isoDate: Date? {
        return Date.isoFormatter.date(from: self)
    }
}

extension UIViewController {
    func showHUD() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
    }
    
    func hideHUD() {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
}

extension Dictionary where Value: Equatable {
    func keysForValue(value: Value) -> [Key] {
        return flatMap { (key: Key, val: Value) -> Key? in
            value == val ? key : nil
        }
    }
}

extension Date {
    static let isoFormatter = ISO8601DateFormatter()
    
    static let localFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = NSTimeZone.local
        return formatter
    }()
    
    var monthNumber: String? {
        Date.localFormatter.dateFormat = "MM"
        return Date.localFormatter.string(from: self)
    }
    
    var monthAbbrevation: String? {
        Date.localFormatter.dateFormat = "MMM"
        return Date.localFormatter.string(from: self)
    }
    
    var dayNumber: String? {
        Date.localFormatter.dateFormat = "dd"
        return Date.localFormatter.string(from: self)
    }
    
    var dayAbbreviation: String? {
        Date.localFormatter.dateFormat = "EEE"
        return Date.localFormatter.string(from: self)
    }
    
    var hour: String? {
        Date.localFormatter.dateFormat = "h"
        return Date.localFormatter.string(from: self)
    }
    
    var timePeriod: String? {
        Date.localFormatter.dateFormat = "a"
        return Date.localFormatter.string(from: self)
    }
    
    var eventTime: String? {
        var timeComponents = [String]()
        if let dayAbbrev = self.dayAbbreviation {
            timeComponents.append(dayAbbrev)
        }
        if let hour = self.hour {
            timeComponents.append(hour)
        }
        if let period = self.timePeriod {
            timeComponents.append(period)
        }
        return timeComponents.joined(separator: " ")
    }
    
    func numberDaysUpTo(futureDate: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: self, to: futureDate)
        return components.day ?? -1
    }
}

extension DateComponents {
    static var localComponents: DateComponents = {
        var components = DateComponents()
        components.calendar = Calendar.current
        return components
    }()
    
    func date(monthInt: Int, dayInt: Int) -> Date? {
        var components = DateComponents.localComponents
        components.month = monthInt
        components.day = dayInt
        return components.date
    }
}

extension UIImageView {
    func setImageWithTintColor(image: UIImage, tintColor: UIColor) {
        self.image = image.withRenderingMode(.alwaysTemplate)
        self.tintColor = tintColor
    }
    
    func fetchImageForUrl(urlString: String?, callback: ((UIImage?) -> Void)?) {
        if let imageUrl = urlString {
            self.sd_setImage(with: URL.init(string: imageUrl), placeholderImage: nil,
                             options: [.continueInBackground, .lowPriority])
            { (image, error, cacheType, url) in
                self.image = image
                callback?(image)
            }
            
        } else {
            callback?(nil)
        }
    }
}

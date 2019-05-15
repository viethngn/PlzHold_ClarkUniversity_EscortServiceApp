//
//  Rider.swift
//  Escort Driver
//
//  Created by Viet Hong Nguyen on 4/25/19.
//  Copyright © 2019 Viet Hong Nguyen. All rights reserved.
//

import Foundation
struct Rider {
    let name: String
    let longitude: Double
    let latitude: Double
    init(data: [String:AnyObject]) {
        self.name = data["name"] as! String
        self.longitude = data["longitude"] as! Double
        self.latitude = data["latitude"] as! Double
    }
}

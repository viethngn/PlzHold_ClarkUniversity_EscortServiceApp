//
//  RideStatus.swift
//  Escort Client
//
//  Created by Viet Hong Nguyen on 4/22/19.
//  Copyright © 2019 Viet Hong Nguyen. All rights reserved.
//

import Foundation

enum RideStatus: String {
    case Neutral = "Neutral"
    case Searching = "Searching"
    case FoundRide = "FoundRide"
    case Arrived = "Arrived"
    case OnTrip = "OnTrip"
    case EndedTrip = "EndedTrip"
}

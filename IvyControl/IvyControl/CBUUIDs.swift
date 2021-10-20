//
//  CBUUIDs.swift
//  IvyControl
//
//  Created by RRRRR on 2021/10/20.
//  Copyright © 2021 iGEM Whittle. All rights reserved.
//

import Foundation
import CoreBluetooth

struct CBUUIDs {

    static let serviceString = "Please replace this with the service UUID of your bluetooth module"
    static let characteristicString = "Please replace this with the read & write characteristic UUID of your bluetooth module"

    static let serviceUUID = CBUUID(string: serviceString)
    static let characterisitcUUID = CBUUID(string: characteristicString)
}

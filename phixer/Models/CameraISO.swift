//
//  CameraISO.swift
//  phixer
//
//  Created by Philip Price on 9/26/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation

// enum type defining the different ISO values allowed

enum CameraISO: Float {
    
    case iso_auto = 0.0
    case iso_100  = 100.0
    case iso_200  = 200.0
    case iso_400  = 400.0
    case iso_800  = 800.0
    case iso_1600 = 1600.0
    case iso_3200 = 3200.0
    
    func getIconName() -> String{
        switch self {
        case .iso_auto:
            return "ic_iso_auto.png"
        case .iso_100:
            return "ic_iso_100.png"
        case .iso_200:
            return "ic_iso_200.png"
        case .iso_400:
            return "ic_iso_400.png"
        case .iso_800:
            return "ic_iso_800.png"
        case .iso_1600:
            return "ic_iso_1600.png"
        case .iso_3200:
            return "ic_iso_3200.png"
        }
    }
}

//
//  GridStyle.swift
//  FilterCam
//
//  Created by Philip Price on 9/26/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

// enum type defining the different types of grid overlay

enum GridStyle {
    case none
    case thirds
    case center
    case golden
    
    func getIconName() -> String{
        switch self {
        case .none:
            return "ic_grid_none.png"
        case .thirds:
            return "ic_grid_thirds.png"
        case .center:
            return "ic_grid_center.png"
        case .golden:
            return "ic_grid_golden.png"
        }
    }
}

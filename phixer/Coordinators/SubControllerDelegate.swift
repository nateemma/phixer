//
//  SubControllerDelegate.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation


// SubController interface available to Coordinators, in addition to the regular ControllerDelegate interfaces

protocol SubControllerDelegate: class {
    
    // move on to the next thing in the list, if any
    func nextItem()
    
    // move to the previous thing on the list
    func previousItem()
    
}

//
//  ControllerDelegate.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation


// Controller interface available to Coordinators

protocol ControllerDelegate: class {
    
    // start processing
    func start()
    
    // notification to prepare to end processing
    func end()

    // notifies  controller that a filter has been selected. 
    func selectFilter (key: String)
    
    // notifies the controller that an update is required
    func updateDisplays()
    
    // informs the controller that the theme has changed
    func updateTheme()
    
    // asks the controller to handle the menu request.
    func handleMenu()
}

//
//  CoordinatorDelegate.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation


// Coordinator interface available to View Controllers

protocol CoordinatorDelegate: class {
    
    // start processing
    func start(completion: @escaping ()->())
    
    // notifies active controller that a filter has been selected
    func selectFilter (key: String)
    
    // returns the 'next' filter, which can vary based on what is currently active
    func nextFilter() -> String
    
    // returns the 'previous' filter, which can vary based on what is currently active
    func previousFilter()  -> String
    
    // requests the active controller to update the UI
    func requestUpdate (tag: String)
    
    // notifies the previous controller that the current controller has ended
    func notifyCompletion (tag: String)
    
    // requests activation of controller (using the known list of controllers)
    func activate (_ controller: ControllerIdentifier)
    
    // // request to hide any subcontrollers that are active
    func hideSubcontrollers()
    
    // // request to show any subcontrollers that are active
    func showSubcontrollers()
    
    // request navigation back to the previous coordinator (or root)
    func back()
    
    // activate help function for current state (typically not known by the controller if there are sub-controllers active)
    func help()
}

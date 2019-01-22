//
//  CoordinatorDelegate.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation


// Coordinator interface available to View Controllers (or other Coordinators)

// Note: Request implies the coordinator is being asked to do something, Notification implies it is being informed about something.
//       It's also a way to avoid naming clashes with teh opposite interface (Coordinator->Controller)

protocol CoordinatorDelegate: class {
    
    // sets the coordinator parent
    func setCoordinator(_ coordinator:Coordinator)
    
    // start processing
    func startRequest(completion: @escaping ()->())
    
    // notification to prepare to end processing. Coordinator will wait for the endNotification
    func endRequest()
    
    
    // notifies the coordinator that a controller or coordinator has ended, and request the activation of another coordinator (set to .none if not needed)
    func completionNotification (id: ControllerIdentifier, activate: ControllerIdentifier)
    
    // requests activation of controller (using the known list of controllers)
    func activateRequest (id: ControllerIdentifier)

    // notifies active controller that a filter has been selected. 
    func selectFilterNotification (key: String)
    
    // move to the next item, whatever that is (can be nothing)
    func nextItemRequest()
    
    // move to the previous item, whatever that is (can be nothing)
    func previousItemRequest()
    
    // requests the active controller to update the UI
    func updateRequest (id: ControllerIdentifier)
    
    // // request to hide any subcontrollers that are active
    func hideSubcontrollersRequest()
    
    // // request to show any subcontrollers that are active
    func showSubcontrollersRequest()
    
    // activate help function for current state (typically not known by the controller if there are sub-controllers active)
    func helpRequest()
    
    // lets the coordinator know that the theme has been updated
    func themeUpdatedNotification()
}

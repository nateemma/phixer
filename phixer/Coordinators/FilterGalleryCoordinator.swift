//
//  BrowseFiltersCoordinator.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import GoogleMobileAds

// Coordinator for the Browse Filter Gallery (standalone) functionality

class BrowseFiltersCoordinator: Coordinator {
   
    
    /////////////////////////////
    // MARK:  Delegate Functions
    /////////////////////////////
    

    override func selectFilterNotification (key: String) {
        // filter selected, display it
        log.debug("key: \(key)")
        self.activateRequest(id: ControllerIdentifier.displayFilter)
        //self.activateRequest(id: ControllerIdentifier.edit)
    }

    
    
    /////////////////////////////
    // MARK:  Delegate Functions
    /////////////////////////////
    
    override func startRequest(completion: @escaping ()->()){
        // Logging nicety, show that controller has changed:
        print ("\n========== \(self.getTag()) ==========\n")

        
        // reset controller/coordinator vars
        self.completionHandler = completion
        self.subCoordinators = [:]
        self.mainController = nil
        self.subControllers = [:]
        
        self.mainControllerId = .filterGallery
        self.validControllers = [.filterGallery, .displayFilter, .edit, .help]

        // no (main) mappings for coordinators
        // Note that we deliberately do not allow the edit subcontrollers here because we only want them to run in 'full' edit mode
        self.coordinatorMap = [:]
        self.coordinatorMap [ControllerIdentifier.edit] = CoordinatorIdentifier.edit
        self.coordinatorMap [ControllerIdentifier.displayFilter] = CoordinatorIdentifier.filterDisplay
        self.coordinatorMap [ControllerIdentifier.help] = CoordinatorIdentifier.help

        // start the main controller
        self.activateRequest(id: self.mainControllerId)

        
    }
 
}

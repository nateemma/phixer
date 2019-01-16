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
        //Coordinator.filterManager?.setCurrentFilterKey(key)
        self.activateRequest(id: ControllerIdentifier.displayFilter)
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
        self.validControllers = [.filterGallery, .displayFilter]

        // no (main) mappings for coordinators
        //self.coordinatorMap = [:]
        self.coordinatorMap [ControllerIdentifier.displayFilter] = CoordinatorIdentifier.filterDisplay

        // start the main controller
        self.activateRequest(id: self.mainControllerId)

        
    }
 
}

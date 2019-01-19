//
//  BrowseStyleTransferCoordinator.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import GoogleMobileAds

// Coordinator for the Style Transfer Gallery (standalone) functionality

class BrowseStyleTransferCoordinator: Coordinator {
   
    
    /////////////////////////////
    // MARK:  Delegate Functions
    /////////////////////////////
 

    override func selectFilterNotification (key: String) {
        // filter selected, display it
        log.debug("key: \(key)")
        //Coordinator.filterManager?.setCurrentFilterKey(key)
        self.activateRequest(id: ControllerIdentifier.displayFilter)
   }

 
    
    override func startRequest(completion: @escaping ()->()){
        // Logging nicety, show that controller has changed:
        print ("\n========== \(self.getTag()) ==========\n")

        
        // reset controller/coordinator vars
        self.completionHandler = completion
        self.subCoordinators = [:]
        self.mainController = nil
        self.subControllers = [:]
        
        self.mainControllerId = .styleGallery
        self.validControllers = [.styleGallery, .displayFilter, .help]

        // mappings for coordinators
        self.coordinatorMap = [:]
        self.coordinatorMap [ControllerIdentifier.displayFilter] = CoordinatorIdentifier.filterDisplay
        self.coordinatorMap [ControllerIdentifier.help] = CoordinatorIdentifier.help

        // start the main controller
        self.activateRequest(id: self.mainControllerId)

    }
 
}

//
//  FilterGalleryCoordinator.swift
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

class FilterGalleryCoordinator: Coordinator {
   
    
    /////////////////////////////
    // MARK:  Delegate Functions
    /////////////////////////////
    
    override func selectFilter(key: String) {
        // filter selected, display it
        Coordinator.filterManager?.setCurrentFilterKey(key)
        self.activate(.displayFilter)
    }
    
    
    
    /////////////////////////////
    // MARK:  Delegate Functions
    /////////////////////////////
    
    override func start(completion: @escaping ()->()){
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
        self.coordinatorMap = [:] 
        
        // start the main controller
        self.activate (self.mainControllerId)

        
    }
 
}

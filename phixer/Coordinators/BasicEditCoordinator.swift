//
//  BasicEditCoordinator.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import GoogleMobileAds

// Coordinator for the Basic Edit functionality

class BasicEditCoordinator: Coordinator {
   
    
    /////////////////////////////
    // MARK:  Delegate Functions
    /////////////////////////////
    
    override func selectFilter(key: String) {
        // filter selected, so update the edit display
        Coordinator.filterManager?.setCurrentFilterKey(key)
        self.mainController?.requestUpdate(tag: self.getTag())
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
        
        self.mainControllerId = .edit
        self.validControllers = [.edit, .filterGallery, .styleGallery, .editMainMenu, .editBasicAdjustmentsMenu, .curveTool]

        // no (main) mappings for coordinators
        self.coordinatorMap = [:] 
        
        // start the Edit Controller and the Main Menu
        self.activate (.edit)
        self.activate (.editMainMenu)

    }
    
}

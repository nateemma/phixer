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
    
    // move to the next item, whatever that is (can be nothing)
    override func nextItemRequest() {
        
        // get next filter and send it to the main controller
        let key = Coordinator.filterManager?.getNextFilterKey()
        self.mainController?.selectFilter(key: key!)
    }
    
    
    
    // move to the previous item, whatever that is (can be nothing)
    override func previousItemRequest() {
        
        // get prev filter and send it to the main controller
        let key = Coordinator.filterManager?.getPreviousFilterKey()
        self.mainController?.selectFilter(key: key!)
    }

    override func selectFilterNotification (key: String) {
        // filter selected, display it. e want this to go back to the edit controller, not launch a separate viewer (as is done for the gallery scenes)
        log.debug("key: \(key)")
        self.mainController?.selectFilter(key: key)
    }

    
    override func startRequest(completion: @escaping ()->()){
        // Logging nicety, show that controller has changed:
        print ("\n========== \(self.getTag()) ==========\n")

        
        // reset controller/coordinator vars
        self.completionHandler = completion
        self.subCoordinators = [:]
        self.mainController = nil
        self.subControllers = [:]
        
        self.mainControllerId = .edit
        self.validControllers = [.edit, .help, .filterGallery, .styleGallery, .blendGallery,  .editMainMenu, .editBasicAdjustmentsMenu,
                                 .curveTool, .hsvTool, .editDetailMenu, .cropTool, .editFacesMenu]

        //  mappings for coordinators
        self.coordinatorMap = [:]
        self.coordinatorMap [ControllerIdentifier.help] = CoordinatorIdentifier.help
        self.coordinatorMap [ControllerIdentifier.filterGallery] = CoordinatorIdentifier.filterGallery
        self.coordinatorMap [ControllerIdentifier.styleGallery] = CoordinatorIdentifier.styleGallery
        self.coordinatorMap [ControllerIdentifier.blendGallery] = CoordinatorIdentifier.blendGallery

        // start the Edit Controller and the Main Menu
        self.activateRequest(id: .edit)
        self.activateRequest(id: .editMainMenu)

    }
    
}

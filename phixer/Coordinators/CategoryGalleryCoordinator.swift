//
//  CategoryGalleryCoordinator.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import GoogleMobileAds

// class that implements the coordination for a Category Gallery browser

class CategoryGalleryCoordinator: Coordinator {
    
    
    
    /////////////////////////////
    // MARK:  Delegate Functions
    /////////////////////////////
    
    
    override func startRequest(completion: @escaping ()->()){
        
        
        // Logging nicety, show that controller has changed:
        print ("\n========== \(String(describing: type(of: self))) ==========\n")
        
        
        // reset controller/coordinator vars
        self.completionHandler = completion
        self.subCoordinators = [:]
        self.mainController = nil
        self.subControllers = [:]

        // reset for this coordinator
        self.mainControllerId = .categoryGallery
        
        // define the list of valid Controllers
        self.validControllers = [ .categoryGallery, .edit, .browseFilters, .help  ]
        
        // map controllers to their associated coordinators
        self.coordinatorMap = [:]
        self.coordinatorMap [ControllerIdentifier.edit] = CoordinatorIdentifier.edit
        self.coordinatorMap [ControllerIdentifier.browseFilters] = CoordinatorIdentifier.browseFilters
        self.coordinatorMap [ControllerIdentifier.help] = CoordinatorIdentifier.help

        
        // start the main controller
        self.activateRequest(id: self.mainControllerId)
    }
    
}

//
//  BlendImagesCoordinator.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import GoogleMobileAds

// class that implements the coordination for the Blend Images functionality

class BlendImagesCoordinator: Coordinator {
    
    
    
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
        self.mainControllerId = .blendImages
        
        // define the list of valid Controllers
        self.validControllers = [ .blendImages, .help ]
        
        // map controllers to their associated coordinators
        self.coordinatorMap = [:]
        self.coordinatorMap [ControllerIdentifier.help] = CoordinatorIdentifier.help

        
        // start the main controller
        self.activateRequest(id: self.mainControllerId)
    }
    
}

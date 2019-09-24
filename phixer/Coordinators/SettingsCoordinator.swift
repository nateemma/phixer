//
//  SettingsCoordinator.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit

// Coordinator for the Settings functionality

class SettingsCoordinator: Coordinator {
   
    
    /////////////////////////////
    // MARK:  Delegate Functions
    /////////////////////////////
    
    // use defaults
    
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
        
        self.mainControllerId = .settings
        self.validControllers = [.settings, .about, .reset, .blendGallery, .themeChooser, .help ]

        self.coordinatorMap = [:]
        self.coordinatorMap [ControllerIdentifier.blendGallery] = CoordinatorIdentifier.blendGallery
        self.coordinatorMap [ControllerIdentifier.themeChooser] = CoordinatorIdentifier.themeChooser
        self.coordinatorMap [ControllerIdentifier.reset] = CoordinatorIdentifier.reset
        self.coordinatorMap [ControllerIdentifier.about] = CoordinatorIdentifier.about
        self.coordinatorMap [ControllerIdentifier.help] = CoordinatorIdentifier.help

        // start the main controller
        self.activateRequest(id: self.mainControllerId)

        
    }
 
}

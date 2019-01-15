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
    
    override func start(completion: @escaping ()->()){
        // Logging nicety, show that controller has changed:
        print ("\n========== \(self.getTag()) ==========\n")

        
        // reset controller/coordinator vars
        self.completionHandler = completion
        self.subCoordinators = [:]
        self.mainController = nil
        self.subControllers = [:]
        
        self.mainControllerId = .settings
        self.validControllers = [.settings, .about, .reset, .sampleGallery, .blendGallery, .themeChooser, .colorScheme]

        // no (main) mappings for coordinators
        self.coordinatorMap = [:] 
        
        // start the main controller
        self.activate (self.mainControllerId)

        
    }
 
}

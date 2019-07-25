//
//  SplashScreenCoordinator.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation

// Coordinator for the initial Splash screen

class SplashScreenCoordinator: Coordinator {
   
    

    
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
        
        self.mainControllerId = .splashScreen
        self.validControllers = [.splashScreen, .choosePhoto ]
        
        self.coordinatorMap = [:]
        self.coordinatorMap [ControllerIdentifier.splashScreen] = CoordinatorIdentifier.splashScreen
        self.coordinatorMap [ControllerIdentifier.choosePhoto] = CoordinatorIdentifier.choosePhoto
        
        // start the main controller
        self.activateRequest(id: self.mainControllerId)
        
        
    }

}

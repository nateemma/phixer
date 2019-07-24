//
//  ChoosePhotoCoordinator.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import GoogleMobileAds

// Coordinator for the Choose Photo screen

class ChoosePhotoCoordinator: Coordinator {
   
    

    
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
        
        self.mainControllerId = .choosePhoto
        self.validControllers = [.choosePhoto, .mainMenu, .help ]
        
        self.coordinatorMap = [:]
        self.coordinatorMap [ControllerIdentifier.mainMenu] = CoordinatorIdentifier.mainMenu
        self.coordinatorMap [ControllerIdentifier.help] = CoordinatorIdentifier.help
        
        // start the main controller
        self.activateRequest(id: self.mainControllerId)
        
        
    }

}

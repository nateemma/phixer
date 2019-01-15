//
//  CoordinatorFactory.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit


// the list of Coordinators that can be requested

enum CoordinatorIdentifier: String {
    
    case edit
    case styleTransfer
    case browse
    case settings
    
    // TODO: add coordinators for next levels
 }



// Factory class to create instances of the requested Coordinator

class CoordinatorFactory {
    
    private init(){} // prevent instantiation
    
    
    public static func getCoordinator(_ coordinator: CoordinatorIdentifier) -> Coordinator? {
        
        var instance:Coordinator? = nil
        switch (coordinator){
        case .edit:
            instance = BasicEditCoordinator()
            
        case .styleTransfer:
            instance = StyleTransferGalleryCoordinator()
            
        case .browse:
            instance = FilterGalleryCoordinator()
            
        case .settings:
            instance = SettingsCoordinator()
            
        default:
            log.error("Invalid coordinator: \(coordinator.rawValue)")
            instance = nil
        }
        
        return instance
        
    }
}

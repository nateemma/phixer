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
    
    case none
    
    case edit
    case browseStyleTransfer
    case browseFilters
    case settings
    
    case filterDisplay
    case filterGallery
    case styleGallery

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
            
        case .browseStyleTransfer:
            instance = BrowseStyleTransferCoordinator()
            
        case .browseFilters:
            instance = BrowseFiltersCoordinator()
            
        case .settings:
            instance = SettingsCoordinator()
            
        case .filterDisplay:
            let sc = SimpleCoordinator()
            sc.setMainController (ControllerIdentifier.displayFilter)
            instance = sc
            
        case .filterGallery:
            let sc = SimpleCoordinator()
            sc.setMainController (ControllerIdentifier.filterGallery)
            instance = sc
            
        case .styleGallery:
            let sc = SimpleCoordinator()
            sc.setMainController (ControllerIdentifier.styleGallery)
            instance = sc

        default:
            log.error("Invalid coordinator: \(coordinator.rawValue)")
            instance = nil
        }
        
        if instance != nil {
            log.debug("Created Coordinator: \(coordinator.rawValue)")
            instance?.id = coordinator
        }
        return instance
        
    }
}

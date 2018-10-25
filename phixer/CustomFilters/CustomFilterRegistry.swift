//
//  CustomFilterRegistry.swift
//  Class that encapsulates registration of custom filters and their creation
// You must add all custom filters here so that they can be created
//
//  Created by Philip Price on 10/24/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

class CustomFiltersRegistry: NSObject, CIFilterConstructor {
    
    private static var initDone:Bool = false
    static let instance = CustomFiltersRegistry()
    
    private override init(){
        super.init()
    }

    
    // this function registers all of the custom filters with the CIFilter framework
    static func registerFilters()  {
        if !initDone {
            initDone = true
            log.debug("Registering Custom Filters")
            CIFilter.registerName("OpacityFilter", constructor: instance, classAttributes: [kCIAttributeFilterCategories: ["CustomFilters"]])
            CIFilter.registerName("EdgeGlowFilter", constructor: instance, classAttributes: [kCIAttributeFilterCategories: ["CustomFilters"]])
        }
    }
    
    
    // this function is called by the CIFilter framework when a custom filter is created
    func filter(withName name: String) -> CIFilter? {
        switch name {
        case "OpacityFilter":
            return OpacityFilter()
        case "EdgeGlowFilter":
            return EdgeGlowFilter()
        default:
            return nil
        }
    }
}

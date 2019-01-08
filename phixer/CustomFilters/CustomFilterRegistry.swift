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
    private static let instance = CustomFiltersRegistry()
    
    private static var filterCache:[String:CIFilter?] = [:]
    
    private override init(){
        super.init()
    }

    // any filters that use multiple pixels need to be in this list:
    private static let filterList:[String] = ["OpacityFilter", "EdgeGlowFilter", "ClarityFilter", "SaturationFilter", "BrightnessFilter", "ContrastFilter",
                                              "WhiteBalanceFilter",
                                              "ColorSobelFilter", "SobelFilter", "Sobel3x3Filter", "Sobel5x5Filter", "LaplacianGaussianFilter",
                                              "SketchFilter", "ColorSketchFilter",
                                              "Style_Scream", "Style_Candy", "Style_Mosaic", "Style_Udnie", "Style_LaMuse", "Style_Feathers" ]
    
    // any filters that do not need to access any more than 1 pixel can go here:
    private static let colorFilters:[String] = ["SmoothThresholdFilter", "AdaptiveThresholdFilter", "LumaRangeFilter", "DehazeFilter"]
    
    
    // this function registers all of the custom filters with the CIFilter framework
    static func registerFilters()  {
        if !CustomFiltersRegistry.initDone {
            CustomFiltersRegistry.initDone = true
            log.debug("Registering Custom Filters")
            
            CustomFiltersRegistry.filterCache = [:]
            
            for f in CustomFiltersRegistry.filterList {
                CIFilter.registerName(f, constructor: instance, classAttributes: [kCIAttributeFilterCategories: ["CustomFilters"]])
            }
            
            for cf in CustomFiltersRegistry.colorFilters {
                CIFilter.registerName(cf, constructor: instance,
                                      classAttributes: [kCIAttributeFilterCategories: [kCICategoryColorAdjustment, kCICategoryVideo,
                                                                                       kCICategoryStillImage, kCICategoryInterlaced,
                                                                                       kCICategoryNonSquarePixels]])
            }
        }
    }
    
    
    // this function is called by the CIFilter framework when a custom filter is created
    func filter(withName name: String) -> CIFilter? {
        
        var filterInstance:CIFilter? = nil
        
        // check cache to see if the filter has already been created
        if CustomFiltersRegistry.filterCache[name] != nil {
            filterInstance = CustomFiltersRegistry.filterCache[name]!
        } else {
            log.verbose("Creating custom filter:\(name)")

            // not in cache, create an instance from the classname
            let ns = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
            let className = ns + "." + name
            let theClass = NSClassFromString(className) as? CIFilter.Type
            filterInstance = theClass?.init() // NOTE: this only works because we know that the protocol requires the init() func
            
            if (filterInstance == nil){
                log.error ("ERR: Could not create class: \(name)")
            } else {
                CustomFiltersRegistry.filterCache[name] = filterInstance
            }
        }
        return filterInstance
    }
    
}

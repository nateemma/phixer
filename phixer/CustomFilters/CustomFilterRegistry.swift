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

    private static let filterList:[String] = ["OpacityFilter", "EdgeGlowFilter", "ClarityFilter", "SaturationFilter", "BrightnessFilter", "ContrastFilter",
                                              "WhiteBalanceFilter",
                                              "ColorSobelFilter", "SobelFilter", "Sobel3x3Filter", "Sobel5x5Filter", "LaplacianGaussianFilter",
                                              "SketchFilter", "ColorSketchFilter",
                                              "Style_Scream", "Style_Candy", "Style_Mosaic", "Style_Udnie", "Style_LaMuse", "Style_Feathers" ]
    
    private static let colorFilters:[String] = ["SmoothThresholdFilter", "AdaptiveThresholdFilter", "LumaRangeFilter", "DehazeFilter"]
    
    // this function registers all of the custom filters with the CIFilter framework
    static func registerFilters()  {
        if !initDone {
            initDone = true
            log.debug("Registering Custom Filters")
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
        //TODO: create class dynamicaly based on the name?
        log.verbose("Creating custom filter:\(name)")
/*** Manual way:
        switch name {
        case "SaturationFilter":           return ContrastFilter()
        case "BrightnessFilter":           return ContrastFilter()
        case "ContrastFilter":           return ContrastFilter()
        case "ClarityFilter":           return ClarityFilter()
        case "OpacityFilter":           return OpacityFilter()
        case "EdgeGlowFilter":          return EdgeGlowFilter()
        case "LumaRangeFilter":         return LumaRangeFilter()
        case "AdaptiveThresholdFilter": return AdaptiveThresholdFilter()
        case "SmoothThresholdFilter":   return SmoothThresholdFilter()
        case "Style_Scream":            return Style_Scream()
        case "Style_Candy":             return Style_Candy()
        case "Style_Mosaic":            return Style_Mosaic()
        case "Style_Udnie":             return Style_Udnie()
        case "Style_LaMuse":            return Style_LaMuse()
        case "Style_Feathers":          return Style_Feathers()
            
        default:
            log.warning("Filter not registered: \(name)")
            return nil
        }
         ***/
        
        // create an instance from the classname
        let ns = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
        let className = ns + "." + name
        let theClass = NSClassFromString(className) as? CIFilter.Type
        let filterInstance = theClass?.init() // NOTE: this only works because we know that the protocol requires the init() func
        
        if (filterInstance == nil){
            log.error ("ERR: Could not create class: \(name)")
        }
        
        return filterInstance
    }
    
}

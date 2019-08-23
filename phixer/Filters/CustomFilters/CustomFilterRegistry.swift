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

class CustomFilterRegistry: NSObject, CIFilterConstructor {
    
    public static let  customFilterCategory = "CustomFilters"
    private static var initDone:Bool = false
    private static let instance = CustomFilterRegistry()
    
    private static var filterCache:[String:CIFilter?] = [:]
    
    private override init(){
        super.init()
    }

    // any filters that use multiple pixels need to be in this list:
    private static let filterList:[String] = ["OpacityFilter", "EdgeGlowFilter", "ClarityFilter", "SaturationFilter", "BrightnessFilter", "ContrastFilter",
                                              "WhiteBalanceFilter",
                                              "ColorSobelFilter", "SobelFilter", "Sobel3x3Filter", "Sobel5x5Filter", "LaplacianGaussianFilter",
                                              "SketchFilter", "ColorSketchFilter",
                                              "Style_Scream", "Style_Candy", "Style_Mosaic", "Style_Udnie", "Style_LaMuse", "Style_Feathers",
                                              "CarnivalMirror", "KuwaharaFilter", "MercurializeFilter",
                                              "CRTFilter", 
                                               "ColorDirectedBlur", "HomogeneousColorBlur", "VHSTrackingLines",  "TransverseChromaticAberration" ,
                                              "RGBChannelCompositing", "RGBChannelToneCurve", "RGBChannelBrightnessAndContrast", "ChromaticAberration", "RGBChannelGaussianBlur",
                                              "HighPassSharpeningFilter", "CropRotateFilter", "AutoAdjustFilter", "SplitToningFilter",
                                              "PresetFilter", "VoronoiNoise", "GrainFilter", "BWZoneFilter"
                                             ]
    
    // any filters that do not need to access any more than 1 pixel can go here:
    private static let colorFilters:[String] = ["SmoothThresholdFilter", "AdaptiveThresholdFilter", "LumaRangeFilter", "DehazeFilter", "UnsharpMaskFilter",
                                                "MultiBandHSV", 
                                                "CausticNoise", "CausticRefraction",
                                                "CMYKToneCurves", "CMYKLevels", "CMYKRegistrationMismatch",
                                                "CompoundEye", "EightBit", "HighPassFilter", "HighPassSkinSmoothingFilter", "CLAHEFilter",
                                                "HueRangeFilter", "MaskedSkinSmoothingFilter",
                                                "EnhanceLipsFilter", "EnhanceEyesFilter", "EnhanceEyebrowsFilter", "EnhanceTeethFilter", "EnhanceFaceFilter",
                                                "ForegroundMaskFilter", "BackgroundBlurFilter", "ForegroundLightingFilter"
                                                ]
    
    
    // this function registers all of the custom filters with the CIFilter framework
    public static func registerFilters()  {
        if !CustomFilterRegistry.initDone {
            CustomFilterRegistry.initDone = true
            log.debug("Registering Custom Filters")
            
            CustomFilterRegistry.filterCache = [:]
            
            for f in CustomFilterRegistry.filterList {
                CIFilter.registerName(f, constructor: instance, classAttributes: [kCIAttributeFilterCategories: [CustomFilterRegistry.customFilterCategory]])
            }
            
            for cf in CustomFilterRegistry.colorFilters {
                CIFilter.registerName(cf, constructor: instance,
                                      classAttributes: [kCIAttributeFilterCategories: [CustomFilterRegistry.customFilterCategory,
                                                                                       kCICategoryColorAdjustment, kCICategoryVideo,
                                                                                       kCICategoryStillImage, kCICategoryInterlaced,
                                                                                       kCICategoryNonSquarePixels]])
            }
        }
    }
    
    
    // this function is called by the CIFilter framework when a custom filter is created
    public func filter(withName name: String) -> CIFilter? {
        
        var filterInstance:CIFilter? = nil
        
        // check cache to see if the filter has already been created (but only if on main thread)
        if (CustomFilterRegistry.filterCache[name] != nil) && Thread.current.isMainThread {
            filterInstance = CustomFilterRegistry.filterCache[name]!
        } else {
            //log.verbose("Creating custom filter:\(name)")
            
            // not in cache, create an instance from the classname
            let ns = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
            let className = ns + "." + name
            let theClass = NSClassFromString(className) as? CIFilter.Type
            filterInstance = theClass?.init() // NOTE: this only works because we know that the protocol requires the init() func
            
            if (filterInstance == nil){
                log.error ("ERR: Could not create class: \(name)")
            } else {
                if Thread.current.isMainThread {
                    CustomFilterRegistry.filterCache[name] = filterInstance
                }
            }
        }
        return filterInstance
    }
    
    public static func clearCache(){
        CustomFilterRegistry.filterCache = [:]
    }
    
    //////////////////////////////
    // MARK: Utilities
    //////////////////////////////
    
    // debug function to print the 'specs' of all available filters
    
    public static func listFilters(){
        print("--- Available CIFilters and their parameters ---")

        // this is the list of CIFilter categories
        // Note that custom filters defined in this framework will be in the "CustomFilters" or kCICategoryColorAdjustment category
        let categories:[String] = [ "CICategoryBlur", "CICategoryColorEffect", "CICategoryCompositeOperation",
                                    "CICategoryDistortionEffect", "CICategoryGeometryAdjustment", "CICategoryGradient",
                                    "CICategoryHalftoneEffect", "CICategoryReduction", "CICategorySharpen", "CICategoryStylize", "CICategoryTileEffect",
                                    "CustomFilters", kCICategoryColorAdjustment
        ]
        
        for c in categories {
            print ("Category = \(c):")
            for f in CIFilter.filterNames(inCategories: [c]) {
                //describeFilter(f)
                let def = makeFilterDefinition(f)
                if def != nil {
                    print ("Found filter: key:\((def?.key)!) title:\((def?.title)!) ftype:\((def?.ftype)!)")
                    //FilterConfiguration.addFilter(key:(def?.key)!, definition:def!)
                }
            }
            print ("----------------")
        }
        print ("----------------------------------------------")
    }
    
    // print out the definition of the filter in JSON Form
    static func describeFilter(_ name:String){
        if let filter = CIFilter(name: name){
            
            let inputNames = (filter.inputKeys as [String]).filter { (parameterName) -> Bool in
                return (parameterName as String) != "inputImage"
            }
            
            let attributes = filter.attributes
            
            var title:String = ""
            var aname:String, atype: String
            var amin:Float, amax:Float, aval:Float
            
            // Print filter top-level attributes
            //print ("Filter: \(f)")
            title = attributes[kCIAttributeFilterDisplayName]  as! String
            print ("{\"key\": \"\(name)\", \"title\": \"\(String(describing: title))\", \"ftype\": \"singleInput\", ")
            
            print ("  \"parameters\": { [")
            // print attributes for each input parameter
            let nump = inputNames.count
            if nump > 0 {
                for i in 0...(nump-1) {
                    let inp = inputNames[i]
                    let a = attributes[inp] as! [String : AnyObject]
                    if let tmp = a[kCIAttributeDisplayName] { aname = tmp as! String } else { aname = "???" }
                    if let tmp = a[kCIAttributeSliderMin]   { amin = toFloat(tmp) } else { amin = 0.0 }
                    if let tmp = a[kCIAttributeSliderMax]   { amax = toFloat(tmp) } else { amax = 0.0 }
                    if let tmp = a[kCIAttributeDefault]     { aval = toFloat(tmp) } else { aval = 0.0 }
                    if let tmp = a[kCIAttributeType]        { atype = tmp as! String
                    } else {
                        if let tmp = a[kCIAttributeClass]   { atype = tmp as! String } else { atype = "???" }
                    }
                    
                    if i < (nump-1) {
                        print("    {\"key\": \"\(inp)\", \"title\": \"\(aname)\", \"min\": \(amin), \"max\":\(amax), \"val\": \(aval), \"type\": \"\(atype)\"},")
                    } else {
                        print("    {\"key\": \"\(inp)\", \"title\": \"\(aname)\", \"min\": \(amin), \"max\":\(amax), \"val\": \(aval), \"type\": \"\(atype)\"}")
                    }
                }
            }
            print("  ]}")
            print("},")
        }
    }
    
    
    // convert the definition of the filter into FilterDescriptor form
    static func makeFilterDefinition(_ name:String) -> FilterDefinition? {
        var def:FilterDefinition? = nil
        
        if let filter = CIFilter(name: name){
            
            def = FilterDefinition()
            
            let inputNames = (filter.inputKeys as [String]).filter { (parameterName) -> Bool in
                return (parameterName as String) != "inputImage" // everything has inputImage so don't return that
            }
            
            let attributes = filter.attributes
            
            
            // filter top-level attributes
            def?.key = name
            def?.title = attributes[kCIAttributeFilterDisplayName]  as! String
            def?.ftype = FilterOperationType.singleInput.rawValue
            def?.hide = false
            def?.rating = 0
            def?.lookup = ""
            def?.slow = false
            def?.parameters = []

            // process attributes for each input parameter
            var aname:String
            var atype:String
            var amin:Float=0.0, amax:Float=0.0, aval:Float=0.0

            let nump = inputNames.count
            if nump > 0 {
                for i in 0...(nump-1) {
                    let inp = inputNames[i]
                    let a = attributes[inp] as! [String : AnyObject]
                    if let tmp = a[kCIAttributeDisplayName] { aname = tmp as! String } else { aname = "???" }
                    if let tmp = a[kCIAttributeSliderMin]   { amin = toFloat(tmp) } else { amin = 0.0 }
                    if let tmp = a[kCIAttributeSliderMax]   { amax = toFloat(tmp) } else { amax = 0.0 }
                    if let tmp = a[kCIAttributeDefault]     { aval = toFloat(tmp) } else { aval = 0.0 }
                    if let tmp = a[kCIAttributeType]        { atype = tmp as! String
                    } else {
                        if let tmp = a[kCIAttributeClass]   { atype = tmp as! String } else { atype = "???" }
                    }
                    let p = ParameterSettings(key: inp, title: aname, min: amin, max: amax, value: aval, type: FilterConfiguration.attributeToParameterType(atype))
                    def?.parameters.append(p)
                    
                    // If we find a background image parameter, then change filter type to blend
                    if inp == kCIInputBackgroundImageKey {
                        def?.ftype = FilterOperationType.blend.rawValue
                    }
                }
            }
        }
        return def
    }
    

    
    static func toFloat(_ obj:AnyObject)->Float{
        
        let str:String = String(format: "%@", obj as! CVarArg)
        let fval = Float(str) ?? 0.0
        return fval
    }

/*** use version in FilterConfiguration to avoid mismatches
    // converts from CIFilter Attribute Type to internal ParameterType
    static func toParameterType(_ atype:String)->ParameterType{
        
        var ptype:ParameterType = .unknown
        switch (atype){
        case kCIAttributeTypeTime:
            ptype = .float
        case kCIAttributeTypeScalar:
            ptype = .float
        case kCIAttributeTypeDistance:
            ptype = .distance
        case kCIAttributeTypeAngle:
            ptype = .float
        case kCIAttributeTypeBoolean:
            ptype = .float
        case kCIAttributeTypeInteger:
            ptype = .float
        case kCIAttributeTypeCount:
            ptype = .float
        case kCIAttributeTypeOffset:
            ptype = .float
        case kCIAttributeTypeColor:
            ptype = .color
        case kCIAttributeTypeImage:
            ptype = .image
        case kCIAttributeTypePosition:
            ptype = .position
        case kCIAttributeTypeRectangle:
            //ptype = .rectangle
            ptype = .vector
        default:
            // anything else is too difficult to handle automatically
            // anything that needs to use such filters will need to understand these types anyway (vectors, curves, masks etc.)
            ptype = .unknown
        }
        return ptype
    }
***/

}

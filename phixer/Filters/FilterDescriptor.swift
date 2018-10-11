//
//  FilterDescriptor.swift
//  phixer
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// Class that encapsulates an underlying filter
// Intended to form the 'bridge' between UI functionality and Filter Operations


// settings for each filter parameter.
// 'isRGB' indicates to use an RGB/HSB color gradient slider (i.e. to choose a color)
// the 'key' parameter is the name used to identify the parameter to the underlying Filter (CIFilter at this moment)




class  FilterDescriptor {
  
     // constant used to indicate that a parameter has not (yet) been set, or doesn't exist
    public static let parameterNotSet:Float = -1000.00
    
    // name of CIFilter used to create Lookup filters
    //private static let lookupFilterName:String = "CIColorMap"
    private static let lookupFilterName:String = "YUCIColorLookup"
    private static let lookupArgImage:String = "inputColorLookupTable"
    private static let lookupArgIntensity:String = "inputIntensity"
    
    // the type of the parameter
    public enum ParameterType {
        case float
        case color
        case image
        case vector2
        case vector3
        case vector4
        case unknown
    }
    
    // set of parameters that are used to set up a filter
    //public typealias ParameterSettings = (key:String, title:String, min:Float, max:Float, value:Float, type:ParameterType)
    public struct ParameterSettings {
        var key:String
        var title:String
        var min:Float
        var max:Float
        var value:Float
        var type:ParameterType
        
        init(key:String, title:String, min:Float, max:Float, value:Float, type:ParameterType){
            self.key = key
            self.title = title
            self.min = min
            self.max = max
            self.value = value
            self.type = type
        }
    }
    
    
    // identifies the general type of filter, so that an app can configure it properly (e.g. with 2 images instead of 1)
    // Note: declared as String so that you can convert a String (str) to an enum by ftype = FilterOperationType(rawValue:str)
    public enum FilterOperationType: String {
        case singleInput
        case blend
        case lookup
    }
    

    // Accessible vars (read-only)
    public private(set) var key: String
    public private(set) var title: String
    public private(set) var filterOperationType: FilterOperationType
    public private(set) var numParameters: Int
    //these are get/set because they are often changed
    public var show: Bool
    public var rating: Int
    
    // private vars
    private var parameterConfiguration: [String:ParameterSettings] // dictionary of parameter settings
    private var stashedParameters: [String:ParameterSettings]
    
    private var filter: CIFilter? = nil
    private var lookupImageName:String = ""
    private var lookupImage:CIImage? = nil
    
    let defaultColor = CIColor(red: 0, green: 0, blue: 0)


    // constructor
    init(key:String, title:String, ftype:FilterOperationType, parameters:[ParameterSettings]){
        self.key = key
        self.title = title
        self.show = false
        self.rating = 0
        self.filterOperationType = ftype
        self.stashedParameters = [:]
        self.parameterConfiguration = [:]
        self.numParameters = 0
        self.lookupImage = nil
        self.lookupImageName = ""
        
        // create the filter
        if ftype == .lookup {
            self.filter = CIFilter(name: FilterDescriptor.lookupFilterName)
            //HACK: lookup image from FilterLibrary
            if let name = FilterLibrary.lookupDictionary[key] {
                // set the name of the lookup image and default intensity
                self.setLookupImage(name:name)
                self.filter?.setValue(1.0, forKey:FilterDescriptor.lookupArgIntensity)
                
                // manually add the intensity parameter to the parameter list (so that it will be displayed)
                let p = ParameterSettings(key: FilterDescriptor.lookupArgIntensity, title: "intensity", min: 0.0, max: 1.0, value: 0.5, type: .float)
                self.parameterConfiguration[FilterDescriptor.lookupArgIntensity] = p
                self.numParameters = 1
            } else {
                log.error("Could not find lookup image for filter: \(key)")
            }
        } else {
            self.filter = CIFilter(name: key)
        }
        if self.filter == nil {
            log.error("Error creating filter:\(key)")
        } else {
            //self.filter?.setDefaults()
            // (deep) copy the parameters and set up the filter
            for p in parameters {
                self.stashedParameters[p.key] = p
                self.parameterConfiguration[p.key] = p
                if p.type == .float { // any other types must be set by the app
                    self.filter?.setValue(p.value, forKey: p.key)
                }
            }
            self.numParameters = parameters.count
        }
    }
    
    // get number of parameters
    func getNumParameters() -> Int {
        return parameterConfiguration.count
    }
    
    // get list of parameter keys
    func getParameterKeys() -> [String] {
        return Array(parameterConfiguration.keys)
    }
    
    
    // get full parameter settings
    func getParameterSettings(_ key:String) -> ParameterSettings? {
        if let p = parameterConfiguration[key] {
            return p
        } else {
            return nil
        }
    }
    
    
    // Parameter access for Float parameters (covers most parameters)
    func getParameter(_ key:String)->Float {
        var pval:Float
        pval = FilterDescriptor.parameterNotSet
        if let p = parameterConfiguration[key] {
            if p.type == .float {
                pval = self.filter?.value(forKey: key) as! Float
            } else {
                log.error("Parameter (\(key) is not a Float")
            }
        } else {
            log.error("Invalid key:\(key) for filter:\(self.key)")
        }
        return pval
    }

    func setParameter(_ key:String, value:Float) {
        if let p = parameterConfiguration[key] {
            if p.type == .float {
                if ((self.filter?.inputKeys.contains(p.key))!) {
                    self.filter?.setValue(value, forKey: key)
                } else {
                    log.error("Invalid parameter:(\(p.key)) for filter:(\(key)")
                }
            } else {
                log.error("Parameter (\(key) is not a Float")
            }
        } else {
            log.error("Invalid key:\(key) for filter:\(self.key)")
        }
    }

    // Parameter access for Color parameters
    func getColorParameter(_ key:String)->CIColor {
        var cval:CIColor
        cval = defaultColor
        if let p = parameterConfiguration[key] {
            if p.type == .color {
                cval = self.filter?.value(forKey: key) as! CIColor
            } else {
                log.error("Parameter (\(key) is not a Color")
            }
        } else {
            log.error("Invalid key:\(key) for filter:\(self.key)")
        }
        return cval
    }
    
    func setColorParameter(_ key:String, color:CIColor) {
        if let p = parameterConfiguration[key] {
            if p.type == .color {
                if ((self.filter?.inputKeys.contains(p.key))!) {
                    self.filter?.setValue(color, forKey: key)
                } else {
                    log.error("Invalid parameter:(\(p.key)) for filter:(\(key)")
                }
            } else {
                log.error("Parameter (\(key) is not a Color")
            }
        } else {
            log.error("Invalid key:\(key) for filter:\(self.key)")
        }
    }
    
   
    
    // check that the argument key is valid for this filter
    private func checkArg(_ arg:String) -> Bool {
        if (self.filter?.inputKeys.contains(arg))!{
            return true
        } else {
            log.error("Invalid parameter key:\(arg) for filter:\(self.key)")
            return false
        }
    }

    
    // Lookup filters are funny because they are actually all the same underlying type
    // use this to 'convert' a filter to be a lookup and correct the naming etc.
    func convertToLookup(key: String, image:String){
        guard !image.isEmpty else {
            log.error("NIL lookup name provided")
            return
        }

        self.key = key
        self.setLookupImage(name:image)
    }
    
    
    // set the lokup image for a lookup filter (String version)
    func setLookupImage(name:String) {
        
        // we need to trust that this is correct, and overwrite the current settings to reflect the lookup image
/***
        guard self.filterOperationType == .lookup else {
            log.error("Filter (\(self.title)) is not a lookup filter")
            //DEBUG: check conversion
            let chk = FilterOperationType(rawValue:"lookup")
            log.error("CHECK - enum:\(self.filterOperationType) conversion:\(chk)")
            return
        }
 ***/
        guard !name.isEmpty else {
            log.error("NIL lookup image provided")
            return
        }
        
        if ((name != self.lookupImageName) || (self.lookupImage == nil)){
            let l = name.components(separatedBy:".")
            let title = l[0]
            let ext = l[1]
            
            guard let path = Bundle.main.path(forResource: title, ofType: ext) else {
                log.error("ERR: File not found:\(name)")
                return
            }
            
            self.title = title
            self.lookupImageName = name
            let image = UIImage(contentsOfFile: path)
            self.lookupImage = CIImage(image: image!)
            if let ciimage = self.lookupImage {
                if self.checkArg(FilterDescriptor.lookupArgImage) {
                    log.debug("Set lookup to: \(name) for filter:\(key)")
                    self.filter?.setValue(ciimage, forKey: FilterDescriptor.lookupArgImage)
                } else {
                    log.error("Filter: \(key) does not have arg:\(FilterDescriptor.lookupArgImage)")
                }
            } else {
                log.error("Could not create CIImage for: \(name)")
            }
        }
    }
    
    // set the lokup image for a lookup filter (CIImage version)
    func setLookupImage(image:CIImage?) {
        
        guard self.filterOperationType == .lookup else {
            log.error("Filter (\(self.title)) is not a lookup filter")
            return
        }
        guard image != nil else {
            log.error("NIL lookup image provided")
            return
        }

        self.lookupImage = image
        if self.checkArg(FilterDescriptor.lookupArgImage) {
            self.filter?.setValue(image, forKey: FilterDescriptor.lookupArgImage)
        } else {
            log.error("Filter: \(key) does not have arg:\(FilterDescriptor.lookupArgImage)")
        }
    }

    
    // save a copy of the parameters so that they can be restoed later
    func stashParameters() {
        for k in parameterConfiguration.keys {
            let p = parameterConfiguration[k]!
            self.stashedParameters[k] = p
        }
    }
    
    // restore the saved parameters
    func restoreParameters() {
        for k in stashedParameters.keys {
            let p = stashedParameters[k]!
            self.parameterConfiguration[k] = p
        }
    }
    
    // various flavours of applying the filter:
    
    /***
    // single input image
    func apply (image: CIImage?) -> CIImage? {
        if let filter = self.filter {
            filter.setValue(image, forKey: kCIInputImageKey)
            return filter.outputImage
        } else {
            return nil
        }
    }
    ***/
    
    // generic function run the filter. The second image is optional, and is only used for blend/composite filters
    func apply (image: CIImage?, image2: CIImage?=nil) -> CIImage? {
        
        guard image != nil else {
            log.error("NIL image supplied")
            return nil
        }
        
        if let filter = self.filter {
            
            log.debug("Running filter: \(String(describing: self.key)), type:\(self.filterOperationType)")
            log.debug("Input keys: \(filter.inputKeys)")
            
            if checkArg(kCIInputImageKey) { filter.setValue(image, forKey: kCIInputImageKey) }

            switch (self.filterOperationType){
            case .lookup:
                self.setLookupImage(name:self.lookupImageName)
                fallthrough
            case .singleInput:
 
                //filter.setValue(image, forKey: kCIInputImageKey)
                return filter.outputImage
            case .blend:
                log.debug("Using BLEND mode for filter: \(String(describing: self.key))")
                //TOFIX: blend image needs to be resized to fit the render view
                
                var blend:CIImage?
                if image2 != nil {
                    blend = image2
                } else {
                    blend = ImageManager.getCurrentBlendImage(size:(image?.extent.size)!)
                }
                if checkArg("inputBackgroundImage") { filter.setValue(blend, forKey: "inputBackgroundImage") }
                //filter.setValue(image, forKey: kCIInputImageKey)
                //filter.setValue(image, forKey: "inputBackgroundImage")
                //filter.setValue(blend, forKey: kCIInputImageKey)
                return filter.outputImage
            default:
                log.warning("Don't know how to handle filter \(String(describing: self.key))")
            }
        } else {
            return nil
        }
    }

    // reset to default parameters (usefil in UIs)
    func reset() {
        restoreParameters()
    }
    

}


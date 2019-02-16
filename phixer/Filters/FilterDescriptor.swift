//
//  FilterDescriptor.swift
//  phixer
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import UIKit

// Class that encapsulates an underlying filter
// Intended to form the 'bridge' between UI functionality and Filter Operations


// settings for each filter parameter.
// 'isRGB' indicates to use an RGB/HSB color gradient slider (i.e. to choose a color)
// the 'key' parameter is the name used to identify the parameter to the underlying Filter (CIFilter at this moment)




class FilterDescriptor {


    // Accessible vars (read-only). These can/should be overriden in subclasses
    public private(set) var key: String
    public private(set) var title: String
    public private(set) var filterOperationType: FilterOperationType
    public private(set) var numParameters: Int
    public private(set) var parameterConfiguration: [String: ParameterSettings] = [:] // dictionary of parameter settings

    //these are get/set because they are often changed
    public var show: Bool = false
    public var rating: Int = 0
    public var slow: Bool = false



    // constant used to indicate that a parameter has not (yet) been set, or doesn't exist
    public static let parameterNotSet: Float = -1000.00

    // name of CIFilter used to create Lookup filters
    //private static let lookupFilterName:String = "CIColorMap"
    private static let lookupFilterName: String = "YUCIColorLookup"
    private static let lookupArgImage: String = "inputColorLookupTable"
    private static let lookupArgIntensity: String = "inputIntensity"

    private static let blendArgIntensity: String = "inputIntensity"
    private static let opacityFilter = Opacity()

    public static let nullFilter = "NoFilter"


    // private vars
    private var stashedParameters: [String: ParameterSettings] = [:]
    private var filter: CIFilter? = nil
    private var lookupImageName: String = ""
    private var lookupImage: CIImage? = nil

    let defaultColor = CIColor(red: 0, green: 0, blue: 0)

    private var default_image: CIImage? = nil
    private var default_position: CIVector? = CIVector(x: 0, y: 0)
    //private var default_rect: CGRect = CGRect.zero
    private var default_rect: CIVector? = CIVector(cgRect: CGRect.zero)

    ///////////////////////////////////////////
    // Constructors
    ///////////////////////////////////////////

    // constructor intended for use by subclasses:
    init() {
        self.key = ""
        self.title = ""
        self.show = false
        self.rating = 0
        self.slow = false
        self.filterOperationType = .custom
        self.stashedParameters = [:]
        self.parameterConfiguration = [:]
        self.numParameters = 0
        self.lookupImage = nil
        self.lookupImageName = ""
        self.filter = nil
    }

    // constructors with parameters

    init (key: String, definition: FilterDefinition) {
        self.key = key
        self.title = definition.title
        self.show = !(definition.hide)
        self.rating = definition.rating
        self.slow = definition.slow
        self.filterOperationType = FilterOperationType.singleInput
        self.stashedParameters = [:]
        self.parameterConfiguration = [:]
        self.numParameters = 0
        self.lookupImage = nil
        self.lookupImageName = definition.lookup

        if definition.ftype.isEmpty { // not an error
            //log.error("NIL Operation Type for filter: \(key)")
            self.filterOperationType = FilterOperationType.singleInput
        } else {
            self.filterOperationType = FilterOperationType(rawValue: definition.ftype)!
        }


        // check for null filter (i.e. no operation is applied)
        if self.key == FilterDescriptor.nullFilter {
            self.filter = nil
        } else {
            // create the filter
            initFilter(ftype: self.filterOperationType, key: self.key, title: self.title, parameters: definition.parameters)
        }
    }

    init(key: String, title: String, ftype: FilterOperationType, parameters: [ParameterSettings]) {
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

        // check for null filter (i.e. no operation is applied)
        if self.key == FilterDescriptor.nullFilter {
            self.filter = nil
        } else {
            // create the filter
            initFilter(ftype: ftype, key: key, title: title, parameters: parameters)
        }
    }

    // different initializers for the different filter types

    private func initFilter(ftype: FilterOperationType, key: String, title: String, parameters: [ParameterSettings]) {
        switch (ftype) {
        case .singleInput:
            initSingleInputFilter(key: key, title: title, parameters: parameters)
        case .lookup:
            initLookupFilter(key: key, title: title, parameters: parameters)
        case .blend:
            initBlendFilter(key: key, title: title, parameters: parameters)
        case .custom:
            initCustomFilter(key: key, title: title, parameters: parameters)
        }
    }

    private func initSingleInputFilter(key: String, title: String, parameters: [ParameterSettings]) {
        //log.debug("Creating CIFilter:\(key)")

        try self.filter = CIFilter(name: key)
        if self.filter == nil {
            log.error("Error creating filter:\(key)")
        } else {
            // set up default params
            if (default_image == nil) {
                //default_image = ImageManager.getCurrentSampleImage()
                default_image = InputSource.getCurrentImage()
                if UIScreen.main.bounds.width > 1.0 {
                    default_rect = CIVector(cgRect: UIScreen.main.bounds)
                    //default_position = CIVector(cgPoint: CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2))
                    default_position = CIVector(cgPoint: CGPoint(x: 0, y: 0))
                } else {
                    default_rect = CIVector(cgRect: CGRect(x: 0, y: 0, width: 256, height: 256))
                    //default_position = CIVector(cgPoint: CGPoint(x: 256, y: 256))
                    default_position = CIVector(cgPoint: CGPoint(x: 0, y: 0))
                }
                //log.verbose("default pos:\(default_position)")
            }
            self.filter?.setDefaults()
            copyParameters(parameters)
            self.stashParameters()
        }

    }

    private func initLookupFilter(key: String, title: String, parameters: [ParameterSettings]) {
        self.filter = CIFilter(name: FilterDescriptor.lookupFilterName)
        //HACK: lookup image from FilterConfiguration
        if let name = FilterConfiguration.lookupDictionary[key] {
            // set the name of the lookup image and default intensity
            self.setLookupImage(name: name)
            self.filter?.setValue(1.0, forKey: FilterDescriptor.lookupArgIntensity)

            // manually add the intensity parameter to the parameter list (so that it will be displayed)
            let p = ParameterSettings(key: FilterDescriptor.lookupArgIntensity, title: "intensity", min: 0.0, max: 1.0, value: 1.0, type: .float)
            self.parameterConfiguration[FilterDescriptor.lookupArgIntensity] = p
            self.numParameters = 1
        } else {
            log.error("Could not find lookup image for filter: \(key)")
        }
    }

    private func initBlendFilter(key: String, title: String, parameters: [ParameterSettings]) {
        //log.debug("Creating Blend Filter:\(key)")
        self.filter = CIFilter(name: key)
        if self.filter == nil {
            log.error("Error creating filter:\(key)")
        } else {
            copyParameters(parameters)

            // add an artificial parameter to control transparency
            let p = ParameterSettings(key: FilterDescriptor.blendArgIntensity, title: "opacity", min: 0.0, max: 1.0, value: 0.8, type: .float)
            self.parameterConfiguration[FilterDescriptor.blendArgIntensity] = p
            self.numParameters = self.numParameters + 1
            self.stashParameters()
        }
    }

    private func initCustomFilter(key: String, title: String, parameters: [ParameterSettings]) {
        log.error("Custom filters not implemented yet. Ignoring")

    }

    func copyParameters(_ parameters: [ParameterSettings]) {
        // (deep) copy the parameters and set up the filter
        for p in parameters {
            //self.stashedParameters[p.key] = p
            //self.parameterConfiguration[p.key] = p
            self.stashedParameters[p.key] = ParameterSettings(key: p.key, title: p.title, min: p.min, max: p.max, value: p.value, type: p.type)
            self.parameterConfiguration[p.key] = ParameterSettings(key: p.key, title: p.title, min: p.min, max: p.max, value: p.value, type: p.type)
            if p.type == .float { // any other types must be set by the app
                self.filter?.setValue(p.value, forKey: p.key)
            } else {
                // there are some other types that we handle with default values:
                switch (p.type) {
                case .image:
                    self.filter?.setValue(default_image, forKey: p.key)
                case .position:
                    log.verbose("\(p.key) Using default pos:\(default_position)")
                    self.filter?.setValue(default_position, forKey: p.key)
                case .rectangle:
                    self.filter?.setValue(default_rect, forKey: p.key)
                default:
                    // just ignore
                    break
                }
            }
        }
        self.numParameters = parameters.count
    }


    ///////////////////////////////////////////
    // Accessors
    ///////////////////////////////////////////

    // get the corresponding FilterDefinition. This is intended as a way to 'save' a filter
    func getFilterDefinition() -> FilterDefinition {
        var fd: FilterDefinition = FilterDefinition()
        
        // copy the easy stuff
        fd.key = self.key
        fd.title = self.title
        fd.hide = !(self.show)
        fd.rating = self.rating
        fd.slow = self.slow
        fd.lookup = self.lookupImageName
        fd.ftype = self.filterOperationType.rawValue
        
        // (deep) copy the parameters
        fd.parameters = []
        for key in parameterConfiguration.keys {
            if let p = self.parameterConfiguration[key] {
                fd.parameters.append(ParameterSettings(key: p.key, title: p.title, min: p.min, max: p.max, value: p.value, type: p.type))
            }
        }
        return fd
    }

    // get number of parameters
    func getNumParameters() -> Int {
        return parameterConfiguration.count
    }

    // get number of 'displayable' parameters (scalars and colours)
    func getNumDisplayableParameters() -> Int {
        var count: Int = 0

        count = 0
        for k in parameterConfiguration.keys {
            if let p = parameterConfiguration[k] {
                if (p.type == .float) || (p.type == .color) || (p.type == .position) {
                    count = count + 1
                }
            }
        }

        return count
    }

    // get list of parameter keys
    func getParameterKeys() -> [String] {
        return Array(parameterConfiguration.keys)
    }


    // get full parameter settings
    func getParameterSettings(_ key: String) -> ParameterSettings? {
        if let p = parameterConfiguration[key] {
            return p
        } else {
            return nil
        }
    }

    // TODO: add function that handles type "Any" ?

    // Parameter access for Float parameters (covers most parameters)
    func getParameter(_ key: String) -> Float {
        var pval: Float
        pval = FilterDescriptor.parameterNotSet
        if let p = parameterConfiguration[key] {
            if p.type == .float {
                pval = p.value
            } else {
                log.error("Parameter (\(key) is not a Float")
            }
        } else {
            log.error("Invalid key:\(key) for filter:\(self.key)")
        }
        return pval
    }

    func setParameter(_ key: String, value: Float) {
        if let p = parameterConfiguration[key] {
            if p.type == .float {
                parameterConfiguration[key]!.value = value
                if (self.filter != nil) {
                    if ((self.filter?.inputKeys.contains(p.key))!) { // OK if not true
                        self.filter?.setValue(value, forKey: key)
                    }
                }
            } else {
                log.error("Parameter (\(key) is not a Float")
            }
        } else {
            log.error("Invalid key:\(key) for filter:\(self.key)")
        }
    }

    // Parameter access for Color parameters
    func getColorParameter(_ key: String) -> CIColor {
        var cval: CIColor?
        cval = defaultColor
        if let p = parameterConfiguration[key] {
            if p.type == .color {
                cval = self.filter?.value(forKey: key) as? CIColor
            } else {
                log.error("Parameter (\(key) is not a Color")
            }
        } else {
            log.error("Invalid key:\(key) for filter:\(self.key)")
        }
        if cval != nil {
            return cval!
        } else {
            return CIColor(red: 0, green: 0, blue: 0)
        }
    }

    func setColorParameter(_ key: String, color: CIColor) {
        if let p = parameterConfiguration[key] {
            if p.type == .color {
                self.filter?.setValue(color, forKey: key)
                /**** color types have funky names, so don't check - trust that config is correct (will crash otherwise)
                if ((self.filter?.inputKeys.contains(p.key))!) {
                    self.filter?.setValue(color, forKey: key)
                } else {
                    log.error("Invalid parameter:(key:\(key) p.key:\(p.key)) for filter:(\(self.key))")
                    log.debug("inputKeys:\(self.filter?.inputKeys)")
                }
                 ****/
            } else {
                log.error("Parameter (\(key) is not a Color")
            }
        } else {
            log.error("Invalid key:\(key) for filter:\(self.key)")
        }
    }

    // Parameter access for Position parameters
    func getPositionParameter(_ key: String) -> CIVector? {
        var vec: CIVector? = nil
        vec = default_position
        if let p = parameterConfiguration[key] {
            if p.type == .position {
                vec = self.filter?.value(forKey: key) as? CIVector
            } else {
                log.error("Parameter (\(key) is not a Position")
            }
        } else {
            log.error("Invalid key:\(key) for filter:\(self.key)")
        }
        return vec
    }

    func setPositionParameter(_ key: String, position: CIVector) {
        if let p = parameterConfiguration[key] {
            if p.type == .position {
                if ((self.filter?.inputKeys.contains(p.key))!) {
                    self.filter?.setValue(position, forKey: key)
                } else {
                    log.error("Invalid parameter:(\(p.key)) for filter:(\(key)")
                }
            } else {
                log.error("Parameter (\(key) is not a Position")
            }
        } else {
            log.error("Invalid key:\(key) for filter:\(self.key)")
        }
    }

    // Parameter access for CIVector parameters. The distinction relative to position is that these are not displayed
    func getVectorParameter(_ key: String) -> CIVector? {
        var vec: CIVector? = nil
        vec = default_position
        if let p = parameterConfiguration[key] {
            if p.type == .vector {
                vec = self.filter?.value(forKey: key) as? CIVector
            } else {
                log.error("Parameter (\(key) is not a Vector")
            }
        } else {
            log.error("Invalid key:\(key) for filter:\(self.key)")
        }
        return vec
    }
    
    func setVectorParameter(_ key: String, vector: CIVector) {
        if let p = parameterConfiguration[key] {
            if p.type == .vector {
                if ((self.filter?.inputKeys.contains(p.key))!) {
                    self.filter?.setValue(vector, forKey: key)
                } else {
                    log.error("Invalid parameter:(\(p.key)) for filter:(\(key)")
                }
            } else {
                log.error("Parameter (\(key) is not a Vector")
            }
        } else {
            log.error("Invalid key:\(key) for filter:\(self.key)")
        }
    }
  



    // set the lokup image for a lookup filter (String version)
    func setLookupImage(name: String) {

        guard !name.isEmpty else {
            log.error("NIL lookup image provided")
            return
        }

        if ((name != self.lookupImageName) || (self.lookupImage == nil)) {
            let l = name.components(separatedBy: ".")
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
                if self.validParam(FilterDescriptor.lookupArgImage) {
                    //log.debug("Set lookup to: \(name) for filter:\(key)")
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
    func setLookupImage(image: CIImage?) {

        guard self.filterOperationType == .lookup else {
            log.error("Filter (\(self.title)) is not a lookup filter")
            return
        }
        guard image != nil else {
            log.error("NIL lookup image provided")
            return
        }

        self.lookupImage = image
        if self.validParam(FilterDescriptor.lookupArgImage) {
            self.filter?.setValue(image, forKey: FilterDescriptor.lookupArgImage)
        } else {
            log.error("Filter: \(key) does not have arg:\(FilterDescriptor.lookupArgImage)")
        }
    }

    // get the source image (for StyleTransfer filters)
    func getSourceImage() -> UIImage? {

        if let styleFilter = self.filter as? StyleTransferFilter {
            return styleFilter.getSourceImage()
        } else {
            return nil
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


    // generic function run the filter. The second image is optional, and is only used for blend/composite filters
    func apply (image: CIImage?, image2: CIImage? = nil) -> CIImage? {

        guard image != nil else {
            log.error("NIL image supplied")
            return nil
        }

        // check for null filter (i.e. no operation is applied)
        if self.key == FilterDescriptor.nullFilter {
            return image
        }

        if let filter = self.filter {

            //log.debug("Running filter: \(String(describing: self.key)), type:\(self.filterOperationType)")
            //log.debug("Input keys: \(filter.inputKeys)")


            switch (self.filterOperationType) {
            case .lookup:
                self.setLookupImage(name: self.lookupImageName)
                if validParam(kCIInputImageKey) { filter.setValue(image, forKey: kCIInputImageKey) }
                return filter.outputImage

            case .singleInput:
                if validParam(kCIInputImageKey) { filter.setValue(image, forKey: kCIInputImageKey) }
                return filter.outputImage?.clampedToExtent().cropped(to: (image?.extent)!)

            case .blend:
                //log.debug("Using BLEND mode for filter: \(String(describing: self.key))")
                //TOFIX: blend image needs to be resized to fit the render view

                var blend: CIImage?
                if image2 != nil {
                    blend = image2
                } else {
                    blend = ImageManager.getCurrentBlendImage(size: (image?.extent.size)!)
                }

                // we are blending the supplied image on top of the blend image, just seems to look better
                var bImage: CIImage? = blend

                if let oFilter = CIFilter(name: "OpacityFilter") {
                    var alpha = self.getParameter(FilterDescriptor.blendArgIntensity)
                    if (alpha < 0.0) { alpha = 1.0 }
                    oFilter.setValue(alpha, forKey: "inputOpacity")
                    oFilter.setValue(blend, forKey: "inputImage")
                    bImage = oFilter.outputImage
                } else {
                    log.error("Could not create OpacityFilter")
                }

                if validParam(kCIInputImageKey) { filter.setValue(bImage, forKey: kCIInputImageKey) }
                if validParam("inputBackgroundImage") { filter.setValue(image, forKey: "inputBackgroundImage") }

                return filter.outputImage?.clampedToExtent().cropped(to: (image?.extent)!)

            default:
                log.warning("Don't know how to handle filter \(String(describing: self.key))")
            }
        }
        return nil
    }

    // reset to default parameters (usefil in UIs)
    func reset() {
        //restoreParameters()
        if filter != nil {
            self.filter!.setDefaults()
        }
    }


    ///////////////////////////////////////////
    // Private
    ///////////////////////////////////////////



    // check that the parameter key is valid for this filter
    private func validParam(_ key: String) -> Bool {
        guard self.filter != nil else {
            return false
        }
        if (self.filter?.inputKeys.contains(key))! {
            return true
        } else if self.parameterConfiguration[key] != nil {
            return true // artificially added parameter
        } else {
            log.error("Invalid parameter key:\(key) for filter:\(self.key)")
            return false
        }
    }


}


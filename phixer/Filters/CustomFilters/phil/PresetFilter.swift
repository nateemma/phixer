//
//  PresetFilter.swift
//  phixer
//
//  Created by Philip Price on 6/17/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import SwiftyJSON


// This is a 'special' filter that processes a preset definition and runs a series of filters defined in that preset definition
// It's special because we need to process the definition itself within the filter, so we have to add extra APIs (because CIFilter does not support String args)

class PresetFilter: CIFilter {
    let fname = "Preset"
    var inputImage: CIImage?
    var outImage: CIImage?
    var inputIntensity: CGFloat = 1.0
    
    var presetFile: String = ""
    
    private var fileLoaded:Bool = false
    private var running:Bool = false
    private var parsedConfig:JSON = JSON.null
    
    private var imgRect:CIVector = CIVector(x: 0.0, y: 0.0)
    private var imgCentre:CIVector = CIVector(x: 0.0, y: 0.0)
    private var imgRadius:CGFloat = 0.0

    private var opacityFilter:CIFilter? = CIFilter(name: "OpacityFilter")

    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputIntensity = 1.0
        parsedConfig = JSON.null
        fileLoaded = false
    }
    
    
    // filter display name
    func displayName() -> String {
        return fname
    }
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputIntensity": [kCIAttributeIdentity: 0,
                             kCIAttributeClass: "NSNumber",
                             kCIAttributeDefault: 1,
                             kCIAttributeDisplayName: "Intensity",
                             kCIAttributeMin: 0,
                             kCIAttributeSliderMin: 0,
                             kCIAttributeSliderMax: 1,
                             kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            guard (value != nil) else {
                log.error("NIL Input Image")
                return
            }
            inputImage = value as? CIImage
            // set defaults to deal with distance, centre and rect arguments for this image
            imgRect = CIVector(cgRect: inputImage!.extent)
            imgCentre = CIVector(cgPoint: CGPoint(x: inputImage!.extent.width/2.0, y: inputImage!.extent.height/2.0))
            imgRadius = min(inputImage!.extent.width, inputImage!.extent.height) / 2.0
            fileLoaded = false

        case "inputIntensity":
            inputIntensity = value as! CGFloat
            //fileLoaded = false

        default:
            log.error("Invalid key: \(key)")
        }
    }

    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            log.error("No input image")
            return nil
        }
        
        // check intensity. If approx. 0.0 then just return the input image (saves processing)
        guard inputIntensity > 0.01 else {
            log.warning("Preset not applied")
            return inputImage
        }

        if (running) { // calls can/will overlap because of multiple filters
            return (outImage != nil) ? outImage : inputImage
        }
        
        running = true
        
        outImage = inputImage
        var tmpImage: CIImage? = nil

        if parsedConfig == JSON.null || (parsedConfig["filters"].count <= 0) {
            log.debug("parsing preset file")
            loadPresetFile(name: presetFile)
        }
        
        //TODO: cache result. Need way to see if anything changed
        
        let count = parsedConfig["filters"].count
        if (count > 0) {
            if (abs(imgRadius) < 0.01) {
                imgRect = CIVector(cgRect: inputImage.extent)
                imgCentre = CIVector(cgPoint: CGPoint(x: inputImage.extent.width/2.0, y: inputImage.extent.height/2.0))
                imgRadius = min(inputImage.extent.width, inputImage.extent.height) / 2.0
                if (abs(imgRadius) < 0.01){
                    log.error("WARNING: image extent not set")
                }
            }

            //log.verbose("Running preset: \(self.presetFile) (\(count) filters)")
            for i in 0...(count - 1) {
                let fdesc = parsedConfig["filters"][i] // entry for a filter
                let fkey = fdesc["key"].stringValue
                let params = fdesc["parameters"].arrayValue // array of parameter dictionaries
                //log.verbose("Applying filter:\(fkey)")
                let filter = CIFilter(name: fkey)

                if filter != nil {
                    if outImage == nil { log.warning("NIL image") }
                    if (filter?.inputKeys.contains(kCIInputImageKey))! { filter?.setValue(outImage, forKey: kCIInputImageKey) }
                    // loop through the parameters for this filter
                    for p in params {
                        // OK, so p is now a dictionary holding the key, val and type
                        let pkey = p["key"].stringValue
                        if filter?.inputKeys.contains(pkey) ?? false {
                            let atype = p["type"].stringValue
                            let ptype = FilterConfiguration.attributeToParameterType(atype)
                            // process based on the parameter type. Note that this is a little different from the config file processing
                            switch (ptype) {
                            case .float:
                                let value = CGFloat(p["val"].floatValue)
                                //log.verbose("...arg: \(p["key"]) val:\(value) type:\(p["type"])")
                                filter?.setValue(value, forKey: pkey)
                            case .vector:
                                let sarray = p["val"].arrayValue // array of string values
                                let farray = sarray.map{ CGFloat($0.floatValue) }
                                var vec:CIVector
                                if farray.count == 2 { // special case, treat as a coordinate
                                    vec = CIVector(cgPoint: CGPoint(x: farray[0], y: farray[1]))
                               } else {
                                    vec = CIVector(values: farray, count: farray.count)
                                }
                                //log.verbose("...arg: \(p["key"]) farray:\(farray) val:\(vec) type:\(p["type"])")
                                //log.verbose("...arg: \(p["key"]) val:\(vec) type:\(p["type"])")
                                filter?.setValue(vec, forKey: pkey)
                            case .position:
                                //log.verbose("...arg: \(p["key"]) val:\(imgCentre) type:\(p["type"])")
                                filter?.setValue(imgCentre, forKey: pkey)
                            case .distance:
                                //log.verbose("...arg: \(p["key"]) val:\(imgRadius) type:\(p["type"])")
                                filter?.setValue(imgRadius, forKey: pkey)
                            case .rectangle:
                                //log.verbose("...arg: \(p["key"]) val:\(imgRect) type:\(p["type"])")
                                filter?.setValue(imgRect, forKey: pkey)
                            default:
                                // just ignore
                                log.warning("Ignoring parameter:\(pkey), type:\(ptype) for filter:\(fkey)")
                                break
                            }
                            
                        } else {
                            log.error("Invalid parameter: \(pkey) for filter:\(fkey)")
                        }
                    }
                    tmpImage = filter?.outputImage
                    outImage = tmpImage
                    
                } else {
                    log.error("Could not create filter: \(fkey)")
                }
            } // end filter loop
            
            // blend with the original image based on the intensity parameter
            //log.verbose("Intensity: \(inputIntensity)")
            if inputIntensity < 0.99 {
                // reduce opacity of filtered image and overlay on original
                if (self.opacityFilter == nil) {
                    self.opacityFilter = CIFilter(name: "OpacityFilter")
                }
                self.opacityFilter?.setValue(inputIntensity, forKey: "inputOpacity")
                self.opacityFilter?.setValue(outImage, forKey: "inputImage")
                self.opacityFilter?.setValue(inputImage, forKey: "inputBackgroundImage")
                tmpImage = self.opacityFilter?.outputImage
                outImage = tmpImage
           }

        } else {
            log.warning("No filters found for preset: \(presetFile)")
        }
        
        tmpImage = nil
        
        if outImage == nil {
            log.warning("NIL image produced")
            outImage = inputImage
        }
        
        running = false

        return (outImage != nil) ? outImage : inputImage
    }
    
    
    // this method is unique to the Preset filter
    func setPreset(name: String){
        //presetFile = name + ".json"
        presetFile = name
        //fileLoaded = false
        //log.verbose("loading: \(presetFile)")
        loadPresetFile(name: presetFile)
        
    }

    
    private func loadPresetFile(name: String) {
        
        if !fileLoaded {
            fileLoaded = true

            // find the preset json file, which must be part of the project
            let path = Bundle.main.path(forResource: name, ofType: "json")
            guard path != nil else {
                log.error("ERROR: file not found: \(presetFile)")
                return
            }
            
            do {
                // load the file contents and parse the JSON string
                let fileContents = try NSString(contentsOfFile: path!, encoding: String.Encoding.utf8.rawValue) as String
                if let data = fileContents.data(using: String.Encoding.utf8) {
                    //log.verbose("parsing data from: \(path!)")
                    parsedConfig = try JSON(data: data)
                    if (parsedConfig != JSON.null){
                        //log.verbose("parsing data")
                        //log.verbose ("\(parsedConfig)")
                        log.verbose("Preset:  \(name) (\(parsedConfig["filters"].count) filters)")
                     }
                }
            } catch let error as NSError {
                log.error("ERROR: error reading from preset file (\(presetFile)): \(error.localizedDescription)")
            }
        } else {
            log.debug("Already loaded")
        }
    }
    
    
}

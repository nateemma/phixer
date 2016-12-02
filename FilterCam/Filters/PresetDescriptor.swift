//
//  PresetDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


// This descriptor emulates a Lightroom/Photoshop PresetDescriptor
// Input parameter ranges match those of Lightroom/Photoshop, and are translated to GUImage ranges
class PresetDescriptor: FilterDescriptorInterface {
    
    // settable parameters:
    
    var temperature: Float { didSet {
        lclFilter.temperature = inputToParameter(index:0, value:temperature)
        log.verbose("temperature: \(temperature)->\(lclFilter.temperature)")
        }
    }
    
    var tint: Float { didSet {
            lclFilter.tint = inputToParameter(index:1, value:tint)
        log.verbose("tint: \(tint)->\(lclFilter.tint)")
        }
    }
    
    var exposure: Float { didSet {
            lclFilter.exposure = inputToParameter(index:2, value:exposure)
        log.verbose("exposure: \(exposure)->\(lclFilter.exposure)")
        }
    }
    var contrast: Float { didSet {
        lclFilter.contrast = inputToParameter(index:3, value:contrast)
        log.verbose("contrast: \(contrast)->\(lclFilter.contrast)")
        }
    }
    var highlights: Float { didSet {
        lclFilter.highlights = inputToParameter(index:4, value:highlights)
        log.verbose("highlights: \(highlights)->\(lclFilter.highlights)")
        }
    }
    var shadows: Float { didSet {
        lclFilter.shadows = inputToParameter(index:5, value:shadows)
        log.verbose("shadows: \(shadows)->\(lclFilter.shadows)")
        }
    }
    

    var vibrance: Float { didSet {
        lclFilter.vibrance = inputToParameter(index:6, value:vibrance)
        log.verbose("vibrance: \(vibrance)->\(lclFilter.vibrance)")
        }
    }
    var saturation: Float { didSet {
        lclFilter.saturation = inputToParameter(index:7, value:saturation)
        log.verbose("saturation: \(saturation)->\(lclFilter.saturation)")
        }
    }
    
    
    var sharpness: Float { didSet {
        lclFilter.sharpness = inputToParameter(index:8, value:sharpness)
        log.verbose("sharpness: \(sharpness)->\(lclFilter.sharpness)")
        }
    }
    
    var start: Float { didSet {
        lclFilter.vignetteStart = inputToParameter(index:9, value:start)
        log.verbose("vignetteStart: \(start)->\(lclFilter.vignetteStart)")
        }
    }
    var end: Float { didSet {
        lclFilter.vignetteEnd = inputToParameter(index:10, value:end)
        log.verbose("vignetteEnd: \(end)->\(lclFilter.vignetteEnd)")
        }
    }
    
    
    
    var key = "Preset"
    var title = "Preset"
    
    let filter: BasicOperation?  = nil
    var filterGroup: OperationGroup? = nil
    
    // parameterConfiguration and inputConfiguration must have the same entries in the same order. Used for translation between the 2 schemes
    let numParameters = 11
    let parameterConfiguration = [ParameterSettings(title:"temperature", minimumValue:2500.0, maximumValue:7500.0, initialValue:5000.0, isRGB:false),
                                  ParameterSettings(title:"tint",        minimumValue:-200.0, maximumValue:200.0,  initialValue:0.0, isRGB:false),
                                  ParameterSettings(title:"exposure",    minimumValue:-4.0,   maximumValue:4.0,    initialValue:0.0, isRGB:false),
                                  ParameterSettings(title:"contrast",    minimumValue:0.0,    maximumValue:4.0,    initialValue:1.0, isRGB:false),
                                  ParameterSettings(title:"highlights",  minimumValue:0.0,    maximumValue:1.0,    initialValue:1.0, isRGB:false),
                                  ParameterSettings(title:"shadows",     minimumValue:0.0,    maximumValue:1.0,    initialValue:0.0, isRGB:false),
                                  ParameterSettings(title:"vibrance",    minimumValue:-1.2,   maximumValue:1.2,    initialValue:0.0, isRGB:false),
                                  ParameterSettings(title:"saturation",  minimumValue:0.0,    maximumValue:2.0,    initialValue:1.0, isRGB:false),
                                  ParameterSettings(title:"sharpness",   minimumValue:0.0,    maximumValue:1.0,    initialValue:0.5, isRGB:false),
                                  ParameterSettings(title:"start",       minimumValue:0.0,    maximumValue:1.0,   initialValue:0.5, isRGB:false),
                                  ParameterSettings(title:"end",         minimumValue:0.0,    maximumValue:1.0,    initialValue:0.75, isRGB:false)]
    
    let inputConfiguration = [ParameterSettings(title:"temperature", minimumValue:2500.0,    maximumValue:+7500.0, initialValue:5000.0, isRGB:false),
                              ParameterSettings(title:"tint",        minimumValue:-100.0, maximumValue:+100.0,   initialValue:0.0, isRGB:false),
                              ParameterSettings(title:"exposure",    minimumValue:-4.0,   maximumValue:4.0,      initialValue:0.0, isRGB:false),
                              ParameterSettings(title:"contrast",    minimumValue:-100.0, maximumValue:+100.0,   initialValue:0.0, isRGB:false),
                              ParameterSettings(title:"highlights",  minimumValue:0.0,    maximumValue:+100.0,   initialValue:0.0, isRGB:false),
                              ParameterSettings(title:"shadows",     minimumValue:0.0,    maximumValue:+100.0,   initialValue:0.0, isRGB:false),
                              ParameterSettings(title:"vibrance",    minimumValue:-100.0, maximumValue:+100.0,   initialValue:0.0, isRGB:false),
                              ParameterSettings(title:"saturation",  minimumValue:-100.0, maximumValue:+100.0,   initialValue:0.0, isRGB:false),
                              ParameterSettings(title:"sharpness",   minimumValue:0.0,    maximumValue:100.0,    initialValue:0.0, isRGB:false),
                              ParameterSettings(title:"start",       minimumValue:0.0,    maximumValue:+100.0,   initialValue:100.0, isRGB:false),
                              ParameterSettings(title:"end",         minimumValue:0.0,    maximumValue:+100.0,   initialValue:100.0, isRGB:false)]
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:Preset = Preset() // the actual filter

    // stashed copies of the external parameters
    fileprivate var stash_temperature: Float
    fileprivate var stash_tint: Float
    fileprivate var stash_exposure: Float
    fileprivate var stash_contrast: Float
    fileprivate var stash_highlights: Float
    fileprivate var stash_shadows: Float
    fileprivate var stash_vibrance: Float
    fileprivate var stash_saturation: Float
    fileprivate var stash_sharpness: Float
    fileprivate var stash_start: Float
    fileprivate var stash_end: Float

    
    
    init(){
        filterGroup = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        
        // set default values

        lclFilter.temperature = parameterConfiguration[0].initialValue
        lclFilter.tint = parameterConfiguration[1].initialValue
        lclFilter.exposure = parameterConfiguration[2].initialValue
        lclFilter.contrast = parameterConfiguration[3].initialValue
        lclFilter.highlights = parameterConfiguration[4].initialValue
        lclFilter.shadows = parameterConfiguration[5].initialValue
        lclFilter.vibrance = parameterConfiguration[6].initialValue
        lclFilter.saturation = parameterConfiguration[7].initialValue
        lclFilter.sharpness = parameterConfiguration[8].initialValue
        lclFilter.vignetteStart = parameterConfiguration[9].initialValue
        lclFilter.vignetteEnd = parameterConfiguration[10].initialValue

        // save values to 'stash' copies

        // need to figure out how to set appropriate values in init()
        temperature = inputConfiguration[0].initialValue
        tint = inputConfiguration[1].initialValue
        exposure = inputConfiguration[2].initialValue
        contrast = inputConfiguration[3].initialValue
        highlights = inputConfiguration[4].initialValue
        shadows = inputConfiguration[5].initialValue
        vibrance = inputConfiguration[6].initialValue
        saturation = inputConfiguration[7].initialValue
        sharpness = inputConfiguration[8].initialValue
        start = inputConfiguration[9].initialValue
        end = inputConfiguration[10].initialValue

        stash_temperature = temperature
        stash_tint = tint
        stash_exposure = exposure
        stash_contrast = contrast
        stash_highlights = highlights
        stash_shadows = shadows
        stash_vibrance = vibrance
        stash_saturation = saturation
        stash_sharpness = sharpness
        stash_start = start
        stash_end = end

        //log.verbose("inputConfiguration: \(inputConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = Preset()
        restoreParameters()
    }
    

    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return parameterToInput(index:index-1, value:lclFilter.temperature)
        case 2:
            return parameterToInput(index:index-1, value:lclFilter.tint)
        case 3:
            return parameterToInput(index:index-1, value:lclFilter.exposure)
        case 4:
            return parameterToInput(index:index-1, value:lclFilter.contrast)
        case 5:
            return parameterToInput(index:index-1, value:lclFilter.highlights)
        case 6:
            return parameterToInput(index:index-1, value:lclFilter.shadows)
        case 7:
            return parameterToInput(index:index-1, value:lclFilter.vibrance)
        case 8:
            return parameterToInput(index:index-1, value:lclFilter.saturation)
        case 9:
            return parameterToInput(index:index-1, value:lclFilter.sharpness)
        case 10:
            return parameterToInput(index:index-1, value:lclFilter.vignetteStart)
        case 11:
            return parameterToInput(index:index-1, value:lclFilter.vignetteEnd)
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.temperature = inputToParameter(index:index-1, value:value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        case 2:
            lclFilter.tint = inputToParameter(index:index-1, value:value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        case 3:
            lclFilter.exposure = inputToParameter(index:index-1, value:value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        case 4:
            lclFilter.contrast = inputToParameter(index:index-1, value:value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        case 5:
            lclFilter.highlights = inputToParameter(index:index-1, value:value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        case 6:
            lclFilter.shadows = inputToParameter(index:index-1, value:value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        case 7:
            lclFilter.vibrance = inputToParameter(index:index-1, value:value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        case 8:
            lclFilter.saturation = inputToParameter(index:index-1, value:value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        case 9:
            lclFilter.sharpness = inputToParameter(index:index-1, value:value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        case 10:
            lclFilter.vignetteStart = inputToParameter(index:index-1, value:value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        case 11:
            lclFilter.vignetteEnd = inputToParameter(index:index-1, value:value)
            log.debug("\(parameterConfiguration[index-1].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    func stashParameters() {
        stash_temperature = parameterToInput(index:0, value:lclFilter.temperature)
        stash_tint = parameterToInput(index:1, value:lclFilter.tint)
        stash_exposure = parameterToInput(index:2, value:lclFilter.exposure)
        stash_contrast = parameterToInput(index:3, value:lclFilter.contrast)
        stash_highlights = parameterToInput(index:4, value:lclFilter.highlights)
        stash_shadows = parameterToInput(index:5, value:lclFilter.shadows)
        stash_vibrance = parameterToInput(index:6, value:lclFilter.vibrance)
        stash_saturation = parameterToInput(index:7, value:lclFilter.saturation)
        stash_sharpness = parameterToInput(index:8, value:lclFilter.sharpness)
        stash_start = parameterToInput(index:9, value:lclFilter.vignetteStart)
        stash_end = parameterToInput(index:10, value:lclFilter.vignetteEnd)
    }
    
    func restoreParameters(){
        lclFilter.temperature = inputToParameter(index:0, value:stash_temperature)
        lclFilter.tint = inputToParameter(index:1, value:stash_tint)
        lclFilter.exposure = inputToParameter(index:2, value:stash_exposure)
        lclFilter.contrast = inputToParameter(index:3, value:stash_contrast)
        lclFilter.highlights = inputToParameter(index:4, value:stash_highlights)
        lclFilter.shadows = inputToParameter(index:5, value:stash_shadows)
        lclFilter.vibrance = inputToParameter(index:6, value:stash_vibrance)
        lclFilter.saturation = inputToParameter(index:7, value:stash_saturation)
        lclFilter.sharpness = inputToParameter(index:8, value:stash_sharpness)
        lclFilter.vignetteStart = inputToParameter(index:9, value:stash_start)
        lclFilter.vignetteEnd = inputToParameter(index:10, value:stash_end)
    }

  
    
    
    // Conversions between Input values and GPUImage (Parameter) values
    
    private func parameterToInput(index:Int, value:Float)->Float{
        var inputValue:Float = 0.0
        var val:Float
        
        guard ((index>=0) && (index<numParameters)) else {
            log.error("index out of range: \(index)")
            return inputValue
        }
        
        // constrain values
        val = value
        if (value < parameterConfiguration[index].minimumValue) { val = parameterConfiguration[index].minimumValue }
        if (value > parameterConfiguration[index].maximumValue) { val = parameterConfiguration[index].maximumValue }
        
        // normalise to a 0..1 range
        let pos = (val - parameterConfiguration[index].minimumValue) / (parameterConfiguration[index].maximumValue - parameterConfiguration[index].minimumValue)
        
        // convert to same position in the "input" range
        inputValue = pos * (inputConfiguration[index].maximumValue - inputConfiguration[index].minimumValue) + inputConfiguration[index].minimumValue
        
        return inputValue
    }
  
    
    private func inputToParameter(index:Int, value:Float)->Float{
        var parameterValue: Float = 0.0
        var val:Float
        
        guard ((index>=0) && (index<numParameters)) else {
            log.error("index out of range: \(index)")
            return parameterValue
        }
        
        // constrain values
        val = value
        if (value < inputConfiguration[index].minimumValue) { val = inputConfiguration[index].minimumValue }
        if (value > inputConfiguration[index].maximumValue) { val = inputConfiguration[index].maximumValue }
        
        // normalise to a 0..1 range
        let pos = (val - inputConfiguration[index].minimumValue) / (inputConfiguration[index].maximumValue - inputConfiguration[index].minimumValue)
        
        // convert to same position in the "input" range
        parameterValue = pos * (parameterConfiguration[index].maximumValue - parameterConfiguration[index].minimumValue) + parameterConfiguration[index].minimumValue
        
        return parameterValue
    }
    
    
    open func logParameters(){
        log.verbose("temperature: \(parameterToInput(index:0, value:lclFilter.temperature))->\(lclFilter.temperature)")
        log.verbose("tint: \(parameterToInput(index:1, value:lclFilter.tint))->\(lclFilter.tint)")
        log.verbose("exposure: \( parameterToInput(index:2, value:lclFilter.exposure))->\(lclFilter.exposure)")
        log.verbose("contrast: \(parameterToInput(index:3, value:lclFilter.contrast))->\(lclFilter.contrast)")
        log.verbose("highlights: \(parameterToInput(index:4, value:lclFilter.highlights))->\(lclFilter.highlights)")
        log.verbose("shadows: \(parameterToInput(index:5, value:lclFilter.shadows))->\(lclFilter.shadows)")
        log.verbose("vibrance: \(parameterToInput(index:6, value:lclFilter.vibrance))->\(lclFilter.vibrance)")
        log.verbose("saturation: \(parameterToInput(index:7, value:lclFilter.saturation))->\(lclFilter.saturation)")
        log.verbose("sharpness: \(parameterToInput(index:8, value:lclFilter.sharpness))->\(lclFilter.sharpness)")
        log.verbose("vignetteStart: \(parameterToInput(index:9, value:lclFilter.vignetteStart))->\(lclFilter.vignetteStart)")
        log.verbose("vignetteEnd: \(parameterToInput(index:10, value:lclFilter.vignetteEnd))->\(lclFilter.vignetteEnd)")
    }

}

//
//  Preset.swift
//  phixer
//
//  Created by Philip Price on 11/18/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import CoreImage


// This is a filter operation that collects most of the common image editing filters into one
// The intent is to allow this to be used to create presets modelled on those in Lightroom or Photoshop

//TODO: lookup from FilterManager

class Preset : FilterDescriptor{
    
    // vars required by interface:
    let key = "ColorInversion"
    let title = "ColorInversion"
    var filter:FilterDescriptor? = nil
    var show: Bool = false
    var rating: Int = 0
    let numParameters = 0
    let parameterConfiguration:[ParameterSettings] = []
    let filterOperationType = FilterOperationType.singleInput
    
    
    // Modifiable parameters
    
    // White Balance:
    open var temperature: Float = 5000.0 { didSet { fWb.temperature = temperature } }
    open var tint:        Float = 0.0 { didSet { fWb.tint = tint } }
    
    // Tone:
    open var exposure:   Float = 0.0 { didSet { fExp.exposure = exposure } }
    open var contrast:   Float = 1.0 { didSet { fCon.contrast = contrast } }
    open var shadows:    Float = 0.0 { didSet { fHil.shadows = shadows } }
    open var highlights: Float = 1.0 { didSet { fHil.highlights = highlights } }
    
    // Presence:
    open var vibrance:   Float = 0.0 { didSet { fVib.vibrance = vibrance } }
    open var saturation: Float = 1.0 { didSet { fSat.saturation = saturation } }

    
    // Sharpen:
    open var sharpness: Float = 0.5 { didSet { fShp.sharpness = sharpness } }
    
    // Vignette:
    open var vignetteStart: Float = 0.5  { didSet { fVgt.start = vignetteStart } }
    open var vignetteEnd:   Float = 0.75 { didSet { fVgt.end = vignetteEnd } }
    
    
    // the individual filters (using short names because they need to fit on one line)
    let fWb = ()
    let fExp = MTIExposureFilter()
    let fCon = MTIContrastFilter()
    let fHil = ()
    let fVib = MTIVibranceFilter()
    let fSat = MTISaturationFilter()
    let fShp = ()
    let fVgt = ()
    
    public override init() {
        super.init()
        
    }
    
    
    
    fileprivate static func getColorFromValue(_ value: Float)->Color{
        let color:Color = Color(red: value, green: value, blue: value, alpha: 1.0)
        return color
    }
    
    
    fileprivate static func getValueFromColor(_ color: Color)->Float{
        return Float(color.redComponent)
    }
    

    
}

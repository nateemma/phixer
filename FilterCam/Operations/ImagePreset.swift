//
//  ImagePreset.swift
//  FilterCam
//
//  Created by Philip Price on 11/18/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


// This is a filter operation that collects most of the common image editing filters into one
// The intent is to allow this to be used to create presets modelled on those in Lightroom or Photoshop

class ImagePreset: OperationGroup {
    // Modifiable parameters
    
    // White Balance:
    open var temperature: Float = 5000.0 { didSet { wbFilter.temperature = temperature } }
    open var tint:        Float = 0.0 { didSet { wbFilter.tint = tint } }
    
    // Tone:
    open var exposure:   Float = 0.0 { didSet { exposureFilter.exposure = exposure } }
    open var contrast:   Float = 1.0 { didSet { contrastFilter.contrast = contrast } }
    open var shadows:    Float = 0.0 { didSet { highlightFilter.shadows = shadows } }
    open var highlights: Float = 1.0 { didSet { highlightFilter.highlights = highlights } }
    
    // Presence:
    open var clarity:    Float = 1.0 { didSet { clarityFilter.strength = clarity } }
    open var vibrance:   Float = 0.0 { didSet { vibranceFilter.vibrance = vibrance } }
    open var saturation: Float = 1.0 { didSet { saturationFilter.saturation = saturation } }
    
    // Levels:
    // TODO: single value means points are on a line, i.e. linear contrast. Figure out how to adjust as points (i.e. 2D)
    open var minOutput: Float = 0.00 { didSet { levelsFilter.minOutput = ImagePreset.getColorFromValue(minOutput) } }
    open var minimum:   Float = 0.25 { didSet { levelsFilter.minimum = ImagePreset.getColorFromValue(minimum) } }
    open var middle:    Float = 0.50 { didSet { levelsFilter.middle = ImagePreset.getColorFromValue(middle) } }
    open var maximum:   Float = 0.75 { didSet { levelsFilter.maximum = ImagePreset.getColorFromValue(maximum) } }
    open var maxOutput: Float = 1.0  { didSet { levelsFilter.maxOutput = ImagePreset.getColorFromValue(maxOutput) } }

    
    // Sharpen:
    open var sharpness: Float = 0.5 { didSet { sharpenFilter.sharpness = sharpness } }
    
    // Haze:
    open var hazeDistance: Float = 0.1 { didSet { hazeFilter.distance = hazeDistance } }
    open var hazeSlope:    Float = 0.0 { didSet { hazeFilter.slope = hazeSlope } }
    
    // Vignette:
    open var vignetteStart: Float = 0.5  { didSet { vignetteFilter.start = vignetteStart } }
    open var vignetteEnd:   Float = 0.75 { didSet { vignetteFilter.start = vignetteEnd } }
    
    
    // the individual filters
    let wbFilter = WhiteBalance()
    let exposureFilter = ExposureAdjustment()
    let contrastFilter = ContrastAdjustment()
    let highlightFilter = HighlightsAndShadows()
    let clarityFilter = Clarity()
    let vibranceFilter = Vibrance()
    let saturationFilter = SaturationAdjustment()
    let levelsFilter = LevelsAdjustment()
    let sharpenFilter = Sharpen()
    let hazeFilter = Haze()
    let vignetteFilter = Vignette()
    
    public override init() {
        super.init()
        
        
        self.configureGroup{input, output in
            input --> self.wbFilter --> self.exposureFilter --> self.contrastFilter --> self.highlightFilter --> self.clarityFilter --> self.vibranceFilter -->
                self.saturationFilter --> self.levelsFilter --> self.sharpenFilter --> self.hazeFilter --> self.vignetteFilter --> output
        }
    }
    
    
    
    fileprivate static func getColorFromValue(_ value: Float)->Color{
        let color:Color = Color(red: value, green: value, blue: value, alpha: 1.0)
        return color
    }
    
    
    fileprivate static func getValueFromColor(_ color: Color)->Float{
        return Float(color.redComponent)
    }
    

    
}

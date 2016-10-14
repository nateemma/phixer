//
//  FilterManager.swift
//  FilterCam
//
//  Created by Philip Price on 10/5/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage

// class that manages the list of available filters and groups them into categories



// The list of Categories
fileprivate var _categoryList:[String] = [FilterCategoryType.quickSelect.rawValue,
                                          FilterCategoryType.colorAdjustments.rawValue,
                                          FilterCategoryType.imageProcessing.rawValue,
                                          FilterCategoryType.blendModes.rawValue,
                                          FilterCategoryType.visualEffects.rawValue ]

// typealias for dictionaries of FilterDescriptors
typealias FilterDictionary = Dictionary<String, FilterDescriptorInterface>

//dictionaries for each category
fileprivate var _quickSelectDictionary: FilterDictionary = [:]
fileprivate var _colorAdjustmentsDictionary: FilterDictionary = [:]
fileprivate var _imageProcessingDictionary: FilterDictionary = [:]
fileprivate var _blendModesDictionary: FilterDictionary = [:]
fileprivate var _visualEffectsDictionary: FilterDictionary = [:]


// enum that lists the available categories
enum FilterCategoryType: String {
    case quickSelect      = "Quick Select"
    case colorAdjustments = "Color Adjustments"
    case imageProcessing  = "Image Processing"
    case blendModes       = "Blend Modes"
    case visualEffects    = "Visual Effects"
    
    func getDictionary()->FilterDictionary {
        switch (self){
        
        case .quickSelect:
            return _quickSelectDictionary
        case .colorAdjustments:
            return _colorAdjustmentsDictionary
       case .imageProcessing:
            return _imageProcessingDictionary
        case .blendModes:
            return _blendModesDictionary
        case .visualEffects:
            return _visualEffectsDictionary
        }
    }
}



// SIngleton class that provides access to the categories/filters
// use FilterManager.sharedInstance to get a reference

class FilterManager{
    
    static let sharedInstance = FilterManager() // the actual instance shared by everyone
    static var initDone:Bool = false
    
    //MARK: - Setup/Teardown
    
    private init(){
        
        // Add filter definitions to the appropriate categories
        populateCategories()
    }
    
    
    
    func populateCategories(){
        
        //var dict: FilterDictionary?
        
        if (!FilterManager.initDone) {
            log.verbose("populateCategories() - Loading Dictionaries...")
            //TODO: load from some kind of configuration file?
            
            // Quick Select
            //TEMP: populate with some filters, but this should really be done by the user (and saved)
            
            _quickSelectDictionary["BulgeDistortion"] = BulgeDistortionDescriptor()
            _quickSelectDictionary["Crosshatch"] = CrosshatchDescriptor()
            _quickSelectDictionary["Emboss"] = EmbossDescriptor()
            _quickSelectDictionary["GlassSphereRefraction"] = GlassSphereRefractionDescriptor()
            _quickSelectDictionary["Highlights"] = HighlightsDescriptor()
            _quickSelectDictionary["LuminanceThreshold"] = LuminanceThresholdDescriptor()
            _quickSelectDictionary["Monochrome"] = MonochromeDescriptor()
            _quickSelectDictionary["PolarPixellate"] = PolarPixellateDescriptor()
            _quickSelectDictionary["PolkaDot"] = PolkaDotDescriptor()
            _quickSelectDictionary["Posterize"] = PosterizeDescriptor()
            _quickSelectDictionary["Saturation"] = SaturationDescriptor()
            _quickSelectDictionary["Sepia"] = SepiaDescriptor()
            _quickSelectDictionary["Sketch"] = SketchDescriptor()
            _quickSelectDictionary["Solarize"] = SolarizeDescriptor()
            _quickSelectDictionary["ThresholdSketch"] = ThresholdSketchDescriptor()
            _quickSelectDictionary["Toon"] = ToonDescriptor()
            _quickSelectDictionary["Vignette"] = VignetteDescriptor()
            _quickSelectDictionary["ZoomBlur"] = ZoomBlurDescriptor()
            
            _quickSelectDictionary["FalseColor"] = FalseColorDescriptor()
            _quickSelectDictionary["Warmth"] = WarmthDescriptor()
            _quickSelectDictionary["WhiteBalance"] = WhiteBalanceDescriptor()
            _quickSelectDictionary["Hue"] = HueDescriptor()
            _quickSelectDictionary["RGB"] = RGBDescriptor()
            _quickSelectDictionary["Brightness"] = BrightnessDescriptor()
            _quickSelectDictionary["Contrast"] = ContrastDescriptor()
            
            _quickSelectDictionary["CannyEdgeDetection"] = CannyEdgeDetectionDescriptor()
            //_quickSelectDictionary["HarrisCornerDetector"] = HarrisCornerDetectorDescriptor()
            //_quickSelectDictionary["NobleCornerDetectorr"] = NobleCornerDetectorDescriptor()
            //_quickSelectDictionary["ShiTomasiFeatureDetector"] = ShiTomasiFeatureDetectorDescriptor()
            _quickSelectDictionary["UnsharpMask"] = UnsharpMaskDescriptor()
            _quickSelectDictionary["Exposure"] = ExposureDescriptor()
            _quickSelectDictionary["Sharpen"] = SharpenDescriptor()
            _quickSelectDictionary["Rotate"] = RotateDescriptor()
            _quickSelectDictionary["Median"] = MedianDescriptor()
            _quickSelectDictionary["Kuwahara"] = KuwaharaDescriptor()
            _quickSelectDictionary["KuwaharaRadius3"] = KuwaharaRadius3Descriptor()
            _quickSelectDictionary["Laplacian"] = LaplacianDescriptor()
            _quickSelectDictionary["ColorInversion"] = ColorInversionDescriptor()
            _quickSelectDictionary["MissEtikate"] = MissEtikateDescriptor()
            _quickSelectDictionary["Amatorka"] = AmatorkaDescriptor()
            _quickSelectDictionary["Crop"] = CropDescriptor()
            _quickSelectDictionary["BilateralBlur"] = BilateralBlurDescriptor()
            _quickSelectDictionary["GaussianBlur"] = GaussianBlurDescriptor()
            _quickSelectDictionary["BoxBlur"] = BoxBlurDescriptor()
            _quickSelectDictionary["Pixellate"] = PixellateDescriptor()
            _quickSelectDictionary["Haze"] = HazeDescriptor()
            _quickSelectDictionary["Grayscale"] = GrayscaleDescriptor()
            _quickSelectDictionary["AverageLuminanceThreshold"] = AverageLuminanceThresholdDescriptor()
            _quickSelectDictionary["SobelEdgeDetection"] = SobelEdgeDetectionDescriptor()
            _quickSelectDictionary["ThresholdSobelEdgeDetection"] = ThresholdSobelEdgeDetectionDescriptor()
            _quickSelectDictionary["PrewittEdgeDetection"] = PrewittEdgeDetectionDescriptor()
            //_quickSelectDictionary[""] = Descriptor()
           

            //dumpDictionary(_quickSelectDictionary)//DEBUG
            
            // Color Adjustments
            
            // Image Processing
            
            // Blend Modes
            
            // Visual Effects
            
            FilterManager.initDone = true
        }
        
    }
    
    
    // dump the keys amd filter names contained in the supplied dictionary
    private func dumpDictionary(_ dictionary:FilterDictionary?){
        var fdi: FilterDescriptorInterface
        for key  in (dictionary?.keys)! {
            fdi = (dictionary?[key])!
            log.debug("key:\(key) filter:\(fdi.key)")
            
        }
    }
  
    
    
    open func getFilterList(category:FilterCategoryType)->[String]{
        return Array(category.getDictionary().keys)
    }
    
    
    
    // get the filter descriptor for the supplied category & filter type
    open func getFilterDescriptor(category:FilterCategoryType, name:String)->FilterDescriptorInterface? {
        
        var dict: FilterDictionary?
        var filterDescr: FilterDescriptorInterface?
        
        if (!FilterManager.initDone) { populateCategories() }
        
        //log.verbose("cat:\(category.rawValue), name:\(name)")
        //dict = FilterManager._dictionaryList[category.rawValue]!
        dict = category.getDictionary()
        
        if (dict == nil){
            log.error("Null dictionary for:\(category.rawValue)")
        } else {
            
            
            filterDescr = (dict?[name])
            if (filterDescr == nil){
                log.error("Null filter for:\(name)")
                dumpDictionary(dict)
            }
        }
        
        /***
        if (filterDescr != nil){
            log.verbose("Found:\(filterDescr?.key)")
        } else {
            log.verbose("!!! Filter not found:\(name) !!!")
        }
        ***/
        return filterDescr
    }
}

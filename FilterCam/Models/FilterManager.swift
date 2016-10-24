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
fileprivate var _categoryList:[FilterCategoryType] = [FilterCategoryType.none,
                                          FilterCategoryType.quickSelect,
                                          FilterCategoryType.basicAdjustments,
                                          FilterCategoryType.imageProcessing,
                                          FilterCategoryType.blendModes,
                                          FilterCategoryType.visualEffects,
                                          FilterCategoryType.presets,
                                          FilterCategoryType.drawing,
                                          FilterCategoryType.blurs]

// typealias for dictionaries of FilterDescriptors
typealias FilterDictionary = Dictionary<String, FilterDescriptorInterface>

//dictionaries for each category
fileprivate var _quickSelectDictionary: FilterDictionary = [:]
fileprivate var _basicAdjustmentsDictionary: FilterDictionary = [:]
fileprivate var _imageProcessingDictionary: FilterDictionary = [:]
fileprivate var _blendModesDictionary: FilterDictionary = [:]
fileprivate var _visualEffectsDictionary: FilterDictionary = [:]
fileprivate var _presetsDictionary: FilterDictionary = [:]
fileprivate var _drawingDictionary: FilterDictionary = [:]
fileprivate var _blursDictionary: FilterDictionary = [:]

// list of callbacks for change notification
fileprivate var _categoryChangeCallbackList:[()] = []
fileprivate var _filterChangeCallbackList:[()] = []

// enum that lists the available categories
enum FilterCategoryType: String {
    case none             = "No Filters"
    case quickSelect      = "Quick Select"
    case basicAdjustments = "Basic Adjustments"
    case imageProcessing  = "Image Processing"
    case blendModes       = "Blend Modes"
    case visualEffects    = "Visual Effects/Distortions"
    case presets          = "Presets"
    case drawing          = "Sketch/Edge Effects"
    case blurs            = "Blur Effects"
    
    func getDictionary()->FilterDictionary? {
        switch (self){
        
        case .none:
            return nil
        case .quickSelect:
            return _quickSelectDictionary
        case .basicAdjustments:
            return _basicAdjustmentsDictionary
       case .imageProcessing:
            return _imageProcessingDictionary
        case .blendModes:
            return _blendModesDictionary
        case .visualEffects:
            return _visualEffectsDictionary
        case .presets:
            return _presetsDictionary
        case .drawing:
            return _drawingDictionary
        case .blurs:
            return _blursDictionary
        }
    }
    
    func getIndex()->Int{
        switch (self){
        case .none: return 0
        case .quickSelect: return 1
        case .basicAdjustments: return 2
        case .imageProcessing: return 3
        case .blendModes: return 4
        case .visualEffects: return 5
        case .presets: return 6
        case .drawing: return 7
        case .blurs: return 8
        }
    }
}



// SIngleton class that provides access to the categories/filters
// use FilterManager.sharedInstance to get a reference

class FilterManager{
    
    static let sharedInstance = FilterManager() // the actual instance shared by everyone
    static var initDone:Bool = false
    static var currCategory: FilterCategoryType = .quickSelect
    static var currFilterDescriptor: FilterDescriptorInterface? = nil
    static var currFilterKey: String = ""
    static var currIndex:Int = -1
    
    static var categoryChangeNotification = Notification.Name(rawValue:"CategoryChangeNotification")
    static var filterChangeNotification = Notification.Name(rawValue:"FilterChangeNotification")
    static var notificationCenter = NotificationCenter.default
    
    //////////////////////////////////////////////
    //MARK: - Setup/Teardown
    //////////////////////////////////////////////
    
    fileprivate func checkSetup(){
        if (!FilterManager.initDone) {
            FilterManager.initDone = true
            
            // Add filter definitions to the appropriate categories
            populateCategories()
            
            // Need to start somewhere...
            setCurrentCategory(.quickSelect)
        }

    }
    
    func reset(){
        FilterManager.initDone = false
        checkSetup()
    }
    
    fileprivate init(){
        checkSetup()
    }
    
    deinit{
        _categoryChangeCallbackList = []
        _filterChangeCallbackList = []
    }
    
    
    
    //////////////////////////////////////////////
    // MARK: - Accessors
    //////////////////////////////////////////////
    
    open func getCategoryList()->[FilterCategoryType]{
        checkSetup()
        return _categoryList
    }
    
    func getCurrentCategory() -> FilterCategoryType{
        checkSetup()
        return FilterManager.currCategory
    }
    
    func setCurrentCategory(_ category:FilterCategoryType){
        checkSetup()
        if (FilterManager.currCategory != category){
            log.debug("Category set to: \(category.rawValue)")
            FilterManager.currCategory = category
            
            // set current filter to the first filter (alphabetically) in the dictionary
            log.verbose("### CHECK 1")
            let dict = category.getDictionary()
            log.verbose("### CHECK 2")
            if ((dict != nil) && !(dict?.isEmpty)!){
                log.verbose("### CHECK 3")
                var filterList: [String] = []
                filterList = (getFilterList(category))
                log.verbose ("\(filterList.count) items found")
                filterList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
                log.verbose("Setting filter to: \(filterList[0])")
                setCurrentFilterKey(filterList[0])
            } else {
                log.verbose("### CHECK 4")
                log.debug("Dictionary empty: \(category)")
                setCurrentFilterDescriptor(nil)
            }
            log.verbose("### CHECK 5")
           
            
            // notify clients
            issueCategoryChangeNotification()
        }
    }
    
    func getCurrentFilterDescriptor() -> FilterDescriptorInterface?{
        checkSetup()
        return FilterManager.currFilterDescriptor
    }
    
    func setCurrentFilterDescriptor(_ descriptor: FilterDescriptorInterface?){
        checkSetup()
        if (FilterManager.currFilterDescriptor?.key != descriptor?.key){
            FilterManager.currFilterDescriptor = descriptor
            if (descriptor != nil){
                FilterManager.currFilterKey = (descriptor?.key)!
            } else {
                FilterManager.currFilterKey = ""
            }

            log.debug("Filter changed to: \(descriptor?.key)")
            
            // Notify clients
            issueFilterChangeNotification()
        }
    }
    
    func getCurrentFilterKey() -> String{
        checkSetup()
        return FilterManager.currFilterKey
    }
    
    func setCurrentFilterKey(_ key:String) {
        checkSetup()
        log.verbose("Key: \(key)")
        FilterManager.currFilterKey = key
        setCurrentFilterDescriptor(getFilterDescriptor(FilterManager.currCategory, name:FilterManager.currFilterKey))
    }
    
    func getCurrentFilter() -> FilterDescriptorInterface? {
        checkSetup()
        
        guard (FilterManager.currFilterKey != "") else {
            return nil
        }
        
        return getFilterDescriptor(FilterManager.currCategory, name:FilterManager.currFilterKey)
    }
    
    
    open func getFilterList(_ category:FilterCategoryType)->[String]{
        checkSetup()
        let dict = category.getDictionary()
        if ((dict == nil) || (dict?.isEmpty)!){
            log.verbose("Empty category")
            return []
        } else {
            return Array(category.getDictionary()!.keys)
        }
    }
    
    
    
    // get the filter descriptor for the supplied category & filter type
    open func getFilterDescriptor(_ category:FilterCategoryType, name:String)->FilterDescriptorInterface? {
        
        var dict: FilterDictionary?
        var filterDescr: FilterDescriptorInterface?
        
        checkSetup()
        
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

    
    
    //////////////////////////////////////////////
    // MARK: - Callback/Notification methods
    //////////////////////////////////////////////
    
    
    open func setCategoryChangeNotification(callback: ()) {
        if ((callback) != nil){
            _categoryChangeCallbackList.append(callback)
        }
    }
    
    
    open func setFilterChangeNotification(callback: ()) {
        if ((callback) != nil){
            _filterChangeCallbackList.append(callback)
        }
    }
    
    func issueCategoryChangeNotification(){
        if (_categoryChangeCallbackList.count>0){
            log.debug("Issuing \(_categoryChangeCallbackList.count) CategoryChange callbacks")
            for cb in _categoryChangeCallbackList {
                cb
            }
        }
    }
    
    func issueFilterChangeNotification(){
        if (_filterChangeCallbackList.count>0){
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                log.debug("Issuing \(_categoryChangeCallbackList.count) FilterChange callbacks")
                for cb in _filterChangeCallbackList {
                    cb
                }
            }
        }
    }
    
    //////////////////////////////////////////////
    // MARK: - Category/Filter Assignments
    //////////////////////////////////////////////
    
    func populateCategories(){
        
        //var dict: FilterDictionary?
        
            log.verbose("populateCategories() - Loading Dictionaries...")
            //TODO: load from some kind of configuration file?
            
            // Quick Select
            //TEMP: populate with some filters, but this should really be done by the user (and saved/restored)
            
            _quickSelectDictionary["BulgeDistortion"] = BulgeDistortionDescriptor()
            _quickSelectDictionary["Crosshatch"] = CrosshatchDescriptor()
            _quickSelectDictionary["Emboss"] = EmbossDescriptor()
            _quickSelectDictionary["GlassSphereRefraction"] = GlassSphereRefractionDescriptor()
            _quickSelectDictionary["PolarPixellate"] = PolarPixellateDescriptor()
            _quickSelectDictionary["PolkaDot"] = PolkaDotDescriptor()
            _quickSelectDictionary["Posterize"] = PosterizeDescriptor()
            _quickSelectDictionary["Sketch"] = SketchDescriptor()
            _quickSelectDictionary["Solarize"] = SolarizeDescriptor()
            _quickSelectDictionary["ThresholdSketch"] = ThresholdSketchDescriptor()
            _quickSelectDictionary["Toon"] = ToonDescriptor()
            _quickSelectDictionary["FalseColor"] = FalseColorDescriptor()
            _quickSelectDictionary["ThresholdSobelEdgeDetection"] = ThresholdSobelEdgeDetectionDescriptor()
            _quickSelectDictionary["Laplacian"] = LaplacianDescriptor()
            _quickSelectDictionary["ColorInversion"] = ColorInversionDescriptor()
            _quickSelectDictionary["Pixellate"] = PixellateDescriptor()
            _quickSelectDictionary["Luminance"] = LuminanceDescriptor()
            _quickSelectDictionary["Halftone"] = HalftoneDescriptor()
            _quickSelectDictionary["SmoothToon"] = SmoothToonDescriptor()
            _quickSelectDictionary["SoftElegance"] = SoftEleganceDescriptor()
            _quickSelectDictionary["CGAColorspace"] = CGAColorspaceDescriptor()
            _quickSelectDictionary["PinchDistortion"] = PinchDistortionDescriptor()
            _quickSelectDictionary["SwirlDistortion"] = SwirlDistortionDescriptor()
            //_quickSelectDictionary[""] = Descriptor()
            
            // move these to different categories once tested:
          

            //dumpDictionary(_quickSelectDictionary)//DEBUG
            
            // Basic Adjustments
            
            _basicAdjustmentsDictionary["Saturation"] = SaturationDescriptor()
            _basicAdjustmentsDictionary["Warmth"] = WarmthDescriptor()
            _basicAdjustmentsDictionary["WhiteBalance"] = WhiteBalanceDescriptor()
            _basicAdjustmentsDictionary["Brightness"] = BrightnessDescriptor()
            _basicAdjustmentsDictionary["Contrast"] = ContrastDescriptor()
            _basicAdjustmentsDictionary["UnsharpMask"] = UnsharpMaskDescriptor()
            _basicAdjustmentsDictionary["Exposure"] = ExposureDescriptor()
            _basicAdjustmentsDictionary["Sharpen"] = SharpenDescriptor()
            _basicAdjustmentsDictionary["Crop"] = CropDescriptor()
            _basicAdjustmentsDictionary["Gamma"] = GammaDescriptor()
            _basicAdjustmentsDictionary["Vibrance"] = VibranceDescriptor()
            _basicAdjustmentsDictionary["Highlights"] = HighlightsDescriptor()
            //_basicAdjustmentsDictionary[""] = Descriptor()
            
            
            // Image Processing
            _imageProcessingDictionary["Vignette"] = VignetteDescriptor()
            _imageProcessingDictionary["FalseColor"] = FalseColorDescriptor()
            _imageProcessingDictionary["Hue"] = HueDescriptor()
            _imageProcessingDictionary["RGB"] = RGBDescriptor()
            _imageProcessingDictionary["Rotate"] = RotateDescriptor()
            _imageProcessingDictionary["Median"] = MedianDescriptor()
            _imageProcessingDictionary["Opening"] = OpeningFilterDescriptor()
            _imageProcessingDictionary["Closing"] = ClosingFilterDescriptor()
            _imageProcessingDictionary["OpacityAdjustment"] = OpacityAdjustmentDescriptor()
            _imageProcessingDictionary["ChromaKeying"] = ChromaKeyingDescriptor()
            _imageProcessingDictionary["LowPassFilter"] = LowPassFilterDescriptor()
            _imageProcessingDictionary["HighPassFilter"] = HighPassFilterDescriptor()
            _imageProcessingDictionary["Haze"] = HazeDescriptor()
            //_imageProcessingDictionary[""] = Decsriptor
            
            // Blend Modes
            _blendModesDictionary["AddBlend"] = AddBlendDescriptor()
            _blendModesDictionary["AlphaBlend"] = AlphaBlendDescriptor()
            _blendModesDictionary["ColorDodgeBlend"] = ColorDodgeBlendDescriptor()
            _blendModesDictionary["ChromaKeyBlend"] = ChromaKeyBlendDescriptor()
            _blendModesDictionary["ColorBlend"] = ColorBlendDescriptor()
            _blendModesDictionary["ColorBurnBlend"] = ColorBurnBlendDescriptor()
            _blendModesDictionary["ColorDodgeBlend"] = ColorDodgeBlendDescriptor()
            _blendModesDictionary["DarkenBlend"] = DarkenBlendDescriptor()
            _blendModesDictionary["DifferenceBlend"] = DifferenceBlendDescriptor()
            _blendModesDictionary["DissolveBlend"] = DissolveBlendDescriptor()
            _blendModesDictionary["DivideBlend"] = DivideBlendDescriptor()
            _blendModesDictionary["ExclusionBlend"] = ExclusionBlendDescriptor()
            _blendModesDictionary["HardLightBlend"] = HardLightBlendDescriptor()
            _blendModesDictionary["HueBlend"] = HueBlendDescriptor()
            _blendModesDictionary["LightenBlend"] = LightenBlendDescriptor()
            _blendModesDictionary["LinearBurnBlend"] = LinearBurnBlendDescriptor()
            _blendModesDictionary["LuminosityBlend"] = LuminosityBlendDescriptor()
            _blendModesDictionary["MultiplyBlend"] = MultiplyBlendDescriptor()
            _blendModesDictionary["NormalBlend"] = NormalBlendDescriptor()
            _blendModesDictionary["OverlayBlend"] = OverlayBlendDescriptor()
            _blendModesDictionary["SaturationBlend"] = SaturationBlendDescriptor()
            _blendModesDictionary["ScreenBlend"] = ScreenBlendDescriptor()
            _blendModesDictionary["SoftLightBlend"] = SoftLightBlendDescriptor()
            _blendModesDictionary["SourceOverBlend"] = SourceOverBlendDescriptor()
            _blendModesDictionary["SubtractBlend"] = SubtractBlendDescriptor()
            //_blendModesDictionary[""] = Decsriptor
            
            // Visual Effects
            _visualEffectsDictionary["BulgeDistortion"] = BulgeDistortionDescriptor()
            _visualEffectsDictionary["GlassSphereRefraction"] = GlassSphereRefractionDescriptor()
            _visualEffectsDictionary["PolarPixellate"] = PolarPixellateDescriptor()
            _visualEffectsDictionary["PolkaDot"] = PolkaDotDescriptor()
            _visualEffectsDictionary["FalseColor"] = FalseColorDescriptor()
            _visualEffectsDictionary["Pixellate"] = PixellateDescriptor()
            _visualEffectsDictionary["TiltShift"] = TiltShiftDescriptor()
            _visualEffectsDictionary["HighlightShadowTint"] = HighlightAndShadowTintDescriptor()
            _visualEffectsDictionary["ChromaKeying"] = ChromaKeyingDescriptor()
            _visualEffectsDictionary["SphereRefraction"] = SphereRefractionDescriptor()
            _visualEffectsDictionary["PinchDistortion"] = PinchDistortionDescriptor()
            _visualEffectsDictionary["SwirlDistortion"] = SwirlDistortionDescriptor()
            _visualEffectsDictionary["SphereRefraction"] = SphereRefractionDescriptor()
            //_visualEffectsDictionary[""] = Decsriptor
            
            // Presets
            _presetsDictionary["Monochrome"] = MonochromeDescriptor()
            _presetsDictionary["Sepia"] = SepiaDescriptor()
            _presetsDictionary["ColorInversion"] = ColorInversionDescriptor()
            _presetsDictionary["MissEtikate"] = MissEtikateDescriptor()
            _presetsDictionary["Amatorka"] = AmatorkaDescriptor()
            _presetsDictionary["Grayscale"] = GrayscaleDescriptor()
            _presetsDictionary["Luminance"] = LuminanceDescriptor()
            _presetsDictionary["SoftElegance"] = SoftEleganceDescriptor()
            _presetsDictionary["CGAColorspace"] = CGAColorspaceDescriptor()
            //_presetsDictionary[""] = Decsriptor
            
            // Drawing/Sketches/Edge Detection
            _drawingDictionary["Crosshatch"] = CrosshatchDescriptor()
            _drawingDictionary["Emboss"] = EmbossDescriptor()
            _drawingDictionary["LuminanceThreshold"] = LuminanceThresholdDescriptor()
            _drawingDictionary["Sketch"] = SketchDescriptor()
            _drawingDictionary["ThresholdSketch"] = ThresholdSketchDescriptor()
            _drawingDictionary["Toon"] = ToonDescriptor()
            _drawingDictionary["Kuwahara"] = KuwaharaDescriptor()
            _drawingDictionary["KuwaharaRadius3"] = KuwaharaRadius3Descriptor()
            _drawingDictionary["AverageLuminanceThreshold"] = AverageLuminanceThresholdDescriptor()
            _drawingDictionary["AdaptiveThreshold"] = AdaptiveThresholdDescriptor()
            _drawingDictionary["SmoothToon"] = SmoothToonDescriptor()
            //_drawingDictionary[""] = Decsriptor
            
            
            // Blurs
            _blursDictionary["ZoomBlur"] = ZoomBlurDescriptor()
            _blursDictionary["BilateralBlur"] = BilateralBlurDescriptor()
            _blursDictionary["GaussianBlur"] = GaussianBlurDescriptor()
            _blursDictionary["SingleComponentGaussianBlur"] = SingleComponentGaussianBlurDescriptor()
            _blursDictionary["BoxBlur"] = BoxBlurDescriptor()
            //_blursDictionary[""] = Decsriptor
            
        
    }
    
    
    // dump the keys amd filter names contained in the supplied dictionary
    func dumpDictionary(_ dictionary:FilterDictionary?){
        var fdi: FilterDescriptorInterface
        for key  in (dictionary?.keys)! {
            fdi = (dictionary?[key])!
            log.debug("key:\(key) filter:\(fdi.key)")
            
        }
    }
}

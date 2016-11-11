//
//  FilterManager
//  FilterCam
//
//  Created by Philip Price on 10/5/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage

// class that manages the list of available filters and groups them into categories



// SIngleton class that provides access to the categories/filters
// use FilterManager.sharedInstance to get a reference

class FilterManager{
    
    static let sharedInstance = FilterManager() // the actual instance shared by everyone
    
    
    // types/constants for identfying and processing the category
    
    static let quickSelectIndex      = 0
    static let basicAdjustmentsIndex = 1
    static let blendModesIndex       = 2
    static let visualEffectsIndex    = 3
    static let presetsIndex          = 4
    static let drawingIndex          = 5
    static let blursIndex            = 6
    static let imageProcessingIndex  = 7
    static let maxIndex = 7
    
    
    
    // enum that lists the available categories
    enum CategoryType: String {
        //case none             = "No Filters"
        case quickSelect      = "Quick Select"
        case basicAdjustments = "Basic Adjustments"
        case blendModes       = "Blend Modes"
        case visualEffects    = "Visual Effects"
        case presets          = "Presets"
        case drawing          = "Sketch Effects"
        case blurs            = "Blur Effects"
        case imageProcessing  = "Image Processing"
        
        func getFilterList()->[String] {
            
            switch (self){
                
            case .quickSelect:
                return FilterManager._quickSelectList
            case .basicAdjustments:
                return FilterManager._basicAdjustmentsList
            case .blendModes:
                return FilterManager._blendModesList
            case .visualEffects:
                return FilterManager._visualEffectsList
            case .presets:
                return FilterManager._presetsList
            case .drawing:
                return FilterManager._drawingList
            case .blurs:
                return FilterManager._blursList
            case .imageProcessing:
                return FilterManager._imageProcessingList
            }
            
            
            /***
             return FilterManager._filterAssignments[self.getIndex()]
             ***/
        }
        
        func getIndex()->Int{
            switch (self){
            case .quickSelect:      return quickSelectIndex
            case .basicAdjustments: return basicAdjustmentsIndex
            case .blendModes:       return blendModesIndex
            case .visualEffects:    return visualEffectsIndex
            case .presets:          return presetsIndex
            case .drawing:          return drawingIndex
            case .blurs:            return blursIndex
            case .imageProcessing:  return imageProcessingIndex
            }
        }
        
        func contains(_ key:String)->Bool{
            return self.getFilterList().contains(key)
        }
    }
    
    static func getCategoryFromIndex(_ index:Int)->CategoryType{
        switch (index){
        case FilterManager.quickSelectIndex:      return .quickSelect
        case FilterManager.basicAdjustmentsIndex: return .basicAdjustments
        case FilterManager.blendModesIndex:       return .blendModes
        case FilterManager.visualEffectsIndex:    return .visualEffects
        case FilterManager.presetsIndex:          return .presets
        case FilterManager.drawingIndex:          return .drawing
        case FilterManager.blursIndex:            return .blurs
        case FilterManager.imageProcessingIndex:  return .imageProcessing
        default:                                  return .quickSelect
        }
    }

    fileprivate static var initDone:Bool = false
    fileprivate static var currCategory: CategoryType = .imageProcessing
    fileprivate static var currFilterDescriptor: FilterDescriptorInterface? = nil
    fileprivate static var currFilterKey: String = ""
    fileprivate static var currIndex:Int = -1
    
    fileprivate static var categoryChangeNotification = Notification.Name(rawValue:"CategoryChangeNotification")
    fileprivate static var filterChangeNotification = Notification.Name(rawValue:"FilterChangeNotification")
    fileprivate static var notificationCenter = NotificationCenter.default

    static let sortClosure = { (value1: String, value2: String) -> Bool in return value1 < value2 }
    
    //////////////////////////////////////////////
    //MARK: - Category/Filter "Database"
    //////////////////////////////////////////////
    
    // The list of Categories
    fileprivate static var _categoryList:[CategoryType] = [CategoryType.quickSelect,
                                                           CategoryType.basicAdjustments,
                                                           CategoryType.imageProcessing,
                                                           CategoryType.blendModes,
                                                           CategoryType.visualEffects,
                                                           CategoryType.presets,
                                                           CategoryType.drawing,
                                                           CategoryType.blurs]
    
    // typealias for dictionaries of FilterDescriptors
    typealias FilterDictionary = Dictionary<String, FilterDescriptorInterface>
    
    fileprivate static var _filterDictionary:[String:FilterDescriptorInterface?] = [:]
    fileprivate static var _renderViewDictionary:[String:RenderView?] = [:]
    
    //fileprivate var _filterAssignments: [[String]] = [[], [], [], [], [], [], [], [], []]
    
    //dictionaries for each category
    fileprivate static var _quickSelectList = [String]()
    fileprivate static var _basicAdjustmentsList: [String] = []
    fileprivate static var _imageProcessingList: [String] = []
    fileprivate static var _blendModesList: [String] = []
    fileprivate static var _visualEffectsList: [String] = []
    fileprivate static var _presetsList: [String] = []
    fileprivate static var _drawingList: [String] = []
    fileprivate static var _blursList: [String] = []
    
    
    // list of callbacks for change notification
    fileprivate static var _categoryChangeCallbackList:[()] = []
    fileprivate static var _filterChangeCallbackList:[()] = []
    
    //////////////////////////////////////////////
    //MARK: - Setup/Teardown
    //////////////////////////////////////////////
    
    fileprivate static func checkSetup(){
        if (!FilterManager.initDone) {
            FilterManager.initDone = true
            
            // initArrays()
            
            // create the filter instances
            createFilters()
            
            // Add filter definitions to the appropriate categories
            populateCategories()
            
            // sort the lists
            sortLists()
            
            // Need to start somewhere...
            FilterManager.currCategory = .quickSelect
        }
        
    }
    
    private static func reset(){
        FilterManager.initDone = false
        FilterManager.checkSetup()
    }
    
    fileprivate init(){
        FilterManager.checkSetup()
    }
    
    deinit{
        FilterManager._categoryChangeCallbackList = []
        FilterManager._filterChangeCallbackList = []
    }
    
    
    //////////////////////////////////////////////
    // MARK: - Category-related Accessors
    //////////////////////////////////////////////
    
    open func getCategoryList()->[CategoryType]{
        FilterManager.checkSetup()
        return FilterManager._categoryList
    }
    
    func getCategoryCount(_ category:CategoryType)->Int {
        FilterManager.checkSetup()
        let list = category.getFilterList()
        return list.count
    }
    
    func getCurrentCategory() -> CategoryType{
        FilterManager.checkSetup()
        return FilterManager.currCategory
        
    }
    
    func setCurrentCategory(_ category:CategoryType){
        FilterManager.checkSetup()
        if (FilterManager.currCategory != category){
            log.debug("Category set to: \(category.rawValue)")
            FilterManager.currCategory = category
            
            // set current filter to the first filter (alphabetically) in the dictionary
            let list = category.getFilterList()

            if (list.count>0){
                log.verbose ("\(list.count) items found")
                log.verbose("Setting filter to: \(list[0])")
                setCurrentFilterKey(list[0])
            } else {
                log.debug("List empty: \(category)")
                setCurrentFilterDescriptor(nil)
            }
            
            // notify clients
            issueCategoryChangeNotification()
        }
    }
    
    
    
    //////////////////////////////////////////////
    // MARK: - Category-related Accessors
    //////////////////////////////////////////////
    
    
    
    func getCurrentFilterDescriptor() -> FilterDescriptorInterface?{
        FilterManager.checkSetup()
        return FilterManager.currFilterDescriptor
    }
    
    func setCurrentFilterDescriptor(_ descriptor: FilterDescriptorInterface?){
        FilterManager.checkSetup()
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
        FilterManager.checkSetup()
        return FilterManager.currFilterKey
    }
    
    func setCurrentFilterKey(_ key:String) {
        FilterManager.checkSetup()
        log.verbose("Key: \(key)")
        FilterManager.currFilterKey = key
        setCurrentFilterDescriptor(getFilterDescriptor(key:FilterManager.currFilterKey))
    }
    
    
    private static var selectedFilter:String = ""
    
    func setSelectedFilter(key: String){
        FilterManager.checkSetup()
        FilterManager.selectedFilter = key
        log.verbose("Selected filter: \(FilterManager.selectedFilter)")
    }
    
    func getSelectedFilter()->String{
        FilterManager.checkSetup()
        return FilterManager.selectedFilter
    }
    

    
    open func getFilterList(_ category:CategoryType)->[String]?{
        FilterManager.checkSetup()
        return category.getFilterList()
    }
    
    
    
    // get the filter descriptor for the supplied filter type
    open func getFilterDescriptor(key:String)->FilterDescriptorInterface? {
        
        var filterDescr: FilterDescriptorInterface? = nil
        
        FilterManager.checkSetup()
        
        let index = FilterManager._filterDictionary.index(forKey: key)
        if (index != nil){
            filterDescr = (FilterManager._filterDictionary[key])!
            //log.verbose("Found key:\((filterDescr?.key)!) addr:\(filterAddress(filterDescr))")
        } else {
            log.error("Filter (\(key)) not found")
        }
        
        return filterDescr
    }
    
    
    func addFilterDescriptor(category:CategoryType, key:String, descriptor:FilterDescriptorInterface?){
        // add to the filter list
        FilterManager._filterDictionary[key] = descriptor
        
        //add to category list
        var list = category.getFilterList()
        if (!(list.contains(key))){
            list.append(key)
            FilterManager.sortLists()
        }
    }
    
    func removeFilterDescriptor(category:CategoryType, key:String){
        var list = category.getFilterList()
        if let index = list.index(of: key) {
            list.remove(at: index)
            log.verbose ("Key (\(key)) removed from category (\(category))")
        }else {
            log.warning("Key (\(key)) not present for category (\(category))")
        }
    }
    
    func filterAddress(_ descriptor:FilterDescriptorInterface?)->String{
        var addr:String
        guard (descriptor != nil) else {
            return "NIL"
        }
        
        if (descriptor?.filter != nil){
            addr = Utilities.addressOf(descriptor?.filter) + " (filter)"
        } else  if (descriptor?.filterGroup != nil){
            addr = Utilities.addressOf(descriptor?.filterGroup) + " (group)"
        } else {
            addr = "INVALID"
        }
        return addr
    }
    
    
    
    func getRenderView(key:String)->RenderView?{
        var renderView: RenderView? = nil
        
        FilterManager.checkSetup()
        
        let index = FilterManager._renderViewDictionary.index(forKey: key)
        if (index != nil){
            renderView = (FilterManager._renderViewDictionary[key])!
        } else {
            log.error("RenderView for key:(\(key)) not found")
        }
        
        return renderView
    }
    //////////////////////////////////////////////
    // MARK: - Callback/Notification methods
    //////////////////////////////////////////////
    
    
    open func setCategoryChangeNotification(callback: ()) {
        FilterManager._categoryChangeCallbackList.append(callback)
    }
    
    
    open func setFilterChangeNotification(callback: ()) {
        FilterManager._filterChangeCallbackList.append(callback)
    }
    
    func issueCategoryChangeNotification(){
        if (FilterManager._categoryChangeCallbackList.count>0){
            log.debug("Issuing \(FilterManager._categoryChangeCallbackList.count) CategoryChange callbacks (->\(FilterManager.currCategory.rawValue))")
            for cb in FilterManager._categoryChangeCallbackList {
                cb
            }
        }
    }
    
    func issueFilterChangeNotification(){
        if (FilterManager._filterChangeCallbackList.count>0){
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                log.debug("Issuing \(FilterManager._categoryChangeCallbackList.count) FilterChange callbacks")
                for cb in FilterManager._filterChangeCallbackList {
                    cb
                }
            }
        }
    }
    
    //////////////////////////////////////////////
    // MARK: - Category/Filter Assignments
    //////////////////////////////////////////////
    
    static func makeFilter(key: String, descriptor:FilterDescriptorInterface){
        if (FilterManager._filterDictionary[key] != nil){
            log.warning("Duplicate key: \(key)")
        }
        
        if (key != descriptor.key){
            log.warning("!!! Key/Index mismatch, check configuration for filter: \(key) or: \(descriptor.key)) ?!")
        }
        
        FilterManager._filterDictionary[key] = descriptor
        FilterManager._renderViewDictionary[key] = RenderView()
        
        //log.debug("Add key:\(key), address: \(filterAddress(descriptor))")
        
    }
    
    static func createFilters(){
        log.verbose("Creating Filters...")
        
        // NOTE: I try to keep these in alphabetical order just because it's easier to compare to a directory listing (when adding/deleting filters)
        
        //makeFilter(key: "",  descriptor: Descriptor())
        
        FilterManager._filterDictionary = [:]
        FilterManager._renderViewDictionary = [:]
        
        makeFilter(key: "AdaptiveThreshold", descriptor: AdaptiveThresholdDescriptor())
        makeFilter(key: "AddBlend", descriptor: AddBlendDescriptor())
        makeFilter(key: "AlphaBlend", descriptor: AlphaBlendDescriptor())
        makeFilter(key: "Amatorka", descriptor: AmatorkaDescriptor())
        makeFilter(key: "AverageLuminanceThreshold", descriptor: AverageLuminanceThresholdDescriptor())
        makeFilter(key: "BilateralBlur", descriptor: BilateralBlurDescriptor())
        makeFilter(key: "BoxBlur", descriptor: BoxBlurDescriptor())
        makeFilter(key: "Brightness", descriptor: BrightnessDescriptor())
        makeFilter(key: "BulgeDistortion", descriptor: BulgeDistortionDescriptor())
        makeFilter(key: "CGAColorspace", descriptor: CGAColorspaceDescriptor())
        makeFilter(key: "CannyEdgeDetection", descriptor: CannyEdgeDetectionDescriptor())
        makeFilter(key: "ChromaKeyBlend", descriptor: ChromaKeyBlendDescriptor())
        makeFilter(key: "ChromaKeying", descriptor: ChromaKeyingDescriptor())
        makeFilter(key: "ClosingFilter", descriptor: ClosingFilterDescriptor())
        makeFilter(key: "ColorBlend", descriptor: ColorBlendDescriptor())
        makeFilter(key: "ColorBurnBlend", descriptor: ColorBurnBlendDescriptor())
        makeFilter(key: "ColorDodgeBlend", descriptor: ColorDodgeBlendDescriptor())
        makeFilter(key: "ColorInversion", descriptor: ColorInversionDescriptor())
        makeFilter(key: "Contrast", descriptor: ContrastDescriptor())
        makeFilter(key: "Crop", descriptor: CropDescriptor())
        makeFilter(key: "Crosshatch", descriptor: CrosshatchDescriptor())
        makeFilter(key: "DarkenBlend", descriptor: DarkenBlendDescriptor())
        makeFilter(key: "DifferenceBlend", descriptor: DifferenceBlendDescriptor())
        makeFilter(key: "DissolveBlend", descriptor: DissolveBlendDescriptor())
        makeFilter(key: "DivideBlend", descriptor: DivideBlendDescriptor())
        makeFilter(key: "Emboss", descriptor: EmbossDescriptor())
        makeFilter(key: "ExclusionBlend", descriptor: ExclusionBlendDescriptor())
        makeFilter(key: "Exposure", descriptor: ExposureDescriptor())
        makeFilter(key: "FalseColor", descriptor: FalseColorDescriptor())
        makeFilter(key: "Gamma", descriptor: GammaDescriptor())
        makeFilter(key: "GaussianBlur", descriptor: GaussianBlurDescriptor())
        makeFilter(key: "GlassSphereRefraction", descriptor: GlassSphereRefractionDescriptor())
        makeFilter(key: "Grayscale", descriptor: GrayscaleDescriptor())
        makeFilter(key: "Halftone", descriptor: HalftoneDescriptor())
        makeFilter(key: "HardLightBlend", descriptor: HardLightBlendDescriptor())
        makeFilter(key: "HarrisCornerDetector", descriptor: HarrisCornerDetectorDescriptor())
        makeFilter(key: "Haze", descriptor: HazeDescriptor())
        makeFilter(key: "HighPassFilter", descriptor: HighPassFilterDescriptor())
        makeFilter(key: "HighlightShadowTint", descriptor: HighlightAndShadowTintDescriptor())
        makeFilter(key: "Highlights", descriptor: HighlightsDescriptor())
        makeFilter(key: "HueBlend", descriptor: HueBlendDescriptor())
        makeFilter(key: "Hue", descriptor: HueDescriptor())
        makeFilter(key: "Kuwahara", descriptor: KuwaharaDescriptor())
        makeFilter(key: "KuwaharaRadius3", descriptor: KuwaharaRadius3Descriptor())
        makeFilter(key: "Laplacian", descriptor: LaplacianDescriptor())
        makeFilter(key: "LevelsAdjustment", descriptor: LevelsAdjustmentDescriptor())
        makeFilter(key: "LightenBlend", descriptor: LightenBlendDescriptor())
        makeFilter(key: "LinearBurnBlend", descriptor: LinearBurnBlendDescriptor())
        makeFilter(key: "LowPassFilter", descriptor: LowPassFilterDescriptor())
        makeFilter(key: "Luminance", descriptor: LuminanceDescriptor())
        makeFilter(key: "LuminanceThreshold", descriptor: LuminanceThresholdDescriptor())
        makeFilter(key: "LuminosityBlend", descriptor: LuminosityBlendDescriptor())
        makeFilter(key: "Median", descriptor: MedianDescriptor())
        makeFilter(key: "MissEtikate", descriptor: MissEtikateDescriptor())
        makeFilter(key: "Monochrome", descriptor: MonochromeDescriptor())
        makeFilter(key: "MultiplyBlend", descriptor: MultiplyBlendDescriptor())
        makeFilter(key: "NobleCornerDetector", descriptor: NobleCornerDetectorDescriptor())
        makeFilter(key: "NormalBlend", descriptor: NormalBlendDescriptor())
        makeFilter(key: "OpacityAdjustment", descriptor: OpacityAdjustmentDescriptor())
        makeFilter(key: "OpeningFilter", descriptor: OpeningFilterDescriptor())
        makeFilter(key: "OverlayBlend", descriptor: OverlayBlendDescriptor())
        makeFilter(key: "PinchDistortion", descriptor: PinchDistortionDescriptor())
        makeFilter(key: "Pixellate", descriptor: PixellateDescriptor())
        makeFilter(key: "PolarPixellate", descriptor: PolarPixellateDescriptor())
        makeFilter(key: "PolkaDot", descriptor: PolkaDotDescriptor())
        makeFilter(key: "Posterize", descriptor: PosterizeDescriptor())
        makeFilter(key: "PrewittEdgeDetection", descriptor: PrewittEdgeDetectionDescriptor())
        makeFilter(key: "RGB", descriptor: RGBDescriptor())
        makeFilter(key: "Rotate", descriptor: RotateDescriptor())
        makeFilter(key: "SaturationBlend", descriptor: SaturationBlendDescriptor())
        makeFilter(key: "Saturation", descriptor: SaturationDescriptor())
        makeFilter(key: "ScreenBlend", descriptor: ScreenBlendDescriptor())
        makeFilter(key: "Sepia", descriptor: SepiaDescriptor())
        makeFilter(key: "Sharpen", descriptor: SharpenDescriptor())
        makeFilter(key: "ShiTomasiFeatureDetector", descriptor: ShiTomasiFeatureDetectorDescriptor())
        makeFilter(key: "SingleComponentGaussianBlur", descriptor: SingleComponentGaussianBlurDescriptor())
        makeFilter(key: "Sketch", descriptor: SketchDescriptor())
        makeFilter(key: "SmoothToon", descriptor: SmoothToonDescriptor())
        makeFilter(key: "SobelEdgeDetection", descriptor: SobelEdgeDetectionDescriptor())
        makeFilter(key: "SoftElegance", descriptor: SoftEleganceDescriptor())
        makeFilter(key: "SoftLightBlend", descriptor: SoftLightBlendDescriptor())
        makeFilter(key: "Solarize", descriptor: SolarizeDescriptor())
        makeFilter(key: "SourceOverBlend", descriptor: SourceOverBlendDescriptor())
        makeFilter(key: "SphereRefraction", descriptor: SphereRefractionDescriptor())
        makeFilter(key: "SubtractBlend", descriptor: SubtractBlendDescriptor())
        makeFilter(key: "SwirlDistortion", descriptor: SwirlDistortionDescriptor())
        makeFilter(key: "ThresholdSketch", descriptor: ThresholdSketchDescriptor())
        makeFilter(key: "ThresholdSobelEdgeDetection", descriptor: ThresholdSobelEdgeDetectionDescriptor())
        makeFilter(key: "TiltShift", descriptor: TiltShiftDescriptor())
        makeFilter(key: "Toon", descriptor: ToonDescriptor())
        makeFilter(key: "UnsharpMask", descriptor: UnsharpMaskDescriptor())
        makeFilter(key: "Vibrance", descriptor: VibranceDescriptor())
        makeFilter(key: "Vignette", descriptor: VignetteDescriptor())
        makeFilter(key: "Warmth", descriptor: WarmthDescriptor())
        makeFilter(key: "WhiteBalance", descriptor: WhiteBalanceDescriptor())
        makeFilter(key: "ZoomBlur", descriptor: ZoomBlurDescriptor())
    }
    
    
    
    func addToCategory(_ category:CategoryType, key:String){
        if (FilterManager._filterDictionary.index(forKey: key) != nil){
            var list = category.getFilterList()
            //var list = list

            if (!((list.contains(key)))){
                log.verbose("Adding key:\(key) for category:\(category)  (\(list.count))")
                //list.append(key)
                list.append(key)
                log.verbose("list: \(list)")
            } else {
                log.warning("Filter:\(key) already member of category: \(category.rawValue)...")
            }
        } else {
            log.warning("Filter:\(key) not defined. NOT added to category: \(category.rawValue)...")
        }
    }
    
    static func populateCategories(){
        
        
        log.verbose("Loading Category Lists...")
        //TODO: load from some kind of configuration file?
        
        // Quick Select
        //TEMP: populate with some filters, but this should really be done by the user (and saved/restored)
        

        // For some reason, I could only get this working with a static assignment
        // Note that filters can be in multiple categories, but they will still be the 'same' filter
        
        FilterManager._quickSelectList = [ "Crosshatch", "Emboss", "Halftone", "SwirlDistortion", "Luminance", "CGAColorspace"  ]
        
        FilterManager._basicAdjustmentsList = [ "Saturation", "Warmth", "WhiteBalance", "Brightness", "Contrast", "UnsharpMask", "Exposure", "Sharpen", "Crop",
                                  "Gamma", "Vibrance", "Highlights", "LevelsAdjustment", "Vignette"]
        
        FilterManager._imageProcessingList = [ "FalseColor", "Hue", "RGB", "Rotate", "Median", "OpeningFilter", "ClosingFilter", "OpacityAdjustment", "ChromaKeying", "Haze" ]
        
        FilterManager._blendModesList = [ "AddBlend", "AlphaBlend", "ChromaKeyBlend", "ColorBlend", "ColorBurnBlend", "ColorDodgeBlend", "DarkenBlend",
                            "DifferenceBlend", "DissolveBlend", "DivideBlend", "ExclusionBlend", "HardLightBlend", "HueBlend", "LightenBlend", "LinearBurnBlend",
                            "LuminosityBlend", "MultiplyBlend", "NormalBlend", "OverlayBlend", "SaturationBlend", "ScreenBlend", "SoftLightBlend", "SourceOverBlend", "SubtractBlend"]
        
        FilterManager._visualEffectsList = [ "BulgeDistortion", "GlassSphereRefraction", "PolarPixellate", "PolkaDot", "FalseColor", "Pixellate", "TiltShift", "HighlightShadowTint",
                               "ChromaKeying", "PinchDistortion", "SwirlDistortion", "SphereRefraction", "Solarize"]
        
        FilterManager._presetsList = [ "Monochrome", "Sepia", "ColorInversion", "MissEtikate", "Amatorka", "Grayscale", "Luminance", "SoftElegance", "CGAColorspace" ]
        
        FilterManager._drawingList = [ "Crosshatch", "Emboss", "LuminanceThreshold", "Sketch", "ThresholdSketch", "Toon", "Kuwahara", "AverageLuminanceThreshold", "AdaptiveThreshold",
                         "SmoothToon", "Posterize", "ThresholdSobelEdgeDetection", "Halftone" ]
        
        FilterManager._blursList = [ "ZoomBlur", "BilateralBlur", "GaussianBlur", "SingleComponentGaussianBlur", "BoxBlur" ]
       
    }
    
    
    static func sortLists(){

        // Sort all category arrays alphabetically
        log.verbose("Sorting lists...")
        FilterManager._quickSelectList.sort(by: sortClosure)
        FilterManager._basicAdjustmentsList.sort(by: sortClosure)
        FilterManager._imageProcessingList.sort(by: sortClosure)
        FilterManager._blendModesList.sort(by: sortClosure)
        FilterManager._visualEffectsList.sort(by: sortClosure)
        FilterManager._presetsList.sort(by: sortClosure)
        FilterManager._drawingList.sort(by: sortClosure)
        FilterManager._blursList.sort(by: sortClosure)
        
    }
    
    // dump the keys amd filter names contained in the supplied dictionary
    func dumpList(_ dictionary:FilterDictionary?){
        var fdi: FilterDescriptorInterface
        for key  in (dictionary?.keys)! {
            fdi = (dictionary?[key])!
            log.debug("key:\(key) filter:\(fdi.key)")
            
        }
    }
}

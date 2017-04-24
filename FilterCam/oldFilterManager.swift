//
//  oldFilterManager
//  FilterCam
//
//  Created by Philip Price on 10/5/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage
import SwiftyJSON

// class that manages the list of available filters and groups them into categories



// SIngleton class that provides access to the categories/filters
// use oldFilterManager.sharedInstance to get a reference

class oldFilterManager{
    
    static let sharedInstance = oldFilterManager() // the actual instance shared by everyone
    
    
    // types/constants for identfying and processing the category
    
    static let quickSelectIndex      = 0
    static let basicAdjustmentsIndex = 1
    static let blendModesIndex       = 2
    static let visualEffectsIndex    = 3
    static let presetsIndex          = 4
    static let drawingIndex          = 5
    static let blursIndex            = 6
    static let monochromeIndex       = 7
    static let colorIndex            = 8
    static let maxIndex              = 8
    
    
    
    // enum that lists the available categories
    enum CategoryType: String {
        //case none             = "No Filters"
        case quickSelect      = "Quick Select"
        case basicAdjustments = "Basic"
        case blendModes       = "Blends"
        case visualEffects    = "Distortions"
        case presets          = "Presets"
        case drawing          = "Drawing"
        case blurs            = "Blurs"
        case monochrome       = "Monochrome"
        case color            = "Color Effects"
        
        func getFilterList()->[String] {
            
            switch (self){
                
            case .quickSelect:
                return oldFilterManager._quickSelectList
            case .basicAdjustments:
                return oldFilterManager._basicAdjustmentsList
            case .blendModes:
                return oldFilterManager._blendModesList
            case .visualEffects:
                return oldFilterManager._visualEffectsList
            case .presets:
                return oldFilterManager._presetsList
            case .drawing:
                return oldFilterManager._drawingList
            case .blurs:
                return oldFilterManager._blursList
            case .monochrome:
                return oldFilterManager._monochromeList
            case .color:
                return oldFilterManager._colorList
            }
            
            
            /***
             return oldFilterManager._filterAssignments[self.getIndex()]
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
            case .monochrome:       return monochromeIndex
            case .color:            return colorIndex
            }
        }
        
        func contains(_ key:String)->Bool{
            return self.getFilterList().contains(key)
        }
    }
    
    static func getCategoryFromIndex(_ index:Int)->CategoryType{
        switch (index){
        case oldFilterManager.quickSelectIndex:      return .quickSelect
        case oldFilterManager.basicAdjustmentsIndex: return .basicAdjustments
        case oldFilterManager.blendModesIndex:       return .blendModes
        case oldFilterManager.visualEffectsIndex:    return .visualEffects
        case oldFilterManager.presetsIndex:          return .presets
        case oldFilterManager.drawingIndex:          return .drawing
        case oldFilterManager.blursIndex:            return .blurs
        case oldFilterManager.monochromeIndex:       return .monochrome
        case oldFilterManager.colorIndex:            return .color
        default:                                  return .quickSelect
        }
    }

    fileprivate static var initDone:Bool = false
    fileprivate static var currCategory: CategoryType = .monochrome
    fileprivate static var currFilterDescriptor: FilterDescriptorInterface? = nil
    fileprivate static var currFilterKey: String = ""
    fileprivate static var currIndex:Int = -1
    
    //fileprivate static var categoryChangeNotification = Notification.Name(rawValue:"CategoryChangeNotification")
    //fileprivate static var filterChangeNotification = Notification.Name(rawValue:"FilterChangeNotification")
    //fileprivate static var notificationCenter = NotificationCenter.default

    static let sortClosure = { (value1: String, value2: String) -> Bool in return value1 < value2 }
    
    //////////////////////////////////////////////
    //MARK: - Category/Filter "Database"
    //////////////////////////////////////////////
    
    // The list of Categories
    fileprivate static var _categoryList:[CategoryType] = [CategoryType.quickSelect,
                                                           CategoryType.basicAdjustments,
                                                           CategoryType.blendModes,
                                                           CategoryType.blurs,
                                                           CategoryType.color,
                                                           CategoryType.visualEffects,
                                                           CategoryType.drawing,
                                                           CategoryType.monochrome,
                                                           CategoryType.presets]
    
    // typealias for dictionaries of FilterDescriptors
    typealias FilterDictionary = Dictionary<String, FilterDescriptorInterface>
    
    fileprivate static var _filterDictionary:[String:FilterDescriptorInterface?] = [:]
    fileprivate static var _renderViewDictionary:[String:RenderView?] = [:]
    
    //fileprivate var _filterAssignments: [[String]] = [[], [], [], [], [], [], [], [], []]
    
    //List for each category
    fileprivate static var _quickSelectList = [String]()
    fileprivate static var _basicAdjustmentsList: [String] = []
    fileprivate static var _monochromeList: [String] = []
    fileprivate static var _blendModesList: [String] = []
    fileprivate static var _visualEffectsList: [String] = []
    fileprivate static var _presetsList: [String] = []
    fileprivate static var _drawingList: [String] = []
    fileprivate static var _blursList: [String] = []
    fileprivate static var _colorList: [String] = []
    
    
    // list of callbacks for change notification
    fileprivate static var _categoryChangeCallbackList:[()] = []
    fileprivate static var _filterChangeCallbackList:[()] = []
    
    //////////////////////////////////////////////
    //MARK: - Setup/Teardown
    //////////////////////////////////////////////
    
    fileprivate static func checkSetup(){
        if (!oldFilterManager.initDone) {
            oldFilterManager.initDone = true
            
            // initArrays()
            
            // create the filter instances
            createFilters()
            
            // Add filter definitions to the appropriate categories
            populateCategories()
            
            // sort the lists
            sortLists()
            
            // Need to start somewhere...
            //oldFilterManager.currCategory = .basicAdjustments
            oldFilterManager.currCategory = .quickSelect
            oldFilterManager.currIndex = 0
            oldFilterManager.currFilterKey = _quickSelectList[oldFilterManager.currIndex]
            oldFilterManager.currFilterDescriptor = _filterDictionary[oldFilterManager.currFilterKey]!
            
            // TEMP DEBUG:
            FilterLibrary.checkSetup()
        }
        
    }
    
    private static func reset(){
        oldFilterManager.initDone = false
        oldFilterManager.checkSetup()
    }
    
    fileprivate init(){
        oldFilterManager.checkSetup()
    }
    
    deinit{
        oldFilterManager._categoryChangeCallbackList = []
        oldFilterManager._filterChangeCallbackList = []
    }
    
    
    //////////////////////////////////////////////
    // MARK: - Category-related Accessors
    //////////////////////////////////////////////
    
    open func getCategoryList()->[CategoryType]{
        oldFilterManager.checkSetup()
        return oldFilterManager._categoryList
    }
    
    func getFilterCount(_ category:CategoryType)->Int {
        oldFilterManager.checkSetup()
        let list = category.getFilterList()
        return list.count
    }
    
    func getCategoryCount()->Int {
        oldFilterManager.checkSetup()
        return oldFilterManager._categoryList.count
    }
    
    func getCurrentCategory() -> CategoryType{
        oldFilterManager.checkSetup()
        return oldFilterManager.currCategory
        
    }
    
    func setCurrentCategory(_ category:CategoryType){
        oldFilterManager.checkSetup()
        if (oldFilterManager.currCategory != category){
            log.debug("Category set to: \(category.rawValue)")
            oldFilterManager.currCategory = category
            
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
    
    
    
    private static var selectedCategory:CategoryType = .quickSelect
    
    func setSelectedCategory(_ category: CategoryType){
        oldFilterManager.checkSetup()
        oldFilterManager.selectedCategory = category
        log.verbose("Selected Category: \(oldFilterManager.selectedCategory)")
    }
    
    func getSelectedCategory()->CategoryType{
        oldFilterManager.checkSetup()
        return oldFilterManager.selectedCategory
    }
  
    
    // 'Index' methods are provided to support previous/next types of navigation
    
    // get the index of the category within the category list.
    open func getCategoryIndex(category:CategoryType)->Int {
        
        oldFilterManager.checkSetup()
        return oldFilterManager._categoryList.index(of: category)!
    }
    
    
    open func getCurrentCategoryIndex()->Int {
        
        return getCategoryIndex(category:oldFilterManager.currCategory)
    }
  
    
    open func getCategory(index: Int) -> CategoryType{
        oldFilterManager.checkSetup()
        var category:CategoryType = .quickSelect
        if ((index >= 0) && (index < oldFilterManager._categoryList.count)){
            category =  oldFilterManager._categoryList[index]
        }
        return category
    }
 
    
    //////////////////////////////////////////////
    // MARK: - Filter-related Accessors
    //////////////////////////////////////////////
    
    
    
    func getCurrentFilterDescriptor() -> FilterDescriptorInterface?{
        oldFilterManager.checkSetup()
        return oldFilterManager.currFilterDescriptor
    }
    
    func setCurrentFilterDescriptor(_ descriptor: FilterDescriptorInterface?){
        oldFilterManager.checkSetup()
        if (oldFilterManager.currFilterDescriptor?.key != descriptor?.key){
            oldFilterManager.currFilterDescriptor = descriptor
            if (descriptor != nil){
                oldFilterManager.currFilterKey = (descriptor?.key)!
            } else {
                oldFilterManager.currFilterKey = ""
            }
            
            log.debug("Filter changed to: \(String(describing: descriptor?.key))")
            
            // Notify clients
            issueFilterChangeNotification()
        }
    }
    func getCurrentFilterKey() -> String{
        oldFilterManager.checkSetup()
        return oldFilterManager.currFilterKey
    }
    
    func setCurrentFilterKey(_ key:String) {
        oldFilterManager.checkSetup()
        log.verbose("Key: \(key)")
        oldFilterManager.currFilterKey = key
        setCurrentFilterDescriptor(getFilterDescriptor(key:oldFilterManager.currFilterKey))
    }
    
    
    private static var selectedFilter:String = ""
    
    func setSelectedFilter(key: String){
        oldFilterManager.checkSetup()
        oldFilterManager.selectedFilter = key
        log.verbose("Selected filter: \(oldFilterManager.selectedFilter)")
    }
    
    func getSelectedFilter()->String{
        oldFilterManager.checkSetup()
        return oldFilterManager.selectedFilter
    }
    

    
    open func getFilterList(_ category:CategoryType)->[String]?{
        oldFilterManager.checkSetup()
        return category.getFilterList()
    }
    
    
    
    // get the filter descriptor for the supplied filter type
    open func getFilterDescriptor(key:String)->FilterDescriptorInterface? {
        
        var filterDescr: FilterDescriptorInterface? = nil
        
        oldFilterManager.checkSetup()
        
        let index = oldFilterManager._filterDictionary.index(forKey: key)
        if (index != nil){
            filterDescr = (oldFilterManager._filterDictionary[key])!
            //log.verbose("Found key:\((filterDescr?.key)!) addr:\(filterAddress(filterDescr))")
        } else {
            log.error("Filter (\(key)) not found")
        }
        
        return filterDescr
    }
    
    
    // 'Index' methods are provided to support previous/next types of navigation
    
    // get the index of the filter within the category list. -1 if not found
    open func getFilterIndex(category:CategoryType, key:String)->Int {
        
        oldFilterManager.checkSetup()
        
        var index = -1
        
        let list = category.getFilterList()
        if (list.contains(key)){
            index = list.index(of: key)!
        }
        
        return index
    }
    
    
    open func getCurrentFilterIndex()->Int {
   
        return getFilterIndex(category:oldFilterManager.currCategory, key:oldFilterManager.currFilterKey)
    }
    
    
    // returns the key based on the index in the list
    open func getFilterKey(category:CategoryType, index:Int)->String {
        
        var key: String = ""
        
        oldFilterManager.checkSetup()
        
        let list = category.getFilterList()
        if ((index>=0) && (index<list.count)){
            key = list[index]
        }
        
        return key
    }
    
    
    func addFilterDescriptor(category:CategoryType, key:String, descriptor:FilterDescriptorInterface?){
        // add to the filter list
        oldFilterManager._filterDictionary[key] = descriptor
        
        //add to category list
        var list = category.getFilterList()
        if (!(list.contains(key))){
            list.append(key)
            oldFilterManager.sortLists()
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
        
        oldFilterManager.checkSetup()
        
        let index = oldFilterManager._renderViewDictionary.index(forKey: key)
        if (index != nil){
            renderView = (oldFilterManager._renderViewDictionary[key])!
        } else {
            log.error("RenderView for key:(\(key)) not found")
        }
        
        return renderView
    }
    //////////////////////////////////////////////
    // MARK: - Callback/Notification methods
    //////////////////////////////////////////////
    
  /***
    open func setCategoryChangeNotification(callback: ()) {
        oldFilterManager._categoryChangeCallbackList.append(callback)
    }
    
    
    open func setFilterChangeNotification(callback: ()) {
        oldFilterManager._filterChangeCallbackList.append(callback)
    }
***/
    
    func issueCategoryChangeNotification(){
        if (oldFilterManager._categoryChangeCallbackList.count>0){
            log.debug("Issuing \(oldFilterManager._categoryChangeCallbackList.count) CategoryChange callbacks (->\(oldFilterManager.currCategory.rawValue))")
            for cb in oldFilterManager._categoryChangeCallbackList {
                cb
            }
        }
    }
    
    func issueFilterChangeNotification(){
        if (oldFilterManager._filterChangeCallbackList.count>0){
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                log.debug("Issuing \(oldFilterManager._categoryChangeCallbackList.count) FilterChange callbacks")
                for cb in oldFilterManager._filterChangeCallbackList {
                    cb
                }
            }
        }
    }
    
    //////////////////////////////////////////////
    // MARK: - Category/Filter Assignments
    //////////////////////////////////////////////
    
    static func makeFilter(key: String, descriptor:FilterDescriptorInterface){
        if (oldFilterManager._filterDictionary[key] != nil){
            log.warning("Duplicate key: \(key)")
        }
        
        if (key != descriptor.key){
            log.warning("!!! Key/Index mismatch, check configuration for filter: \(key) or: \(descriptor.key)) ?!")
        }
        
        oldFilterManager._filterDictionary[key] = descriptor
        oldFilterManager._renderViewDictionary[key] = RenderView()
        
        //log.debug("Add key:\(key), address: \(filterAddress(descriptor))")
        
    }
    
    
    
    static func createFilters(){
        log.verbose("Creating Filters...")
        
        // NOTE: I try to keep these in alphabetical order just because it's easier to compare to a directory listing (when adding/deleting filters)
        
        //makeFilter(key: "",  descriptor: Descriptor())
        
        oldFilterManager._filterDictionary = [:]
        oldFilterManager._renderViewDictionary = [:]
        
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
        makeFilter(key: "Clarity", descriptor: ClarityDescriptor())
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
        
        createLookupFilters()
        createPresetFilters()
    }

    ////////////////////////////
    // Lookup Filters
    ////////////////////////////
    
    // the images listed here are based on Lookup.png, with various photoshop actions applied to them. They are then used to transform colours
    
    private static let _bwLookupList:[String] = ["bw_000_neutral.JPG", "bw_001_underexposed.JPG", "bw_002_overexposed.JPG", "bw_003_hi_contrast_harsh.JPG", "bw_004_hi_contrst_smooth.JPG",
                                               "bw_005_hi_structure_harsh.JPG", "bw_006_hi_structure_smooth.JPG", "bw_007_hi_key_1.JPG", "bw_008_hi_key_2.JPG", "bw_009_lo_key_1.JPG",
                                               "bw_010_lo_key_2.JPG", "bw_011_push_1.JPG", "bw_012_push_2.JPG", "bw_013_grad_nd_1.JPG", "bw_014_grad_nd_2.JPG", "bw_015_full_dynamic_harsh.JPG",
                                               "bw_016_full_dynamic_smooth.JPG", "bw_017_full_spectrum.JPG", "bw_018_full_spectrum_inverse.JPG", "bw_019_fine_art.JPG", "bw_020_fine_art_hi_key.JPG",
                                               "bw_021_triste_1.JPG", "bw_022_triste_2.JPG", "bw_023_wet_rocks.JPG", "bw_024_full_contrast_structure.JPG", "bw_025_silhouette.JPG",
                                               "bw_026_dark_sepia.JPG", "bw_027_soft_sepia.JPG", "bw_028_cool_tones_1.JPG", "bw_029_cool_tones_2.JPG", "bw_030_film_noir_1.JPG",
                                               "bw_031_film_noir_2.JPG", "bw_032_film_noir_3.JPG", "bw_033_yellowed_1.JPG", "bw_034_yellowed_2.JPG", "bw_035_antique_plate_1.JPG",
                                               "bw_036_antique_plate_2.JPG", "bw_037_pinhole.JPG"
                                              ]
    
    private static let _fxLookupList:[String] = ["fx_001_bleach_bypass.JPG", "fx_035_monday_morning_1.JPG", "fx_002_duplex.JPG", "fx_036_monday_morning_2.JPG", "fx_003_fog.JPG",
                                                 "fx_037_monday_morning_3.JPG", "fx_004_foliage_1.JPG", "fx_038_monday_morning_4.JPG", "fx_005_foliage_2.JPG", "fx_039_monday_morning_5.JPG",
                                                 "fx_006_foliage_3.JPG", "fx_040_old_photo_1.JPG", "fx_007_hi_key.JPG", "fx_041_old_photo_2.JPG", "fx_008_indian_summer.JPG", "fx_042_old_photo_3.JPG",
                                                 "fx_009_infrared_1.JPG", "fx_043_old_photo_4.JPG", "fx_010_infrared_2.JPG", "fx_044_old_photo_5.JPG", "fx_011_infrared_3.JPG", "fx_045_old_photo_6.JPG",
                                                 "fx_012_infrared_4.JPG", "fx_046_old_photo_color_1.JPG", "fx_013_infrared_color_1.JPG", "fx_047_old_photo_color_2.JPG", "fx_014_infrared_color_2.JPG",
                                                 "fx_048_old_photo_color_3.JPG", "fx_015_infrared_color_3.JPG", "fx_049_old_photo_color_4.JPG", "fx_016_infrared_color_4.JPG", "fx_050_old_photo_color_5.JPG",
                                                 "fx_017_infrared_color_5.JPG", "fx_051_old_photo_color_6.JPG", "fx_018_ink_1.JPG", "fx_052_pastel_1.JPG", "fx_019_ink_2.JPG", "fx_053_pastel_2.JPG",
                                                 "fx_020_ink_3.JPG", "fx_054_pastel_3.JPG", "fx_021_ink_4.JPG", "fx_055_solarize_1.JPG", "fx_022_ink_5.JPG", "fx_056_solarize_2.JPG", "fx_023_ink_6.JPG",
                                                 "fx_057_solarize_3.JPG", "fx_024_ink_7.JPG", "fx_058_solarize_4.JPG", "fx_025_ink_8.JPG", "fx_060_solarize_5.JPG", "fx_026_ink_9.JPG",
                                                 "fx_061_solarize_6.JPG", "fx_027_ink_10.JPG", "fx_062_solarize_bw_1.JPG", "fx_028_ink_11.JPG", "fx_063_solarize_bw_2.JPG", "fx_029_lo_key.JPG",
                                                 "fx_064_solarize_bw_3.JPG", "fx_030_midnight_1.JPG", "fx_065_solarize_bw_4.JPG", "fx_031_midnight_2.JPG", "fx_066_solarize_bw_5.JPG",
                                                 "fx_032_midnight_3.JPG", "fx_067_solarize_bw_6.JPG", "fx_033_midnight_4.JPG", "fx_034_midnight_5.JPG"
                                                ]
    private static func createLookupFilters(){
        var key: String
        var descriptor:  LookupFilterDescriptor?
        
        //  B&W
        for name in oldFilterManager._bwLookupList {
            key = name[name.startIndex...name.index(name.startIndex, offsetBy:5)]
            descriptor = LookupFilterDescriptor()
            descriptor?.key = key
            descriptor?.title = name[name.startIndex...name.index(name.endIndex, offsetBy:-5)]
            descriptor?.setLookupFile(name: name)
            makeFilter(key:key, descriptor: descriptor!)
            //log.debug("Preset: \(key) (\(name))")
            //print("Preset: \(key) (\(name))")
        }
        
        // Colour Effects
        for name in oldFilterManager._fxLookupList {
            key = name[name.startIndex...name.index(name.startIndex, offsetBy:5)]
            descriptor = LookupFilterDescriptor()
            descriptor?.key = key
            descriptor?.title = name[name.startIndex...name.index(name.endIndex, offsetBy:-5)]
            descriptor?.setLookupFile(name: name)
            makeFilter(key:key, descriptor: descriptor!)
        }
    }
    

    // loading is a separate function because it is done after populateCategories static initialisation
    
    private static func loadLookupFilters(){
        var key: String
        
        //  B&W
        for name in oldFilterManager._bwLookupList {
            key = name[name.startIndex...name.index(name.startIndex, offsetBy:5)]
            //addToCategory(.presets, key:key)
            oldFilterManager._monochromeList.append(key)
        }
        
        // Colour Effects
        for name in oldFilterManager._fxLookupList {
            key = name[name.startIndex...name.index(name.startIndex, offsetBy:5)]
            //addToCategory(.presets, key:key)
            oldFilterManager._colorList.append(key)
        }
        
        //print("Preset list: \(oldFilterManager._presetsList)")
    }
    
    
    ////////////////////////////
    // JSON-based Image Presets
    ////////////////////////////
    
    // the presets are defined in ImagePresets.json, which should be in the app bundle somewhere
    // This is used to define Lightroom-style presets
    
    private static func createPresetFilters(){
    
        // parameters retrieved from the preset definition
        var key:String
        var title:String
        
        var temperature: Float
        var tint: Float
        
        var exposure: Float
        var contrast: Float
        var highlights: Float
        var shadows: Float
        
        var vibrance: Float
        var saturation: Float
        
        var sharpness: Float
        
        var start: Float
        var end: Float
        
    
    print ("createPresetFilters() - Loading presets...")
        // read the configuration file, which must be part of the project
        let path = Bundle.main.path(forResource: "PresetList", ofType: "json")
        
        do {
            let fileContents = try NSString(contentsOfFile: path!, encoding: String.Encoding.utf8.rawValue) as String
            if let data = fileContents.data(using: String.Encoding.utf8) {
                let json = JSON(data: data)
                print("createPresetFilters() - parsing data")
                
                var presetDescriptor:PresetDescriptor? = nil
                
                var count:Int = 0
                for item in json["presets"].arrayValue {
                    count = count + 1
                    
                    // Parse the Preset
                    key = item["key"].stringValue
                    title = item["title"].stringValue
                    
                    temperature = item["parameters"]["whiteBalance"]["temperature"].floatValue
                    tint = item["parameters"]["whiteBalance"]["tint"].floatValue
                    
                    exposure = item["parameters"]["tone"]["exposure"].floatValue
                    contrast = item["parameters"]["tone"]["contrast"].floatValue
                    highlights = item["parameters"]["tone"]["highlights"].floatValue
                    shadows = item["parameters"]["tone"]["shadows"].floatValue
                    
                    vibrance = item["parameters"]["presence"]["vibrance"].floatValue
                    saturation = item["parameters"]["presence"]["saturation"].floatValue
                    
                    sharpness = item["parameters"]["sharpen"]["sharpness"].floatValue
                    
                    start = item["parameters"]["vignette"]["start"].floatValue
                    end = item["parameters"]["vignette"]["end"].floatValue
                    
                    //DEBUG: print values (comment out later)
                    print("Key: \(key), Title: \(title)")
                    //print("Parameters: \(item["parameters"])")
                    print("WB: (\(temperature), \(tint)), Exposure:(\(exposure), \(contrast), \(highlights), \(shadows)), Presence: (\(vibrance), \(saturation)), Sharpen:(\(sharpness)), Vignette:(\(start), \(end))")
                    
    
                    // build a descriptor
                    presetDescriptor = PresetDescriptor()
                    presetDescriptor?.key = key
                    presetDescriptor?.title = title
                    presetDescriptor?.temperature = temperature
                    presetDescriptor?.tint = tint
                    presetDescriptor?.exposure = exposure
                    presetDescriptor?.contrast = contrast
                    presetDescriptor?.highlights = highlights
                    presetDescriptor?.shadows = shadows
                    presetDescriptor?.vibrance = vibrance
                    presetDescriptor?.saturation = saturation
                    presetDescriptor?.sharpness = sharpness
                    presetDescriptor?.start = start
                    presetDescriptor?.end = end
                    
                    // add it to the Filter dictionary
                    makeFilter(key:key, descriptor: presetDescriptor!)

                    // add it to the preset list
                    oldFilterManager._presetsList.append(key)
                }
                
                print ("\(count) Presets found")
                
            } else {
                print("createPresetFilters() - ERROR : no data found")
            }
        }
        catch let error as NSError {
            print("createPresetFilters() - ERROR : reading from presets file : \(error.localizedDescription)")
        }
    }
    
    private static func loadPresetFilters(){
    
    }
    
    ////////////////////////////
    // Data loading
    ////////////////////////////
    
    
    
    // TODO: figure out how to modify the global list, not a copy
    static func addToCategory(_ category:CategoryType, key:String){
        if (oldFilterManager._filterDictionary.index(forKey: key) != nil){
            var list = category.getFilterList()


            if (!(list.contains(key))){
                //log.verbose("Adding key:\(key) for category:\(category)  (\(list.count))")
                print("addToCategory() Adding key:\(key) for category:\(category)  (\(list.count))")
                list.append(key)
                print("addToCategory() list: \(list)")
            } else {
                print("addToCategory() Filter:\(key) already member of category: \(category.rawValue)...")
            }
        } else {
            print("addToCategory() Filter:\(key) not defined. NOT added to category: \(category.rawValue)...")
        }
    }
    
    
    
    static func populateCategories(){
        
        
        log.verbose("Loading Category Lists...")
        //TODO: load from some kind of configuration file?
        
        // Quick Select
        //TEMP: populate with some filters, but this should really be done by the user (and saved/restored)
        

        // For some reason, I could only get this working with a static assignment
        // Note that filters can be in multiple categories, but they will still be the 'same' filter
        // Lists will be sorted, so don't worry about the order
        
        oldFilterManager._quickSelectList += [ "Crosshatch", "Emboss", "Halftone", "SwirlDistortion", "Luminance", "ThresholdSketch"  ]
        
        oldFilterManager._basicAdjustmentsList += [ "Saturation", "Warmth", "WhiteBalance", "Brightness", "Contrast", "UnsharpMask", "Exposure", "Sharpen", "Crop",
                                                "Gamma", "Vibrance", "Highlights", "LevelsAdjustment", "Vignette", "Haze", "Clarity"]
        
        oldFilterManager._blendModesList += [ "AddBlend", "AlphaBlend", "ChromaKeyBlend", "ColorBlend", "ColorBurnBlend", "ColorDodgeBlend", "DarkenBlend",
                                          "DifferenceBlend", "DissolveBlend", "DivideBlend", "ExclusionBlend", "HardLightBlend", "HueBlend", "LightenBlend",
                                          "LinearBurnBlend", "LuminosityBlend", "MultiplyBlend", "NormalBlend", "OverlayBlend", "SaturationBlend", "ScreenBlend",
                                          "SoftLightBlend", "SourceOverBlend", "SubtractBlend"]
        
        oldFilterManager._visualEffectsList += [ "BulgeDistortion", "GlassSphereRefraction", "PolarPixellate", "PolkaDot", "Pixellate", "TiltShift",
                                             "ChromaKeying", "PinchDistortion", "SwirlDistortion", "SphereRefraction"]
        
        // Note: Soft Elegance causes problems wth still Images
        oldFilterManager._presetsList += [ "MissEtikate", "Amatorka", "CGAColorspace" ]
        
        oldFilterManager._drawingList += [ "Crosshatch", "Emboss", "LuminanceThreshold", "Sketch", "ThresholdSketch", "Toon", "Kuwahara", "AverageLuminanceThreshold", "AdaptiveThreshold",
                                       "SmoothToon", "Posterize", "ThresholdSobelEdgeDetection", "Halftone" ]
        
        oldFilterManager._blursList += [ "ZoomBlur", "BilateralBlur", "GaussianBlur", "SingleComponentGaussianBlur", "BoxBlur" ]
       
        
        oldFilterManager._monochromeList += [ "Luminance",  "Monochrome", "Sepia", "Grayscale" ]
        
        oldFilterManager._colorList += [ "FalseColor", "Hue", "RGB",  "CGAColorspace", "Solarize", "ColorInversion", "HighlightShadowTint" ]
        
        loadLookupFilters()
        loadPresetFilters()
    }
    
    
    static func sortLists(){

        // Sort all category arrays alphabetically
        log.verbose("Sorting lists...")
        oldFilterManager._quickSelectList.sort(by: sortClosure)
        oldFilterManager._basicAdjustmentsList.sort(by: sortClosure)
        oldFilterManager._monochromeList.sort(by: sortClosure)
        oldFilterManager._blendModesList.sort(by: sortClosure)
        oldFilterManager._visualEffectsList.sort(by: sortClosure)
        oldFilterManager._presetsList.sort(by: sortClosure)
        oldFilterManager._drawingList.sort(by: sortClosure)
        oldFilterManager._blursList.sort(by: sortClosure)
        oldFilterManager._colorList.sort(by: sortClosure)
        
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

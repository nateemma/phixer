//
//  FilterConfiguration
//  phixer
//
//  Created by Philip Price on 12/2/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import SwiftyJSON

// Static class that provides the data structures for holding the category and filter information, and also methods for loading from/saving to config files

class FilterConfiguration{

    fileprivate static var initDone:Bool = false
    fileprivate static var saveDone:Bool = false
    fileprivate static var overwriteConfig:Bool = false

    static let sortClosure = { (value1: String, value2: String) -> Bool in return value1 < value2 }
    
    //////////////////////////////////////////////
    //MARK: - Category/Filter "Database"
    //////////////////////////////////////////////
    
    // lists of blends & Samples
    public static var blendList:[String] = []
    public static var sampleList:[String] = []

    // The dictionary of Categories (key, title). key is category name
    public static var categoryDictionary:[String:String] = [:]
    public static var categoryList:[String] = []
    
    // Dictionary of FilterDescriptors (key, FilterDescriptor). key is filter name
    //public static var filterDictionary:[String:FilterDescriptor?] = [:]
    
    // Dictionary of Lookup images (key, image name). key is filter name
    public static var lookupDictionary:[String:String] = [:]
 
    // The dictionary of Style Transfer Filters (key, title). key is style name
    public static var styleTransferList:[String] = []

    // Dictionary of Category Dictionaries. Use category as key to get list of filters in that category
    public static var categoryFilters:[String:[String]] = [:]

    
    //////////////////////////////////////////////
    //MARK: - Setup/Teardown
    //////////////////////////////////////////////
    
    public static func checkSetup(){
        if (!FilterConfiguration.initDone) {
            FilterConfiguration.initDone = true
            
            initLists()
            
            // Load custom CIFilters (do this before loading config)
            CustomFilterRegistry.registerFilters()

            // 'restore' the configuration from the setup file
            FilterConfiguration.restore()
            CustomFilterRegistry.clearCache() // lots of filters, so start with a clean cache
        }
        
    }
    
    fileprivate init(){
        FilterConfiguration.checkSetup()
    }
    
    deinit{
        if (!FilterConfiguration.saveDone){
            FilterConfiguration.save()
            FilterConfiguration.saveDone = true
        }
    }
    
    
    fileprivate static func initLists(){
        categoryDictionary = [:]
        categoryList = []
        categoryFilters = [:]
        styleTransferList = []
    }
    
    ////////////////////////////
    // Restore from persistent storage
    ////////////////////////////
    
    
    public static func restore(){
        
        // TODO: check version number and/or allow 'reset' to contents of config file
        //if (Database.isSetup()){
        //    loadFromDatabase()
        //} else {
        loadFilterConfig()
        if !FilterConfiguration.overwriteConfig {
            loadFromDatabase()
        } else {
            clearDatabase()
        }
        commitChanges()
        //}
    }

   
    // restore default parameters from the config file
    public static func restoreDefaults(){
        clearDatabase()
        loadFilterConfig()
        commitChanges()
    }
    
  
    
    
    ////////////////////////////
    // Config File Processing
    ////////////////////////////
    
    
    fileprivate static let configFile = "defaultConfig"
    //fileprivate static let configFile = "testFilterConfig"

//    fileprivate static var parsedConfig:JSON = JSON.null
    
    
    fileprivate  static func loadFilterConfig(){
        var count:Int = 0
        var version:Float
        
        var key:String, title:String
        var parsedConfig:JSON = JSON.null

        print ("======================== Loading Config File ========================")
        initLists()

        // load the settings first because timing is a bit tricky and we may need those values set before
        // parsing the config file is done
        
        
  
        log.verbose("loading configuration...")
        
        // find the configuration file, which must be part of the project
        let path = Bundle.main.path(forResource: configFile, ofType: "json")
        
        do {
            // load the file contents and parse the JSON string
            let fileContents = try NSString(contentsOfFile: path!, encoding: String.Encoding.utf8.rawValue) as String
            if let data = fileContents.data(using: String.Encoding.utf8) {
                log.verbose("parsing data from: \(path!)")
                parsedConfig = try JSON(data: data)
                if (parsedConfig != JSON.null){
                    log.verbose("parsing data")
                    //log.verbose ("\(parsedConfig)")
                    
                    // version
                    let vParams = parsedConfig["version"].dictionaryValue
                    log.verbose("vParams:\(vParams)")
                    version = vParams["id"]?.floatValue ?? 0.0
                    overwriteConfig = vParams["overwrite"]?.boolValue ?? false
                    log.verbose ("version: \(version) overwrite: \(overwriteConfig)")
                    
                    if overwriteConfig {
                        //TODO: if overwrite flag is set, clear stored values before processing config file
                        
                        log.debug ("Using config file settings instead of saved settings")
                        Database.clearSettings()

                        // blend, sample, edit assignments
                        let blend = parsedConfig["settings"]["blend"].stringValue
                        let sample = parsedConfig["settings"]["sample"].stringValue
                        let edit = parsedConfig["settings"]["edit"].stringValue
                        log.debug("Sample:\(sample) Blend:\(blend) Edit:\(edit)")
                        // Note: need to do edit image first, so that default can be processed
                        ImageManager.setCurrentEditImageName(edit) // set even if empty
                        ImageManager.setCurrentSampleImageName(sample) // set even if empty
                       if !blend.isEmpty { ImageManager.setCurrentBlendImageName(blend)}
 

                    } else {
                        log.debug("Skipping config file settings, using database entries instead")
                        loadSettings()
                    }
                    
                    // blend list
                    for blend in parsedConfig["blends"].arrayValue {
                        blendList.append(blend.stringValue)
                    }
                    ImageManager.setBlendList(blendList)
                    
                    // sample list
                    for sample in parsedConfig["samples"].arrayValue {
                        sampleList.append(sample.stringValue)
                    }
                    ImageManager.setSampleList(sampleList)
  
                    var def:FilterDefinition = FilterDefinition()

                    addNullFilter() // useful for showing unmodified image
                    addAvailableFilters()  // adds all CIFilters, including custom filters
                    
                    // 'Slow' filters (allows the UI to take action)
                    for f in parsedConfig["slow"].arrayValue {
                        FilterFactory.setSlow(key: f.stringValue, slow: true)
                    }
                    
                    
                    // Lookup Images
                    count = 0
                    for item in parsedConfig["lookup"].arrayValue {
                        count = count + 1
                        def.key = item["key"].stringValue
                        def.lookup = item["image"].stringValue
                        def.title = def.lookup
                        def.ftype = "lookup"
                        def.slow = item["slow"].boolValue
                        def.hide = item["hide"].boolValue
                        def.rating = item["rating"].intValue
                        addLookup(key:def.key, definition:def)
                    }
                    log.verbose ("\(count) Lookup Images found")
                    
                    // Presets
                    count = 0
                    for item in parsedConfig["preset"].arrayValue {
                        count = count + 1
                        def.key = item["key"].stringValue
                        def.preset = def.key
                        def.title = item["title"].stringValue
                        def.ftype = "preset"
                        def.slow = item["slow"].boolValue
                        def.hide = item["hide"].boolValue
                        def.rating = item["rating"].intValue
                        addPreset(key:def.key, definition:def)
                    }
                    log.verbose ("\(count) Presets found")
                    
                    
                    // only do these if the database has not already been set up
                    // TODO: check version number
                    
                    
                    /** moved back to general filters
                    // Style Transfer list
                    // These are 'normal' filters, so they are already registered. Just need to maintain a list of them
                    count = 0
                    for item in parsedConfig["styletransfer"].arrayValue {
                        count = count + 1
                        key = item["key"].stringValue
                        title = item["title"].stringValue
                        styleTransferList = item["filters"].arrayValue.map { $0.string!}
                        styleTransferList.sort(by: sortClosure) // sort alphabetically
                    }
                    log.verbose ("\(count) Style Transfer filters found")
                    ***/
                    
                    // Category list
                    count = 0
                    for item in parsedConfig["categories"].arrayValue {
                        count = count + 1
                        key = item["key"].stringValue
                        title = item["title"].stringValue
                        addCategory(key:key, title:title)
                        var list:[String] = item["filters"].arrayValue.map { $0.string!}
                        list.sort(by: sortClosure) // sort alphabetically
                        addAssignment(category:key, filters:list)
                    }
                    log.verbose ("\(count) Categories found")
                    
                    // Build Category array from dictionary. More convenient than a dictionary
                    categoryList = Array(categoryDictionary.keys)
                    categoryList.sort(by: sortClosure)


                    
                } else {
                    log.error("ERROR parsing JSON file")
                    log.error("*** categories error: \(String(describing: parsedConfig["categories"].error))")
                    log.error("*** filters error: \(String(describing: parsedConfig["filters"].error))")
                    log.error("*** lookup error: \(String(describing: parsedConfig["lookup"].error))")
                    log.error("*** assign error: \(String(describing: parsedConfig["assign"].error))")
                }
            } else {
                log.error("restore() - ERROR : no data found")
            }
        }
        catch let error as NSError {
            log.error("ERROR: restore() - error reading from config file : \(error.localizedDescription)")
            log.error("*** categories error: \(String(describing: parsedConfig["categories"].error))")
            log.error("*** filters error: \(String(describing: parsedConfig["filters"].error))")
            log.error("*** lookup error: \(String(describing: parsedConfig["lookup"].error))")
            log.error("*** assign error: \(String(describing: parsedConfig["assign"].error))")
        }
        
        parsedConfig = JSON.null
    }


    // load settings from the database
    private static func loadSettings(){
        if let settings = Database.getSettings() {
            // Double-check that there is something valid in there...
            if (settings.blendImage!.isEmpty) {
                settings.blendImage = ImageManager.getDefaultBlendImageName()
                log.warning("Blend image empty. Set to default: \(settings.blendImage)")
            }
            if (settings.sampleImage!.isEmpty) {
                settings.sampleImage = ImageManager.getDefaultSampleImageName()
                log.warning("Sample image empty. Set to default: \(settings.sampleImage)")
            }
            if (settings.editImage!.isEmpty) {
                settings.editImage = ImageManager.getDefaultEditImageName()
                log.warning("Edit image empty. Set to default: \(settings.editImage)")
            }
            
            log.verbose("Restoring Settings: key:\(settings.key) Sample:\(settings.sampleImage!) Blend:\(settings.blendImage!) Edit:\(settings.editImage!)")

            // Inform ImageManager. Note that edit must be done first otherwise it leads to race conditions
            ImageManager.setCurrentEditImageName(settings.editImage!)
            ImageManager.setCurrentBlendImageName(settings.blendImage!)
            ImageManager.setCurrentSampleImageName(settings.sampleImage!)
        } else {
            log.verbose("ERR: settings NOT found...")
        }
        
    }
    
    // function to convert from CIFilter Attribute Type string to simpler internal parameter type. Note that there is NOT a 1:1 mapping
    public static func attributeToParameterType(_ atype:String) -> ParameterType {
        var ptype: ParameterType
        ptype = .unknown
        switch (atype){
        case kCIAttributeTypeTime:
            ptype = .float
        case kCIAttributeTypeScalar:
            ptype = .float
        case kCIAttributeTypeDistance:
            ptype = .distance
        case kCIAttributeTypeAngle:
            ptype = .float
        case kCIAttributeTypeBoolean:
            ptype = .float
        case kCIAttributeTypeInteger:
            ptype = .float
        case kCIAttributeTypeCount:
            ptype = .float
        case kCIAttributeTypeColor:
            ptype = .color
        case kCIAttributeTypeImage:
            ptype = .image
        case kCIAttributeTypePosition:
            ptype = .position
        case kCIAttributeTypePosition3:
            ptype = .vector
        case kCIAttributeTypeOffset:
            ptype = .vector
        case kCIAttributeTypeRectangle:
            //ptype = .rectangle
            ptype = .vector
        case "CIAttributeTypeVector":
            ptype = .vector
        default:
            // anything else is too difficult to handle automatically
            ptype = .unknown
        }
        return ptype
    }


    public static func save(){
        log.verbose ("saving configuration...")
        commitChanges()
    }

 
    
    private static func addCategory(key:String, title:String){
        // just add the data to the dictionary
        FilterConfiguration.categoryDictionary[key] = title
        log.verbose("addCategory(\(key), \(title))")
    }
  
    
    
    public static func addFilter(key:String, definition:FilterDefinition){
        
        // just store the mapping. Do lazy allocation as needed because of the potentially large number of filters
        //FilterDescriptorCache.get(key:key) = nil // just make sure there is an entry to find later
        FilterFactory.addFilterDefinition(key: key, definition:definition)
        log.verbose("addFilter(\(definition.key): \(definition.title), \(definition.ftype), \(definition.hide), \(definition.rating)), \(definition.parameters)")
    }
    
    
    
    public static func addPreset(key:String, definition:FilterDefinition){
        
        FilterFactory.addFilterDefinition(key: key, definition:definition)
        log.verbose("addPreset(\(definition.key): \(definition.title), \(definition.ftype), \(definition.hide), \(definition.rating)), \(definition.parameters)")
    }

    
    
    public static func addLookup(key:String, definition:FilterDefinition){
        
        let l = definition.lookup.components(separatedBy:".")
        let title = l[0]
        let ext = l[1]
        
        guard Bundle.main.path(forResource: title, ofType: ext) != nil else {
            log.error("ERR: File not found:\(definition.lookup)")
            return
        }
        
        // save the image name for later use, when the filter is created
        if (FilterConfiguration.lookupDictionary[key] != nil){ // check for duplicate and warn
            log.warning("WARN: Duplicate key:\(key)")
        }
        FilterConfiguration.lookupDictionary[key] = definition.lookup
        
        var def = definition
        def.title = title
        //FilterDescriptorCache.get(key:key) = nil
        FilterFactory.addLookupFilter(key: key, definition:def)
        //FilterFactory.addFilterDefinition(key: key, title: key, ftype: "lookup",  hide:hide, rating:rating)
        log.verbose("addLookup(\(definition.key), \(definition.lookup), \(definition.hide), \(definition.rating))")
    }
    
    
    
    private static func addAssignment(category:String, filters: [String]){
        // scan through list to make sure they are valid filters
        //FilterConfiguration.categoryFilters[category] = []
        //var list:[String] = []
        let validKeys = FilterFactory.getFilterList()
        for f in filters {
            if (validKeys.contains(f)) {
                if FilterConfiguration.categoryFilters[category] == nil {
                    FilterConfiguration.categoryFilters[category] = []
                }
                if !FilterConfiguration.categoryFilters[category]!.contains(f){ // don't add if already there
                    FilterConfiguration.categoryFilters[category]?.append(f)
                }
                //list.append(f)
                
                // double check
                if !FilterConfiguration.categoryFilters[category]!.contains(f){
                    log.error("ERROR: did not add to category:\(category)")
                }
            } else {
                log.warning("Ignoring filter: \(f)")
            }
        }
    }

    
    
    
    ////////////////////////////
    // Built in (CI) Filter Processing
    ////////////////////////////
    
    // add the "null" filter
    private static func addNullFilter(){
        var def = FilterDefinition()
        def.key = FilterDescriptor.nullFilter
        def.title = "No Filter"
        def.ftype = FilterOperationType.singleInput.rawValue
        def.parameters = []
        FilterConfiguration.addFilter(key:def.key, definition:def)
    }
    
    // adds all of the filters found by querying CIFilter, which will include our custom filters
    private static func addAvailableFilters(){
        // this is the list of CIFilter categories
        // Note that custom filters defined in this framework will be in the "CustomFilters" or kCICategoryColorAdjustment category
        /***
        let categories:[String] = [ "CICategoryBlur", "CICategoryColorEffect", "CICategoryCompositeOperation",
                                    "CICategoryDistortionEffect", "CICategoryGeometryAdjustment", "CICategoryGradient",
                                    "CICategoryHalftoneEffect", "CICategoryReduction", "CICategorySharpen", "CICategoryStylize", "CICategoryTileEffect",
                                    "CustomFilters", kCICategoryColorAdjustment
        ]
        ***/
        
         let categories:[String] = [ kCICategoryDistortionEffect, kCICategoryGeometryAdjustment, kCICategoryCompositeOperation, kCICategoryHalftoneEffect,
                                     kCICategoryColorAdjustment, kCICategoryColorEffect, kCICategoryTileEffect, kCICategoryGenerator, kCICategoryGradient,
                                     kCICategoryStylize, kCICategorySharpen, kCICategoryBlur, kCICategoryHighDynamicRange,
                                     CustomFilterRegistry.customFilterCategory ]
        
        for c in categories {
            //log.verbose ("Category = \(c):")
            for f in CIFilter.filterNames(inCategories: [c]) {
                //describeFilter(f)
                let def = makeFilterDefinition(f)
                if def != nil {
                    //log.verbose ("Found filter: key:\((def?.key)!) title:\((def?.title)!) ftype:\((def?.ftype)!)")
                    FilterConfiguration.addFilter(key:(def?.key)!, definition:def!)
                }
            }
        }

    }

    
    // convert the definition of the filter into FilterDescriptor form
    static func makeFilterDefinition(_ name:String) -> FilterDefinition? {
        var def:FilterDefinition? = nil
        //var filter: CIFilter? = nil
        
        if let filter = CIFilter(name: name) {
        
            def = FilterDefinition()
            
            let inputNames = (filter.inputKeys as! [String]).filter { (parameterName) -> Bool in
                return (parameterName as String) != "inputImage" // everything has inputImage so don't return that
            }
            
            let attributes = filter.attributes
            
            
            // filter top-level attributes
            def?.key = name
            def?.title = attributes[kCIAttributeFilterDisplayName]  as! String
            def?.ftype = FilterOperationType.singleInput.rawValue
            def?.hide = false
            def?.rating = 0
            def?.lookup = ""
            def?.slow = false
            def?.parameters = []
            
            // process attributes for each input parameter
            var aname:String
            var atype:String
            var amin:Float=0.0, amax:Float=0.0, aval:Float=0.0
            
            let nump = inputNames.count
            if nump > 0 {
                for i in 0...(nump-1) {
                    let inp = inputNames[i]
                    if attributes[inp] != nil {
                        let a = attributes[inp] as! [String : AnyObject]
                        if let tmp = a[kCIAttributeDisplayName] { aname = tmp as! String } else { aname = "???" }
                        if let tmp = a[kCIAttributeSliderMin]   { amin = toFloat(tmp) } else { amin = 0.0 }
                        if let tmp = a[kCIAttributeSliderMax]   { amax = toFloat(tmp) } else { amax = 0.0 }
                        if let tmp = a[kCIAttributeDefault]     { aval = toFloat(tmp) } else { aval = 0.0 }
                        if let tmp = a[kCIAttributeType]        { atype = tmp as! String
                        } else {
                            if let tmp = a[kCIAttributeClass]   { atype = tmp as! String } else { atype = "???" }
                        }
                        let p = ParameterSettings(key: inp, title: aname, min: amin, max: amax, value: aval, type: attributeToParameterType(atype))
                        def?.parameters.append(p)
                        
                        // If we find a background image parameter, then change filter type to blend
                        if inp == kCIInputBackgroundImageKey {
                            def?.ftype = FilterOperationType.blend.rawValue
                        }
                    } else {
                        log.error("NIL attributes for: \(inp). Filter: \(name)")
                    }
                }
            }
        }
        return def
    }
    
    
    
    static func toFloat(_ obj:AnyObject)->Float{
        
        let str:String = String(format: "%@", obj as! CVarArg)
        let fval = Float(str) ?? 0.0
        return fval
    }

    
    
    ////////////////////////////
    // Database Processing
    ////////////////////////////
    
    fileprivate static func loadFromDatabase(){
        
        
        
        // restore the settings
        
        if let settings = Database.getSettings() {
            log.verbose("loadFromDatabase() - Restoring Settings: key:\(settings.key) Sample:\(settings.sampleImage!) Blend:\(settings.blendImage!) Edit:\(settings.editImage!)")
            ImageManager.setCurrentBlendImageName(settings.blendImage!)
            ImageManager.setCurrentSampleImageName(settings.sampleImage!)
            ImageManager.setCurrentEditImageName(settings.editImage!)
        } else {
            log.error("ERR: settings NOT found...")
        }
        
/****
        // Categories
        for crec in Database.getCategoryRecords(){
            addCategory(key:(crec.key)!, title:(crec.title)!)
        }
 ***/
        // Build Category array from dictionary. More convenient than a dictionary
        categoryList = Array(categoryDictionary.keys)
        categoryList.sort(by: sortClosure)
        
        /*** Won't be needing this for quite a while
        // Assignments
        for arec in Database.getAssignmentRecords(){
            addAssignment(category:arec.category!, filters:arec.filters)
        }
        ***/

        // user changes
        for urec in Database.getUserChangesRecords(){
            FilterFactory.setHidden(key: urec.key!, hidden: urec.hide)
            FilterFactory.setRating(key: urec.key!, rating: urec.rating)
        }

    }
    
    public static func clearDatabase(){
        Database.clearSettings()
        Database.clearCategoryRecords()
        Database.clearAssignmentRecords()
        Database.clearUserChangesRecords()
    }

    
    public static func commitChanges(){
        
        // Settings
        let settings = SettingsRecord()
        
        settings.blendImage = ImageManager.getCurrentBlendImageName()
        settings.sampleImage = ImageManager.getCurrentSampleImageName()
        settings.editImage = ImageManager.getCurrentEditImageName()
        
        Database.saveSettings(settings)
        
/*** Won't be needing this for quite a while

        // Categories
        
        let crec: CategoryRecord = CategoryRecord()
        for key in FilterConfiguration.categoryList {
            crec.key = key
            crec.title = FilterConfiguration.categoryDictionary[key]
            crec.hide = false
            Database.updateCategoryRecord(crec)
        }
 ***/
        /***
        // Standard and Lookup filters
        let frec: FilterRecord = FilterRecord()
        let lrec: LookupFilterRecord = LookupFilterRecord()
        
        for key in FilterFactory.getFilterList() {
            // built-in or preset?
            if (FilterConfiguration.lookupDictionary[key] == nil){ // built-in filter
                frec.key = key
                frec.hide = FilterFactory.isHidden(key: key)
                frec.rating = FilterFactory.getRating(key: key)
                Database.updateFilterRecord(frec)
            } else { // Lookup Filter
                lrec.key = key
                lrec.image = FilterConfiguration.lookupDictionary[key]
                lrec.hide = FilterFactory.isHidden(key: key)
                lrec.rating = FilterFactory.getRating(key: key)
                Database.updateLookupFilterRecord(lrec)
            }
        }
         ***/
/*** Won't be needing this for quite a while

        // Category->Filter Assignments
        
        let arec:AssignmentRecord = AssignmentRecord()
        
        for category in FilterConfiguration.categoryList {
            arec.category = category
            arec.filters = []
            if (FilterConfiguration.categoryFilters[category] != nil){
                if ((FilterConfiguration.categoryFilters[category]?.count)! > 0){
                    for f in (FilterConfiguration.categoryFilters[category])!{
                        arec.filters.append(f)
                    }
                    //arec.filters = (FilterConfiguration.categoryFilters[category])!
                } else {
                    log.verbose("commitChanges()() no filters found for: \(category)")
                }
            } else {
                log.verbose("commitChanges()() no filters found for: \(category)")
            }
            Database.updateAssignmentRecord(arec)
        }
        
        // User changes
        let urec:UserChangesRecord = UserChangesRecord()
        for key in FilterFactory.getFilterList() {
            // show or ratings not default?
            if (FilterFactory.isHidden(key: key)) || (FilterFactory.getRating(key: key) != 0) {
                urec.key = key
                urec.hide = FilterFactory.isHidden(key: key)
                urec.rating = FilterFactory.getRating(key: key)
                Database.updateUserChangesRecord(urec)
            }
        }
***/
 
        Database.save()
    }

}

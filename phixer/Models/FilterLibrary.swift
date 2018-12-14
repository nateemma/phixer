//
//  FilterLibrary
//  phixer
//
//  Created by Philip Price on 12/2/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import SwiftyJSON

// Static class that provides the data structures for holding the category and filter information, and also methods for loading from/saving to config files
// NOTE: loaded sometime during static initialisation, so cannot rely on log service to be running yet, ie. have to use 'print' statements or local calls

class FilterLibrary{

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
    public static var filterDictionary:[String:FilterDescriptor?] = [:]
    
    // Dictionary of Lookup images (key, image name). key is filter name
    public static var lookupDictionary:[String:String] = [:]
    
    // Dictionary of Category Dictionaries. Use category as key to get list of filters in that category
    //typealias FilterList = Array<String>
    //typealias FilterList = [String]
    //public static var categoryFilters:[String:FilterList] = [:]
    public static var categoryFilters:[String:[String]] = [:]

    
    //////////////////////////////////////////////
    //MARK: - Setup/Teardown
    //////////////////////////////////////////////
    
    public static func checkSetup(){
        if (!FilterLibrary.initDone) {
            FilterLibrary.initDone = true
            
            categoryDictionary = [:]
            categoryList = []
            filterDictionary = [:]
            lookupDictionary = [:]
            categoryFilters = [:]

            // Load custom CIFilters (do this before loading config)
            CustomFiltersRegistry.registerFilters()
            
            // 'restore' the configuration from the setup file
            FilterLibrary.restore()
        }
        
    }
    
    fileprivate init(){
        FilterLibrary.checkSetup()
    }
    
    deinit{
        if (!FilterLibrary.saveDone){
            FilterLibrary.save()
            FilterLibrary.saveDone = true
        }
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
        if !FilterLibrary.overwriteConfig {
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

    fileprivate static var parsedConfig:JSON = JSON.null
    
    
    fileprivate  static func loadFilterConfig(){
        var count:Int = 0
        var version:Float
        var key:String, title:String, ftype:String
        var value:String
        var hide:Bool
        var rating:Int
        
        var pkey:String, ptitle:String
        var ptype: FilterDescriptor.ParameterType
        var pmin:Float, pmax:Float, pval:Float
        var psettings:[FilterDescriptor.ParameterSettings]

     
        blendList = []
        sampleList = []
        categoryDictionary = [:]
        categoryList = []
        filterDictionary = [:]
        lookupDictionary = [:]
        categoryFilters = [:]
        
        // load the settings first because timing is a bit tricky and we may need those values set before
        // parsing the config file is done
        
        
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

            print("loadFilterConfig() - Restoring Settings: key:\(settings.key) Sample:\(settings.sampleImage!) Blend:\(settings.blendImage!) Edit:\(settings.editImage!)")
            ImageManager.setCurrentBlendImageName(settings.blendImage!)
            ImageManager.setCurrentSampleImageName(settings.sampleImage!)
            ImageManager.setCurrentEditImageName(settings.editImage!)
        } else {
            print("loadFilterConfig() - ERR: settings NOT found...")
        }

        
        print ("FilterLibrary.loadFilterConfig() - loading configuration...")
        
        // find the configuration file, which must be part of the project
        let path = Bundle.main.path(forResource: configFile, ofType: "json")
        
        do {
            // load the file contents and parse the JSON string
            let fileContents = try NSString(contentsOfFile: path!, encoding: String.Encoding.utf8.rawValue) as String
            if let data = fileContents.data(using: String.Encoding.utf8) {
                print("restore() - parsing data from: \(path!)")
                parsedConfig = try JSON(data: data)
                if (parsedConfig != JSON.null){
                    print("restore() - parsing data")
                    //print ("\(parsedConfig)")
                    
                    // version
                    let vParams = parsedConfig["version"].dictionaryValue
                    print("vParams:\(vParams)")
                    version = vParams["id"]?.floatValue ?? 0.0
                    overwriteConfig = vParams["overwrite"]?.boolValue ?? false
                    print ("version: \(version) overwrite: \(overwriteConfig)")
                    
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
                    
                    // Filter list
                    count = 0
                    for item in parsedConfig["filters"].arrayValue {
                        count = count + 1
                        key = item["key"].stringValue
                        title = item["title"].stringValue
                        ftype = item["ftype"].stringValue
                        hide = !(item["show"].boolValue)
                        rating = item["rating"].intValue
                        // get filter parameters
                        psettings = []
                        for p in item["parameters"].arrayValue {
                            pkey = p["key"].stringValue
                            ptitle = p["title"].stringValue
                            pmin = p["min"].floatValue
                            pmax = p["max"].floatValue
                            pval = p["val"].floatValue
                            ptype = attributeToParameterType(p["type"].stringValue)
                            psettings.append(FilterDescriptor.ParameterSettings(key: pkey, title: ptitle, min: pmin, max: pmax, value: pval, type: ptype))
                        }
                        addFilter(key:key, title:title, ftype:ftype, hide:hide, rating:rating, settings: psettings)
                    }
                    print ("\(count) Filters found")
                    
                    
                    // Lookup Images
                    count = 0
                    for item in parsedConfig["lookup"].arrayValue {
                        count = count + 1
                        key = item["key"].stringValue
                        value = item["image"].stringValue
                        hide = item["hide"].boolValue
                        rating = item["rating"].intValue
                        addLookup(key:key, image:value, hide:hide, rating:rating)
                    }
                    print ("\(count) Lookup Images found")
                    
                    
                    // only do these if the database has not already been set up
                    // TODO: check version number
                    
                    //TODO: if overwrite flag is set, clear stored values before processing config file
                    
                    if (!Database.isSetup()) || overwriteConfig {
                        // blend, sample, edit assignments
                        let blend = parsedConfig["settings"]["blend"].stringValue
                        let sample = parsedConfig["settings"]["sample"].stringValue
                        let edit = parsedConfig["settings"]["edit"].stringValue
                        if !blend.isEmpty { ImageManager.setCurrentBlendImageName(blend)}
                        if !sample.isEmpty { ImageManager.setCurrentSampleImageName(sample)}
                        ImageManager.setCurrentBlendImageName(edit) // set even if empty
                    } else {
                        log.debug("Skipping config file settings, using database entries instead")
                    }
                    
                    // Category list
                    count = 0
                    for item in parsedConfig["categories"].arrayValue {
                        count = count + 1
                        key = item["key"].stringValue
                        title = item["title"].stringValue
                        addCategory(key:key, title:title)
                        var list:[String] = item["filters"].arrayValue.map { $0.string!}
                        list.sort(by: sortClosure) // sort alphabetically
                        addAssignment(category:key, filters:list)                   }
                    print ("\(count) Categories found")
                    
                    // Build Category array from dictionary. More convenient than a dictionary
                    categoryList = Array(categoryDictionary.keys)
                    categoryList.sort(by: sortClosure)
                    
                    /***
                    // List of Filters in each Category
                    count = 0
                    for item in parsedConfig["assign"].arrayValue {
                        count = count + 1
                        key = item["category"].stringValue
                        var list:[String] = item["filters"].arrayValue.map { $0.string!}
                        list.sort(by: sortClosure) // sort alphabetically
                        addAssignment(category:key, filters:list)
                    }
                    print ("\(count) Category<-Filter Assignments found")
                    ***/
                    
                } else {
                    print("ERROR parsing JSON file")
                    print("*** categories error: \(String(describing: parsedConfig["categories"].error))")
                    print("*** filters error: \(String(describing: parsedConfig["filters"].error))")
                    print("*** lookup error: \(String(describing: parsedConfig["lookup"].error))")
                    print("*** assign error: \(String(describing: parsedConfig["assign"].error))")
                }
            } else {
                print("restore() - ERROR : no data found")
            }
        }
        catch let error as NSError {
            print("ERROR: restore() - error reading from config file : \(error.localizedDescription)")
            print("*** categories error: \(String(describing: parsedConfig["categories"].error))")
            print("*** filters error: \(String(describing: parsedConfig["filters"].error))")
            print("*** lookup error: \(String(describing: parsedConfig["lookup"].error))")
            print("*** assign error: \(String(describing: parsedConfig["assign"].error))")
        }
    }


    // functio to convert from CIFilter Attribute Type string to simpler internal parameter type
    private static func attributeToParameterType(_ atype:String) -> FilterDescriptor.ParameterType {
        var ptype: FilterDescriptor.ParameterType
        ptype = .unknown
        switch (atype){
        case kCIAttributeTypeTime:
            ptype = .float
        case kCIAttributeTypeScalar:
            ptype = .float
        case kCIAttributeTypeDistance:
            ptype = .float
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
        case kCIAttributeTypeRectangle:
            ptype = .rectangle
        default:
            // anything else is difficult to handle automatically (maybe position?)
            ptype = .unknown
        }
        return ptype
    }


    public static func save(){
        print ("FilterLibrary.save() - saving configuration...")
        commitChanges()
    }

 
    
    private static func addCategory(key:String, title:String){
        // just add the data to the dictionary
        FilterLibrary.categoryDictionary[key] = title
        print("addCategory(\(key), \(title))")
    }
  
    
    
    private static func addFilter(key:String, title:String, ftype:String, hide:Bool, rating:Int, settings:[FilterDescriptor.ParameterSettings]){
        /*
        // create an instance from the classname and add it to the dictionary
        var descriptor:FilterDescriptor? = nil
        let ns = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
        let className = ns + "." + classname
        let theClass = NSClassFromString(className) as! FilterDescriptor.Type
        descriptor = theClass.init()
        
        if (descriptor != nil){
            FilterLibrary.filterDictionary[key] = descriptor
            //print ("FilterLibrary.addFilter() Added class: \(classname)")
        } else {
            print ("FilterLibrary.addFilter() ERR: Could not create class: \(classname)")
        }
 */
        // just store the mapping. Do lazy allocation as needed because of the potentially large number of filters
        FilterLibrary.filterDictionary[key] = nil // just make sure there is an entry to find later
        FilterFactory.addFilterDefinition(key: key, title:title, ftype:ftype,  hide:hide, rating:rating, settings:settings)
        print("addFilter(\(key): \(title), \(ftype), \(hide), \(rating)), \(settings)")
    }
    
    
    
    private static func addLookup(key:String, image:String, hide:Bool, rating:Int){
        
        let l = image.components(separatedBy:".")
        let title = l[0]
        let ext = l[1]
        
        guard Bundle.main.path(forResource: title, ofType: ext) != nil else {
            print("addLookup() ERR: File not found:\(image)")
            return
        }
        
        /** old way
        // create a Lookup filter, set the name/title/image and add it to the Filter dictioary
        var descriptor:LookupFilterDescriptor
        descriptor = LookupFilterDescriptor()
        descriptor.key = key
        descriptor.title = title
        descriptor.setLookupFile(name: image)
        FilterLibrary.filterDictionary[key] = descriptor
 **/
        
        // new way: save the image name for later use, when the filter is created
        if (FilterLibrary.lookupDictionary[key] != nil){ // check for duplicate and warn
            print("addLookup() WARN: Duplicate key:\(key)")
        }
        FilterLibrary.lookupDictionary[key] = image
        FilterLibrary.filterDictionary[key] = nil
        FilterFactory.addLookupFilter(key: key, title: title, image: image,  hide:hide, rating:rating)
        //FilterFactory.addFilterDefinition(key: key, title: key, ftype: "lookup",  hide:hide, rating:rating)
        print("addLookup(\(key), \(image), \(hide), \(rating))")
    }
    
    
    
    private static func addAssignment(category:String, filters: [String]){
        // scan through list to make sure they are valid filters
        //FilterLibrary.categoryFilters[category] = []
        //var list:[String] = []
        let validKeys = FilterFactory.getFilterList()
        for f in filters {
            if (validKeys.contains(f)) {
                if FilterLibrary.categoryFilters[category] == nil {
                    FilterLibrary.categoryFilters[category] = []
                }
                if !FilterLibrary.categoryFilters[category]!.contains(f){ // don't add if already there
                    FilterLibrary.categoryFilters[category]?.append(f)
                }
                //list.append(f)
                
                // double check
                if !FilterLibrary.categoryFilters[category]!.contains(f){
                    print("addAssignment() ERROR: did not add to category:\(category)")
                }
            } else {
                log.warning("Ignoring filter: \(f)")
            }
        }
    }

    
    
    
    ////////////////////////////
    // Database Processing
    ////////////////////////////
    
    fileprivate static func loadFromDatabase(){
        
        
        
        // restore the settings
        
        if let settings = Database.getSettings() {
            print("loadFromDatabase() - Restoring Settings: key:\(settings.key) Sample:\(settings.sampleImage!) Blend:\(settings.blendImage!) Edit:\(settings.editImage!)")
            ImageManager.setCurrentBlendImageName(settings.blendImage!)
            ImageManager.setCurrentSampleImageName(settings.sampleImage!)
            ImageManager.setCurrentEditImageName(settings.editImage!)
        } else {
            print("loadFromDatabase() - ERR: settings NOT found...")
        }
        
        
        // Categories
        for crec in Database.getCategoryRecords(){
            addCategory(key:(crec.key)!, title:(crec.title)!)
        }
        
        // Build Category array from dictionary. More convenient than a dictionary
        categoryList = Array(categoryDictionary.keys)
        categoryList.sort(by: sortClosure)
        
        // Assignments
        for arec in Database.getAssignmentRecords(){
            addAssignment(category:arec.category!, filters:arec.filters)
        }
        

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
        
        
        // Categories
        
        let crec: CategoryRecord = CategoryRecord()
        for key in FilterLibrary.categoryList {
            crec.key = key
            crec.title = FilterLibrary.categoryDictionary[key]
            crec.hide = false
            Database.updateCategoryRecord(crec)
        }
        
        /***
        // Standard and Lookup filters
        let frec: FilterRecord = FilterRecord()
        let lrec: LookupFilterRecord = LookupFilterRecord()
        
        for key in FilterFactory.getFilterList() {
            // built-in or preset?
            if (FilterLibrary.lookupDictionary[key] == nil){ // built-in filter
                frec.key = key
                frec.hide = FilterFactory.isHidden(key: key)
                frec.rating = FilterFactory.getRating(key: key)
                Database.updateFilterRecord(frec)
            } else { // Lookup Filter
                lrec.key = key
                lrec.image = FilterLibrary.lookupDictionary[key]
                lrec.hide = FilterFactory.isHidden(key: key)
                lrec.rating = FilterFactory.getRating(key: key)
                Database.updateLookupFilterRecord(lrec)
            }
        }
         ***/

        // Category->Filter Assignments
        
        let arec:AssignmentRecord = AssignmentRecord()
        
        for category in FilterLibrary.categoryList {
            arec.category = category
            arec.filters = []
            if (FilterLibrary.categoryFilters[category] != nil){
                if ((FilterLibrary.categoryFilters[category]?.count)! > 0){
                    for f in (FilterLibrary.categoryFilters[category])!{
                        arec.filters.append(f)
                    }
                    //arec.filters = (FilterLibrary.categoryFilters[category])!
                } else {
                    print("commitChanges()() no filters found for: \(category)")
                }
            } else {
                print("commitChanges()() no filters found for: \(category)")
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

 
        Database.save()
    }

}

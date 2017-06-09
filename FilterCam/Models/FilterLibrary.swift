//
//  FilterLibrary
//  FilterCam
//
//  Created by Philip Price on 12/2/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage
import SwiftyJSON

// Static class that provides the data structures for holding the category and filter information, and also methods for loading from/saving to config files

class FilterLibrary{

    fileprivate static var initDone:Bool = false
    fileprivate static var saveDone:Bool = false

    static let sortClosure = { (value1: String, value2: String) -> Bool in return value1 < value2 }
    
    //////////////////////////////////////////////
    //MARK: - Category/Filter "Database"
    //////////////////////////////////////////////
    
    // The dictionary of Categories (key, title). key is category name
    open static var categoryDictionary:[String:String] = [:]
    open static var categoryList:[String] = []
    
    // Dictionary of FilterDescriptors (key, FilterDescriptorInterface). key is filter name
    open static var filterDictionary:[String:FilterDescriptorInterface?] = [:]
    
    // Dictionary of Lookup images (key, image name). key is filter name
    open static var lookupDictionary:[String:String] = [:]
    
    // Dictionary of Category Dictionaries. Use category as key to get list of filters in that category
    //typealias FilterList = Array<String>
    //typealias FilterList = [String]
    //open static var categoryFilters:[String:FilterList] = [:]
    open static var categoryFilters:[String:[String]] = [:]

    
    //////////////////////////////////////////////
    //MARK: - Setup/Teardown
    //////////////////////////////////////////////
    
    open static func checkSetup(){
        if (!FilterLibrary.initDone) {
            FilterLibrary.initDone = true
            
            // 'restore' the configuration from the setup file
            FilterLibrary.restore()
        }
        
    }
    
    fileprivate init(){
        FilterLibrary.checkSetup()
    }
    
    deinit{
        if (!FilterLibrary.saveDone){
            FilterLibrary.saveDone = true
            FilterLibrary.save()
        }
    }
    
    
    ////////////////////////////
    // Restore from persistent storage
    ////////////////////////////
    
    
    open static func restore(){
        
        // TODO: check version number and/or allow 'reset' to contents of config file
        if (Database.isSetup()){
            loadFromDatabase()
        } else {
            loadFromConfigFile()
            commitChanges()
        }
    }

   
    // restore default parameters from the config file
    open static func restoreDefaults(){
        loadFromConfigFile()
        commitChanges()
    }
    
    ////////////////////////////
    // Config File Processing
    ////////////////////////////
    
    
    fileprivate static let configFile = "FilterConfig"
    
    fileprivate static var parsedConfig:JSON = JSON.null
    
    
    fileprivate  static func loadFromConfigFile(){
        var count:Int = 0
        var key:String
        var value:String
        var hide:Bool
        var rating:Int
     
        categoryDictionary = [:]
        categoryList = []
        filterDictionary = [:]
        lookupDictionary = [:]
        categoryFilters = [:]
        
        print ("FilterLibrary.loadFromConfigFile() - loading configuration...")
        
        // find the configuration file, which must be part of the project
        let path = Bundle.main.path(forResource: configFile, ofType: "json")
        
        do {
            // load the file contents and parse the JSON string
            let fileContents = try NSString(contentsOfFile: path!, encoding: String.Encoding.utf8.rawValue) as String
            if let data = fileContents.data(using: String.Encoding.utf8) {
                parsedConfig = JSON(data: data)
                if (parsedConfig != JSON.null){
                    print("restore() - parsing data")
                    //print ("\(parsedConfig)")
                    
                    // Category list
                    count = 0
                    for item in parsedConfig["categories"].arrayValue {
                        count = count + 1
                        key = item["key"].stringValue
                        value = item["title"].stringValue
                        addCategory(key:key, title:value)
                    }
                    print ("\(count) Categories found")
                    
                    // Build Category array from dictionary. More convenient than a dictionary
                    categoryList = Array(categoryDictionary.keys)
                    categoryList.sort(by: sortClosure)
                    
                    // Filter list
                    count = 0
                    for item in parsedConfig["filters"].arrayValue {
                        count = count + 1
                        key = item["key"].stringValue
                        value = item["class"].stringValue
                        hide = item["hide"].boolValue
                        rating = item["rating"].intValue
                        addFilter(key:key, classname:value, hide:hide, rating:rating)
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
            print("restore() - ERROR : reading from presets file : \(error.localizedDescription)")
        }
    }




    open static func save(){
        print ("FilterLibrary.save() - saving configuration...")
        commitChanges()
    }

 
    
    private static func addCategory(key:String, title:String){
        // just add the data to the dictionary
        FilterLibrary.categoryDictionary[key] = title
        print("addCategory(\(key), \(title))")
    }
  
    
    
    private static func addFilter(key:String, classname:String, hide:Bool, rating:Int){
        /*
        // create an instance from the classname and add it to the dictionary
        var descriptor:FilterDescriptorInterface? = nil
        let ns = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
        let className = ns + "." + classname
        let theClass = NSClassFromString(className) as! FilterDescriptorInterface.Type
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
        FilterFactory.addFilterDefinition(key: key, classname: classname,  hide:hide, rating:rating)
        print("addFilter(\(key), \(classname), \(hide), \(rating))")
    }
    
    
    
    private static func addLookup(key:String, image:String, hide:Bool, rating:Int){
        
        let l = image.components(separatedBy:".")
        let title = l[0]
        let ext = l[1]
        
        guard let path = Bundle.main.path(forResource: title, ofType: ext) else {
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
        FilterFactory.addFilterDefinition(key: key, classname: "",  hide:hide, rating:rating)
        print("addLookup(\(key), \(image), \(hide), \(rating))")
    }
    
    
    
    private static func addAssignment(category:String, filters: [String]){
        FilterLibrary.categoryFilters[category] = filters
        print("addAssignment(\(category), \(filters))")
       
        if (!FilterLibrary.categoryList.contains(category)){
            print("addAssignment() ERROR: invalid category:\(category)")
        }
        
        // double-check that filters exist
        //for key in filters {
        //    if (FilterLibrary.filterDictionary[key] == nil){
        //        print("addAssignment() ERROR: Filter not defined: \(key)")
        //    }
        //}
        //print("Category:\(category) Filters: \(filters)")
    }

    
    
    
    ////////////////////////////
    // Database Processing
    ////////////////////////////
    
    fileprivate static func loadFromDatabase(){

        categoryDictionary = [:]
        categoryList = []
        filterDictionary = [:]
        lookupDictionary = [:]
        categoryFilters = [:]

        
        // restore the settings
        
        if let settings = Database.getSettings() {
            print("loadFromDatabase() - Restoring Settings: Sample:\(settings.sampleImage!) Blend:\(settings.blendImage!) Edit:\(settings.editImage!)")
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
        
        
        
        // Builtin Filters
        for frec in Database.getFilterRecords(){
            if (frec.key != nil){
                if (frec.classname != nil){
                    addFilter(key:frec.key!, classname:frec.classname!, hide:frec.hide, rating:frec.rating)
                } else {
                    print("loadFromDatabase() - NIL classname returned")
                }
            } else {
                print("loadFromDatabase() - NIL key returned")
            }
        }
        
        
        
        // Lookup Filters
        for lrec in Database.getLookupLookupFilterRecords(){
            addLookup(key:lrec.key!, image:lrec.image!, hide:lrec.hide, rating:lrec.rating)
        }
        
        
        
        // Assignments
        for arec in Database.getAssignmentRecords(){
            addAssignment(category:arec.category!, filters:arec.filters)
        }

/***
        // TEMP: just load config file until full database is ready
        print("loadFromDatabase() - TEMP: loading config file anyway...")
        loadFromConfigFile()
        commitChanges()()
***/
        
    }
    
    
    open static func commitChanges(){
        
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
        
        // Standard and Lookup filters
        let frec: FilterRecord = FilterRecord()
        let lrec: LookupFilterRecord = LookupFilterRecord()
        
        for key in FilterFactory.getFilterList() {
            // built-in or preset?
            if (FilterLibrary.lookupDictionary[key] == nil){ // built-in filter
                frec.key = key
                frec.classname = FilterFactory.getClassname(key: key)
                frec.title = frec.classname //TODO: fix title
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
        
        // Category->Filter Assignments
        
        let arec:AssignmentRecord = AssignmentRecord()
        
        for category in FilterLibrary.categoryList {
            arec.category = category
            arec.filters = []
            if ((FilterLibrary.categoryFilters[category]?.count)! > 0){
                for f in (FilterLibrary.categoryFilters[category])!{
                    arec.filters.append(f)
                }
                //arec.filters = (FilterLibrary.categoryFilters[category])!
            } else {
                print("commitChanges()() no filters found for: \(category)")
            }
            Database.updateAssignmentRecord(arec)
        }

        Database.save()
    }

}

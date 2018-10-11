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

    static let sortClosure = { (value1: String, value2: String) -> Bool in return value1 < value2 }
    
    //////////////////////////////////////////////
    //MARK: - Category/Filter "Database"
    //////////////////////////////////////////////
    
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
    
    
    public static func restore(){
        
        // TODO: check version number and/or allow 'reset' to contents of config file
        //if (Database.isSetup()){
        //    loadFromDatabase()
        //} else {
            loadFromConfigFile()
            commitChanges()
        //}
    }

   
    // restore default parameters from the config file
    public static func restoreDefaults(){
        loadFromConfigFile()
        commitChanges()
    }
    
    ////////////////////////////
    // Config File Processing
    ////////////////////////////
    
    
    fileprivate static let configFile = "FilterConfig"
    //fileprivate static let configFile = "testFilterConfig"

    fileprivate static var parsedConfig:JSON = JSON.null
    
    
    fileprivate  static func loadFromConfigFile(){
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
                print("restore() - parsing data from: \(path!)")
                parsedConfig = try JSON(data: data)
                if (parsedConfig != JSON.null){
                    print("restore() - parsing data")
                    //print ("\(parsedConfig)")
                    
                    // version
                    version = parsedConfig["version"].floatValue
                    print ("version: \(version)")
                    
                    // Category list
                    count = 0
                    for item in parsedConfig["categories"].arrayValue {
                        count = count + 1
                        key = item["key"].stringValue
                        title = item["title"].stringValue
                        addCategory(key:key, title:title)
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
                        title = item["title"].stringValue
                        ftype = item["ftype"].stringValue
                        hide = item["hide"].boolValue
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
        FilterLibrary.categoryFilters[category] = []
        var list:[String] = []
        let validKeys = FilterFactory.getFilterList()
        for f in filters {
            if (validKeys.contains(f)) {
                list.append(f)
            } else {
                log.warning("Ignoring filter: \(f)")
            }
        }
        FilterLibrary.categoryFilters[category] = list
        //FilterLibrary.categoryFilters[category] = filters
        //print("addAssignment(\(category), \(filters))")
       
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

    public static func commitChanges(){
        log.warning("TODO: save updates and restore")
    }
}

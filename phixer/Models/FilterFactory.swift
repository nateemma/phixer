//
//  FilterFactory.swift
//  phixer
//
//  Created by Philip Price on 12/15/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation


// Class that handles creating a specific filter type from its String representation

class FilterFactory{
    
    private static var filterList: [String:String] = [:]
    private static var typeList: [String:String] = [:]
    private static var hideList: [String:Bool] = [:]
    private static var ratingList: [String:Int] = [:]
    private static var settingsList: [String:[FilterDescriptor.ParameterSettings]] = [:]
    private static var lookupList: [String:String] = [:]

    private static var initDone: Bool  = false
    
    // since this is a static class, there are no guarantees that initialisation will be complete before one of the methods is called,
    // so always check that init has been done from each function
    
    private static func checkSetup(){
        if (!FilterFactory.initDone){
            FilterFactory.initDone = true
            FilterFactory.filterList = [:]
            FilterFactory.typeList = [:]
            FilterFactory.hideList = [:]
            FilterFactory.ratingList = [:]
            FilterFactory.settingsList = [:]
            FilterFactory.lookupList = [:]
        }
    }
    
    // return the full filter list
    public static func getFilterList() -> [String]{
        return Array(filterList.keys)
    }
    
    
    // Adds a filter definition to the dictionary
    public static func addFilterDefinition(key: String, title: String,  ftype: String, hide:Bool, rating:Int, settings:[FilterDescriptor.ParameterSettings]){

        checkSetup()
        FilterFactory.filterList[key] = title
        FilterFactory.typeList[key] = ftype
        FilterFactory.hideList[key] = hide
        FilterFactory.ratingList[key] = rating
        FilterFactory.settingsList[key] = settings
        //log.verbose("ADD Filter - key:\(key) classname:\(classname) show:\(show) rating:\(rating)")
    }
    
    
    /*** old way
    // Creates an object of the appropriate class based on the supplied key
    public static func createFilter(key:String)->FilterDescriptor?{
        var descriptor:FilterDescriptor? = nil
        
        checkSetup()
        
        // find the class name from the key
        
        if (FilterFactory.filterList[key] != nil){
            let classname = (FilterFactory.filterList[key])!
            
            // create an instance from the classname and add it to the dictionary
            let ns = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
            let className = ns + "." + classname
            let theClass = NSClassFromString(className) as! FilterDescriptor.Type
            descriptor = theClass.init() // NOTE: this only works because we know that the protocol requires the init() func
            
            if (descriptor == nil){
                print ("FilterFactory.createFilter() ERR: Could not create class: \(classname)")
            } else {
                descriptor?.show = FilterFactory.hideList[key]!
                descriptor?.rating = FilterFactory.ratingList[key]!
            }
            
        } else {
            print ("FilterFactory.createFilter() ERR: Unkown class: \(key)")
        }
        
        
        return descriptor
    }
    
    // returns the classname of the requested filter. nil if not found
    public static func getClassname(key:String)->String?{
        return FilterFactory.filterList[key]
    }
     ***/

    
    
    public static func createFilter(key:String)->FilterDescriptor?{
        var descriptor:FilterDescriptor? = nil
        
        checkSetup()
        
        
        descriptor = nil
        
         if (FilterFactory.filterList[key] != nil){
            log.verbose("Creating descriptor for: \(key)")
            let stype = FilterFactory.typeList[key]
            let ftype: FilterDescriptor.FilterOperationType
            if stype != nil {
                ftype = FilterDescriptor.FilterOperationType(rawValue:stype!)!
            } else {
                log.error("NIL Operation Type for filter: \(key)")
                // assume lookup, because this is normal for that case
                //FilterFactory.typeList[key] = FilterDescriptor.FilterOperationType.lookup.rawValue
                //ftype = FilterDescriptor.FilterOperationType.lookup
                ftype = FilterDescriptor.FilterOperationType.singleInput
            }
            var params = FilterFactory.settingsList[key]
            if (params == nil) {
                //log.warning("NIL parameters for filter: \(key)") // it might be valid, as some types of parameters are not added to the list
                params = []
            }
            descriptor = FilterDescriptor(key: key, title: FilterFactory.filterList[key]!, ftype: ftype, parameters: params!)
            descriptor?.show = FilterFactory.hideList[key]!
            descriptor?.rating = FilterFactory.ratingList[key]!
            //if ftype == .lookup {
            //    descriptor?.setLookupImage(FilterFactory.lookupList[key]!)
            //}
        } else {
            print ("FilterFactory.createFilter() ERR: Unkown class: \(key)")
        }
        
        
        return descriptor
    }
    

    
    
    
    // // adds an entry for a lookup filter and sets up a 'pseudo' filter definition
    public static func addLookupFilter(key:String, title: String, image:String,  hide:Bool, rating:Int) {
        if FilterFactory.lookupList[key] != nil {
            log.warning("Overwriting Lookup Filter for key:\(key), image:\(image)")
        }
        
        // set up entries for the lookup filter
        FilterLibrary.filterDictionary[key] = nil // forces lazy allocation
        FilterFactory.filterList[key] = title
        FilterFactory.typeList[key] = FilterDescriptor.FilterOperationType.lookup.rawValue
        FilterFactory.lookupList[key] = image
        FilterFactory.hideList[key] = hide
        FilterFactory.ratingList[key] = rating
        log.verbose("Created Lookup filter:\(key) image:\(image)")
    }
    
    // get the (readable) title of the filter
    public static func getTitle(key: String)->String{
        if (FilterFactory.filterList[key] != nil){
            return (FilterFactory.filterList[key]!)
        } else {
            log.error("ERR: unknown key:\"\(key)\"")
            return ""
        }
    }

    
    // get the type of the filter
    public static func getFilterType(key: String)->String{
        if (FilterFactory.typeList[key] != nil){
            return (FilterFactory.typeList[key]!)
        } else {
            log.error("ERR: unknown key:\"\(key)\"")
            return ""
        }
    }

    // indicates whether filter should be hidden or not
    public static func isHidden(key: String)->Bool{
        if (FilterFactory.hideList[key] != nil){
            return (FilterFactory.hideList[key]!)
        } else {
            log.error("ERR: unknown key:\"\(key)\"")
            return true
        }
    }

    
    // sets the hidden state of a filter
    public static func setHidden(key: String, hidden:Bool) {
        if (FilterFactory.hideList[key] != nil){
            FilterFactory.hideList[key] = hidden
        } else {
            log.error("ERR: unknown key:\"\(key)\"")
        }
    }
    
    public static func getRating(key:String) -> Int{
        if (FilterFactory.ratingList[key] != nil){
            return FilterFactory.ratingList[key]!
        } else {
            return 0
        }
    }
    
    // set the rating for a filter
    public static func setRating(key:String, rating:Int){
        if (FilterFactory.ratingList[key] != nil){
            FilterFactory.ratingList[key] = rating
        }else {
            log.error("ERR: unknown key:\"\(key)\"")
        }
    }

}

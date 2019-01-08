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
    

    
    private static var filterList: [String:FilterDefinition] = [:]
    //private static var typeList: [String:String] = [:]
    //private static var hideList: [String:Bool] = [:]
    //private static var ratingList: [String:Int] = [:]
    //private static var settingsList: [String:[FilterDescriptor.ParameterSettings]] = [:]
    //private static var lookupList: [String:String] = [:]

    private static var initDone: Bool  = false
    
    // since this is a static class, there are no guarantees that initialisation will be complete before one of the methods is called,
    // so always check that init has been done from each function
    
    private static func checkSetup(){
        if (!FilterFactory.initDone){
            FilterFactory.initDone = true
            FilterFactory.filterList = [:]
        }
    }
    
    // return the full filter list
    public static func getFilterList() -> [String]{
        return Array(filterList.keys)
    }
    
    
    // Adds a filter definition to the dictionary
    public static func addFilterDefinition(key: String, definition:FilterDefinition){

        checkSetup()
        FilterFactory.filterList[key] = definition
        //log.verbose("ADD Filter - key:\(key) classname:\(classname) show:\(show) rating:\(rating)")
    }
    
 
    
    
    public static func createFilter(key:String)->FilterDescriptor?{
        var descriptor:FilterDescriptor? = nil
        
        checkSetup()
        
        
        descriptor = nil
        
         if (FilterFactory.filterList[key] != nil){
            //log.verbose("Creating descriptor for: \(key)")
            let def = FilterFactory.filterList[key]
            descriptor = FilterDescriptor(key: key, definition:def!)
        } else {
            print ("FilterFactory.createFilter() ERR: Unkown class: \(key)")
        }
        
        return descriptor
    }
    

    
    
    
    // // adds an entry for a lookup filter and sets up a 'pseudo' filter definition
    public static func addLookupFilter(key:String, definition:FilterDefinition) {
        if FilterFactory.filterList[key] != nil {
            log.warning("Overwriting Lookup Filter for key:\(key), image:\(definition.lookup)")
        }
        
        // set up entries for the lookup filter
        FilterLibrary.filterDictionary[key] = nil // forces lazy allocation
        FilterFactory.filterList[key] = definition
        log.verbose("Created Lookup filter:\(key) image:\(definition.lookup)")
    }
    
    // get the (readable) title of the filter
    public static func getTitle(key: String)->String{
        if (FilterFactory.filterList[key] != nil){
            return ((FilterFactory.filterList[key]?.title)!)
        } else {
            log.error("ERR: unknown key:\"\(key)\"")
            return ""
        }
    }

    
    // get the type of the filter
    public static func getFilterType(key: String)->String{
        if (FilterFactory.filterList[key] != nil){
            return (FilterFactory.filterList[key]?.ftype)!
        } else {
            log.error("ERR: unknown key:\"\(key)\"")
            return ""
        }
    }

    // indicates whether filter should be hidden or not
    public static func isHidden(key: String)->Bool{
        if (FilterFactory.filterList[key] != nil){
            return (FilterFactory.filterList[key]?.hide)!
        } else {
            log.error("ERR: unknown key:\"\(key)\"")
            return true
        }
    }

    
    // sets the hidden state of a filter
    public static func setHidden(key: String, hidden:Bool) {
        if (FilterFactory.filterList[key] != nil){
            FilterFactory.filterList[key]!.hide = hidden
        } else {
            log.error("ERR: unknown key:\"\(key)\"")
        }
    }
    
    public static func getRating(key:String) -> Int{
        if (FilterFactory.filterList[key] != nil){
            return FilterFactory.filterList[key]!.rating
        } else {
            return 0
        }
    }
    
    // set the rating for a filter
    public static func setRating(key:String, rating:Int){
        if (FilterFactory.filterList[key] != nil){
            FilterFactory.filterList[key]!.rating = rating
        }else {
            log.error("ERR: unknown key:\"\(key)\"")
        }
    }

}

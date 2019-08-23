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
    fileprivate static var hideList: [String:Bool] = [:]
    fileprivate static var ratingList: [String:Int] = [:]
    fileprivate static var slowList: [String:Bool] = [:]
    //private static var settingsList: [String:[FilterDescriptor.ParameterSettings]] = [:]
    //private static var lookupList: [String:String] = [:]

    private static var initDone: Bool  = false
    
    // since this is a static class, there are no guarantees that initialisation will be complete before one of the methods is called,
    // so always check that init has been done from each function
    
    private static func checkSetup(){
        if (!FilterFactory.initDone){
            FilterFactory.initDone = true
            FilterFactory.filterList = [:]
            FilterFactory.hideList = [:]
            FilterFactory.ratingList = [:]
            FilterFactory.slowList = [:]
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
            // not present in list, so try to create
            let def = FilterConfiguration.makeFilterDefinition(key)
            if def != nil {
                FilterConfiguration.addFilter(key:(def?.key)!, definition:def!)
                descriptor = FilterDescriptor(key: key, definition:def!)
                FilterFactory.filterList[key] = def
            } else {
                print ("FilterFactory.createFilter() ERR: Unkown class: \(key)")
            }
        }
        
        if descriptor != nil {
            descriptor?.slow = isSlow(key: key)
            descriptor?.show = !isHidden(key: key)
            descriptor?.rating = getRating(key: key)
        }
        
        return descriptor
    }
    

    
    
    
    // // adds an entry for a lookup filter and sets up a 'pseudo' filter definition
    public static func addLookupFilter(key:String, definition:FilterDefinition) {
        if FilterFactory.filterList[key] != nil {
            log.warning("Overwriting Lookup Filter for key:\(key), image:\(definition.lookup)")
        }
        
        // set up entries for the lookup filter
        //FilterDescriptorCache.get(key:key) = nil // forces lazy allocation
        FilterFactory.filterList[key] = definition
        //log.verbose("Created Lookup filter:\(key) image:\(definition.lookup)")
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
        if (FilterFactory.hideList[key] != nil){
            return FilterFactory.hideList[key]!
        } else {
            return false
        }
//        if (FilterFactory.filterList[key] != nil){
//            return (FilterFactory.filterList[key]?.hide)!
//        } else {
//            log.error("ERR: unknown key:\"\(key)\"")
//            return false
//        }
    }

    
    // sets the hidden state of a filter
    public static func setHidden(key: String, hidden:Bool) {
        FilterFactory.hideList[key] = hidden
//        if (FilterFactory.filterList[key] != nil){
//            FilterFactory.filterList[key]!.hide = hidden
//        } else {
//            log.error("ERR: unknown key:\"\(key)\"")
//        }
    }
    
    // sets the hidden state of a filter
    public static func setSlow(key: String, slow:Bool) {
        FilterFactory.slowList[key] = slow
//        if (FilterFactory.filterList[key] != nil){
//            FilterFactory.filterList[key]!.slow = slow
//        } else {
//            log.error("ERR: unknown key:\"\(key)\"")
//        }
    }
    
    // indicates whether filter is slow or not
    public static func isSlow(key: String)->Bool{
        if (FilterFactory.slowList[key] != nil){
            return FilterFactory.slowList[key]!
        } else {
            return false
        }
//        if (FilterFactory.filterList[key] != nil){
//            return (FilterFactory.filterList[key]?.slow)!
//        } else {
//            log.error("ERR: unknown key:\"\(key)\"")
//            return false
//        }
    }
    
    public static func getRating(key:String) -> Int{
        if (FilterFactory.ratingList[key] != nil){
            return FilterFactory.ratingList[key]!
        } else {
            return 0
        }
//        if (FilterFactory.filterList[key] != nil){
//            return FilterFactory.filterList[key]!.rating
//        } else {
//            return 0
//        }
    }
    
    // set the rating for a filter
    public static func setRating(key:String, rating:Int){
        FilterFactory.ratingList[key] = rating
//        if (FilterFactory.filterList[key] != nil){
//            FilterFactory.filterList[key]!.rating = rating
//        }else {
//            log.error("ERR: unknown key:\"\(key)\"")
//        }
    }

}

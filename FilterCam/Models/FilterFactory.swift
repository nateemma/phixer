//
//  FilterFactory.swift
//  FilterCam
//
//  Created by Philip Price on 12/15/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation


// Class that handles creating a specific filter type from its String representation

class FilterFactory{
    
    private static var filterList: [String:String] = [:]
    private static var hideList: [String:Bool] = [:]
    private static var ratingList: [String:Int] = [:]
    
    private static var initDone: Bool  = false
    
    // since this is a static class, there are no guarantees that initialisation will be complete before one of the methods is called,
    // so always check that init has been done from each function
    
    private static func checkSetup(){
        if (!FilterFactory.initDone){
            FilterFactory.initDone = true
            FilterFactory.filterList = [:]
            FilterFactory.hideList = [:]
            FilterFactory.ratingList = [:]
        }
    }
    
    // return the full filter list
    open static func getFilterList() -> [String]{
        return Array(filterList.keys)
    }
    
    
    // Adds a filter definition to the dictionary
    open static func addFilterDefinition(key: String, classname: String,  hide:Bool, rating:Int){
        checkSetup()
        FilterFactory.filterList[key] = classname
        FilterFactory.hideList[key] = hide
        FilterFactory.ratingList[key] = rating
        //log.verbose("ADD Filter - key:\(key) classname:\(classname) show:\(show) rating:\(rating)")
    }
    
    
    
    // Creates an object of the appropriate class based on the supplied key
    open static func createFilter(key:String)->FilterDescriptorInterface?{
        var descriptor:FilterDescriptorInterface? = nil
        
        checkSetup()
        
        // find the class name from the key
        
        if (FilterFactory.filterList[key] != nil){
            let classname = (FilterFactory.filterList[key])!
            
            // create an instance from the classname and add it to the dictionary
            let ns = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
            let className = ns + "." + classname
            let theClass = NSClassFromString(className) as! FilterDescriptorInterface.Type
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
    open static func getClassname(key:String)->String?{
        return FilterFactory.filterList[key]
    }
    
    // indicates whether filter should be hidden or not
    open static func isHidden(key: String)->Bool{
        if (FilterFactory.hideList[key] != nil){
            return (FilterFactory.hideList[key]!)
        } else {
            log.error("ERR: unknown key:\"\(key)\"")
            return true
        }
    }
    
    
    // sets the hidden state of a filter
    open static func setHidden(key: String, hidden:Bool) {
        if (FilterFactory.hideList[key] != nil){
            FilterFactory.hideList[key] = hidden
        } else {
            log.error("ERR: unknown key:\"\(key)\"")
        }
    }
    
    open static func getRating(key:String) -> Int{
        if (FilterFactory.ratingList[key] != nil){
            return FilterFactory.ratingList[key]!
        } else {
            return 0
        }
    }
    
    // set the rating for a filter
    open static func setRating(key:String, rating:Int){
        if (FilterFactory.ratingList[key] != nil){
            FilterFactory.ratingList[key] = rating
        }else {
            log.error("ERR: unknown key:\"\(key)\"")
        }
    }

}

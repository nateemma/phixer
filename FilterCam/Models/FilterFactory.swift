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
    private static var initDone: Bool  = false
    
    // since this is a static class, there are no guarantees that initialisation will be complete before one of the methods is called,
    // so always check that init has been done from each function
    
    private static func checkSetup(){
        if (!FilterFactory.initDone){
            FilterFactory.initDone = true
            filterList = [:]
        }
    }
    
    
    
    
    // Adds a filter definition to the dictionary
    open static func addFilterDefinition(key: String, classname: String){
        checkSetup()
        FilterFactory.filterList[key] = classname
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
            }
            
        } else {
            print ("FilterFactory.createFilter() ERR: Unkown class: \(key)")
        }
        
        
        return descriptor
    }
}

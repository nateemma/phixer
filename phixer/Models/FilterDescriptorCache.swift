//
//  FilterDescriptorCache.swift
//  phixer
//
//  Created by Philip Price on 1/25/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

// static cache that can be used to store and retrieve FilterDescriptor objects
// Primarily intended for use where images are created by controllers or main views, then used when a display needs them (usually a UICollectionViewCell)
// NOTE: Controllers/Collections should remove any entries when they are done with them

import Foundation
import CoreImage


class FilterDescriptorCache {
    
    // The cache
    private static var cache = NSCache<NSString, FilterDescriptor>()
    
    
    // make initialiser private to prevent instantiation
    private init(){}

    
    // add/replace a FilterDescriptor
    public static func add(_ image:FilterDescriptor?, key:String){
        guard image != nil, !key.isEmpty else {
            log.error("Empty parameter for key:\(key). Ignored")
            return
        }
        
        cache.setObject(image!, forKey: key as NSString)
        //log.verbose("Added: \(key)")
    }
   
    
    // remove a FilterDescriptor
    public static func remove(key:String){
        guard !key.isEmpty else {
            log.error("Empty key. Ignored")
            return
        }

        cache.removeObject(forKey: key as NSString)
        //log.verbose("Removed: \(key)")
    }

    
    // get the FilterDescriptor for the supplied key
    public static func get(key: String) -> FilterDescriptor? {
        guard !key.isEmpty else {
            log.error("Empty key. Ignored")
            return nil
        }
        
        return cache.object(forKey: key as NSString)
    }
    
    
    // check whether a FilterDescriptor is present for the supplied key
    public static func contains(key: String) -> Bool {
        guard !key.isEmpty else {
            log.error("Empty key. Ignored")
            return false
        }
        
       return (cache.object(forKey: key as NSString) != nil)
    }
    
    
    // clear the entire cache
    public static func clear() {
        cache.removeAllObjects()
    }
}

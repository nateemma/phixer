//
//  RenderViewCache.swift
//  phixer
//
//  Created by Philip Price on 1/25/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

// static cache that can be used to store and retrieve RenderView objects
// Primarily intended for use where images are created by controllers or main views, then used when a display needs them (usually a UICollectionViewCell)
// NOTE: Controllers/Collections should remove any entries when they are done with them

import Foundation
import CoreImage


class RenderViewCache {
    
    // The cache
    private static var cache = NSCache<NSString, RenderView>()
    
    
    // make initialiser private to prevent instantiation
    private init(){}

    
    // add/replace a RenderView
    public static func add(_ image:RenderView?, key:String){
        guard image != nil, !key.isEmpty else {
            log.error("Empty parameter for key:\(key). Ignored")
            return
        }
        
        cache.setObject(image!, forKey: key as NSString)
        //log.verbose("Added: \(key)")
    }
   
    
    // remove a RenderView
    public static func remove(key:String){
        guard !key.isEmpty else {
            log.error("Empty key. Ignored")
            return
        }

        cache.removeObject(forKey: key as NSString)
        //log.verbose("Removed: \(key)")
    }

    
    // get the RenderView for the supplied key
    public static func get(key: String) -> RenderView? {
        guard !key.isEmpty else {
            log.error("Empty key. Ignored")
            return nil
        }
        
        return cache.object(forKey: key as NSString)
    }
    
    
    // check whether a RenderView is present for the supplied key
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

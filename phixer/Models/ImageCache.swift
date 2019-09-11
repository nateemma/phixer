//
//  ImageCache.swift
//  phixer
//
//  Created by Philip Price on 1/25/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

// static cache that can be used to store and retrieve (CI)Images.
// Primarily intended for use where images are created by controllers or main views, then used when a display needs them (usually a UICollectionViewCell)
// NOTE: Controllers/Collections should remove any entries when they are done with them

import Foundation
import CoreImage


class ImageCache {
    
    // The cache
    private static var cache = NSCache<NSString, CIImage>()
    
    // reference counted list of locked images. Image will not be removed if locked
    fileprivate static var _lockList:[String:Int] = [:]
    
    // make initialiser private to prevent instantiation
    private init(){}
    
    // 'locks' an image in cache
    public static func lock(key: String){
        
        log.debug("key:\(key)")
        if (ImageCache._lockList[key] == nil){
            ImageCache._lockList[key] = 0
        }
        ImageCache._lockList[key] = ImageCache._lockList[key]! + 1
    }
    
    // decrements the reference count unlocks an image. Note that the image is *not* removed from cache
    public static func unlock(key: String){
        
        log.debug("key:\(key)")
        if (ImageCache._lockList[key] != nil){
            ImageCache._lockList[key] = ImageCache._lockList[key]! - 1
            if (ImageCache._lockList[key]! <= 0) {
                //ImageCache._lockList[key] = nil
                ImageCache._lockList.removeValue(forKey: key)
            }
        }
    }
    
    public static func isLocked(key: String) -> Bool {
        var locked:Bool = false
        if ImageCache._lockList.count > 0 {
            if ImageCache._lockList[key] != nil {
                if let count = ImageCache._lockList[key]{
                    if count > 0 {
                        locked = true
                    }
                }
            }
        }
        return locked
    }
    
    // add/replace an image
    public static func add(_ image:CIImage?, key:String){
        guard image != nil, !key.isEmpty else {
            log.error("Empty parameter for key:\(key). Ignored")
            return
        }
        
        cache.setObject(image!, forKey: key as NSString)
        //log.verbose("Added: \(key)")
    }
   
    
    // remove an image
    public static func remove(key:String){
        guard !key.isEmpty else {
            log.error("Empty key. Ignored")
            return
        }

        if (!isLocked(key: key)){
            cache.removeObject(forKey: key as NSString)
            //log.verbose("Removed: \(key)")
        }
    }

    
    // get the image for the supplied key
    public static func get(key: String) -> CIImage? {
        guard !key.isEmpty else {
            log.error("Empty key. Ignored")
            return nil
        }
        
        return cache.object(forKey: key as NSString)
    }
    
    
    // check whether an image is present for the supplied key
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

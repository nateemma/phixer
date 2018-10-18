//
//  MuliticastDelegate.swift
//  Generic class to efficiently support implementation of multicast delegates while avoiding ARC memory leak issues
//
//  Created by Philip Price on 10/17/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation


class MulticastDelegate <T> {
    //private let delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    //private let delegates: NSMapTable<NSString, AnyObject> = NSMapTable<NSString, AnyObject>(keyOptions: .StrongMemory, valueOptions: .weakMemory)
    private let delegates: NSMapTable<NSString, AnyObject> = NSMapTable<NSString, AnyObject>.strongToWeakObjects()
    
    func add(key:String, delegate: T) {
        delegates.setObject(delegate as AnyObject, forKey:key as NSString)
    }
   
    
    func remove(key:String) {
        delegates.removeObject(forKey: key as NSString)
    }
    
    
    func invoke(invocation: (T) -> ()) {
        if delegates.count > 0 {
            let enumerator = delegates.objectEnumerator()
            
            while let delegate = enumerator?.nextObject() {
                invocation(delegate as! T)
            }
        }
    }
    
    
    func count()->Int{
        return delegates.count
    }
}


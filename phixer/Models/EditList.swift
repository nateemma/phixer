//
//  EditList.swift
//  phixer
//
//  Created by Philip Price on 7/6/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

// This is a set of functions to keep track of the list of photos that have been edited. The list is persistent

import Foundation


class EditList {
    
    private static var _editList:[String] = []
    private static var loaded:Bool = false
    private static let maxItems:Int = 6
    private static let assetKey = "editList"
    
    
    // add an asset to the list
    public static func add(_ name: String) {
        EditList.checkList()
        guard (!name.isEmpty) else {
            return
        }
        EditList.remove(name)
        if EditList._editList.count > 0 {
            EditList._editList.insert(name, at: 0)
        } else {
            EditList._editList.append(name)
        }
    }
    
    
    // remove an asset from the list (probably not needed)
    public static func remove(_ name: String) {
        EditList.checkList()
        guard (!name.isEmpty) else {
            return
        }
        if EditList._editList.count > 0 {
            if EditList._editList.contains(name) {
                for i in 0...EditList._editList.count-1 {
                    if (EditList._editList[i] == name){
                        EditList._editList.remove(at: i)
                        break
                    }
                }
            }
        }
    }
    
    // get the current list
    public static func get() -> [String] {
        EditList.checkList()
        return EditList._editList
    }
    
    // load the list from persistent storage
    public static func load() {
        EditList.checkList()
    }
    
    // save the current list to persistent storage
    public static func save() {
        let rec:AssetListRecord = AssetListRecord()
        rec.key = EditList.assetKey
        rec.assets = EditList._editList
        log.verbose("Saved List: \(EditList._editList)")

        DispatchQueue.global(qos: .background).async() {
            //Database.addAssetListRecord(rec)
            //Database.clearAssetListRecords()
            Database.updateAssetListRecord(rec)
            Database.save()
        }
    }
    
    
    // check to see whether the list has been loaded and, if not, load it
    private static func checkList() {
        if !EditList.loaded {
            EditList.loaded = true
            EditList._editList = []
            if let rec = Database.getAssetListRecord(key: EditList.assetKey) {
                if rec.assets.count > 0 {
                    EditList._editList = rec.assets
                    log.verbose("Restored List: \(EditList._editList)")

                } else {
                    log.debug("Empty edit list")
                }
            } else {
                log.error("AssetListRecord not found")
                let alist = Database.getAssetListRecords()
                log.debug("AssetLists: \(alist)")
                for rec in alist {
                    log.debug("  key:\(rec.key) assets:\(rec.assets)")
                }
            }
        }
    }
}

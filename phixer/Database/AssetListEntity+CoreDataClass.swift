//
//  AssetListEntity+CoreDataClass.swift
//  phixer
//
//  Created by Philip Price on 5/18/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import CoreData

@objc(AssetListEntity)
public class AssetListEntity: NSManagedObject {
    
    // convert to "Record" format
    public func toRecord() -> AssetListRecord{
        var record: AssetListRecord
        
        record = AssetListRecord()
        record.assets = []
        if (self.assets.count>0){
            for f in self.assets{
                record.assets.append(f as String)
            }
        }
        return record
    }
    
    // update using supplied "Record" format
    public func update(record: AssetListRecord){
        
        self.assets = []
        if (record.assets.count>0){
            for f in record.assets{
                self.assets.append(f as NSString)
            }
        }
    }
}

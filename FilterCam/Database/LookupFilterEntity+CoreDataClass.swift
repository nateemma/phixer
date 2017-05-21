//
//  LookupFilterEntity+CoreDataClass.swift
//  FilterCam
//
//  Created by Philip Price on 5/18/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import CoreData

@objc(LookupFilterEntity)
public class LookupFilterEntity: NSManagedObject {
    
    // convert to "Record" format
    public func toRecord() -> LookupFilterRecord{
        var record: LookupFilterRecord
        
        record = LookupFilterRecord()
        record.key = self.key
        record.title = self.title
        record.image = self.image
        record.hide = self.hide
        record.rating = Int(self.rating)
        return record
    }
    
    // update using supplied "Record" format
    public func update(record: LookupFilterRecord){
        self.setValue(record.key, forKey: "key")
        self.setValue(record.title, forKey: "title")
        self.setValue(record.image, forKey: "image")
        self.setValue(record.hide, forKey: "hide")
        self.setValue(Int16(record.rating), forKey: "rating")
    }

}

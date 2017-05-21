//
//  FilterEntity+CoreDataClass.swift
//  FilterCam
//
//  Created by Philip Price on 5/18/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import CoreData

@objc(FilterEntity)
public class FilterEntity: NSManagedObject {

    
    // convert to "Record" format
    public func toRecord() -> FilterRecord{
        var record: FilterRecord
        
        record = FilterRecord()
        record.key = self.key
        record.title = self.title
        record.classname = self.classname
        record.hide = self.hide
        record.rating = Int(self.rating)
        return record
    }
    
    // update using supplied "Record" format
    public func update(record: FilterRecord){
        self.setValue(record.key, forKey: "key")
        self.setValue(record.title, forKey: "title")
        self.setValue(record.classname, forKey: "classname")
        self.setValue(record.hide, forKey: "hide")
        self.setValue(Int16(record.rating), forKey: "rating")
    }

}

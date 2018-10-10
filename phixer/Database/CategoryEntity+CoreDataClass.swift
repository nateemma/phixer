//
//  CategoryEntity+CoreDataClass.swift
//  phixer
//
//  Created by Philip Price on 5/18/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import CoreData

@objc(CategoryEntity)
public class CategoryEntity: NSManagedObject {

    // convert to "Record" format
   public func toRecord() -> CategoryRecord{
        var record: CategoryRecord
        
        record = CategoryRecord()
        record.key = self.key
        record.title = self.title
        record.hide = self.hide
        return record
    }
    
    // update using supplied "Record" format
    public func update(record: CategoryRecord){
        self.setValue(record.key, forKey: "key")
        self.setValue(record.title, forKey: "title")
        self.setValue(record.hide, forKey: "hide")
    }
}

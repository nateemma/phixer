//
//  AssignmentEntity+CoreDataClass.swift
//  FilterCam
//
//  Created by Philip Price on 5/18/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import CoreData

@objc(AssignmentEntity)
public class AssignmentEntity: NSManagedObject {
    
    // convert to "Record" format
    public func toRecord() -> AssignmentRecord{
        var record: AssignmentRecord
        
        record = AssignmentRecord()
        record.category = self.category
        record.filters = []
        if (self.filters.count>0){
            for f in self.filters{
                record.filters.append(f as String)
            }
        }
        return record
    }
    
    // update using supplied "Record" format
    public func update(record: AssignmentRecord){
        //var filterData: [NSString]
        
        //self.setValue(record.category, forKey: "category")
        self.category = record.category
        
        self.filters = []
        if (record.filters.count>0){
            for f in record.filters{
                self.filters.append(f as NSString)
            }
        }

        //self.setValue(filterData, forKey: "filters")
    }

}

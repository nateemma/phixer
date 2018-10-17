//
//  UserChangesEntity+CoreDataClass.swift
//  phixer
//
//  Created by Philip Price on 5/18/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import CoreData

@objc(UserChangesEntity)
public class UserChangesEntity: NSManagedObject {
    
    // convert to "Record" format
    public func toRecord() -> UserChangesRecord{
        var record: UserChangesRecord
        
        record = UserChangesRecord()
        record.key = self.key
        record.hide = self.hide
        record.rating = Int(self.rating)
        return record
    }
    
    // update using supplied "Record" format
    public func update(record: UserChangesRecord){
        self.setValue(record.key, forKey: "key")
        self.setValue(record.hide, forKey: "hide")
        self.setValue(Int16(record.rating), forKey: "rating")
    }

}

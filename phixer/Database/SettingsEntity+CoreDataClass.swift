//
//  SettingsEntity+CoreDataClass.swift
//  phixer
//
//  Created by Philip Price on 5/18/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import CoreData

@objc(SettingsEntity)
public class SettingsEntity: NSManagedObject {

    // convert to "Record" format
    public func toRecord() -> SettingsRecord {
        var settingsRecord: SettingsRecord
        
        settingsRecord = SettingsRecord()
        settingsRecord.key = self.key
        settingsRecord.blendImage = self.blendImage
        settingsRecord.editImage = self.editImage
        settingsRecord.sampleImage = self.sampleImage
        settingsRecord.configVersion = self.configVersion
        
        return settingsRecord
    }
    
    // update using supplied "Record" format
    public func update(record: SettingsRecord){
        self.setValue(record.key, forKey: "key")
        self.setValue(record.blendImage, forKey: "blendImage")
        self.setValue(record.editImage, forKey: "editImage")
        self.setValue(record.sampleImage, forKey: "sampleImage")
        self.setValue(record.configVersion, forKey: "configVersion")
    }
}

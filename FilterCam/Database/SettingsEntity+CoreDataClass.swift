//
//  SettingsEntity+CoreDataClass.swift
//  FilterCam
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
        settingsRecord.blendImage = self.blendImage
        settingsRecord.editImage = self.editImage
        settingsRecord.sampleImage = self.sampleImage
        settingsRecord.configVersion = self.configVersion
        
        return settingsRecord
    }
    
    // update using supplied "Record" format
    public func update(record: SettingsRecord){
        //self.setValue(record.configVersion, forKey: "configVersion")
        //self.setValue(record.blendImage, forKey: "blendImage")
        //self.setValue(record.sampleImage, forKey: "sampleImage")
        
        self.blendImage = record.blendImage
        self.editImage = record.editImage
        self.sampleImage = record.sampleImage
        self.configVersion = record.configVersion
        
    }
}

//
//  SettingsEntity+CoreDataProperties.swift
//  
//
//  Created by Philip Price on 5/24/17.
//
//

import Foundation
import CoreData


extension SettingsEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SettingsEntity> {
        return NSFetchRequest<SettingsEntity>(entityName: "SettingsEntity")
    }

    @NSManaged public var key: String?
    @NSManaged public var blendImage: String?
    @NSManaged public var configVersion: String?
    @NSManaged public var sampleImage: String?
    @NSManaged public var editImage: String?

}

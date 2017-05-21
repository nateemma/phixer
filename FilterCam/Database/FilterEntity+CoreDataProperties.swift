//
//  FilterEntity+CoreDataProperties.swift
//  FilterCam
//
//  Created by Philip Price on 5/18/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import CoreData


extension FilterEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FilterEntity> {
        return NSFetchRequest<FilterEntity>(entityName: "FilterEntity")
    }

    @NSManaged public var key: String?
    @NSManaged public var title: String?
    @NSManaged public var classname: String?
    @NSManaged public var hide: Bool
    @NSManaged public var rating: Int16

}

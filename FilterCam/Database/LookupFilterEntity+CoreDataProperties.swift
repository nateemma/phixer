//
//  LookupFilterEntity+CoreDataProperties.swift
//  FilterCam
//
//  Created by Philip Price on 5/18/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import CoreData


extension LookupFilterEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LookupFilterEntity> {
        return NSFetchRequest<LookupFilterEntity>(entityName: "LookupFilterEntity")
    }

    @NSManaged public var key: String?
    @NSManaged public var title: String?
    @NSManaged public var image: String?
    @NSManaged public var hide: Bool
    @NSManaged public var rating: Int16

}

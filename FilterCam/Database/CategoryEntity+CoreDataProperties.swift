//
//  CategoryEntity+CoreDataProperties.swift
//  FilterCam
//
//  Created by Philip Price on 5/18/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import CoreData


extension CategoryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoryEntity> {
        return NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
    }

    @NSManaged public var key: String?
    @NSManaged public var title: String?
    @NSManaged public var hide: Bool
    @NSManaged public var category: AssignmentEntity?

}

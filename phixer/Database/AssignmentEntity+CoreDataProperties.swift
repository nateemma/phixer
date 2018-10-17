//
//  AssignmentEntity+CoreDataProperties.swift
//  phixer
//
//  Created by Philip Price on 5/18/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import CoreData


extension AssignmentEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AssignmentEntity> {
        return NSFetchRequest<AssignmentEntity>(entityName: "AssignmentEntity")
    }

    @NSManaged public var category: String?
    @NSManaged public var filters: [NSString]

}

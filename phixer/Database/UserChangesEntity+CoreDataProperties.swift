//
//  UserChangesEntity+CoreDataProperties.swift
//  phixer
//
//  Created by Philip Price on 5/18/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import CoreData


extension UserChangesEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserChangesEntity> {
        return NSFetchRequest<UserChangesEntity>(entityName: "UserChangesEntity")
    }

    @NSManaged public var key: String?
    @NSManaged public var hide: Bool
    @NSManaged public var rating: Int16

}

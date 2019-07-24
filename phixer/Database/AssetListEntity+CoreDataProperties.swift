//
//  AssetListEntity+CoreDataProperties.swift
//  phixer
//
//  Created by Philip Price on 5/18/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import CoreData


extension AssetListEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AssetListEntity> {
        return NSFetchRequest<AssetListEntity>(entityName: "AssetListEntity")
    }

    @NSManaged public var key: String?
    @NSManaged public var assets: [NSString]

}

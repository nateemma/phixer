//
//  AssetListRecord.swift
//  phixer
//
//  Created by Philip Price on 5/19/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation


// Represents the data stored in a "AssetList" record of the database.
// Corresponds to AssetListEntity Managed Object class
// This is a 'clean' definition so you don't need to mess with CoreData to use it (inefficient but much easier to use)


public class AssetListRecord {
    public var key: String? = nil
    public var assets: [String] = []
}

//
//  CategoryRecord.swift
//  FilterCam
//
//  Created by Philip Price on 5/19/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation


// Represents the data stored in a "Category" record of the database. 
// Corresponds to CategoryEntity Managed Object class
// This is a 'clean' definition so you don't need to mess with CoreData to use it (inefficient but much easier to use)


public class CategoryRecord {
    public var key: String? = nil
    public var title: String? = nil
    public var hide: Bool = false
}

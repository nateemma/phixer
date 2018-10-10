//
//  AssignmentRecord.swift
//  phixer
//
//  Created by Philip Price on 5/19/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation


// Represents the data stored in a "Assignment" record of the database. 
// Corresponds to AssignmentEntity Managed Object class
// This is a 'clean' definition so you don't need to mess with CoreData to use it (inefficient but much easier to use)


public class AssignmentRecord {
    public var category: String? = nil
    public var filters: [String] = []
}

//
//  FilterBasedControllerDelegate.swift
//  phixer
//
//  Created by Philip Price on 1/10/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation


// all ViewControllers that deal with filters should implement this protocol, so that the top-level controllers can deal with them generically
protocol FilterBasedControllerDelegate: class {
    func filterControllerSelection (key: String)
    func filterControllerUpdateRequest (tag: String)
    func filterControllerCompleted (tag: String)
}

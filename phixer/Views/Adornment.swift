//
//  Adornment.swift
//  phixer
//
//  Created by Philip Price on 1/1/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit


// struct that contains vars used to create an 'adornment' (image + text + handler)

// NOTE: you can either specify an icon name (from the Asset catalog) or provide an image directly
//       If you specify an image, set the icon text to ""
struct Adornment {
    var text: String = ""
    var icon: String = ""
    var view: UIImage? = nil
    var isHidden: Bool = false
    var callback: (()->())? = nil
    
    init() {
        text = ""
        icon = ""
        view = nil
        isHidden = false
        callback = nil
    }
}

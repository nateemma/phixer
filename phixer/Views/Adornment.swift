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

protocol AdornmentDelegate: class{
    func adornmentItemSelected(key:String)
}


// NOTE: you can either specify an icon name (from the Asset catalog) or provide an image directly
//       If you specify an image, set the icon text to ""
struct Adornment {
    var key: String = ""
    var text: String = ""
    var icon: String = ""
    var view: UIImage? = nil
    var isHidden: Bool = false
    
    init(key: String, text: String, icon: String, view: UIImage?, isHidden: Bool){
        self.key = key
        if key.isEmpty {
            log.error("Empty key supplied")
        }
        self.text = text
        self.icon = icon
        self.view = view
        self.isHidden = isHidden
    }
}

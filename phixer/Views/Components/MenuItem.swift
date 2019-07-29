//
//  MenuItem.swift
//  phixer
//
//  Created by Philip Price on 7/26/19
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit


// NOTE: you can either specify an icon name (from the Asset catalog) or provide an image directly
//       If you specify an image, set the icon String to ""
struct MenuItem {
    var key: String = ""
    var title: String = ""
    var subtitile: String = ""
    var icon: String = ""
    var view: UIImage? = nil
    var isHidden: Bool = false
    
    init(key: String, title: String, subtitile: String, icon: String, view: UIImage?, isHidden: Bool){
        self.key = key
        if key.isEmpty {
            log.error("Empty key supplied")
        }
        self.title = title
        self.subtitile = subtitile
        self.icon = icon
        self.view = view
        self.isHidden = isHidden
    }
    
    // convenience init for text-only adornment
    init(key: String, title: String){
        self.key = key
        if key.isEmpty {
            log.error("Empty key supplied")
        }
        self.title = title
        self.subtitile = ""
        self.icon = ""
        self.view = nil
        self.isHidden = false
    }
}

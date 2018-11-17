//
//  GalleryViewCell.swift
//  Generic cell view for gallery-type displays. Needed mainly if you need to track re-use, e.g. to free memory
//
//  Created by Philip Price on 10/18/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import UIKit


class GalleryViewCell: UICollectionViewCell {
    
    var theme = ThemeManager.currentTheme()
    

    public static let reuseID: String = "GalleryViewCell"
    
    public var cellIndex:Int = -1 // used for tracking cell reuse
    

    // everything else is in the seuperclass (UICollectionViewCell)

}

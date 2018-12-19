//
//  GalleryControllerMode.swift
//  phixer
//
//  Created by Philip Price on 12/18/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation


// enum type that controls the behaviour of a gallery (grid-style image selection) view controller
// The intent is to allow galleries to operate as standalone controllers, or as part of a collection of controlllers,
// e.g. as part of a compound editing flow

enum GalleryControllerMode {
    case displaySelection
    case returnSelection
}




// delegate method to let the launching ViewController know that this one has finished
protocol GalleryViewControllerDelegate: class {
    func galleryCompleted()
    func gallerySelection(key:String)
}

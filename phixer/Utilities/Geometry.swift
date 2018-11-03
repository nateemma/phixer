//
//  Geometry.swift
//  phixer
//
//  Created by Philip Price on 11/2/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

// common geometric calculations, primarily for resizing images

import Foundation
import CoreGraphics

class Geometry {
    
    private init(){}
    
    // calculate the size that will fit the 'boundingSize' into a rectangle that has aspect ratio that matches the supplied size
    // i.e. the resulting size is a multiple of the aspect ratio, but with dimensions that contain 'boundingSize'
    public static func aspectFitToSize(aspectRatio: CGSize, boundingSize: CGSize) -> CGSize {
        
        let widthRatio = boundingSize.width / aspectRatio.width
        let heightRatio = boundingSize.height / aspectRatio.height
        var size = boundingSize
        
        if widthRatio < heightRatio {
            size.height = boundingSize.width / aspectRatio.width * aspectRatio.height
        } else if (heightRatio < widthRatio) {
            size.width = boundingSize.height / aspectRatio.height * aspectRatio.width
        }
        
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    
    
    public static func aspectFillToSize(aspectRatio: CGSize, minimumSize: CGSize) -> CGSize {
        
        let widthRatio = minimumSize.width / aspectRatio.width
        let heightRatio = minimumSize.height / aspectRatio.height
        
        var size = minimumSize
        
        if widthRatio > heightRatio {
            size.height = minimumSize.width / aspectRatio.width * aspectRatio.height;
        } else if heightRatio > widthRatio {
            size.width = minimumSize.height / aspectRatio.height * aspectRatio.width;
        }
        
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    
    public static func aspectFitToRect(aspectRatio: CGSize, boundingRect: CGRect) -> CGRect {
        let size = aspectFitToSize(aspectRatio: aspectRatio, boundingSize: boundingRect.size)
        var origin = boundingRect.origin
        origin.x += (boundingRect.size.width - size.width) / 2.0
        origin.y += (boundingRect.size.height - size.height) / 2.0
        return CGRect(origin: origin, size: size)
    }
    
    public static func aspectFillToRect(aspectRatio: CGSize, minimumRect: CGRect) -> CGRect {
        let size = aspectFillToSize(aspectRatio: aspectRatio, minimumSize: minimumRect.size)
        var origin = CGPoint.zero
        origin.x = (minimumRect.size.width - size.width) / 2.0
        origin.y = (minimumRect.size.height - size.height) / 2.0
        return CGRect(origin: origin, size: size)
    }
    
    public static func diagonalRatio(to: CGSize, from: CGSize) -> CGFloat {
        
        let _from = sqrt(pow(from.height, 2) + pow(from.width, 2))
        let _to = sqrt(pow(to.height, 2) + pow(to.width, 2))
        
        return _to / _from
    }
    
}

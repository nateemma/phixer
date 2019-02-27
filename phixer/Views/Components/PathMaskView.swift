//
//  PathMaskView.swift
//  phixer
//
//  Created by Philip Price on 2/15/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit

// class intended for drawing shapes using Bezier Paths to create a mask

class PathMaskView: UIView {
    
    // the collection of paths to be drawn
    var paths: UIBezierPath = UIBezierPath()
    
    // add a set of coordinates to the paths (rather than BezierPath). The resulting paths is 'smoothed'
    public func addPoints(_ points: [CGPoint]) {
        if points.count > 0 {
            let path = UIBezierPath()
            path.interpolatePointsWithHermite(interpolationPoints: points)
            paths.append(path)
        }
    }
    
    // add a path to the existing set of paths
    public func addPath(_ path: UIBezierPath) {
        if !path.isEmpty {
            paths.append(path)
        }
    }
    
    public func clear() {
        paths.removeAllPoints()
    }
    
    
    // override the draw() function and draw the bezier paths
    override func draw(_ rect: CGRect) {
        if !paths.isEmpty {
            log.verbose("Drawing paths")
            UIColor.white.setFill()
            UIColor.white.setStroke()
            paths.fill()
            paths.stroke()
        }
    }
}

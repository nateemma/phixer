//
//  UIBecierPath+Extensions.swift
//  phixer
//
//  Created by Philip Price on 1/8/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//
// Adapted from code originally from Filterpedia by Simon Gladman

import Foundation
import UIKit


extension UIBezierPath {
    func interpolatePointsWithHermite(interpolationPoints : [CGPoint]) {
        let n = interpolationPoints.count - 1
        
        for ii in 0 ..< n {
            var currentPoint = interpolationPoints[ii]
            
            if ii == 0 {
                self.move(to: interpolationPoints[0])
            }
            
            var nextii = (ii + 1) % interpolationPoints.count
            var previi = (ii - 1 < 0 ? interpolationPoints.count - 1 : ii-1);
            var previousPoint = interpolationPoints[previi]
            var nextPoint = interpolationPoints[nextii]
            let endPoint = nextPoint;
            var mx : CGFloat = 0.0
            var my : CGFloat = 0.0
            
            if ii > 0 {
                mx = (nextPoint.x - currentPoint.x) * 0.5 + (currentPoint.x - previousPoint.x) * 0.5;
                my = (nextPoint.y - currentPoint.y) * 0.5 + (currentPoint.y - previousPoint.y) * 0.5;
            } else {
                mx = (nextPoint.x - currentPoint.x) * 0.5;
                my = (nextPoint.y - currentPoint.y) * 0.5;
            }
            
            let controlPoint1 = CGPoint(x: currentPoint.x + mx / 3.0, y: currentPoint.y + my / 3.0)
            
            currentPoint = interpolationPoints[nextii]
            nextii = (nextii + 1) % interpolationPoints.count
            previi = ii;
            previousPoint = interpolationPoints[previi]
            nextPoint = interpolationPoints[nextii]
            
            if ii < n - 1 {
                mx = (nextPoint.x - currentPoint.x) * 0.5 + (currentPoint.x - previousPoint.x) * 0.5;
                my = (nextPoint.y - currentPoint.y) * 0.5 + (currentPoint.y - previousPoint.y) * 0.5;
            } else {
                mx = (currentPoint.x - previousPoint.x) * 0.5;
                my = (currentPoint.y - previousPoint.y) * 0.5;
            }
            
            let controlPoint2 = CGPoint(x: currentPoint.x - mx / 3.0, y: currentPoint.y - my / 3.0)
            
            self.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        }
    }
}


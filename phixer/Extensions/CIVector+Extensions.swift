//
//  CIVector+Extensions.swift
//  phixer
//
//  Created by Philip Price on 1/8/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//
// Adapted from code originally from Filterpedia by Simon Gladman

import Foundation
import CoreGraphics
import CoreImage


extension CIVector
{
    func toArray() -> [CGFloat] {
        var returnArray = [CGFloat]()
        
        for i in 0 ..< self.count {
            returnArray.append(self.value(at: i))
        }
        
        return returnArray
    }
    
    func normalize() -> CIVector {
        var sum: CGFloat = 0
        
        for i in 0 ..< self.count {
            sum += self.value(at: i)
        }
        
        if sum == 0 {
            return self
        }
        
        var normalizedValues = [CGFloat]()
        
        for i in 0 ..< self.count {
            normalizedValues.append(self.value(at: i) / sum)
        }
        
        return CIVector(values: normalizedValues,
                        count: normalizedValues.count)
    }
    
    func multiply(value: CGFloat) -> CIVector {
        let n = self.count
        var targetArray = [CGFloat]()
        
        for i in 0 ..< n {
            targetArray.append(self.value(at: i) * value)
        }
        
        return CIVector(values: targetArray, count: n)
    }
    
    func interpolateTo(target: CIVector, value: CGFloat) -> CIVector {
        return CIVector( x: self.x + ((target.x - self.x) * value),
                         y: self.y + ((target.y - self.y) * value))
    }
}

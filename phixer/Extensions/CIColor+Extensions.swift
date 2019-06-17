//
//  CIColor+Extensions.swift
//  Various convenient extensions to the CIColor class
//
//  Created by Philip Price on 10/29/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import CoreGraphics

public extension CIColor {
    
    
    convenience init(h:CGFloat, s:CGFloat, v:CGFloat, alpha: CGFloat = 1.0) {

        
        if s == 0 {
            self.init(red: v, green: v, blue: v, alpha: alpha) // Achromatic grey

        } else {
        
            let angle = ((h*360.0) >= 360 ? 0 : h*360.0)
            let sector = angle / 60 // Sector
            let i = floor(sector)
            let f = sector - i // Factorial part of h
            
            let p = v * (1 - s)
            let q = v * (1 - (s * f))
            let t = v * (1 - (s * (1 - f)))
            var r:CGFloat, g:CGFloat, b:CGFloat
            
            switch(i) {
            case 0:
                r = v
                g = t
                b = p
            case 1:
                r = q
                g = v
                b = p
             case 2:
                r = p
                g = v
                b = t
            case 3:
                r = p
                g = q
                b = v
            case 4:
                r = t
                g = p
                b = v
            default:
                r = v
                g = p
                b = q
            }
            print("r:\(r) g:\(g) b:\(b)")
            self.init(red: r, green: g, blue: b, alpha: alpha)

        }
    }
    

}


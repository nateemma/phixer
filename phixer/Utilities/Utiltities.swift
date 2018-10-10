//
//  Utiltities.swift
//  phixer
//
//  Created by Philip Price on 10/28/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation


class Utilities{

    public static func addressOf<T: AnyObject>(_ o: T?) -> String{
            let addr = unsafeBitCast(o!, to: Int.self)
            return NSString(format: "%p", addr) as String
    }
}

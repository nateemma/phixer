//
//  UIViewController+Extensions.swift
//  phixer
//
//  Created by Philip Price on 12/17/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    // add a child controller. Called from the parent
    func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    // remove a child controller. Called by the parent on the child view controller var
    func remove() {
        guard parent != nil else {
            return
        }
        willMove(toParent: nil)
        removeFromParent()
        view.removeFromSuperview()
    }
}

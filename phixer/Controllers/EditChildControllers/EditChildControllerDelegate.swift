//
//  EditChildControllerDelegate.swift
//  phixer
//
//  Created by Philip Price on 12/17/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation

protocol EditChildControllerDelegate {
    func editFilterSelected(key:String)
    func editRequestUpdate()
    func editFinished()
}

//
//  SegueHandlerType.swift
//  phixer
//
//  Initial version created by Natasha Murashev on 12/18/15.
//  Copyright © 2015 NatashaTheRobot. All rights reserved.
//

import UIKit
import Foundation


// defines a protocol/extension for use by UIViewControllers that need to send segues witrh identifiers programmatically

/*****
 
 To use, follow the general outline below in your UIViewController:
 
class ViewController: UIViewController, SegueHandlerType {
    
    // the compiler will now complain if you don't have this implemented, you need this to conform to SegueHandlerType
    enum SegueIdentifier: String {
        case segue1
        case segue2
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // 🎉 goodbye pyramid of doom! (no need to check whether vars have been assigned etc. - done by compiler)
        switch segueIdentifierForSegue(segue) {
        case .segue1:
            print("Segue1 activated")
        case .segue2:
            print("Segue2 activated")
        }
    }
    
    @IBAction func onButton1Tap(sender: AnyObject) {
        performSegueWithIdentifier(.segue1, sender: self)
    }
    
    @IBAction func onButton2Tap(sender: AnyObject) {
        performSegueWithIdentifier(.segue2, sender: self)
    }
}

*****/


protocol SegueHandlerType {
    associatedtype SegueIdentifier: RawRepresentable
}

extension SegueHandlerType where Self: UIViewController, SegueIdentifier.RawValue == String {
    
    func performSegueWithIdentifier(_ segueIdentifier: SegueIdentifier, sender: AnyObject?) {
        performSegue(withIdentifier: segueIdentifier.rawValue, sender: sender)
    }
    
    func segueIdentifierForSegue(_ segue: UIStoryboardSegue) -> SegueIdentifier {
        guard let identifier = segue.identifier,
            let segueIdentifier = SegueIdentifier(rawValue: identifier) else { fatalError("Invalid segue identifier \(String(describing: segue.identifier)).") }
        
        return segueIdentifier
    }
}


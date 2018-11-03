//
//  TimedAlertView.swift
//  phixer
//
//  Created by Philip Price on 11/3/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

// Simple class to show a message and disappear after some time (configurable)

import Foundation
import UIKit

class TimedAlertView: UIAlertController {
    
    private var timer:TimeInterval = 2.0
    
    public func setTitle(_ title:String) {
        self.title = title
    }
    
    public func setMessage(_ message:String) {
        self.message = message
    }
    
    public func setTimer(_ time:Double){
        self.timer = time
    }

    public func showAlert() {
        showAlert(title:self.title!, message:self.message!, timer:self.timer)
    }
    
    public func showAlert(title:String, message:String, timer:Double=2.0) {
        let alert = UIAlertController(title: self.title, message: self.message, preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        Timer.scheduledTimer(withTimeInterval: timer, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)} )
    }

}

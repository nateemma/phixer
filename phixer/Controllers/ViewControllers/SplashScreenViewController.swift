//
//  SplashScreenViewController.swift
//  Displqys splash screen while the app is being initialised
//
//  Created by Philip Price on 10/29/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Neon
import Photos


class SplashScreenViewController: UIViewController {
    
    
    private var displayWidth : CGFloat = 0.0
    private var displayHeight : CGFloat = 0.0
    private let duration = 3.0

    public var completionHandler : (() -> Void)?

    
    // the current UI Theme. Note: this can change
    public var theme = ThemeManager.currentTheme()

    let iconView: UIImageView! = UIImageView()

    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        
        // Create an instance of FilterManager (in a different queue entry). This will take care of reading the configuration file etc.
        DispatchQueue.main.async {
            log.verbose("Loading config...")
            EditManager.reset()
            FilterManager.checkSetup()
            Coordinator.filterManager = FilterManager.sharedInstance
            log.verbose("config loaded - calling completion handler...")
            DispatchQueue.main.async {
                self.completionHandler?()
                self.dismiss(animated: true)
            }
        }

    }
    
    
    deinit{
        //suspend()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Logging nicety, show that controller has changed:
        print ("\n========== \(String(describing: type(of: self))) ==========")

        doLayout()
        
        
        log.debug("fading in...")
        let rotation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = Double.pi * 2
        rotation.duration = 2.0 // or however long you want ...
        rotation.isCumulative = true
        rotation.repeatCount = Float.greatestFiniteMagnitude
        self.view.layer.add(rotation, forKey: "rotationAnimation")
        //TODO: fix origin?
        UIView.animate(withDuration: duration, animations: {
            self.iconView.alpha = 1.0
            self.iconView.frame.size.width = self.view.frame.size.width
            self.iconView.frame.size.height = self.view.frame.size.width
            self.iconView.frame.origin.x = (self.view.frame.size.width - self.iconView.frame.size.width) / 2.0
            self.iconView.frame.origin.y = (self.view.frame.size.height - self.iconView.frame.size.height) / 2.0
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        log.verbose("config loaded - calling completion handler...")
//        DispatchQueue.main.async {
//            self.completionHandler?()
//        }
    }
    
    /////////////////////////////
    // MARK: - public accessors
    /////////////////////////////
    


    /////////////////////////////
    // MARK: - Initialisation & Layout
    /////////////////////////////
    
  
    
    private func doLayout(){
        
        EditList.load()

        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        
        //view.backgroundColor = theme.backgroundColor // default seems to be white
        view.backgroundColor = UIColor.black // always use black because of the graphics (background is white in light mode)

        
        // get app icon
        let appIcon = UIImage(named: "app_icon")
        
        // layout constraints
        iconView.frame = view.frame
        iconView.image = appIcon
        let d = CGFloat(duration)
        self.iconView.alpha = 1.0 / d // we fade this in over time
        iconView.frame.size.width = view.frame.size.width / d
        iconView.frame.size.height = view.frame.size.width / d
        iconView.frame.origin.x = (view.frame.size.width - iconView.frame.size.width) / 2.0
        iconView.frame.origin.y = (view.frame.size.height - iconView.frame.size.height) / 2.0

        view.addSubview(iconView)
        //iconView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: iconView.frame.size.width)
        iconView.anchorInCenter(width: iconView.frame.size.width, height: iconView.frame.size.width)


        //Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.splashTimeOut(sender:)), userInfo: nil, repeats: false)
        // Do any additional setup after loading the view.
    }
    
    @objc func splashTimeOut(sender : Timer){
        log.verbose("Finished...")
        self.completionHandler?()
    }
    

  
    
    //////////////////////////////////////
    //MARK: - Navigation
    //////////////////////////////////////
    @objc func backDidPress(){
        log.verbose("Back ignored")
    }
    
    
    func exitScreen(){
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            dismiss(animated: true, completion:  { })
            return
        }
    }

}




//////////////////////////////////////////
// MARK: - Delegate functions
//////////////////////////////////////////


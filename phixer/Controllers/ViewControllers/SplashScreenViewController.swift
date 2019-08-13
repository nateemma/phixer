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

    public var completionHandler : (() -> Void)?

    
    // the current UI Theme. Note: this can change
    public var theme = ThemeManager.currentTheme()

    let iconView: UIImageView! = UIImageView()

    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        
        // Create an instance of FilterManager (in a different queue entry). This will take care of reading the configuration file etc.
        DispatchQueue.main.async {
            log.verbose("Loading config...")
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
        UIView.animate(withDuration: 5.0, animations: {
            self.iconView.alpha = 1.0
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
        
        
        view.backgroundColor = theme.backgroundColor // default seems to be white

        
        // get app icon
        let appIcon = UIImage(named: "app_icon")
        
        // layout constraints
        iconView.frame = view.frame
        iconView.image = appIcon
        self.iconView.alpha = 0.1 // we fade this in over time
        
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


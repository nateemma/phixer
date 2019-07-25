//
//  SplashScreenViewController.swift
//  Controller to guide the user in choosing a photo to edit
//
//  Created by Philip Price on 10/29/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Neon
import Photos

class SplashScreenViewController: CoordinatedController {
    
    
    private var displayWidth : CGFloat = 0.0
    private var displayHeight : CGFloat = 0.0
    
    private var mainView:UIView! = UIView()

    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////
    
    // return the display title for this Controller
    override public func getTitle() -> String {
        return "phixer"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "About" // temp, change later
    }
    

    /////////////////////////////
    // MARK: - Boilerplate
    /////////////////////////////
    
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
    }
    
    
    deinit{
        //suspend()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // common setup
        self.prepController()

        doLayout()
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
        view.addSubview(mainView)
        mainView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: (displayHeight-UISettings.panelHeight))

        
        // get app icon
        let appIcon = UIImage(named: "AppIcon")
        let iconView: UIImageView! = UIImageView()
        
        // layout constraints
        iconView.frame = mainView.frame
        iconView.image = appIcon
        
        mainView.addSubview(iconView)
        iconView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: iconView.frame.size.height)

        
        // Create an instance of FilterManager (in a different queue entry). This will take care of reading the configuration file etc.
        DispatchQueue.main.async {
            [weak self] in
            Coordinator.filterManager = FilterManager.sharedInstance
        }

        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.splashTimeOut(sender:)), userInfo: nil, repeats: false)
        // Do any additional setup after loading the view.
    }
    
    @objc func splashTimeOut(sender : Timer){
        // start the choose photo screen
        self.coordinator?.activateRequest(id: ControllerIdentifier.choosePhoto)
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


//
//  EditBaseMenuController.swift
//  phixer
//
//  Created by Philip Price on 12/17/18
//  Copyright © 2018 Nateemma. All rights reserved.
//

import UIKit
import Neon
import iCarousel



private var filterList: [String] = []
private var filterCount: Int = 0

// This View Controller is the 'base' class used for creating Edit Control displays which consist of a carousel of text & icons
// The subclass just needs to override the functions that provide the displayed data and the handler for dealing with a user selection

class EditBaseMenuController: CoordinatedController, SubControllerDelegate, EditBaseMenuInterface {
  
    
    
    // The Edit controls/options
    var mainView: UIView! = UIView()
    var menu:SimpleCarousel? = nil

    
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let editControlHeight: CGFloat = UISettings.menuHeight
    
    var childController:UIViewController? = nil
    
    var cancelButton: SquareButton? = nil

    
    ////////////////////
    // Coordination Interface requests (forward/back)
    ////////////////////
    
    // For menu controllers, the response that makes sense is to just go to the next/previous menu item
    // Can be overridden if needed
    func nextItem() {
        DispatchQueue.main.async(execute: { () -> Void in
            log.debug("next...")
            self.menu?.nextItem()
        })
    }
    
    func previousItem() {
        DispatchQueue.main.async(execute: { () -> Void in
            log.debug("previous...")
            self.menu?.previousItem()
        })
    }
    
    // override this func *only* for the top level menu
    func isTopMenu() -> Bool {
        return false
    }
    
    ////////////////////
    // 'Virtual' funcs, these must be overidden by the subclass
    ////////////////////
    
    // returns the text to display at the top of the window
    override func getTitle() -> String {
        log.warning("WARNING: Base class called, should have been overridden by subclass")
        return "BASE"
    }
    
    // returns the list of Adornments (text, icon/image, handler)
    func getItemList() -> [Adornment] {
        log.error("ERROR: Base class called, should have been overridden by subclass")
        return []
    }

    // function to handle a selected item
    func handleSelection(key:String) {
        log.error("ERROR: Base class called, should have been overridden by subclass")
    }

    
    
    ////////////////////
    // Everything below here is generic so subclasses can just inherit this functionality as-is
    ////////////////////

    
    func initFrame() {
        guard view != nil else {
            return
        }
        
        //HACK: resize view based on type
        view.frame = ControllerFactory.getFrame(ControllerType.menu)
    }

    convenience init(){
        self.init(nibName:nil, bundle:nil)
        initFrame()
    }
    

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        initFrame()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initFrame()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initFrame()
        
        // Logging nicety, show that controller has changed. Not using the logging API so that this stands out more
        print ("\n========== \(self.getTag()) ID: \(self.id.rawValue) ==========")


        
        // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        
        //view.backgroundColor = UIColor.clear
        view.backgroundColor = theme.backgroundColor
        //view.isUserInteractionEnabled = false

        // get display dimensions
        //displayHeight = view.height
        displayHeight = view.height
        displayWidth = view.width
        
        
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        
        //self.view.frame.size.height = displayHeight
        //self.view.frame.size.width = displayWidth
        mainView.frame.size.height = displayHeight
        mainView.frame.size.width = displayWidth
        view.addSubview(mainView)
        mainView.anchorToEdge(.bottom, padding: 0, width: mainView.frame.size.width, height: mainView.frame.size.height)

        setupTitle()
        setupMenu()


        log.verbose("mainView: w:\(mainView.frame.size.width) h:\(mainView.frame.size.height)")
        log.verbose("self: w:\(self.view.frame.size.width) h:\(self.view.frame.size.height)")

        
        self.view.isHidden = false

    }
    
    func setupTitle(){
        // set up the title, with a label for the text an an image for the 'cancel' option
        let titleView = UIView()
        titleView.frame.size.width = mainView.frame.size.width
        titleView.frame.size.height = (mainView.frame.size.height * 0.25).rounded()
        titleView.backgroundColor = theme.subtitleColor

 
        // cancel button (if not top-level menu)
        let bsize = (titleView.frame.size.height*0.8).rounded()
        if !self.isTopMenu() {
            cancelButton = SquareButton(bsize: bsize)
            cancelButton?.setImageAsset("ic_no")
            cancelButton?.backgroundColor = theme.subtitleColor.withAlphaComponent(0.5)
            cancelButton?.setTintable(true)
            cancelButton?.highlightOnSelection(true)
            cancelButton?.addTarget(self, action: #selector(self.cancelDidPress), for: .touchUpInside)
            cancelButton?.isUserInteractionEnabled = true

            titleView.addSubview(cancelButton!)
        }

        // label
        let label = UILabel()
        label.frame.size.width = (titleView.frame.size.width - bsize - 4).rounded()
        label.frame.size.height = titleView.frame.size.height - 2
        label.text = getTitle()
        label.textAlignment = .center
        label.textColor = theme.subtitleTextColor
        label.backgroundColor = theme.subtitleColor
        label.font = theme.getFont(ofSize: 12, weight: UIFont.Weight.thin)
        label.adjustsFontSizeToFitWidth = true
        label.isUserInteractionEnabled = false
        //label.fitTextToBounds()
        log.verbose("Menu: \(label.text)")
 
        titleView.addSubview(label)
        //label.anchorToEdge(.left, padding: 0, width: label.frame.size.width, height: label.frame.size.height)
        label.anchorInCorner(.topLeft, xPad: 0, yPad: 0, width: label.frame.size.width, height: label.frame.size.height)
        if !self.isTopMenu() {
            cancelButton?.anchorToEdge(.right, padding: 0, width: (cancelButton?.frame.size.width)!, height: (cancelButton?.frame.size.height)!)
        }
        
        mainView.addSubview(titleView)
        titleView.anchorToEdge(.top, padding: 0, width: titleView.frame.size.width, height: titleView.frame.size.height)
        log.verbose("title: w:\(titleView.frame.size.width) h:\(titleView.frame.size.height)")
    }
    
    func setupMenu(){
        // set up the menu of options
        self.menu = SimpleCarousel()
        
        menu?.frame.size.height = (mainView.frame.size.height * 0.75).rounded()
        menu?.frame.size.width = mainView.frame.size.width
        menu?.backgroundColor = theme.backgroundColor
        menu?.setItems(getItemList())
        menu?.delegate = self
        menu?.isUserInteractionEnabled = true

        mainView.addSubview(menu!)
        menu?.anchorToEdge(.bottom, padding: 0, width: (menu?.frame.size.width)!, height: (menu?.frame.size.height)!)
        mainView.bringSubviewToFront(menu!) // ensure menu is on top, to recieve touches
        log.verbose("menu: w:\(menu?.frame.size.width) h:\(menu?.frame.size.height)")
    }
    

    
    override func clearSubviews(){
        for v in mainView.subviews{
            v.removeFromSuperview()
        }
        for v in self.view.subviews{
            v.removeFromSuperview()
        }
    }

    
    //////////////////////////////////////////
    // MARK: - Touch Handler
    //////////////////////////////////////////
    
    @objc func cancelDidPress(){
        //dismiss()
        end()
    }

    
    //////////////////////////////////////////
    // MARK: - Not yet implemented notifier
    //////////////////////////////////////////

    func notYetImplemented(){
        displayTimedMessage(title: "Oh Dear", text: "Not yet implemented. Sorry!", time: 1.0)
        /***
        DispatchQueue.main.async(execute: { () -> Void in
            let alert = UIAlertController(title: "Oh Dear", message: "Not yet implemented. Sorry!", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)} )
        })
         ***/
    }
    


} // EditBaseMenuController
//########################



//////////////////////////////////////////
// MARK: - Delegate functions
//////////////////////////////////////////

extension EditBaseMenuController: AdornmentDelegate {
    func adornmentItemSelected(key: String) {
        DispatchQueue.main.async(execute: { () -> Void in
            log.debug("key: \(key)")
            self.handleSelection(key: key)
        })
    }
}


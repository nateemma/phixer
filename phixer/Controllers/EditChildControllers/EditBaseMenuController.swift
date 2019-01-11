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

class EditBaseMenuController: FilterBasedController, FilterBasedControllerDelegate {
    
    
    
    var theme = ThemeManager.currentTheme()
    
    // The Edit controls/options
    var mainView: UIView! = UIView()
    let menu:SimpleCarousel! = SimpleCarousel()

    
    // var isLandscape : Bool = false // moved to base class
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let buttonSize : CGFloat = 48.0
    let editControlHeight: CGFloat = 96.0
    //let editControlHeight: CGFloat = 48.0
    
    var childController:UIViewController? = nil
    
 
    ////////////////////
    // 'Virtual' funcs, these must be overidden by the subclass
    ////////////////////
    
    // returns the text to display at the top of the window
    func getTitle() -> String {
        log.warning("Base class called, should have been overridden by subclass")
        return ""
    }
    
    // returns the list of Adornments (text, icon/image, handler)
    func getItemList() -> [Adornment] {
        log.error("Base class called, should have been overridden by subclass")
        return []
    }

    // function to handle a selected item
    func handleSelection(key:String) {
        log.error("Base class called, should have been overridden by subclass")
    }
    
    // go to the next filter, whatever that means for this controller. Note that this is a valid default implementation
    override func nextFilter(){
        log.debug("next...")
        menu.nextItem()
    }
  
    // go to the previous filter, whatever that means for this controller. Note that this is a valid default implementation
    override func previousFilter(){
        log.debug("previous...")
        menu.previousItem()
    }

    
    //////////////////////////////////////////
    // FilterBasedControllerDelegate
    //////////////////////////////////////////
    
    // these are here to allow compilation.
    
    func filterControllerSelection(key: String) {
        log.warning("base class called. key: \(key)")
    }
    
    func filterControllerUpdateRequest(tag: String) {
        log.warning("base class called. tag: \(tag)")
    }
    
    func filterControllerCompleted(tag: String) {
        log.warning("base class called. tag: \(tag)")
    }
    
    
    ////////////////////
    // Everything below here is generic so subclasses can just inherit this functionality as-is
    ////////////////////


    convenience init(){
        self.init(nibName:nil, bundle:nil)
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Logging nicety, show that controller has changed. Not using the logging API so that this stands out more
        print ("\n========== \(String(describing: self)) ==========")

        
        // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        
        view.backgroundColor = theme.backgroundColor

        // get display dimensions
        //displayHeight = view.height
        displayHeight = editControlHeight
        displayWidth = view.width
        
        
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        
        self.view.frame.size.height = displayHeight
        self.view.frame.size.width = displayWidth
        mainView.frame.size.height = displayHeight
        mainView.frame.size.width = displayWidth
        view.addSubview(mainView)

        setupTitle()
        setupMenu()

        mainView.fillSuperview()
        //view.bringSubview(toFront: mainView)
        log.verbose("mainView: w:\(mainView.frame.size.width) h:\(mainView.frame.size.height)")
        log.verbose("self: w:\(self.view.frame.size.width) h:\(self.view.frame.size.height)")

        
        self.view.isHidden = false

    }
    
    func setupTitle(){
        // set up the title, with a label for the text an an image for the 'cancel' option
        let titleView = UIView()
        titleView.frame.size.height = mainView.frame.size.height * 0.3
        titleView.frame.size.width = mainView.frame.size.width
        titleView.backgroundColor = theme.subtitleColor

 
        // cancel button
        let cancelButton = SquareButton(bsize: (titleView.frame.size.height*0.8).rounded())
        cancelButton.setImageAsset("ic_no")
        cancelButton.backgroundColor = theme.titleColor.withAlphaComponent(0.5)
        cancelButton.setTintable(true)
        cancelButton.highlightOnSelection(true)
        cancelButton.addTarget(self, action: #selector(self.cancelDidPress), for: .touchUpInside)
        
        titleView.addSubview(cancelButton)

        // label
        let label = UILabel()
        label.frame.size.width = (titleView.frame.size.width - cancelButton.frame.size.width - 4).rounded()
        label.frame.size.height = titleView.frame.size.height
        label.text = getTitle()
        label.textAlignment = .center
        label.textColor = theme.titleTextColor
        label.backgroundColor = theme.titleColor
        label.font = UIFont.systemFont(ofSize: 14)
        //label.fitTextToBounds()
 
        titleView.addSubview(label)
        //label.anchorToEdge(.left, padding: 0, width: label.frame.size.width, height: label.frame.size.height)
        label.anchorInCorner(.topLeft, xPad: 0, yPad: 0, width: label.frame.size.width, height: label.frame.size.height)
        cancelButton.anchorToEdge(.right, padding: 0, width: cancelButton.frame.size.width, height: cancelButton.frame.size.height)
        
        mainView.addSubview(titleView)
        titleView.anchorToEdge(.top, padding: 0, width: titleView.frame.size.width, height: titleView.frame.size.height)
        
    }
    
    func setupMenu(){
        // set up the menu of option
        menu.frame.size.height = mainView.frame.size.height * 0.7
        menu.frame.size.width = mainView.frame.size.width
        menu.setItems(getItemList())
        menu.delegate = self
        
        mainView.addSubview(menu)
        menu.anchorToEdge(.bottom, padding: 0, width: menu.frame.size.width, height: menu.frame.size.height)
        log.verbose("menu: w:\(menu.frame.size.width) h:\(menu.frame.size.height)")

    }
    
    
    func dismiss(){
        UIView.animate(withDuration: 0.5, animations: {
            self.view.alpha = 0 }) { _ in
                self.clearSubviews()
                self.view.isHidden = true
                //self.removeFromSuperview()
        }
    }

    
    fileprivate func clearSubviews(){
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
        delegate?.filterControllerCompleted(tag:self.getTag())
        dismiss()
    }

    
    //////////////////////////////////////////
    // MARK: - Not yet implemented notifier
    //////////////////////////////////////////

    func notYetImplemented(){
        DispatchQueue.main.async(execute: { () -> Void in
            let alert = UIAlertController(title: "Oh Dear", message: "Not yet implemented. Sorry!", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)} )
        })
    }
    


} // EditBaseMenuController
//########################



//////////////////////////////////////////
// MARK: - Delegate functions
//////////////////////////////////////////

extension EditBaseMenuController: AdornmentDelegate {
    func adornmentItemSelected(key: String) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.handleSelection(key: key)
        })
    }
}


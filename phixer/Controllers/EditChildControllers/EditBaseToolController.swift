//
//  EditBaseToolController.swift
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

// This View Controller is the 'base' class used for creating Edit 'Tool' displays, which take up most of the screen
// This mostly just sets up the framing, title, navigation etc. Other stuff must be done in the subclass, via the loadToolView() callback

class EditBaseToolController: FilterBasedController, FilterBasedControllerDelegate {
    
    var theme = ThemeManager.currentTheme()
    
    // The main views.
    var mainView: UIView! = UIView()
    var titleView: UIView! = UIView()
    var toolView: UIView! = UIView() // this will be passed to the subclass

    
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let buttonSize : CGFloat = 48.0

    
 
    ////////////////////
    // 'Virtual' funcs, these must be overidden by the subclass
    ////////////////////
    
    func getTitle() -> String{
        return "Edit Tool Base Class"
    }
    
    func loadToolView(toolview: UIView){
        log.warning("Base class called")
    }
    
    func commit() {
        log.warning("Base class called")
        delegate?.filterControllerCompleted(tag:self.getTag())
        dismiss()
    }
    
    func cancel(){
        // this is OK as a default implementation since we inherently don't need to save or commit anything
        EditManager.addPreviewFilter(nil)
        delegate?.filterControllerCompleted(tag:self.getTag())
        dismiss()
    }
    
    ////////////////////
    // Filter Navigation - typically not applicable here so override
    ////////////////////

    // go to the next filter, whatever that means for this controller. Note that this is a valid default implementation
    override func nextFilter(){
        // just ignore for tools
    }
  
    // go to the previous filter, whatever that means for this controller. Note that this is a valid default implementation
    override func previousFilter(){
        // just ignore for tools
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
        print ("\n========== \(self.getTag()) ==========")

        
        // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        
        view.backgroundColor = UIColor.clear

        // make the main view a little smaller than the screen

        displayHeight = view.height - 128
        displayWidth = view.width - 64
        
        //TODO: round the corners and add border?
        
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        self.view.isHidden = false

        // sizing
        mainView.frame.size.height = displayHeight
        mainView.frame.size.width = displayWidth
        mainView.backgroundColor = theme.backgroundColor.withAlphaComponent(0.6)
        mainView.layer.cornerRadius = 16.0
        mainView.layer.borderWidth = 2.0
        mainView.layer.borderColor = theme.borderColor.cgColor


        titleView.frame.size.height = 32
        titleView.frame.size.width = mainView.frame.size.width
        titleView.backgroundColor = theme.subtitleColor

        toolView.frame.size.height = mainView.frame.size.height - titleView.frame.size.height
        toolView.frame.size.width = mainView.frame.size.width
        toolView.backgroundColor = mainView.backgroundColor

        // layout
        view.addSubview(mainView)
        mainView.anchorInCenter(width: mainView.frame.size.width, height: mainView.frame.size.height)
        
        mainView.addSubview(titleView)
        mainView.addSubview(toolView)
        titleView.anchorToEdge(.top, padding: 0, width: titleView.frame.size.width, height: titleView.frame.size.height)
        toolView.alignAndFillHeight(align: .underCentered, relativeTo: titleView, padding: 0, width: toolView.frame.size.width)
        //toolView.anchorToEdge(.bottom, padding: 0, width: toolView.frame.size.width, height: toolView.frame.size.height)

        // populate
        setupTitle()
        loadToolView(toolview: toolView)

    }
    
    func setupTitle(){
        // set up the title, with a label for the text an an image for the 'commit' and 'cancel' options
        
        // commit button
        let commitButton = SquareButton(bsize: (titleView.frame.size.height*0.8).rounded())
        commitButton.setImageAsset("ic_yes")
        commitButton.backgroundColor = theme.titleColor.withAlphaComponent(0.5)
        commitButton.setTintable(true)
        commitButton.highlightOnSelection(true)
        commitButton.addTarget(self, action: #selector(self.commitDidPress), for: .touchUpInside)
        
        // cancel button
        let cancelButton = SquareButton(bsize: (titleView.frame.size.height*0.8).rounded())
        cancelButton.setImageAsset("ic_no")
        cancelButton.backgroundColor = theme.titleColor.withAlphaComponent(0.5)
        cancelButton.setTintable(true)
        cancelButton.highlightOnSelection(true)
        cancelButton.addTarget(self, action: #selector(self.cancelDidPress), for: .touchUpInside)


        // label
        let label = UILabel()
        label.frame.size.width = (titleView.frame.size.width - cancelButton.frame.size.width - 4).rounded()
        label.frame.size.height = titleView.frame.size.height
        label.text = getTitle()
        label.textAlignment = .center
        label.textColor = theme.titleTextColor
        label.backgroundColor = theme.titleColor
        label.font = UIFont.systemFont(ofSize: 14)
        label.fitTextToBounds()
 
        titleView.addSubview(label)
        titleView.addSubview(commitButton)
        titleView.addSubview(cancelButton)

        commitButton.anchorToEdge(.left, padding: 8, width: cancelButton.frame.size.width, height: cancelButton.frame.size.height)
        cancelButton.anchorToEdge(.right, padding: 8, width: cancelButton.frame.size.width, height: cancelButton.frame.size.height)
        label.alignBetweenHorizontal(align: .toTheRightCentered, primaryView: commitButton, secondaryView: cancelButton, padding: 2, height: AutoHeight)

        
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
    
    @objc func commitDidPress(){
        commit()
        delegate?.filterControllerCompleted(tag:self.getTag())
        dismiss()
    }
    
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
    


} // EditBaseToolController
//########################



//////////////////////////////////////////
// MARK: - Delegate functions
//////////////////////////////////////////




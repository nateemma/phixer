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

class EditBaseToolController: CoordinatedController, SubControllerDelegate {
    

    
    // The main views.
    var mainView: UIView! = UIView()
    var titleView: UIView! = UIView()
    var toolView: UIView! = UIView() // this will be passed to the subclass

    
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    

    
    
    ////////////////////
    // Coordination requests (forward/back)
    ////////////////////

    // these don't really make sense for a tool controller, which is typically a single item.
    // Can be overridden if needed
    func nextItem() {
        log.verbose("Ignoring request")
    }
    
    func previousItem() {
        log.verbose("Ignoring request")
    }
    
    ////////////////////
    // 'Virtual' funcs, these must be overidden by the subclass
    ////////////////////
    
    override func getTitle() -> String{
        return "Edit Tool Base Class"
    }
    
    func loadToolView(toolview: UIView){
        log.warning("Base class called")
    }
    
    func commitChanges() {
        log.warning("Base class called")
        EditManager.savePreviewFilter()
        self.coordinator?.updateRequest(id: self.id)
        dismiss()
    }
    
    func cancelChanges(){
        // this is OK as a default implementation since we inherently don't need to save or commit anything
        log.debug("default")
        EditManager.addPreviewFilter(nil)
        self.coordinator?.updateRequest(id: self.id)
        dismiss()
    }
    
    
 
    ////////////////////
    // SubController interfaces. Can be ignored for Tools
    ////////////////////
    
   func getNextFilter() -> String {
        return self.filterManager.getCurrentFilterKey()
    }
    
    func getPreviousFilter() -> String {
        return self.filterManager.getCurrentFilterKey()
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
        print ("\n========== \(self.getTag()) ID: \(self.id.rawValue) ==========")

       
        //HACK: resize view based on type
        self.view.frame = ControllerFactory.getFrame(ControllerType.tool)

        // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        
        view.backgroundColor = UIColor.clear
        view.isUserInteractionEnabled = true

        // make the main view a little smaller than the screen

        //displayHeight = view.height - 128
        //displayWidth = view.width - 64
        displayHeight = view.height
        displayWidth = view.width

        //TODO: round the corners and add border?
        
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        self.view.isHidden = false

        // sizing
        mainView.frame.size.height = displayHeight
        mainView.frame.size.width = displayWidth
        mainView.backgroundColor = theme.backgroundColor.withAlphaComponent(0.6)
        //mainView.layer.cornerRadius = 16.0
        mainView.layer.borderWidth = 1.0
        mainView.layer.borderColor = theme.borderColor.cgColor


        titleView.frame.size.width = mainView.frame.size.width
        titleView.frame.size.height = UISettings.titleHeight
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
        toolView.alignAndFillWidth(align: .underCentered, relativeTo: titleView, padding: 0, height: toolView.frame.size.height)
        //toolView.anchorToEdge(.bottom, padding: 0, width: toolView.frame.size.width, height: toolView.frame.size.height)

        // populate
        setupTitle()
        loadToolView(toolview: toolView)
        

    }
    

    
    func setupTitle(){
        // set up the title, with a label for the text an an image for the 'commit' and 'cancel' options
        
        // commit button
        let commitButton = SquareButton(bsize: (UISettings.titleHeight*0.6).rounded())
        commitButton.setImageAsset("ic_yes")
        commitButton.backgroundColor = theme.titleColor.withAlphaComponent(0.5)
        commitButton.setTintable(true)
        commitButton.highlightOnSelection(true)
        commitButton.addTarget(self, action: #selector(self.commitDidPress), for: .touchUpInside)
        
        // cancel button
        let cancelButton = SquareButton(bsize: (UISettings.titleHeight*0.6).rounded())
        cancelButton.setImageAsset("ic_no")
        cancelButton.backgroundColor = theme.titleColor.withAlphaComponent(0.5)
        cancelButton.setTintable(true)
        cancelButton.highlightOnSelection(true)
        cancelButton.addTarget(self, action: #selector(self.cancelDidPress), for: .touchUpInside)


        // label
        let label = UILabel()
        label.frame.size.width = (titleView.frame.size.width - cancelButton.frame.size.width - 4).rounded()
        label.frame.size.height = UISettings.panelHeight
        label.text = getTitle()
        label.textAlignment = .center
        label.textColor = theme.titleTextColor
        label.backgroundColor = theme.titleColor
        label.font = UIFont.systemFont(ofSize: 16)
        label.adjustsFontSizeToFitWidth = true
        //label.fitTextToBounds()
 
        titleView.addSubview(label)
        titleView.addSubview(commitButton)
        titleView.addSubview(cancelButton)

        commitButton.anchorToEdge(.left, padding: 8, width: cancelButton.frame.size.width, height: cancelButton.frame.size.height)
        cancelButton.anchorToEdge(.right, padding: 8, width: cancelButton.frame.size.width, height: cancelButton.frame.size.height)
        label.alignBetweenHorizontal(align: .toTheRightCentered, primaryView: commitButton, secondaryView: cancelButton, padding: 2, height: AutoHeight)

        
    }
    
    // func to reset the height. Intended for use by the subclass if it wants to change height (expand/contract)
    func resetToolHeight(_ height:CGFloat){
         if !height.approxEqual(toolView.frame.size.height) {
            log.debug("old:\(toolView.frame.size.height) new:\(height)")
            
            toolView.frame.size.height = height
            mainView.frame.size.height = UISettings.panelHeight + toolView.frame.size.height
            self.view.frame.size.height = mainView.frame.size.height
            //titleView.anchorToEdge(.top, padding: 0, width: titleView.frame.size.width, height: UISettings.panelHeight)
            toolView.alignAndFillWidth(align: .underCentered, relativeTo: titleView, padding: 0, height: toolView.frame.size.height)
        }
    }
    
    

    
    //////////////////////////////////////////
    // MARK: - Tool Banner Touch Handlers
    //////////////////////////////////////////
    
    @objc func commitDidPress(){
        self.commitChanges()
    }
    
    @objc func cancelDidPress(){
        self.cancelChanges()
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




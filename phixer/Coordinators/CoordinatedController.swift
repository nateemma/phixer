//
//  CoordinatedController.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit


// base class for ViewControllers that are part of the Coordinator approach

class CoordinatedController: UIViewController, ControllerDelegate {
  
    
    // delegate for handling events
    weak var coordinator: CoordinatorDelegate? = nil
    
    // the id of controller (useful to the coordinator)
    public var id: ControllerIdentifier = .home // has to be something
    
    // the type of controller (useful to the coordinator)
    public var controllerType: ControllerType = .fullscreen

    // indicates whether this Controller should show Google Ads
    public var showAds:Bool = false
    
    
    // flag to indicate whether interface (not device) is in landscape mode. TODO: move to UISettings?
    public var isLandscape: Bool { return checkLandscape() }

    // the current UI Theme. Note: this can change
    public var theme = ThemeManager.currentTheme()
    
    // FilterManager reference
    public var filterManager: FilterManager = FilterManager.sharedInstance
    
    
    // Default Menu view
    var defaultMenuView: DefaultControllerMenuView! = DefaultControllerMenuView()
    
    
    //TODO: add titlebar and Ad views (and handling)?
    
    
    ////////////////////
    // Virtual funcs - should be overriden by subclass
    ////////////////////
    
    func start() {
        log.error("\(self.getTag) - ERROR: Base class called")
    }
    
    // prepare to end task. Override in subclass if you need to do anything first (e.g. commit changes). Call dismiss() at the end if you want the VC to exit
    func end() {
        log.debug("\(self.getTag) - Base class called")
        dismiss()
    }
    
    func updateDisplays() {
        log.error("\(self.getTag) - ERROR: Base class called")
    }
    
    func updateTheme() {
        log.warning("\(self.getTag()) - Attempting to reapply theme")
        ThemeManager.applyTheme(key: ThemeManager.getCurrentThemeKey())
        theme = ThemeManager.currentTheme()
        self.view.backgroundColor = theme.backgroundColor
        self.navigationItem.titleView?.backgroundColor = theme.titleColor
    }
    
    func selectFilter(key: String) {
        log.error("\(self.getTag()) - ERROR: Base class called. key: \(key)")
    }
    
    
    private var defaultMenuReady:Bool = false
    
    // handle the menu request.
    func handleMenu() {
        log.debug("\(self.getTag()) - using default menu")
        
        if !defaultMenuReady {
            buildDefaultMenu()
            defaultMenuReady = true
            defaultMenuView.isHidden = true
        }
        
        // if menu is hidden then re-layout and show it, otherwise hide it
        if self.defaultMenuView.isHidden == true {
            log.debug("showing menu")
            self.defaultMenuView.delegate = self
            self.defaultMenuView.isHidden = false
            self.view.bringSubviewToFront(self.defaultMenuView)
        } else {
            log.debug("Menu active, closing")
            self.defaultMenuView.isHidden = true
        }
    }

    
    
    // return the display title for this Controller
    public func getTitle() -> String {
        return "(\(self.getTag()))"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    public func getHelpKey() -> String {
        return "default"
    }
    
    ////////////////////
    // Useful funcs
    ////////////////////
    
    // setup that needs to be run from viewDidLoad()
    func prepController() {
 
        // set the frame size
        self.view.frame = ControllerFactory.getFrame(ControllerType.fullscreen)

        // set the ID
        self.id = ControllerFactory.getId(tag:self.getTag())
        
        // Logging nicety, show that controller has changed:
        print ("\n========== \(self.getTag()) ==========")
        
        // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        
        setupNavBar()
        
        self.view.backgroundColor = theme.backgroundColor
        
        log.verbose("\(self.getTag()) Frame:\(self.view.frame)")
    }
    
    
    
    func clearSubviews(){
        for v in self.view.subviews{
            v.removeFromSuperview()
        }
    }

    
    func dismiss(){
        self.clearSubviews()
        self.view.isHidden = true
        self.coordinator?.completionNotification(id: self.getId(), activate: .none)
    }
    
    // get the tag used to identify this controller. IDs are assigned by the Coordinator pattern and are used to track activity
    func setId(_ id: ControllerIdentifier){
        self.id = id
    }
    
    // get the tag used to identify this controller. IDs are assigned by the Coordinator pattern and are used to track activity
    func getId()->ControllerIdentifier{
        return self.id
    }

    // get the tag used to identify this controller. Implemented as a func so that it gets the actual class, not the base class
    func getTag()->String{
        return "\(String(describing: type(of: self)))"
    }

    
    func checkLandscape() -> Bool {
        let sbo = UIApplication.shared.statusBarOrientation
        return ((sbo == .landscapeLeft) || (sbo == .landscapeRight))
    }
    
    
    func removeSubviews(){
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
    }
    
    public func displayTimedMessage(title:String, text:String, time:TimeInterval){
        log.debug("title:\(title) time:\(time) \ntext: \(text)")
        DispatchQueue.main.async(execute: { () -> Void in
            let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            Timer.scheduledTimer(withTimeInterval: time, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)} )
        })
    }
    
    ////////////////////
    // Default Menu Handling
    ////////////////////

    private func buildDefaultMenu(){
        defaultMenuReady = true
        self.view.addSubview(defaultMenuView)
        let topBarHeight = UIApplication.shared.statusBarFrame.size.height + (Coordinator.navigationController?.navigationBar.frame.height ?? 0.0)
        defaultMenuView.frame.size.height = CGFloat(48.0)
        defaultMenuView.frame.size.width = self.view.frame.size.width
        defaultMenuView.anchorAndFillEdge(.top, xPad: 0, yPad: topBarHeight, otherSize: defaultMenuView.frame.size.height)
        defaultMenuView.isHidden = true
    }

    
    // handler (called from the AdornmentView extension)
    // implemented as switch in case we add something else later
    fileprivate func handleDefaultMenuSelection(key: String){
        switch (key){
        case "help":
            log.debug("help")
            DispatchQueue.main.async(execute: { () -> Void in
                self.coordinator?.helpRequest()
            })
        default:
            log.error("Unknown key: \(key)")
        }
        self.defaultMenuView.isHidden = true
   }

    ////////////////////
    // Navigation Bar setup - apparently, this has to be done from each ViewController
    ////////////////////

    func setupNavBar(){
        
        let h = (Coordinator.navigationController?.navigationBar.frame.height)! * 0.8
        let size = CGSize(width: h, height: h)
        
        log.verbose("Setting up navBar")
        let backButton = UIBarButtonItem(image: UIImage(named: "ic_back")?.imageScaled(to: size), style: .plain, target: self, action: #selector(navbarBackDidPress))
        //let helpButton = UIBarButtonItem(image: UIImage(named: "ic_help")?.imageScaled(to: size), style: .plain, target: self, action: #selector(navbarHelpDidPress))
        let menuButton = UIBarButtonItem(image: UIImage(named: "ic_menu")?.imageScaled(to: size), style: .plain, target: self, action: #selector(navbarMenuDidPress))
        

        if (self.id != .home) &&  (self.id != .none) {
            self.navigationItem.leftBarButtonItem = backButton
        }
        //self.navigationItem.rightBarButtonItems = [ menuButton, helpButton ] // build custom view?
        self.navigationItem.rightBarButtonItem = menuButton
        
        self.navigationItem.title = self.getTitle()
        
        // Apply theme colours
        self.navigationController?.navigationBar.backgroundColor = theme.backgroundColor
        self.navigationController?.navigationBar.tintColor = theme.tintColor
        
        // build the menu
        buildDefaultMenu()

    }
    
    @objc func navbarBackDidPress(){
        log.debug("\(self.getTag()) Back Pressed")
        if self.id != .home {
            //self.dismiss()
            self.end()
        }
    }
    
    @objc func navbarMenuDidPress(){
        self.handleMenu() 
    }
    
    @objc func navbarHelpDidPress(){
        log.debug("\(self.getTag()) Help Pressed")
        self.coordinator?.helpRequest()
    }
    
    
    ////////////////////
    // Default implementations of UIViewController funcs, mostly just for convenience and consistency
    ////////////////////
    
    private var firstTime = true
    
    override func viewDidAppear(_ animated: Bool) {
        
        // there is a race condition where vars are not always configured before viewDidLoad() is called, so make sure they are set here
        self.id = ControllerFactory.getId(tag:self.getTag())

        log.debug("\(self.getTag()) ID:\(self.id)")
        
        if firstTime {
            firstTime = false
            setupNavBar()
       }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.warning("Low Memory Warning (\(self.getTag()))")
        // Dispose of any resources that can be recreated.
    }
    
    
    
    /* restricting to portrait for now, so no need for these
     override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
     if ((UIApplication.shared.statusBarOrientation == .landscapeLeft) || (UIApplication.shared.statusBarOrientation == .landscapeRight)) {
     log.verbose("Preparing for transition to Landscape")
     } else {
     log.verbose("Preparing for transition to Portrait")
     }
     }
     */
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        
        if ((UIApplication.shared.statusBarOrientation == .landscapeLeft) || (UIApplication.shared.statusBarOrientation == .landscapeRight)){
            log.verbose("### Detected change to: Landscape")
        } else {
            log.verbose("### Detected change to: Portrait")
            
        }
        //TODO: animate and maybe handle before rotation finishes
        self.viewDidLoad()
    }
    
    
    // Autorotate configuration default behaviour. Override for something different
    
    //NOTE: only works for iOS 10 and later
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    
} // CoordinatedController





// Default Menu delegate

extension CoordinatedController: DefaultControllerMenuDelegate {
    func defaultMenuItemSelected(key: String) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.handleDefaultMenuSelection(key: key)
        })
    }
}

//
//  FilterCamViewController.swift
//  FilterCam
//
//  Created by Philip Price on 9/6/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import GPUImage
import Neon
import AVFoundation
import MediaPlayer


private var filterList: [String] = []
private var filterCount: Int = 0


class FilterCamViewController: UIViewController, SegueHandlerType {
    
    // Camera Settings
    var cameraSettingsView: CameraSettingsView! = CameraSettingsView()
    
    // Main Camera View
    var cameraDisplayView: CameraDisplayView! = CameraDisplayView()
    
    // View for holding the (modal) overlays. Note: must come after CameraDisplayView()
    var cameraInfoView : CameraInfoView! = CameraInfoView()
    
    // The Camera controls/options
    var cameraControlsView: CameraControlsView! = CameraControlsView()

    // The filter configuration subview
    var filterSettingsView: FilterSettingsView! = FilterSettingsView()
    
    
    var filterManager: FilterManager? = nil
    
    var currFilterDescriptor:FilterDescriptorInterface? = nil
 
    var isLandscape : Bool = false
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 48.0
    
    
    // the list of segues initiated from this view controller
    enum SegueIdentifier: String {
        case photoBrowser
        case filterManager
        case attributions
        case about
        case preferences
    }
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        
        filterManager = FilterManager.sharedInstance
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            
            // get display dimensions
            displayHeight = view.height
            displayWidth = view.width
            
            log.verbose("h:\(displayHeight) w:\(displayWidth)")
            
            // get orientation
            //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
            isLandscape = (displayWidth > displayHeight)
            
            
            // Note: need to add subviews before modifying constraints
            view.addSubview(cameraSettingsView)
            view.addSubview(cameraDisplayView)
            view.addSubview(cameraInfoView) // must come after cameraDisplayView
            view.addSubview(cameraControlsView)
            
            // set up layout based on orientation
            if (isLandscape){
                // left-to-right layout scheme
                cameraSettingsView.frame.size.height = displayHeight
                cameraSettingsView.frame.size.width = bannerHeight
                cameraSettingsView.anchorAndFillEdge(.left, xPad: 0, yPad: 0, otherSize: bannerHeight)
                
                cameraControlsView.frame.size.height = displayHeight
                cameraControlsView.frame.size.width = bannerHeight
                cameraControlsView.anchorAndFillEdge(.right, xPad: 0, yPad: 0, otherSize: bannerHeight)
                
                cameraDisplayView.frame.size.height = displayHeight
                cameraDisplayView.frame.size.width = displayWidth - 2 * bannerHeight
                cameraDisplayView.alignBetweenHorizontal(.toTheLeftMatchingTop, primaryView: cameraSettingsView, secondaryView: cameraControlsView, padding: 0, height: displayHeight)
                
                
                // Align Overlay view to bottom of Render View
                cameraInfoView.frame.size.height = bannerHeight / 2.0
                cameraInfoView.frame.size.width = displayWidth - 2 * bannerHeight
                //cameraInfoView.align(.aboveCentered, relativeTo: cameraControlsView, padding: 0, width: displayWidth - 2 * bannerHeight, height: bannerHeight)
                cameraInfoView.alignBetweenHorizontal(.toTheLeftMatchingBottom, primaryView: cameraControlsView, secondaryView: cameraSettingsView, padding: 0, height: bannerHeight)
                
            } else {
                // Portrait: top-to-bottom layout scheme
                
                cameraSettingsView.frame.size.height = bannerHeight
                cameraSettingsView.frame.size.width = displayWidth
                cameraSettingsView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: bannerHeight)
                
                cameraControlsView.frame.size.height = bannerHeight
                cameraControlsView.frame.size.width = displayWidth
                cameraControlsView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: bannerHeight)
                
                cameraInfoView.frame.size.height = bannerHeight / 2.0
                cameraInfoView.frame.size.width = displayWidth
                cameraInfoView.align(.aboveCentered, relativeTo: cameraControlsView, padding: 0, width: displayWidth, height: cameraInfoView.frame.size.height)
                
                
                //cameraDisplayView.frame.size.height = displayHeight - 2 * bannerHeight
                cameraDisplayView.frame.size.height = displayHeight - 2.5 * bannerHeight
                cameraDisplayView.frame.size.width = displayWidth
                cameraDisplayView.align(.aboveCentered, relativeTo: cameraInfoView, padding: 0, width: displayWidth, height: cameraDisplayView.frame.size.height)
            }
            
            //setFilterIndex(0) // no filter
            
            // add delegates to sub-views (for callbacks)
            cameraSettingsView.delegate = self
            cameraControlsView.delegate = self
            cameraInfoView.delegate = self
            //filterSettingsView.delegate = self
            
            // listen to key press events
            setVolumeListener()
            
            //TODO: start timer and update setting display peridodically
        }
        catch  let error as NSError {
            log.error ("Error detected: \(error.localizedDescription)");
        }
    }
    /*
     override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
     if UIDevice.current.orientation.isLandscape {
     log.verbose("Preparing for transition to Landscape")
     } else {
     log.verbose("Preparing for transition to Portrait")
     }
     }
     */
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if UIDevice.current.orientation.isLandscape{
            log.verbose("### Detected change to: Landscape")
        } else {
            log.verbose("### Detected change to: Portrait")
            
        }
        //TODO: animate and maybe handle before rotation finishes
        self.viewDidLoad()
        cameraDisplayView.setFilter(currFilterDescriptor?.filter) // forces reset of filter pipeline
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let id = segueIdentifierForSegue(segue)
        log.debug ("Issuing segue: \(id)") // don't really need to do anything, just log which segue was activated
    }
    
    
    
    // handle the pressing of a physical button
    
    
    func setVolumeListener() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
        } catch {
            log.error("\(error)")
        }
        audioSession.addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions(), context: nil)
        
        //TODO: hide system volume HUD
        self.view.addSubview(volumeView)
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        log.debug("Key event: \(keyPath)")
        if keyPath == "outputVolume" {
            log.debug("Volume Button press detected, taking picture")
            saveImage()
        }
    }
    
    // redefine the volume view so that it isn't really visible to the user
    lazy var volumeView: MPVolumeView = {
        let view = MPVolumeView()
        view.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        view.alpha = 0.000001
        return view
    }()
    
    //MARK: - Utility functions
    
    open func saveImage(){
        do{
            let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
            //TOFIX: generate filename? Or, just overwrite same file since it's copied to Photos anyway?
            cameraDisplayView.saveImage(URL(string:"FilterCamImage.png", relativeTo:documentsDir)!)
            
        } catch {
            log.error("Error saving image: \(error)")
        }
        
    }
  
    fileprivate func populateFilterList(){
        
        // make sure the FilterManager instance has been loaded
        if (filterManager == nil) {
            log.warning("WARN: FilterManager not allocated. Lazy allocation")
            filterManager = FilterManager.sharedInstance
        }
        
        // get list of filters in the Quick Selection category
        if (filterCount==0){
            filterList = []
            filterList = (filterManager?.getFilterList(category: FilterCategoryType.quickSelect))!
            filterList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
            filterCount = filterList.count
            log.debug("Filter list: \(filterList)")
        }
    }
    
    
    // TEMP: set Filter based on index
    
    open func setFilterIndex(_ index:Int){
        
        // make sure the FilterManager instance has been loaded
        if (filterManager == nil) {
            log.warning("WARN: FilterManager not allocated. Lazy allocation")
            filterManager = FilterManager.sharedInstance
        }
        
        if (filterCount==0){ populateFilterList() }

        
        // setup the filter descriptor
        if ((index>=0) && (index<filterCount)){
            currFilterDescriptor = filterManager?.getFilterDescriptor(category:.quickSelect, name:filterList[index])
        } else {
            currFilterDescriptor = nil
            log.error("!!! Unknown index:\(index) No filter")
        }
        
        cameraDisplayView.setFilter(currFilterDescriptor?.filter)
        
        if let name = currFilterDescriptor?.key {
            log.verbose("Filter: \(name)")
            cameraInfoView.setFilterName(name)
            
            if ((currFilterDescriptor?.numSliders)! > 0){
                self.view.addSubview(filterSettingsView)
                filterSettingsView.setFilter(currFilterDescriptor)
                
                filterSettingsView.align(.aboveCentered, relativeTo: cameraInfoView, padding: 4, width: filterSettingsView.frame.size.width, height: filterSettingsView.frame.size.height)
                
                //filterSettingsView.show()
            }
        } else {
            cameraInfoView.setFilterName("No Filter")
        }
    }
}


// MARK: - Delegate methods for sub-views

extension FilterCamViewController: CameraControlsViewDelegate {
    func imagePreviewPressed(){
        log.debug("imagePreview pressed")
    }
    func takePicturePressed(){
        log.debug("Take Picture pressed")
        saveImage()
        cameraControlsView.update()
    }
    func filterSelectionPressed(){
        log.debug("Filter Mgr pressed")
    }
    func settingsPressed(){
        log.debug("Settings pressed")
    }
}

extension FilterCamViewController: CameraSettingsViewDelegate {
    func flashPressed(){
        log.debug("Flash pressed")
        //TODO: handle Flash options
    }

    func gridPressed(){
        log.debug("Grid pressed")
        //TODO: handle Grid options
    }

    func aspectPressed(){
        log.debug("Aspect Ratio pressed")
        //TODO: handle Aspect Ratio options
    }

    func cameraPressed(){
        log.debug("Camera Options pressed")
        //TODO: handle Camera Exposure options
    }

    func timerPressed(){
        log.debug("Timer pressed")
        //TODO: handle Timer options
    }


    func switchPressed(){
        log.debug("Switch Cameras pressed")
        CameraManager.switchCameraLocation()
        cameraDisplayView.setFilter(currFilterDescriptor?.filter) // forces reset of filter pipeline
    }
}

var filterIndex:Int = 0

extension FilterCamViewController: CameraInfoViewDelegate {
    func filterPressed(){
        log.debug("Curr Filter pressed")
        
        
        // get list of filters in the Quick Selection category
        if (filterCount==0){
            populateFilterList()
            filterIndex = 0
        }
        
        //TEMP: cycle through filters when button is pressed
        if (filterCount>0){
            self.setFilterIndex(filterIndex)
            filterIndex = (filterIndex+1)%filterCount
        }
        
    }
}


/*** Not needed?!
extension FilterCamViewController: FilterSettingsViewDelegate {
    func updateFilterSettings(value1:Float, value2:Float,  value3:Float,  value4:Float){
        
        log.debug("\(currFilterDescriptor?.key): 1:\(value1) 2:\(value2) 3:\(value3) 4:\(value4)")
        currFilterDescriptor?.updateParameters(value1:value1, value2:value2, value3:value3, value4:value4 )
        
        filterSettingsView.isHidden = true
    }

}
***/



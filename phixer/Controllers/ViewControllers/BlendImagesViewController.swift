//
//  BlendImagesViewController.swift
//  phixer
//
//  Created by Philip Price on 9/27/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

// View Controller for blending multiple images together, with various blend modes

import UIKit
import CoreImage
import Neon
import AVFoundation
import Photos
import GoogleMobileAds


class BlendImagesViewController: CoordinatedController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    // Advertisements View
    fileprivate var adView: GADBannerView! = GADBannerView()

    // Views for simplifying layout of components
    var controlView: UIView! = UIView()
    var previewView: UIView! = UIView()

    // aspect ratio of main image (we match te blend image to this)
    var aspectRatio:CGFloat = 1.0
    
    // image view to show current blend texture
    var blendImage: UIImageView! = UIImageView()
    
    // drop down picker for blend mode
    var modePicker:UIPickerView = UIPickerView()
    
    // array of blend mode strings
    var modeList:[String] = []
    
    // slider for opacity
    var slider:UISlider! = UISlider()

    // Preview of filtered image
    var previewImage: EditImageDisplayView! = EditImageDisplayView()
    
    // Custom Menu view
    var menuView: AdornmentView! = AdornmentView()
    
    // image picker for changing edit image
    let imagePicker = UIImagePickerController()
    
    // filters used internally
    var blendFilter: FilterDescriptor? = nil
    
    // current values
    var currBlendMode:Int = 0
    var currOpacity:Float = 1.0
    
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    // vars related to the blend image source
    enum blendSource {
        case texture
        case photo
    }
    
    var currBlendSource: blendSource = .texture
    
    
    // vars related to gestures/touches
    enum touchMode {
        case none
        case gestures
        case filter
        case preview
    }
    
    var currTouchMode:touchMode = .gestures
    
    
     
     /////////////////////////////
     // MARK: - Override Base Class functions
     /////////////////////////////
     
     // return the display title for this Controller
     override public func getTitle() -> String {
         return "Blend Images"
     }
     
     // return the name of the help file associated with this Controller (without extension)
     override public func getHelpKey() -> String {
         return "blendImages"
     }
     
     /////////////////////////////
     // MARK: - INIT
     /////////////////////////////
     
     convenience init(){
         self.init(nibName:nil, bundle:nil)
         doInit()
     }
     
     
     override func viewDidLoad() {
         super.viewDidLoad()
         
         // common setup
         self.prepController()

         // get display dimensions
         displayHeight = view.height
         displayWidth = view.width
         
         doInit()
         
         doLayout()
         
         // start Ads
         if (UISettings.showAds){
             Admob.startAds(view:adView, viewController:self)
         }
         
     }
     
     
     
     static var initDone:Bool = false
     
     func doInit(){
         
         if (!BlendImagesViewController.initDone){
             BlendImagesViewController.initDone = true
            
            blendFilter = filterManager.getFilterDescriptor(key: "BlendImageFilter")
            if blendFilter == nil {
                log.error("Error getting blend filter")
            }
            blendFilter?.setParameter("inputMode", value: Float(currBlendMode))
            blendFilter?.setParameter("inputOpacity", value: currOpacity)
         }
     }
     
     
     
     func suspend(){
     }
     
 

    ////////////////////////////////////////////////
    // MARK: - Layout
    ////////////////////////////////////////////////


    func doLayout(){
        
        doInit()
        
        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        //UISettings.showAds = false // this screen looks bad with ads included...
        
        view.backgroundColor = theme.backgroundColor
        
        aspectRatio = EditManager.getAspectRatio()

        //set up  main views
        setupAds()
        setupControls()
        setupPreview()
        
        // layout constraints
        
        if (UISettings.showAds){
            adView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: adView.frame.size.height)
            controlView.align(.underCentered, relativeTo: adView, padding: 0,
                              width: controlView.frame.size.width, height: controlView.frame.size.height)
        } else {
            controlView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: controlView.frame.size.height)
        }

         previewView.align(.underCentered, relativeTo: controlView, padding: 0,
                           width: previewView.frame.size.width, height: previewView.frame.size.height)

        
        // register gesture detection for Blend Preview View
        setGestureDetectors(previewImage)
        
    }
    
    private func setupAds() {
        
        if (UISettings.showAds){
            adView.frame.size.height = UISettings.panelHeight
            adView.frame.size.width = displayWidth
            adView.layer.borderColor = theme.borderColor.cgColor
            adView.layer.cornerRadius = 0.0
            adView.layer.borderWidth = 1.0
            adView.isHidden = false
            view.addSubview(adView)
        } else {
            log.debug("Not showing Ads")
            adView.frame.size.height = 0.0
            adView.frame.size.width = displayWidth
            adView.isHidden = true
        }
    }
    

        
    private func setupControls() {

        let padding:CGFloat = 2.0
        let labelWidth = (displayWidth * 0.4).rounded()
        let widgetWidth = (displayWidth - labelWidth).rounded()
        
        // blend image
        let blendLabel:UILabel! = UILabel()
        blendLabel.frame.size.width = labelWidth
        blendLabel.frame.size.height = (UISettings.menuHeight / 2.0).rounded()
        blendLabel.textAlignment = .right
        blendLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.thin)
        blendLabel.textColor = theme.textColor
        blendLabel.text = "Blend Image: "

        // calculate display size based on source aspect ratio
        let maxw = (displayWidth / 3.0).rounded()
        let bounds = CGSize(width: maxw, height: maxw)
        let imgSize = ImageManager.aspectFit(aspectRatio: EditManager.getImageSize(), boundingSize: bounds)
        
        // Blend texture
        blendImage.frame.size = imgSize
        blendImage.frame.size.width = widgetWidth
        blendImage.contentMode = .scaleAspectFit
        blendImage.image = UIImage(ciImage: ImageManager.getCurrentBlendImage(size: imgSize)!)
        checkImageAlignment(&blendImage)

        // TODO: touch handler for blend image
        
        // Labels
        let modeLabel:UILabel! = UILabel()
        modeLabel.frame.size.width = labelWidth
        modeLabel.frame.size.height = (UISettings.menuHeight / 2.0).rounded()
        modeLabel.textAlignment = .right
        modeLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.thin)
        modeLabel.textColor = theme.textColor
        modeLabel.text = "Blend Mode: "
        
        let opacityLabel:UILabel! = UILabel()
        opacityLabel.frame.size.width = labelWidth
        opacityLabel.frame.size.height = (UISettings.menuHeight / 2.0).rounded()
        opacityLabel.textAlignment = .right
        opacityLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.thin)
        opacityLabel.textColor = theme.textColor
        opacityLabel.text = "Opacity: "

         // Mode
        modePicker.frame.size.width = widgetWidth
        modePicker.frame.size.height = (UISettings.menuHeight / 2.0).rounded()
        modePicker.delegate = self
        modePicker.dataSource = self
        modePicker.showsSelectionIndicator = true
        modePicker.setValue(theme.titleTextColor, forKeyPath: "textColor")
        setupModePicker()

        // Opacity
        slider.frame.size.width = widgetWidth
        slider.frame.size.height = (UISettings.menuHeight / 2.0).rounded()
        setupOpacitySlider()
        
        controlView.frame.size.height = blendImage.frame.size.height + modePicker.frame.size.height + slider.frame.size.height + padding * 6.0
        controlView.frame.size.width = displayWidth

        controlView.addSubview(blendLabel)
        controlView.addSubview(blendImage)
        controlView.addSubview(modeLabel)
        controlView.addSubview(opacityLabel)
        controlView.addSubview(modePicker)
        controlView.addSubview(slider)

        view.addSubview(controlView)
        blendLabel.anchorInCorner(.topLeft, xPad: 2, yPad: (blendImage.frame.size.height/2.0 - 16.0).rounded(),
                                  width: blendLabel.frame.size.width, height: blendLabel.frame.size.height)
        blendImage.align(.toTheRightCentered, relativeTo: blendLabel, padding: 0,
                         width: blendImage.frame.size.width, height: blendImage.frame.size.height)

        modePicker.align(.underCentered, relativeTo: blendImage, padding: 0,
                         width: modePicker.frame.size.width, height: modePicker.frame.size.height)
        modeLabel.align(.toTheLeftCentered, relativeTo: modePicker, padding: padding,
                         width: modeLabel.frame.size.width, height: modeLabel.frame.size.height)
        
        opacityLabel.align(.underCentered, relativeTo: modeLabel, padding: 0,
                           width: opacityLabel.frame.size.width, height: opacityLabel.frame.size.height)
        slider.align(.toTheRightCentered, relativeTo: opacityLabel, padding: padding,
                     width: slider.frame.size.width, height: slider.frame.size.height)
    }
    
    
    private func setupPreview() {
    
        previewView.frame.size.width = displayWidth
        previewView.frame.size.height = (displayHeight - controlView.frame.size.height - adView.frame.size.height).rounded()

        if aspectRatio > 1.0 { // landscape: fit width
            previewImage.frame.size.width = previewView.frame.size.width
            previewImage.frame.size.height = (previewImage.frame.size.width / aspectRatio).rounded()
        } else { // portrait: fit height
            previewImage.frame.size.height = previewView.frame.size.height
            previewImage.frame.size.width = (previewImage.frame.size.height * aspectRatio).rounded()
        }

        log.debug("Preview ar:\(aspectRatio) w: \(previewImage.frame.size.width) h:\(previewImage.frame.size.height)")

        previewView.addSubview(previewImage)
        view.addSubview(previewView)

        previewImage.anchorInCenter(width: previewImage.frame.size.width, height: previewImage.frame.size.height)
        
        previewImage.setFilter(key: "BlendImageFilter")

    }
    
    private func setupModePicker(){
        for i in 0..<BlendMode.count.rawValue {
            let mode = BlendMode(rawValue: i)
            modeList.append((mode?.toString())!)
        }
    }

    private func setupOpacitySlider(){
        slider.addTarget(self, action: #selector(self.updateOpacity), for: .touchDown)
        slider.addTarget(self, action: #selector(self.updateOpacity), for: .valueChanged)
        slider.addTarget(self, action: #selector(self.updateOpacity), for: .touchUpInside)
        slider.isContinuous = true
        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.setValue(currOpacity, animated: false)
    }


    ////////////////////////////////////////////////
    // MARK: - Blend Mode management
    ////////////////////////////////////////////////

    fileprivate func setBlendMode(_ mode: Int){
        
        guard ((mode >= 0) && (mode < BlendMode.count.rawValue)) else {
            log.error("Invalid blend mode: \(mode)")
            return
        }
        
        currBlendMode = mode
        
        // set the mode in blend filter
        blendFilter?.setParameter("inputMode", value: Float(mode))
        
        updatePreviewImage()
    }
    

    
    ////////////////////////////////////////////////
    // MARK: - blend image management
    ////////////////////////////////////////////////
    
    private func checkImageAlignment(_ imgView: inout UIImageView)  {
        
        guard imgView.image != nil else {
            log.error("NIL image")
            return
        }
        let w = (imgView.image?.size.width)!
        let h = (imgView.image?.size.height)!
        let ar =  w / h
        
        // check whether orientations are different
        if ((ar > 1.0) && (aspectRatio < 1.0)) { // landscape -> portrait
            // need to rotate 90 degrees clockwise and flip dimensions
            let angle = CGFloat.pi/2
            let scaleW = 1.0 / ar
            let scaleH = ar
            log.debug("ar:\(ar) w:\(w) h:\(h) sw:\(scaleW) sh:\(scaleH)")
            var transform = imgView.transform
            transform = transform.scaledBy(x: scaleW, y: scaleH).concatenating(transform.rotated(by: angle))
            imgView.transform = transform
            imgView.frame.size.width = h
            imgView.frame.size.height = w
        } else if ((ar < 1.0) && (aspectRatio > 1.0)) { // portrait -> landscape
            // need to rotate 90 degrees anti-clockwise  and flip dimensions
            let angle = 3.0 * CGFloat.pi/2
            let scaleW = 1.0 / ar
            let scaleH = ar
            log.debug("ar:\(ar) w:\(w) h:\(h) sw:\(scaleW) sh:\(scaleH)")
            var transform = imgView.transform
            transform = transform.scaledBy(x: scaleW, y: scaleH).concatenating(transform.rotated(by: angle))
            imgView.transform = transform
            imgView.frame.size.width = h
            imgView.frame.size.height = w
        }
    }
    
    ////////////////////////////////////////////////
    // MARK: - Opacity management
    ////////////////////////////////////////////////

    private func setOpacity(_ opacity: Float) {
        currOpacity = opacity
        blendFilter?.setParameter("inputOpacity", value: currOpacity)
        updatePreviewImage()
    }
    
    @objc func updateOpacity(_ sender:UISlider!){
        setOpacity(sender.value)
    }


    ////////////////////////////////////////////////
    // MARK: - Preview display
    ////////////////////////////////////////////////
    
    private func updatePreviewImage() {
        DispatchQueue.main.async { [weak self] in
            self?.previewImage.updateImage()
        }
    }
           

    ////////////////////////////////////////////////
    // MARK: - Gestures
    ////////////////////////////////////////////////
    
    private func setGestureDetectors(_ view: UIView){
        
    }

}

////////////////////////////////////////////////
// MARK: - Extensions
////////////////////////////////////////////////


extension BlendImagesViewController: UIPickerViewDelegate {
    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The data to return fopr the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //log.verbose("[\(row)]: \(modeList[row])")
        return modeList[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.thin)
            pickerLabel?.textAlignment = .center
        }
        if (row>=0) && (row<modeList.count){
            pickerLabel?.text = modeList[row]
            //pickerLabel?.textColor = theme.textColor
            pickerLabel?.textColor = theme.highlightColor
            pickerLabel?.textAlignment = .center
        } else {
            log.error("Invalid row index:\(row)")
            pickerLabel?.text = "unknown"
            pickerLabel?.textColor = theme.highlightColor
        }

        return pickerLabel!
    }
    
    // Capture the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        if (row>=0) && (row<modeList.count){
            log.verbose("Selected [\(row)]: \(modeList[row])")
            setBlendMode(row)
        } else {
            log.error("Invalid row index:\(row)")
        }
    }
}

extension BlendImagesViewController: UIPickerViewDataSource{
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //log.verbose("#items:\(BlendMode.count.rawValue)")
        return BlendMode.count.rawValue
    }
    
    
}


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

    // Custom Menu view
    var menuView: AdornmentView! = AdornmentView()

    // Views for simplifying layout of components
    var controlView: UIView! = UIView()
    var previewView: UIView! = UIView()
    var pickerView: UIView! = UIView()

    // aspect ratio of main image (we match the blend image to this)
    var aspectRatio:CGFloat = 1.0
    
    // image view to show current blend texture
    var blendImage: UIImageView! = UIImageView()
    
    // the current blend mode
    var currModeLabel: UILabel! = UILabel()
    
    // drop down picker for blend mode
    var modePicker:UIPickerView = UIPickerView()
    
    // array of blend mode strings
    var modeList:[String] = []
    
    // slider for opacity
    var slider:UISlider! = UISlider()

    // Preview of filtered image
    var previewImage: EditImageDisplayView! = EditImageDisplayView()
    
    // image picker for changing edit image
    let imagePicker = UIImagePickerController()
    
    // Views holding apply/cancel buttons
    var buttonView: UIView! = UIView()
    
    // filters used internally
    var blendFilter: FilterDescriptor? = nil
    
    // current values
    var currBlendMode:Int = BlendMode.sourceAtopCompositing.rawValue
    var prevBlendMode:Int = 0
    var currOpacity:Float = 0.5
    
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
         return "BlendImages"
     }
     
    // called when this controller is activated (every time, not just on first creation)
    override func start(){
        // re-layout because blend image might have changed
        self.setCustomTitle("Blend Images" )
        doLayout()
        previewImage.updateImage()
    }
    
      // handle the menu request.
      override func handleMenu() {
          // if menu is hidden then re-layout and show it, otherwise hide it
          if self.menuView.isHidden == true {
              DispatchQueue.main.async { [weak self] in
                  self?.setupMenu()
                  self?.menuView.isHidden = false
              }
          } else {
              //log.debug("Menu active, closing")
              self.menuView.isHidden = true
          }
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

        // set up the custom menu
        setupMenu()
        
        //set up  main views
        setupAds()
        setupControls()
        setupPreview()
        
        // layout constraints
        
        if (UISettings.showAds){
            adView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: adView.frame.size.height)
            controlView.align(.underCentered, relativeTo: adView, padding: 0,
                              width: controlView.frame.size.width, height: controlView.frame.size.height)
        } else {
            controlView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: controlView.frame.size.height)
        }

         previewView.align(.underCentered, relativeTo: controlView, padding: 0,
                           width: previewView.frame.size.width, height: previewView.frame.size.height)

        
        
    }
    
    private func setupMenu() {
        menuView.frame.size.height = CGFloat(UISettings.panelHeight)
        menuView.frame.size.width = displayWidth

        view.addSubview(menuView)
        menuView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: menuView.frame.size.height)

        // update the photo and blend icons (they can change)
        loadPhotoThumbnail()
        loadBlendThumbnail()
        updateAdornments()
        
        menuView.addAdornments(itemList)
        menuView.delegate = self
        menuView.isHidden = true
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
        blendLabel.font = theme.getFont(ofSize: 16.0, weight: UIFont.Weight.thin)
        blendLabel.textColor = theme.textColor
        blendLabel.text = "Blend Image: "

        let blendLabel2:UILabel! = UILabel()
        blendLabel2.frame.size.width = labelWidth
        blendLabel2.frame.size.height = (UISettings.menuHeight * 0.4).rounded()
        blendLabel2.textAlignment = .right
        blendLabel2.font = theme.getFont(ofSize: 12.0, weight: UIFont.Weight.thin)
        blendLabel2.textColor = theme.textColor
        blendLabel2.text = "(Tap to change)"

        // calculate display size based on source aspect ratio
        //let maxw = (displayWidth / 3.0).rounded()
        //let bounds = CGSize(width: maxw, height: maxw)
        let maxh = (UISettings.menuHeight * 1.5).rounded()
        let bounds = CGSize(width: maxh, height: maxh)
        let imgSize = ImageManager.aspectFit(aspectRatio: EditManager.getImageSize(), boundingSize: bounds)
        
        // Blend texture
        blendImage.frame.size = imgSize
        blendImage.frame.size.width = widgetWidth
        blendImage.contentMode = .scaleAspectFit
        blendImage.image = UIImage(ciImage: ImageManager.getCurrentBlendImage(size: imgSize)!)
        checkImageAlignment(&blendImage)
        
        let blendTap = UITapGestureRecognizer(target: self, action: #selector(blendDidPress))
        blendImage.addGestureRecognizer(blendTap)
        blendImage.isUserInteractionEnabled = true


        
        // Labels
        let modeLabel:UILabel! = UILabel()
        modeLabel.frame.size.width = labelWidth
        modeLabel.frame.size.height = (UISettings.menuHeight / 2.0).rounded()
        modeLabel.textAlignment = .right
        modeLabel.font = theme.getFont(ofSize: 16.0, weight: UIFont.Weight.thin)
        modeLabel.textColor = theme.textColor
        modeLabel.text = "Blend Mode: "
        
        currModeLabel.frame.size.width = labelWidth
        currModeLabel.frame.size.height = (UISettings.menuHeight / 2.0).rounded()
        currModeLabel.textAlignment = .center
        currModeLabel.font = theme.getFont(ofSize: 16.0, weight: UIFont.Weight.thin)
        currModeLabel.textColor = theme.textColor
        let mode = BlendMode(rawValue: currBlendMode)
        currModeLabel.text = (mode?.toString())!
        
        let modeTap = UITapGestureRecognizer(target: self, action: #selector(modeDidPress))
        currModeLabel.addGestureRecognizer(modeTap)
        currModeLabel.isUserInteractionEnabled = true

        
        
        let opacityLabel:UILabel! = UILabel()
        opacityLabel.frame.size.width = labelWidth
        opacityLabel.frame.size.height = (UISettings.menuHeight / 2.0).rounded()
        opacityLabel.textAlignment = .right
        opacityLabel.font = theme.getFont(ofSize: 16.0, weight: UIFont.Weight.thin)
        opacityLabel.textColor = theme.textColor
        opacityLabel.text = "Opacity: "



        // Opacity
        slider.frame.size.width = widgetWidth
        slider.frame.size.height = (UISettings.menuHeight / 2.0).rounded()
        setupOpacitySlider()
        
        // Apply/Cancel
        setupButtons()
        
        // combined layout
        controlView.frame.size.height = blendImage.frame.size.height + modeLabel.frame.size.height + slider.frame.size.height
        controlView.frame.size.height += buttonView.frame.size.height + padding * 6.0
        controlView.frame.size.width = displayWidth

        controlView.addSubview(blendLabel)
        controlView.addSubview(blendLabel2)
        controlView.addSubview(blendImage)
        controlView.addSubview(modeLabel)
        controlView.addSubview(opacityLabel)
        controlView.addSubview(currModeLabel)
        controlView.addSubview(slider)
        controlView.addSubview(buttonView)

        view.addSubview(controlView)
        blendLabel.anchorInCorner(.topLeft, xPad: 2, yPad: (blendImage.frame.size.height/2.0 - 16.0).rounded(),
                                  width: blendLabel.frame.size.width, height: blendLabel.frame.size.height)
        blendLabel2.align(.underCentered, relativeTo: blendLabel, padding: 0,
                         width: blendLabel2.frame.size.width, height: blendLabel2.frame.size.height)
        blendImage.align(.toTheRightCentered, relativeTo: blendLabel, padding: 0,
                         width: blendImage.frame.size.width, height: blendImage.frame.size.height)

        currModeLabel.align(.underMatchingLeft, relativeTo: blendImage, padding: 0,
                         width: currModeLabel.frame.size.width, height: currModeLabel.frame.size.height)
        modeLabel.align(.toTheLeftCentered, relativeTo: currModeLabel, padding: padding,
                         width: modeLabel.frame.size.width, height: modeLabel.frame.size.height)
        
        opacityLabel.align(.underCentered, relativeTo: modeLabel, padding: 0,
                           width: opacityLabel.frame.size.width, height: opacityLabel.frame.size.height)
        slider.align(.toTheRightCentered, relativeTo: opacityLabel, padding: padding,
                     width: slider.frame.size.width, height: slider.frame.size.height)
        
        buttonView.align(.underMatchingLeft, relativeTo: opacityLabel, padding: 0,
                           width: buttonView.frame.size.width, height: buttonView.frame.size.height)
        
        setupPickerView()
    }
    
    private func setupButtons(){
        buttonView.frame.size.width = displayWidth
        buttonView.frame.size.height = (UISettings.panelHeight * 0.6).rounded()
        
        // build a view with an "Apply" Button and a "Cancel" button
        let cancelButton:BorderedButton = BorderedButton()
        cancelButton.frame.size.width = displayWidth / 3.0
        cancelButton.frame.size.height = buttonView.frame.size.height - 2
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.useGradient = true
        cancelButton.backgroundColor = theme.buttonColor
        
        let applyButton:BorderedButton = BorderedButton()
        applyButton.frame.size = cancelButton.frame.size
        applyButton.setTitle("Apply", for: .normal)
        applyButton.useGradient = true
        applyButton.backgroundColor = theme.buttonColor
        
        
        buttonView.addSubview(cancelButton)
        buttonView.addSubview(applyButton)
        
        // distribute across the control view
        buttonView.groupInCenter(group: .horizontal, views: [applyButton, cancelButton], padding: 16, width: applyButton.frame.size.width, height: applyButton.frame.size.height)
        
        // add touch handlers
        applyButton.addTarget(self, action: #selector(self.applyDidPress), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(self.cancelDidPress), for: .touchUpInside)
        
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
    
    // funcs for setting up usable picker list
    private func setupPickerView(){
        // set up the container view, which overlays the controlView
        pickerView.frame = controlView.frame
        pickerView.backgroundColor = theme.backgroundColor
        view.addSubview(pickerView)
        hidePickerView()
        
        // Done/Cancel controls
        let pickerControlView: UIView! = UIView()
        pickerControlView.frame.size.width = pickerView.frame.size.width
        pickerControlView.frame.size.height = (UISettings.menuHeight / 2.0).rounded()
        
        let cancelLabel: UILabel! = UILabel()
        cancelLabel.frame.size.width = (displayWidth / 4.0).rounded()
        cancelLabel.frame.size.height = (UISettings.menuHeight / 2.0).rounded()
        cancelLabel.textAlignment = .center
        cancelLabel.font = theme.getFont(ofSize: 20.0, weight: UIFont.Weight.regular)
        cancelLabel.textColor = theme.textColor
        cancelLabel.text = "Cancel"
        
        let doneLabel: UILabel! = UILabel()
        doneLabel.frame.size.width = (displayWidth / 4.0).rounded()
        doneLabel.frame.size.height = (UISettings.menuHeight / 2.0).rounded()
        doneLabel.textAlignment = .center
        doneLabel.font = theme.getFont(ofSize: 20.0, weight: UIFont.Weight.regular)
        doneLabel.textColor = theme.textColor
        doneLabel.text = "Done"
        
        let pickerCancelTap = UITapGestureRecognizer(target: self, action: #selector(pickerCancelDidPress))
        cancelLabel.addGestureRecognizer(pickerCancelTap)
        cancelLabel.isUserInteractionEnabled = true
        
        let pickerDoneTap = UITapGestureRecognizer(target: self, action: #selector(pickerDoneDidPress))
        doneLabel.addGestureRecognizer(pickerDoneTap)
        doneLabel.isUserInteractionEnabled = true
        
        pickerControlView.addSubview(cancelLabel)
        pickerControlView.addSubview(doneLabel)
        cancelLabel.anchorInCorner(.topLeft, xPad: 0, yPad: 0, width: cancelLabel.frame.size.width, height: cancelLabel.frame.size.height)
        doneLabel.anchorInCorner(.topRight, xPad: 0, yPad: 0, width: doneLabel.frame.size.width, height: doneLabel.frame.size.height)

        // Mode picker
        modePicker.frame.size.height = pickerView.frame.size.height - pickerControlView.frame.size.height
        modePicker.frame.size.width = pickerView.frame.size.width

        modePicker.delegate = self
        modePicker.dataSource = self
        modePicker.showsSelectionIndicator = true
        modePicker.center = pickerView.center
        setupModePicker()
        
        pickerView.addSubview(pickerControlView)
        pickerView.addSubview(modePicker)
        pickerControlView.anchorInCorner(.topLeft, xPad: 0, yPad: 0,
                                  width: pickerControlView.frame.size.width, height: pickerControlView.frame.size.height)
        modePicker.align(.underCentered, relativeTo: pickerControlView, padding: 0,
                         width: modePicker.frame.size.width, height: modePicker.frame.size.height)
    }
    
    private func showPickerView(){
        pickerView.isHidden = false
        prevBlendMode = currBlendMode
        modePicker.selectRow(currBlendMode, inComponent: 0, animated: true)
    }
    
    private func hidePickerView(){
        pickerView.isHidden = true
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
     // MARK: - Menu support
     ////////////////////////////////////////////////
     
     // these vars are global scope because they are updated asynchronously
     private var photoThumbnail:UIImage? = nil
     private var blendThumbnail:UIImage? = nil
     
     
     
     // set photo image to the last photo in the camera roll
     func loadPhotoThumbnail(){
         
         let tgtSize = CGSize(width: UISettings.buttonSide, height: UISettings.buttonSide)
         
         
         // get most recent photo
         let fetchOptions = PHFetchOptions()
         fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
         
         let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
         
         let last = fetchResult.lastObject
         
         if let lastAsset = last {
             let options = PHImageRequestOptions()
             options.version = .current
             
             PHImageManager.default().requestImage(
                 for: lastAsset,
                 targetSize: tgtSize,
                 contentMode: .aspectFit,
                 options: options,
                 resultHandler: { image, _ in
                     DispatchQueue.main.async {
                         self.photoThumbnail = image
                     }
             })
         }
     }
     
     private func loadBlendThumbnail(){
         self.blendThumbnail = UIImage(ciImage: ImageManager.getCurrentBlendImage(size:UISettings.buttonSize)!)
     }
     
     //////////////////////////////////////
     // MARK: - Menu item handlers
     //////////////////////////////////////
     // build the list of adornments
     
     
     var itemList:[Adornment] = [ ]
     
     func updateAdornments(){
         
         itemList = []
         itemList.append (Adornment(key: "photo", text: "photo", icon: "", view: photoThumbnail, isHidden: false))
         itemList.append (Adornment(key: "blend", text: "blend", icon: "", view: blendThumbnail, isHidden: false))
         itemList.append (Adornment(key: "save", text: "save", icon: "ic_save", view: nil, isHidden: false))
         itemList.append (Adornment(key: "help", text: "help", icon: "ic_info", view: nil, isHidden: false))
     }
     
     func handleSelection(key: String){
         switch (key){
         case "photo":
             imageMenuDidPress()
         case "blend":
             blendMenuDidPress()
         case "save":
             saveMenuDidPress()
         case "help":
             helpMenuDidPress()
         default:
             log.error("Unknown key: \(key)")
         }
     }
     
     @objc func imageMenuDidPress(){
         self.menuView.isHidden = true
         self.changeImage()
     }
     
     @objc func blendMenuDidPress(){
         self.coordinator?.activateRequest(id: .chooseBlend)
     }
     
     @objc func saveMenuDidPress(){
         self.menuView.isHidden = true
         DispatchQueue.main.async { [weak self] in
             if EditManager.isPreviewActive() {
                 self?.displayPreviewAlert()
             } else {
                 self?.saveImage()
                 log.verbose("Image saved")
                 self?.showMessage("Image saved to Photos")
             }
         }
     }
         
     @objc func helpMenuDidPress(){
         log.debug("help")
         DispatchQueue.main.async { [weak self] in
             self?.coordinator?.helpRequest()
             self?.menuView.isHidden = true
         }
     }
     
    
     ////////////////////////////////////////////////
     // MARK: - Touch Handlers
     ////////////////////////////////////////////////

    @objc func blendDidPress(){
        log.verbose("Blend pressed")
        // launch the Blend Gallery
        //self.coordinator?.activateRequest(id: .blendGallery)
        self.coordinator?.activateRequest(id: .chooseBlend)
    }

    
    @objc func modeDidPress(){
        log.verbose("Mode pressed")
        prevBlendMode = currBlendMode
        showPickerView()
    }


    @objc func cancelDidPress(){
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            dismiss(animated: true, completion: { [weak self] in
                log.verbose("Cancelling...")
            })
            return
        }
    }
    
    @objc func applyDidPress(){
        DispatchQueue.main.async { [weak self] in
            EditManager.savePreviewFilter()
            self?.showMessage("Effect applied", time:0.5)
        }
    }
    
    @objc func pickerCancelDidPress(){
        // restore previous blend mode and dismiss the picker
        setBlendMode(prevBlendMode)
        hidePickerView()
    }
    
    @objc func pickerDoneDidPress(){
        // blend mode already set, so just dismiss the picker
        setBlendMode(currBlendMode)
        hidePickerView()
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
        
        let mode = BlendMode(rawValue: currBlendMode)
        currModeLabel.text = (mode?.toString())!
        //hidePickerView()

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
    
     //////////////////////////////////////
     // MARK: - Apply Preview alert processing
     //////////////////////////////////////
     
     
     fileprivate var applyPreviewAlert:UIAlertController? = nil
     
     private func displayPreviewAlert() {
         
         
         // build the alert if first time
         if (applyPreviewAlert == nil){
             applyPreviewAlert = UIAlertController(title: "Preview Not Applied",
                                                   message:"There is a Preview effect that has not been applied.\n" +
                 "Did you want to include this in the Saved image?",
                                                   preferredStyle: .alert)
             
             // add the OK button
             let okAction = UIAlertAction(title: "Apply", style: .default) { (action:UIAlertAction) in
                 log.debug("Apply Preview")
                 EditManager.savePreviewFilter()
                 self.previewImage.updateImage()
                 self.saveImage()
             }
             applyPreviewAlert?.addAction(okAction)
             
             // add the Cancel Button
             let cancelAction = UIAlertAction(title: "Ignore", style: .default) { (action:UIAlertAction) in
                 log.debug("Ignore")
                 EditManager.removePreviewFilter()
                 self.previewImage.updateImage()
                 self.saveImage()
             }
             applyPreviewAlert?.addAction(cancelAction)
             
         }
         
         // display the dialog
         DispatchQueue.main.async { [weak self] in
             self?.present((self?.applyPreviewAlert)!, animated: true, completion:nil)
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
           

    
     //////////////////////////////////////////
     // MARK: - ImagePicker handling
     //////////////////////////////////////////
     
     func changeImage(){
         DispatchQueue.main.async { [weak self] in
             log.debug("imagePreview pressed - launching ImagePicker...")
             // launch an ImagePicker
             self?.imagePicker.allowsEditing = false
             self?.imagePicker.sourceType = .photoLibrary
             //self?.imagePicker.modalPresentationStyle = .popover // required after ios12
             self?.imagePicker.delegate = self
             
             self?.present((self?.imagePicker)!, animated: true, completion: {})
         }
     }
     
     
     func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
         log.verbose("Image picked")
         if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
             let assetResources = PHAssetResource.assetResources(for: asset)
             let name = assetResources.first!.originalFilename
             let id = assetResources.first!.assetLocalIdentifier
             
             log.verbose("Picked image:\(name) id:\(id)")
             //EditManager.setInputImage(name: name)
             EditManager.setInputImage(name: id) // changed in iOS12
             EditManager.update()
             DispatchQueue.main.async { [weak self] in
                 self?.previewImage.updateImage()
             }
             
             // bit of a hack, but reset face detection if image changes. This allows results to be re-used across filters, which is a very expensive operation
             DispatchQueue.main.async { [weak self] in
                 FaceDetection.reset()
                 FaceDetection.detectFaces(on: EditManager.getPreviewImage()!, orientation: EditManager.getEditImageOrientation(), completion: {})
             }
         } else {
             log.error("Error accessing image data")
         }
         picker.dismiss(animated: false, completion: nil)
     }
     
     
     func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
         log.verbose("Image Picker cancelled")
         picker.dismiss(animated: false)
     }

    
    
    //////////////////////////////////////
    //MARK: - Utility functions
    //////////////////////////////////////
    
    open func saveImage(){
        previewImage.saveImage()
        playCameraSound()
    }
    
    fileprivate func playCameraSound(){
        AudioServicesPlaySystemSound(1108) // undocumented iOS feature!
    }
    
    func showMessage(_ msg:String, time:TimeInterval=1.0){
        if !msg.isEmpty {
            DispatchQueue.main.async { [weak self] in
                let alert = UIAlertController(title: "", message: msg, preferredStyle: .alert)
                self?.present(alert, animated: true, completion: nil)
                Timer.scheduledTimer(withTimeInterval: time, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)} )
            }
        }
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
    
    // returns the view to use for the requested row
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = theme.getFont(ofSize: 24.0, weight: UIFont.Weight.regular)
            pickerLabel?.textAlignment = .center
        }
        if (row>=0) && (row<modeList.count){
            pickerLabel?.text = modeList[row]
            pickerLabel?.textColor = theme.textColor
            //pickerLabel?.textColor = theme.highlightColor
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

// Adornment delegate

extension BlendImagesViewController: AdornmentDelegate {
    func adornmentItemSelected(key: String) {
        DispatchQueue.main.async { [weak self] in
            self?.handleSelection(key: key)
        }
    }
}



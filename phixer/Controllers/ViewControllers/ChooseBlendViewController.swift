//
//  ChooseBlendViewController.swift
//  Controller to guide the user in choosing a blend image (photo or built-in texture)
//
//  Created by Philip Price on 10/29/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Neon
import Photos

class ChooseBlendViewController: CoordinatedController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    private var displayWidth : CGFloat = 0.0
    private var displayHeight : CGFloat = 0.0
    private var sectionHeight : CGFloat = 0.0
    private var labelHeight : CGFloat = 0.0
    private var imageHeight : CGFloat = 0.0

    
    private var mainView:UIView! = UIView()
    private var selectedView:UIView! = UIView()
    private var recentPhotosView:UIView! = UIView()
    private var blendTexturesView:UIView! = UIView()
    
    private static let morePhotosKey:String = "more..."

    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////
    
    // return the display title for this Controller
    override public func getTitle() -> String {
        return "Choose Blend Image"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "About" // temp, change later
    }
    
    override func start() {
        self.setCustomTitle("Blend Images" )
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

        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        self.setCustomTitle("Blend Images" )
        
        view.backgroundColor = theme.backgroundColor // default seems to be white
        
        layoutChooseBlendView()
        view.addSubview(mainView)
        
        // layout constraints
        mainView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: displayHeight)
    }
    

    private func layoutChooseBlendView(){
        mainView.frame.size.height = displayHeight-UISettings.panelHeight
        mainView.frame.size.width = displayWidth
        mainView.backgroundColor = theme.backgroundColor
        
        // set up sizes for each section
        sectionHeight = ((mainView.frame.size.height-12.0) / 3.0).rounded()
        labelHeight = 24.0
        imageHeight = sectionHeight - labelHeight - 4.0

        
        layoutCurrentSelection()
        layoutRecentPhotos()
        layoutBlendTextures()
        
        let w = mainView.frame.size.width - 8.0
        let h = sectionHeight.rounded()
        view.groupAgainstEdge(group: .vertical,
                              views: [selectedView, recentPhotosView, blendTexturesView],
                              againstEdge: .top, padding: 8, width: w, height: h)

    }
    

    // view that presents the currently selected image (if any)
    private func layoutCurrentSelection() {
        let w = mainView.frame.size.width - 8.0
        let h = sectionHeight

        selectedView.frame.size.height = h
        selectedView.frame.size.width = w
        selectedView.backgroundColor = theme.backgroundColor
        
        let label:UILabel! = UILabel()
        label.frame.size.height = labelHeight
        label.frame.size.width = w
        label.backgroundColor = theme.subtitleColor
        label.textColor = theme.textColor
        label.font = theme.getFont(ofSize: 16, weight: UIFont.Weight.thin)
        label.textAlignment = .left
        label.text = "Current selection:"

        
        let selectedImage: UIImageView! = UIImageView()
        selectedImage.frame.size.height = imageHeight
        let size = EditManager.getImageSize()
        selectedImage.frame.size.width = selectedImage.frame.size.height * (size.width / size.height)
        //log.verbose("w:\(w) h:\(h) img: \(selectedImage.frame.size)")
        
        selectedImage.contentMode = .scaleAspectFit

        //selectedImage.image = UIImage(ciImage: EditManager.getPreviewImage(size: selectedImage.frame.size)!)
        selectedImage.image = UIImage(ciImage: ImageManager.getCurrentBlendImage(size: selectedImage.frame.size)!)

        selectedView.addSubview(label)
        selectedView.addSubview(selectedImage)
        label.anchorToEdge(.top, padding: 4, width: label.frame.size.width, height: label.frame.size.height)
        selectedImage.align(.underCentered, relativeTo: label, padding: 2.0, width: selectedImage.frame.size.width, height: selectedImage.frame.size.height)

        mainView.addSubview(selectedView)
        
        // add a touch handler for the selected photo:
        let selectedTap = UITapGestureRecognizer(target: self, action: #selector(selectedPhotoDidPress))
        selectedImage.addGestureRecognizer(selectedTap)
        selectedImage.isUserInteractionEnabled = true

    }
    
    // view that presents the list of recently taken photos
    private func layoutRecentPhotos() {
        let w = mainView.frame.size.width - 8.0
        let h = sectionHeight

        recentPhotosView.frame.size.height = h
        recentPhotosView.frame.size.width = w
        recentPhotosView.backgroundColor = theme.backgroundColor
        
        let label:UILabel! = UILabel()
        label.frame.size.height = labelHeight
        label.frame.size.width = w
        label.backgroundColor = theme.subtitleColor
        label.textColor = theme.textColor
        label.font = theme.getFont(ofSize: 16, weight: UIFont.Weight.thin)
        label.textAlignment = .left
        label.text = "Latest Photos:"
        
        let recentStrip:SimpleSwipeView! = SimpleSwipeView()
        recentStrip.delegate = self
        recentStrip.frame.size.height = imageHeight
        recentStrip.frame.size.width = mainView.frame.size.width
        recentStrip.backgroundColor = theme.backgroundColor
        recentStrip.disableWrap()
 
        let numItems = 8
        var itemList: [Adornment] = []

        
        ImageManager.getLatestPhotoList(count: numItems, completion: { list in
            if list.count > 0 {
                for asset in list {
                    itemList.append(Adornment(key: asset ?? "", text: "", icon: asset ?? "", view: nil, isHidden: false))
                }
                
                // TODO: add icon to launch photo browser
                itemList.append(Adornment(key: ChooseBlendViewController.morePhotosKey, text: ChooseBlendViewController.morePhotosKey, icon: "", view: nil, isHidden: false))

                recentStrip.setItems(itemList)
                recentStrip.isHidden = false
             } else {
                recentStrip.isHidden = true
            }
        })
        
 
        recentPhotosView.addSubview(label)
        recentPhotosView.addSubview(recentStrip)
        label.anchorToEdge(.top, padding: 4, width: label.frame.size.width, height: label.frame.size.height)
        recentStrip.align(.underCentered, relativeTo: label, padding: 0.0, width: recentStrip.frame.size.width, height: recentStrip.frame.size.height)

        mainView.addSubview(recentPhotosView)
    }
    

    // view that presents the list of availablke blend textures
    private func layoutBlendTextures() {
        let w = mainView.frame.size.width - 8.0
        let h = sectionHeight

        blendTexturesView.frame.size.height = h
        blendTexturesView.frame.size.width = w
        blendTexturesView.backgroundColor = theme.backgroundColor
        
        let label:UILabel! = UILabel()
        label.frame.size.height = labelHeight
        label.frame.size.width = w
        label.backgroundColor = theme.subtitleColor
        label.textColor = theme.textColor
        label.font = theme.getFont(ofSize: 16, weight: UIFont.Weight.thin)
        label.textAlignment = .left
        label.text = "Built-in Textures:"
       
        
        let textureStrip:SimpleSwipeView! = SimpleSwipeView()
        textureStrip.delegate = self
        textureStrip.frame.size.height = imageHeight
        textureStrip.frame.size.width = mainView.frame.size.width
        textureStrip.backgroundColor = theme.backgroundColor
        textureStrip.disableWrap()
        textureStrip.disableTint()

        
        var itemList: [Adornment] = []
        
        let list = ImageManager.getBlendImageList()
        if list.count > 0 {
            for i in 0...(list.count-1){
                itemList.append(Adornment(key: list[i], text: "", icon: list[i], view: nil, isHidden: false))
            }
            textureStrip.setItems(itemList)
            textureStrip.isHidden = false
        } else {
            textureStrip.isHidden = true
        }

        blendTexturesView.addSubview(label)
        blendTexturesView.addSubview(textureStrip)
        label.anchorToEdge(.top, padding: 4, width: label.frame.size.width, height: label.frame.size.height)
        textureStrip.align(.underCentered, relativeTo: label, padding: 0.0, width: textureStrip.frame.size.width, height: textureStrip.frame.size.height)

        mainView.addSubview(blendTexturesView)

    }
    


    
    //////////////////////////////////////
    //MARK: - Touch handling
    //////////////////////////////////////

    // called when the currently selected photo is pressed. Since it's already selected, we don't need to change anything, just launch the menu
    @objc private func selectedPhotoDidPress() {
        self.coordinator?.activateRequest(id: ControllerIdentifier.mainMenu)
    }
    
    // kicks off next action once a photo has been selected
    private func selectBlendImage(_ name: String){
        if !name.isEmpty {
            log.verbose("Blend image set to: \(name)")
            ImageManager.setCurrentBlendImageName(name)
            self.dismiss()
        } else {
            log.error("Empty asset name supplied. Ignoring")
        }
    }
    

    
    //////////////////////////////////////
    //MARK: - Photo selection
    //////////////////////////////////////
    
    fileprivate let imagePicker = UIImagePickerController()

    private func launchPhotoBrowser() {
        DispatchQueue.main.async(execute: { () -> Void in
            // launch an ImagePicker
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary
            self.imagePicker.modalPresentationStyle = .popover // required after ios12
            self.imagePicker.delegate = self
            self.present(self.imagePicker, animated: true, completion: nil)
        })
    }

    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
            
            let assetResources = PHAssetResource.assetResources(for: asset)
            
            let name = assetResources.first!.originalFilename
            let id = assetResources.first!.assetLocalIdentifier
            
            log.verbose("Picked image:\(name) id:\(id)")
            self.selectBlendImage(id)
        } else {
            log.error("Error accessing image data")
        }
        picker.dismiss(animated: true)
        
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        log.verbose("Image Picker cancelled")
        picker.dismiss(animated: true)
    }
    
    
    //////////////////////////////////////
    //MARK: - Navigation
    //////////////////////////////////////
    @objc func backDidPress(){
        log.verbose("Back pressed")
        exitScreen()
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

extension ChooseBlendViewController: AdornmentDelegate {
    func adornmentItemSelected(key: String) {
        if !key.isEmpty {
            if key == ChooseBlendViewController.morePhotosKey {
                // special key that launches the photo browser
                launchPhotoBrowser()
            } else {
                DispatchQueue.main.async(execute: { () -> Void  in
                    self.selectBlendImage(key)
                })
            }
        }
    }
}

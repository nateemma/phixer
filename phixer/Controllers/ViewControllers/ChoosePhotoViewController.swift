//
//  ChoosePhotoViewController.swift
//  Controller to guide the user in choosing a photo to edit
//
//  Created by Philip Price on 10/29/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Neon
import Photos

class ChoosePhotoViewController: CoordinatedController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    private var displayWidth : CGFloat = 0.0
    private var displayHeight : CGFloat = 0.0
    private var sectionHeight : CGFloat = 0.0
    private var labelHeight : CGFloat = 0.0
    private var imageHeight : CGFloat = 0.0

    
    private var mainView:UIView! = UIView()
    private var selectedView:UIView! = UIView()
    private var recentPhotosView:UIView! = UIView()
    private var recentEditsView:UIView! = UIView()
    
    private static let morePhotosKey:String = "more..."

    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////
    
    // return the display title for this Controller
    override public func getTitle() -> String {
        return "Choose a Photo"
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
        EditList.load()
        //FilterConfiguration.loadSettings()
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
        
        // make sure edit image has been set
        EditManager.setInputImage(ImageManager.getCurrentEditImage())

        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        
        view.backgroundColor = theme.backgroundColor // default seems to be white
        
        layoutChoosePhotoView()
        view.addSubview(mainView)
        
        // layout constraints
        mainView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: displayHeight)
    }
    

    private func layoutChoosePhotoView(){
        mainView.frame.size.height = displayHeight-UISettings.panelHeight
        mainView.frame.size.width = displayWidth
        mainView.backgroundColor = theme.backgroundColor
        
        // set up sizes for each section
        sectionHeight = ((mainView.frame.size.height-12.0) / 3.0).rounded()
        labelHeight = 24.0
        imageHeight = sectionHeight - labelHeight - 4.0

        
        layoutCurrentSelection()
        layoutRecentPhotos()
        layoutRecentEdits()
        
        let w = mainView.frame.size.width - 8.0
        let h = sectionHeight.rounded()
        view.groupAgainstEdge(group: .vertical,
                              views: [selectedView, recentPhotosView, recentEditsView],
                              againstEdge: .top, padding: 8, width: w, height: h)

    }
    

    // view that presents the currently selected photo (if any)
    private func layoutCurrentSelection() {
        let w = mainView.frame.size.width - 8.0
        let h = sectionHeight

        selectedView.frame.size.height = h
        selectedView.frame.size.width = w
        selectedView.backgroundColor = theme.backgroundColor
        
        let label:UILabel! = UILabel()
        label.frame.size.height = labelHeight
        label.frame.size.width = w
        label.backgroundColor = theme.titleColor
        label.textColor = theme.subtitleTextColor
        label.font = theme.getFont(ofSize: 16, weight: UIFont.Weight.light)
        label.textAlignment = .left
        label.text = "Current selection:"

        
        let selectedImage: UIImageView! = UIImageView()
        selectedImage.frame.size.height = imageHeight
        let size = EditManager.getImageSize()
        selectedImage.frame.size.width = selectedImage.frame.size.height * (size.width / size.height)
        //log.verbose("w:\(w) h:\(h) img: \(selectedImage.frame.size)")
        
        selectedImage.contentMode = .scaleAspectFit

        selectedImage.image = UIImage(ciImage: EditManager.getPreviewImage(size: selectedImage.frame.size)!)

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
        label.backgroundColor = theme.titleColor
        label.textColor = theme.subtitleTextColor
        label.font = theme.getFont(ofSize: 16, weight: UIFont.Weight.light)
        label.textAlignment = .left
        label.text = "Latest Photos:"
        
        let recentStrip:SimpleSwipeView! = SimpleSwipeView()
        recentStrip.delegate = self
        recentStrip.frame.size.height = imageHeight
        recentStrip.frame.size.width = mainView.frame.size.width
        recentStrip.backgroundColor = theme.backgroundColor
        recentStrip.disableWrap()
 
        let numItems = 5
        var itemList: [Adornment] = []

        
        ImageManager.getLatestPhotoList(count: numItems, completion: { list in
            if list.count > 0 {
                for asset in list {
                    itemList.append(Adornment(key: asset ?? "", text: "", icon: asset ?? "", view: nil, isHidden: false))
                }
                
                // TODO: add icon to launch photo browser
                itemList.append(Adornment(key: ChoosePhotoViewController.morePhotosKey, text: ChoosePhotoViewController.morePhotosKey, icon: "", view: nil, isHidden: false))

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
    

    // view that presents the list of recently edited/selected photos
    private func layoutRecentEdits() {
        let w = mainView.frame.size.width - 8.0
        let h = sectionHeight

        recentEditsView.frame.size.height = h
        recentEditsView.frame.size.width = w
        recentEditsView.backgroundColor = theme.backgroundColor
        
        let label:UILabel! = UILabel()
        label.frame.size.height = labelHeight
        label.frame.size.width = w
        label.backgroundColor = theme.titleColor
        label.textColor = theme.subtitleTextColor
        label.font = theme.getFont(ofSize: 16, weight: UIFont.Weight.light)
        label.textAlignment = .left
        label.text = "Recent Selections:"
       
        
        let editStrip:SimpleSwipeView! = SimpleSwipeView()
        editStrip.delegate = self
        editStrip.frame.size.height = imageHeight
        editStrip.frame.size.width = mainView.frame.size.width
        editStrip.backgroundColor = theme.backgroundColor
        editStrip.disableWrap()

        
        let numItems = 5
        var itemList: [Adornment] = []
        
        let list = EditList.get()
        if list.count > 0 {
            for i in 0...(min(numItems, list.count)-1){
                itemList.append(Adornment(key: list[i], text: "", icon: list[i], view: nil, isHidden: false))
            }
            editStrip.setItems(itemList)
            editStrip.isHidden = false
        } else {
            editStrip.isHidden = true
        }

        recentEditsView.addSubview(label)
        recentEditsView.addSubview(editStrip)
        label.anchorToEdge(.top, padding: 4, width: label.frame.size.width, height: label.frame.size.height)
        editStrip.align(.underCentered, relativeTo: label, padding: 0.0, width: editStrip.frame.size.width, height: editStrip.frame.size.height)

        mainView.addSubview(recentEditsView)

    }
    


    
    //////////////////////////////////////
    //MARK: - Touch handling
    //////////////////////////////////////

    // called when the currently selected photo is pressed. Since it's already selected, we don't need to change anything, just launch the menu
    @objc private func selectedPhotoDidPress() {
        self.coordinator?.activateRequest(id: ControllerIdentifier.mainMenu)
    }
    
    // kicks off next action once a photo has been selected
    private func selectPhoto(_ name: String){
        if !name.isEmpty {
            ImageManager.setCurrentEditImageName(name)
            EditManager.reset()
            EditManager.setInputImage(ImageManager.getCurrentEditImage())
            EditList.save()
            self.coordinator?.activateRequest(id: ControllerIdentifier.mainMenu)
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
            self.selectPhoto(id)
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

extension ChoosePhotoViewController: AdornmentDelegate {
    func adornmentItemSelected(key: String) {
        if !key.isEmpty {
            if key == ChoosePhotoViewController.morePhotosKey {
                // special key that launches the photo browser
                launchPhotoBrowser()
            } else {
                DispatchQueue.main.async(execute: { () -> Void  in
                    self.selectPhoto(key)
                })
            }
        }
    }
}

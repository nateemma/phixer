//
//  EditStackView.swift
//  phixer
//
//  Created by Philip Price on 901/21/19
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation


protocol EditStackViewDelegate: class {
    func editStackDismiss()
}

// View for displaying the current contents of the Edit Stack
class EditStackView: UIView {
    
    var theme = ThemeManager.currentTheme()
    
    weak var delegate: EditStackViewDelegate? = nil
    
    // title
    fileprivate var titleView: UIView! = UIView()

    // view for each stack layer (plus original and preview)
    fileprivate var layerView: [UIView] = []
    
    // scrollview to hold layers (just in case)
    fileprivate var scrollView: UIScrollView? = nil
    
    
    fileprivate var currInput:CIImage? = nil


    private let titleHeight:CGFloat = 44
    private var imageHeight:CGFloat = 64
    private var rowHeight:CGFloat = 96
    
    fileprivate lazy var imgSize:CGSize = CGSize(width: imageHeight*3, height: imageHeight*3)
    
    ///////////////////////////////////
    // MARK: - Setup/teardown
    ///////////////////////////////////
    convenience init(){
        self.init(frame: CGRect.zero)
        self.isHidden = false
    }
    
    
    deinit {
        //suspend()
    }

   
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.backgroundColor = theme.backgroundColor
        self.layer.cornerRadius = 12.0
        self.layer.borderWidth = 4.0
        self.layer.borderColor = theme.borderColor.withAlphaComponent(0.8).cgColor


        // layout the main contianer views
        titleView.frame.size.width = self.frame.size.width
        titleView.frame.size.height = UISettings.titleHeight

        if (scrollView == nil) {
            var frame = self.frame
            frame.size.height = frame.size.height - titleView.frame.size.height
            scrollView = UIScrollView(frame: frame)
            scrollView?.contentSize = frame.size
        }

        
        self.addSubview(titleView)
        self.addSubview(scrollView!)
        
        setupTitle()
        setupStackLayers()

 
        titleView.anchorToEdge(.top, padding: 8, width: titleView.frame.size.width, height: titleView.frame.size.height)
        //scrollView?.anchorToEdge(.bottom, padding: 8, width: titleView.frame.size.width, height: UISettings.panelHeight)
   }
    
    
    private func setupTitle(){
        // set up the title, with a label for the text and an image for 'exit' options

        // exit button
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
        label.text = "Current Edit Stack"
        label.textAlignment = .center
        label.textColor = theme.titleTextColor
        label.backgroundColor = theme.titleColor
        label.font = UIFont.systemFont(ofSize: 18)
        
        titleView.addSubview(label)
        titleView.addSubview(cancelButton)
        

        cancelButton.anchorToEdge(.right, padding: 8, width: cancelButton.frame.size.width, height: cancelButton.frame.size.height)
        label.anchorInCenter(width: titleView.frame.size.width, height: titleView.frame.size.height)
    
    }
    
    
    private func setupStackLayers() {
        
        layerView = []
        
        let count = EditManager.getAppliedCount()
        let h = max (rowHeight, (scrollView?.frame.size.height)!/CGFloat(count+2))
        rowHeight = h
        imgSize = CGSize(width: h*0.8, height: h*0.8)

        // setup the input
        //self.currInput = InputSource.getCurrentImage()?.resize(size: CGSize(width: imgSize.width*8, height: imgSize.height*8))
        self.currInput = InputSource.getCurrentImage()
        EditManager.setInputImage(self.currInput)

        // Add the preview view on top
        //scrollView?.addSubview(makePreviewView()!)
        layerView.append(makePreviewView()!)
        
        // Add the applied filters (if any)
        if count > 0 {
            // why does Swift not allow backwards iteration?!
            for i in stride(from: count-1, through: 0, by: -1) {
                //scrollView?.addSubview(makeStackEntryView(layer:i)!)
                layerView.append(makeStackEntryView(layer:i)!)
           }
        }
        
        // Add the original on the bottom
        //scrollView?.addSubview(makeOriginalView()!)
        layerView.append(makeOriginalView()!)
        
        let layers = UIView()
        layers.frame = self.frame
        layers.frame.size.height = layers.frame.size.height - UISettings.panelHeight
        self.addSubview(layers)
        layers.align(.underCentered, relativeTo: titleView, padding: 0, width: 0, height: layers.frame.size.height)
        
        
        for v in layerView {
            layers.addSubview(v)
        }

        //layers.groupAndFill(group: .vertical, views: layerView, padding: 0)
        layers.groupAgainstEdge(group: .vertical,
                              views:layerView,
                              againstEdge: .top, padding: 0, width: self.frame.size.width, height: rowHeight)

    }
    

    // make a view from the preview (not yet applied) image
    private func makePreviewView() -> UIView? {
        let image = EditManager.getPreviewImage()
        let title = EditManager.getPreviewTitle()
        return makeLayerView(image: image, text: "\(title)\n(Preview, not saved)")
    }
    
    
    // make a view from one of the applied filters
    private func makeStackEntryView(layer:Int) -> UIView? {
        let image = EditManager.getFilteredImageAt(position:layer)
        let title = EditManager.getTitleAt(position:layer)
        log.debug("Layer:[\(layer)] = \(title)")
        return makeLayerView(image: image, text: "\(title)")
    }
    
    
    // make a view from the original image
    private func makeOriginalView() -> UIView? {
        let image = EditManager.getOriginalImage()
        return makeLayerView(image: image, text: "(Original)")
    }

    
    // make a composite view from the filtered image and associate text
    private func makeLayerView(image:CIImage?, text:String) -> UIView? {
        log.verbose("Adding row for: \(text)")
        let pview = UIView()
        pview.frame.size.width = self.frame.size.width
        pview.frame.size.height = rowHeight
        
        let metalView = MetalImageView()
        metalView.frame.size = CGSize(width: imageHeight, height: imageHeight)
        metalView.setImageSize((image?.extent.size)!)
        metalView.image = image

        
        let label = UILabel()
        label.frame.size.width = self.frame.size.width
        label.frame.size.height = rowHeight
        label.text = text
        label.textAlignment = .left
        label.textColor = self.theme.textColor
        label.backgroundColor = self.theme.backgroundColor
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 0


        pview.addSubview(metalView)
        pview.addSubview(label)
        metalView.anchorToEdge(.left, padding: 16, width: metalView.frame.size.width, height: metalView.frame.size.height)
        label.align(.toTheRightCentered, relativeTo: metalView, padding: 16, width: label.frame.size.width, height: label.frame.size.height)

        return pview
    }

    //////////////////////////////////////////
    // MARK: - Tool Banner Touch Handlers
    //////////////////////////////////////////
   
    @objc func cancelDidPress(){
        if self.delegate != nil {
            self.delegate?.editStackDismiss()
        } else {
            log.warning("NIL delegate")
            self.isHidden = true
        }
    }

    
}

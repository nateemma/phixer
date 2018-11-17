//
//  HTMLViewController.swift
//  A 'basic' View Controller to display a supplied HTML-formatted string, or load an HTML app resource
//
//  Created by Philip Price on 10/29/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Neon
import WebKit

class HTMLViewController: UIViewController {
    
    
    var theme = ThemeManager.currentTheme()
    

    private let statusBarOffset : CGFloat = 12.0
    private let bannerHeight : CGFloat = 64.0

    private var bannerView: TitleView! = TitleView()
    private var htmlView: WKWebView! = WKWebView()
    
    private var isLandscape : Bool = false
    private var screenSize : CGRect = CGRect.zero
    private var displayWidth : CGFloat = 0.0
    private var displayHeight : CGFloat = 0.0

    
    /////////////////////////////
    // MARK: - Boilerplate
    /////////////////////////////
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        doInit()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        

        doInit()
        doLayout()
    }
    
    
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if UIDevice.current.orientation.isLandscape{
            log.verbose("### Detected change to: Landscape")
            isLandscape = true
        } else {
            log.verbose("### Detected change to: Portrait")
            isLandscape = false
            
        }
        //TODO: animate and maybe handle before rotation finishes
        self.removeSubviews()
        self.doLayout()
    }
    
    private func removeSubviews(){
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.warning("Received Memory Warning")
        // Dispose of any resources that can be recreated.
    }
    
    
    /////////////////////////////
    // MARK: - public accessors
    /////////////////////////////
    

    public func setTitle(_ title:String){
        bannerView.title = title
    }
    
    public func setText(_ text:String){
        let html = """

        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        body { font: 100%/150% Arial,calibri,helvetica,sans-serif; font-size: 150%; }
        </style>
        </head>
        <body>
        \(text)
        </body>
        </html>
        """
        
        htmlView.loadHTMLString(html, baseURL: nil)
    }

    
    // load the HTML from an asset file in the App Bundle
    // NOTES: - name should be just the 'base' path, not including the extension or any resource ID
    //        - Assumes extension of .html
    //        - contents can be just the text that goes within the <body> section, or full html
    public func loadFile(name: String){
        var base:String
        let ext:String = "html"
        
        if name.contains("."){
            base = URL(fileURLWithPath: name).lastPathComponent
            base = base.components(separatedBy: ".")[0]
        } else {
            base = name
        }
        
        if let filepath = Bundle.main.path(forResource: base, ofType: ext) {
            do {
                let contents = try String(contentsOfFile: filepath)
                // check to see if <html> tag is present. If so, load whole file, otherwise insert in body
                if contents.lowercased().range(of:"<html>") != nil {
                    htmlView.loadHTMLString(contents, baseURL: nil)
                } else {
                    self.setText(contents)
                }
            } catch {
                // contents could not be loaded
                log.error("Error loading file (\(name)): \(error)")
            }
        } else {
            log.error("File not found: \(name)")
        }
    }


    /////////////////////////////
    // MARK: - Initialisation & Layout
    /////////////////////////////
    
    var initDone:Bool = false
    
    
    private func doInit(){
        
        if (!initDone){
            initDone = true
            setTitle("           HTML Viewer         ")
            setText("<p>Hello World</p><p><i>Hello World!</i></p><p><u>Hello World!!</u></p><p><b>Hello World!!!</b></p>")
        }
    }
    
    
    private func doLayout(){
        
        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        
        // NOTE: isLandscape = UIDevice.current.orientation.isLandscape doesn't always work properly, especially in simulator
        isLandscape = (displayWidth > displayHeight)
        
        view.backgroundColor = theme.backgroundColor // default seems to be white
        
        layoutBanner()
        view.addSubview(bannerView)
        
        layoutHTMLView()
        view.addSubview(htmlView)
        
        // layout constraints
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: bannerView.frame.size.height)
        htmlView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: (displayHeight-bannerView.frame.size.height))
    }
    
    
    // layout the banner view, with the Back button, title etc.
    private func layoutBanner(){
        bannerView.frame.size.height = min (bannerHeight,displayHeight * 0.2)
        bannerView.frame.size.width = displayWidth
        bannerView.delegate = self
    }

    private func layoutHTMLView(){
        htmlView.frame.size.height = displayHeight * 0.8
        htmlView.frame.size.width = displayWidth
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
            //log.debug("Not a navigation Controller")
            //suspend()
            dismiss(animated: true, completion:  { })
            return
        }
    }

}



extension HTMLViewController: TitleViewDelegate {
    func backPressed() {
        backDidPress()
    }
}


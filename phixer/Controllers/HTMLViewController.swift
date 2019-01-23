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

class HTMLViewController: CoordinatedController {
    

    private var bannerView: TitleView! = TitleView()
    private var htmlView: WKWebView! = WKWebView()
    
    private var displayWidth : CGFloat = 0.0
    private var displayHeight : CGFloat = 0.0
    
    private static let defaultHelpFile:String = "default"
    
    private var helpFile:String = ""

    
    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////
    
    // return the display title for this Controller
    override public func getTitle() -> String {
        return "Help"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return HTMLViewController.defaultHelpFile
    }
    

    /////////////////////////////
    // MARK: - Boilerplate
    /////////////////////////////
    
    convenience init(){
        self.init(title:"", file:"")
     }
    
    init(title: String, file: String) {
        super.init(nibName:nil, bundle:nil)
        self.title = title
        if !file.isEmpty {
            self.helpFile = file
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // common setup
        self.prepController()


        processFile()
        doLayout()
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
        body { font: 100%/150% Arial,calibri,helvetica,sans-serif; font-size: 80%; \(buildColourString())}
        h1   {color: blue;}
        </style>
        </style>
        </head>
        <body>
        \(text)
        </body>
        </html>
        """
        
        //log.verbose("HTML:\n \(html)")
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
        
        var filepath:String? = ""
        filepath = Bundle.main.path(forResource: base, ofType: ext)
        if filepath == nil {
            log.error("File not found: \(name). Using default (\(HTMLViewController.defaultHelpFile))")
            filepath = Bundle.main.path(forResource: HTMLViewController.defaultHelpFile, ofType: ext)
        }
        
        if filepath != nil {
            do {
                let contents = try String(contentsOfFile: filepath!)
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
            log.error("Could not find file (\(base).\(ext)) or default (\(HTMLViewController.defaultHelpFile).\(ext))")
        }
    }


    /////////////////////////////
    // MARK: - Initialisation & Layout
    /////////////////////////////
    

    private func processFile(){
        //OK, a bit of a hack, but the problem here is that the coordinators don't really know anything about the specifics of this controller, so it's hard to pass parameters
        // Instead, the previous coodinator will have saved the needed info in the sharedInfo map, so we retrieve it from there
        
        if self.helpFile.isEmpty {
            if let file = Coordinator.sharedInfo["helpFile"] {
                self.helpFile = file
            } else {
                self.helpFile = HTMLViewController.defaultHelpFile
            }
        }
        self.loadFile(name:  self.helpFile)
        
    }
    
    
    private func doLayout(){
        
        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        
        view.backgroundColor = theme.backgroundColor // default seems to be white
        
        layoutBanner()
        view.addSubview(bannerView)
        
        layoutHTMLView()
        view.addSubview(htmlView)
        
        // layout constraints
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.statusBarOffset/2.0, otherSize: bannerView.frame.size.height)
        htmlView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: (displayHeight-bannerView.frame.size.height))
    }
    
    
    // layout the banner view, with the Back button, title etc.
    private func layoutBanner(){
        bannerView.frame.size.height = min (UISettings.panelHeight,displayHeight * 0.2)
        bannerView.frame.size.width = displayWidth
        bannerView.delegate = self
    }

    private func layoutHTMLView(){
        htmlView.frame.size.height = displayHeight * 0.8
        htmlView.frame.size.width = displayWidth
    }
    
    // build HTML/CSS Colour commands based upon the current theme
    
    private func buildColourString() -> String {
        var str:String = ""
        
        str = "background-color: \(theme.backgroundColor.hexString) ; color:\(theme.textColor.hexString);"
        
        return str
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



extension HTMLViewController: TitleViewDelegate {
    func backPressed() {
        backDidPress()
    }
    
    func helpPressed() {
        // no help for the help screen!
    }
    
    func menuPressed() {
        // placeholder
    }
}


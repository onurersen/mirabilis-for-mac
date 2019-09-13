//
//  QuickNoteController.swift
//  Mirabilis
//
//  Created by Onur Ersen on 11/08/16.
//  Copyright © 2016 Berat Onur Ersen. All rights reserved.
//

import Cocoa
import ServiceManagement

class QuickNoteViewController: NSViewController , NSWindowDelegate,NSTextViewDelegate,NSSearchFieldDelegate{
   
    @IBOutlet var noteTextView: NSTextView!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet var searchFieldCell: NSSearchFieldCell!
    @IBOutlet var searchExpandButton: NSButton!
    @IBOutlet var autoLaunchCheckbox: NSButton!
    
    let bundleSettings = NSBundle.mainBundle().pathForResource("Settings", ofType: "plist")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noteTextView.arrangeLineNumbers()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        loadQuickNote()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        updateQuickNote()
    }
    
    func loadQuickNote(){
        let dictSettings = NSDictionary(contentsOfFile: bundleSettings!) as? Dictionary<String, AnyObject>
        noteTextView.textStorage!.mutableString.setString("")
        var inString = ""
        let fileName = dictSettings!["storage.file.name"] as! String
        let DocumentDirURL = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
        let fileURL = DocumentDirURL.URLByAppendingPathComponent(fileName)
        do {
            inString = try String(contentsOfURL: fileURL)
        } catch let error as NSError {
            print("Failed reading from URL: \(fileURL), Error: " + error.localizedDescription)
        }
        noteTextView.insertText(inString)
        do {
            try fileURL.setResourceValue(true, forKey: NSURLIsHiddenKey)
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }
    }
    
    override func awakeFromNib() {
        let bundleSettings = NSBundle.mainBundle().pathForResource("Settings", ofType: "plist")
        let dictSettings = NSDictionary(contentsOfFile: bundleSettings!) as? Dictionary<String, AnyObject>
        let fontType = dictSettings!["note.font.type"] as! String
        let fontSize = dictSettings!["note.font.size"] as! CGFloat
        let font = NSFont(name: fontType, size: fontSize)
        let attributes = NSDictionary(object: font!, forKey: NSFontAttributeName)
        noteTextView.typingAttributes = attributes as! [String : AnyObject]
    }
    
    func updateQuickNote() {
        let fileName = ".mirabilis"
        let DocumentDirURL = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        let fileURL = DocumentDirURL.URLByAppendingPathComponent(fileName)
        let outString = (noteTextView.textStorage as NSAttributedString!).string
        do {
            try outString.writeToURL(fileURL, atomically: true, encoding: NSUTF8StringEncoding)
        } catch let error as NSError {
            print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
        }
    }
    
    func exportNotes(filePath: NSURL) {
        var inString = ""
        let fileName = dictSettings!["storage.file.name"] as! String
        let DocumentDirURL = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
        let fileURL = DocumentDirURL.URLByAppendingPathComponent(fileName)
        do {
            inString = try String(contentsOfURL: fileURL)
        } catch let error as NSError {
            print("Failed reading from URL: \(fileURL), Error: " + error.localizedDescription)
        }
        do {
            try inString.writeToFile(filePath.path!, atomically:true, encoding:NSUTF8StringEncoding)
        }catch{
            print("Failed to write to file")
        }
    }

}

extension QuickNoteViewController {
    
    @IBAction func setAutoLaunch(sender: NSButton) {
        let appBundleIdentifier = "com.onurersen.mirabilis"
        let autoLaunch = (autoLaunchCheckbox.state == NSOnState)
        if SMLoginItemSetEnabled(appBundleIdentifier, autoLaunch) {
            if autoLaunch {
                NSLog("Successfully add login item.")
            } else {
                NSLog("Successfully remove login item.")
            }
            
        } else {
            NSLog("Failed to add login item.")
            let alertQuit = NSAlert()
            alertQuit.messageText = "Error"
            alertQuit.informativeText = "Failed to add login item."
            alertQuit.alertStyle = NSAlertStyle.CriticalAlertStyle
            alertQuit.beginSheetModalForWindow(self.view.window!, completionHandler: { (modalResponse) -> Void in
                if modalResponse == NSAlertFirstButtonReturn {
                }
            })
        }
    }
    
    @IBAction func export(sender: NSButton) {
        self.updateQuickNote()
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.closePopover(nil)
        let savePanel = NSSavePanel()
        savePanel.title = "Export your notes to a file"
        savePanel.showsTagField = false
        savePanel.beginWithCompletionHandler { (result: Int) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let exportedFileURL = savePanel.URL
                print(exportedFileURL)
                self.exportNotes(exportedFileURL!)
            }
        }
    }

    @IBAction func quit(sender: NSButton) {
        let dictSettings = NSDictionary(contentsOfFile: bundleSettings!) as? Dictionary<String, AnyObject>
        let alertQuit = NSAlert()
        alertQuit.messageText = "Quit?"
        var image:NSImage!
        image = NSImage(named:"exit.png")
        alertQuit.icon = image
        alertQuit.informativeText = dictSettings!["quit.text"] as! String
        alertQuit.addButtonWithTitle(dictSettings!["quit.yes"] as! String)
        alertQuit.addButtonWithTitle(dictSettings!["quit.no"] as! String)
        alertQuit.alertStyle = NSAlertStyle.WarningAlertStyle
        alertQuit.beginSheetModalForWindow(self.view.window!, completionHandler: { (modalResponse) -> Void in
            if modalResponse == NSAlertFirstButtonReturn {
                self.updateQuickNote()
                NSApplication.sharedApplication().terminate(sender)
            }
        })
    }
    
    @IBAction func about(sender: NSButton) {
        let dictSettings = NSDictionary(contentsOfFile: bundleSettings!) as? Dictionary<String, AnyObject>
        let alertAbout = NSAlert()
        alertAbout.messageText = "About..."
        var image:NSImage!
        image = NSImage(named:"about.png")
        alertAbout.icon = image
        let aboutText = (dictSettings!["about.text"] as! String).stringByReplacingOccurrencesOfString("\\n", withString: "\n")
        alertAbout.informativeText = aboutText
        alertAbout.addButtonWithTitle("Well noted.")
        alertAbout.alertStyle = NSAlertStyle.InformationalAlertStyle
        alertAbout.beginSheetModalForWindow(self.view.window!, completionHandler: { (modalResponse) -> Void in
            if modalResponse == NSAlertFirstButtonReturn {}
        })
    }
    
    @IBAction func controlTextDidChange_Enter(obj: NSSearchField!) {
        updateQuickNote()
        let dictSettings = NSDictionary(contentsOfFile: bundleSettings!) as? Dictionary<String, AnyObject>
        if (!obj.stringValue.isEmpty) {
            print("Searched: \(obj.stringValue)")
            let fileName = dictSettings!["note.storage.filename"] as! String
            let DocumentDirURL = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
            let maxResultCount = dictSettings!["search.result.maximum"] as! NSInteger
            let maxResultCharByLine = dictSettings!["search.result.maximum.line"] as! NSInteger
            let fileURL = DocumentDirURL.URLByAppendingPathComponent(fileName)
            
            if let aStreamReader = StreamReader(path: fileURL.path!) {
                defer {
                    aStreamReader.close()
                }
                var lineCount = 0
                var foundLineNumbers = [Int]()
                var foundLines = [String]()
                while let line = aStreamReader.nextLine() {
                    lineCount++
                    if line.rangeOfString(obj.stringValue) != nil{
                        if(line.characters.count > maxResultCharByLine){
                            let index: String.Index = line.startIndex.advancedBy(maxResultCharByLine)
                            foundLines.append(line.substringToIndex(index) + "...")
                        }else{
                            foundLines.append(line)
                        }
                        foundLineNumbers.append(lineCount)
                    }
                }
                
                var searchResultLines = ""
                var resultCount = foundLineNumbers.count
                if(resultCount > 0){
                    let alertSearch = NSAlert()
                    if  resultCount >= maxResultCount{
                        resultCount = maxResultCount
                    }
                    for var i = 0; i < resultCount; i++ {
                        searchResultLines = searchResultLines + "Line \(foundLineNumbers[i]) : " + foundLines[i] +  "\n"
                    }
                    if  resultCount >= maxResultCount{
                        alertSearch.informativeText = "and your search returned more than \(maxResultCount) result(s).\n\nHint: Why not be more specific?\n\n" + "\"\(obj.stringValue)\"" + " found at following line(s) :\n\n" + searchResultLines;
                    }else{
                        alertSearch.informativeText = "and your search returned \(resultCount) result(s).\n\n" + "\"\(obj.stringValue)\"" + " found at following line(s) :\n\n" + searchResultLines;
                    }
                    var image:NSImage!
                    image = NSImage(named:"search.png")
                    alertSearch.icon = image
                    alertSearch.messageText="You searched for \"\(obj.stringValue)\""
                    alertSearch.addButtonWithTitle("OK")
                    alertSearch.alertStyle = NSAlertStyle.InformationalAlertStyle
                    alertSearch.beginSheetModalForWindow(self.view.window!, completionHandler: { (modalResponse) -> Void in
                        if modalResponse == NSAlertFirstButtonReturn {}
                    })
                }
            }
            
        }
    }
    
}
//
//  LineNumberView.swift
//  Mirabilis
//
//  Created by Onur Ersen on 11/08/16.
//  Copyright © 2016 Berat Onur Ersen. All rights reserved.
//
import AppKit
import Foundation
import ObjectiveC

var LineNumberKey: UInt8 = 0
var bundleSettings = NSBundle.mainBundle().pathForResource("Settings", ofType: "plist")
let dictSettings = NSDictionary(contentsOfFile: bundleSettings!) as? Dictionary<String, AnyObject>

extension NSTextView {
    
	var lineNumberView:LineNumberView {
		get {
			return objc_getAssociatedObject(self, &LineNumberKey) as! LineNumberView
		}
		set {
			objc_setAssociatedObject(self, &LineNumberKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
	
	func arrangeLineNumbers() {
    
        let rulerFontType = dictSettings!["ruler.font.type"] as! String
        let rulerFontSize = dictSettings!["ruler.font.size"] as! CGFloat
        
        postsFrameChangedNotifications = true
        font = NSFont(name: rulerFontType, size: rulerFontSize)
		if let scrollView = enclosingScrollView {
			lineNumberView = LineNumberView(textView: self)
			scrollView.verticalRulerView = lineNumberView
			scrollView.hasVerticalRuler = true
			scrollView.rulersVisible = true
		}
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "frameDidChange:", name: NSViewFrameDidChangeNotification, object: self)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "textDidChange:", name: NSTextDidChangeNotification, object: self)
	}
	
	func frameDidChange(notification: NSNotification) {
		lineNumberView.needsDisplay = true
	}
	
	func textDidChange(notification: NSNotification) {
		lineNumberView.needsDisplay = true
	}
}

class LineNumberView: NSRulerView {
	var font: NSFont! {
		didSet {
			self.needsDisplay = true
		}
	}
	init(textView: NSTextView) {
		super.init(scrollView: textView.enclosingScrollView!, orientation: NSRulerOrientation.VerticalRuler)
		self.font = textView.font ?? NSFont.systemFontOfSize(NSFont.smallSystemFontSize())
		self.clientView = textView
		self.ruleThickness = dictSettings!["ruler.thickness"] as! CGFloat
	}
	required init?(coder: NSCoder) {
	    fatalError("Not implemented.")
	}
	override func drawHashMarksAndLabelsInRect(rect: NSRect) {
		if let textView = self.clientView as? NSTextView {
			if let layoutManager = textView.layoutManager {
				let relativePoint = self.convertPoint(NSZeroPoint, fromView: textView)
				let lineNumberAttributes = [NSFontAttributeName: textView.font!, NSForegroundColorAttributeName: NSColor.grayColor()]
				let drawLineNumber = { (lineNumberString:String, y:CGFloat) -> Void in
					let attString = NSAttributedString(string: lineNumberString, attributes: lineNumberAttributes)
					let x = dictSettings!["ruler.number.align"] as! CGFloat - attString.size().width
					attString.drawAtPoint(NSPoint(x: x, y: relativePoint.y + y))
				}
				let visibleGlyphRange = layoutManager.glyphRangeForBoundingRect(textView.visibleRect, inTextContainer: textView.textContainer!)
				let firstVisibleGlyphCharacterIndex = layoutManager.characterIndexForGlyphAtIndex(visibleGlyphRange.location)
				let newLineRegex = try! NSRegularExpression(pattern: "\n", options: [])
				var lineNumber = newLineRegex.numberOfMatchesInString(textView.string!, options: [], range: NSMakeRange(0, firstVisibleGlyphCharacterIndex)) + 1
				var glyphIndexForStringLine = visibleGlyphRange.location

				while glyphIndexForStringLine < NSMaxRange(visibleGlyphRange) {
					let characterRangeForStringLine = (textView.string! as NSString).lineRangeForRange(
						NSMakeRange( layoutManager.characterIndexForGlyphAtIndex(glyphIndexForStringLine), 0 )
					)
					let glyphRangeForStringLine = layoutManager.glyphRangeForCharacterRange(characterRangeForStringLine, actualCharacterRange: nil)
					var glyphIndexForGlyphLine = glyphIndexForStringLine
					var glyphLineCount = 0
					while ( glyphIndexForGlyphLine < NSMaxRange(glyphRangeForStringLine) ) {
						var effectiveRange = NSMakeRange(0, 0)
						let lineRect = layoutManager.lineFragmentRectForGlyphAtIndex(glyphIndexForGlyphLine, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
						if glyphLineCount > 0 {
							drawLineNumber("...", lineRect.minY)
						} else {
                            if(lineNumber > dictSettings!["note.maximum.line"] as! NSInteger){
                                drawLineNumber("...", lineRect.minY)
                            }else{
                                drawLineNumber("\(lineNumber)", lineRect.minY)
                            }
						}
						glyphLineCount++
						glyphIndexForGlyphLine = NSMaxRange(effectiveRange)
					}
					glyphIndexForStringLine = NSMaxRange(glyphRangeForStringLine)
					lineNumber++
				}
				if layoutManager.extraLineFragmentTextContainer != nil {
					drawLineNumber("\(lineNumber)", layoutManager.extraLineFragmentRect.minY)
				}
			}
		}
		
	}
}

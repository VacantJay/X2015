//
//  RichFormatTextViewShortcutHandler.swift
//  X2015
//
//  Created by Hang Zhang on 2/17/16.
//  Copyright © 2016 Zhang Hang. All rights reserved.
//

import UIKit
import AVFoundation

protocol RichFormatTextViewShortcutHandlerDelegate: class {

	func richFormatTextViewShortcutHandlerHandlerDidModifyText(
		handler: RichFormatTextViewShortcutHandler) -> Void

	func richFormatTextViewShortcutHandlerHandlerWillBeginEditing(
		handler: RichFormatTextViewShortcutHandler) -> Void

	func richFormatTextViewShortcutHandlerHandlerDidEndEditing(
		handler: RichFormatTextViewShortcutHandler) -> Void

}

// for test
protocol SelectionRangeProvider: class {

	var selectedRange: NSRange { get set }

}

typealias TextProvider = NSMutableAttributedString

extension UITextView: SelectionRangeProvider {}


final class RichFormatTextViewShortcutHandler {

	private(set) weak var rangeProviderCache: SelectionRangeProvider?

	private(set) weak var textProviderCache: TextProvider?

	weak var delegate: RichFormatTextViewShortcutHandlerDelegate?

	var textProvider: TextProvider {
		return textProviderCache!
	}

	var text: String {
		return textProvider.string
	}

	var selectedRange: NSRange {
		get {
			return rangeProviderCache!.selectedRange
		}
		set {
			rangeProviderCache!.selectedRange = newValue
		}
	}

	init(rangeProvider: SelectionRangeProvider, textProvider: TextProvider) {
		self.textProviderCache = textProvider
		self.rangeProviderCache = rangeProvider
	}

	init(textView: UITextView, textStorage: NSTextStorage) {
		self.textProviderCache = textStorage
		self.rangeProviderCache = textView
	}

}

extension RichFormatTextViewShortcutHandler {

	func beginEditing() {
		delegate?.richFormatTextViewShortcutHandlerHandlerWillBeginEditing(self)
	}

	func endEditing() {
		delegate?.richFormatTextViewShortcutHandlerHandlerDidEndEditing(self)
	}
}

extension RichFormatTextView {

	struct Regex {
		private let regularExpression: NSRegularExpression!

		private init(
			pattern: String,
			options: NSRegularExpressionOptions = NSRegularExpressionOptions(rawValue: 0)) {
				var error: NSError?
				let re: NSRegularExpression?
				do {
					re = try NSRegularExpression(pattern: pattern,
						options: options)
				} catch let error1 as NSError {
					error = error1
					re = nil
				}

				// If re is nil, it means NSRegularExpression didn't like
				// the pattern we gave it.  All regex patterns used by Markdown
				// should be valid, so this probably means that a pattern
				// valid for .NET Regex is not valid for NSRegularExpression.
				if re == nil {
					if let error = error {
						print("Regular expression error: \(error.userInfo)")
					}
					assert(re != nil)
				}

				self.regularExpression = re
		}

		private func matches(input: String, range: NSRange,
			completion: (result: NSTextCheckingResult?) -> Void) {
				let s = input as NSString
				let options = NSMatchingOptions(rawValue: 0)
				let range = NSMakeRange(0, s.length)
				regularExpression.enumerateMatchesInString(s as String,
					options: options,
					range: range,
					usingBlock: { (result, flags, stop) -> Void in
						completion(result: result)
				})
		}
	}

}

extension RichFormatTextViewShortcutHandler {

	// Move cursor to next character
	func moveCursorLeft() {

		let av = AVSpeechSynthesizer()
		let speaker = AVSpeechUtterance(string: textProvider.string)
		av.speakUtterance(speaker)

		beginEditing()
		selectedRange = NSMakeRange(max(0, selectedRange.location - 1), 0)
		delegate?.richFormatTextViewShortcutHandlerHandlerDidModifyText(self)
		endEditing()
	}

	// Move cursor to previous character
	func moveCursorRight() {
		beginEditing()
		let stringLength = text.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
		selectedRange = NSMakeRange(min(stringLength, selectedRange.location + 1 + selectedRange.length), 0)
		delegate?.richFormatTextViewShortcutHandlerHandlerDidModifyText(self)
		endEditing()
	}

	/**
	Insert `#` or `# ` to the begining based on the content of line where cursor is
	*/
	func addHeaderSymbolIfNeeded() {
		beginEditing()
		let string = text
		let paragraphRange = string.firstParagraphRangeForNSRange(selectedRange)
		let paragraphString = string.firstParagraphForNSRange(selectedRange)
		if paragraphString.hasPrefix("# ") {
			let stringToInsert = NSAttributedString(string: "#")
			textProvider.insertAttributedString(stringToInsert,
				atIndex: string.startIndex.distanceTo(paragraphRange.startIndex))
			selectedRange.location += 1
		} else {
			let stringToInsert = NSAttributedString(string: "# ")
			textProvider.insertAttributedString(stringToInsert,
				atIndex: string.startIndex.distanceTo(paragraphRange.startIndex))
			selectedRange.location += 2
		}
		delegate?.richFormatTextViewShortcutHandlerHandlerDidModifyText(self)
		endEditing()
	}

	/**
	Insert `\t` to the position where cursor is
	*/
	func addIndentSymbol() {
		beginEditing()
		let stringToInsert = NSAttributedString(string: "\t")
		textProvider.insertAttributedString(stringToInsert, atIndex: selectedRange.location)
		selectedRange = NSMakeRange(selectedRange.location + 1, 0)
		delegate?.richFormatTextViewShortcutHandlerHandlerDidModifyText(self)
		endEditing()
	}

	/**
	Insert `> ` to the begining of the line which cursor is
	*/
	func addQuoteSymbol() {
		beginEditing()
		let stringToInsert = NSAttributedString(string: "> ")
		let paragraphRange = (textProvider.string as NSString).paragraphRangeForRange(selectedRange)
		textProvider.insertAttributedString(stringToInsert, atIndex: paragraphRange.location)
		selectedRange = NSMakeRange(
			selectedRange.location + stringToInsert.string.characters.count,
			0)
		delegate?.richFormatTextViewShortcutHandlerHandlerDidModifyText(self)
		endEditing()
	}

	/**
	Insert `*` to the position where cursor is
	*/
	func addEmphSymbol() {
		beginEditing()
		let stringToInsert = NSAttributedString(string: "*")
		textProvider.insertAttributedString(stringToInsert, atIndex: selectedRange.location)
		selectedRange = NSMakeRange(selectedRange.location + 1, 0)
		delegate?.richFormatTextViewShortcutHandlerHandlerDidModifyText(self)
		endEditing()
	}

	/**
	Insert link symbol to the position where cursor is
	*/
	func addLinkSymbol() {
		beginEditing()
		let titleString = NSLocalizedString("Title", comment: "")
		let linkString = NSLocalizedString("Link", comment: "")
		let stringToInsert = NSAttributedString(string: "[\(titleString)](\(linkString))")
		textProvider.insertAttributedString(stringToInsert, atIndex: selectedRange.location)
		selectedRange = NSMakeRange(
			selectedRange.location + 1,
			titleString.characters.count)
		delegate?.richFormatTextViewShortcutHandlerHandlerDidModifyText(self)
		endEditing()
	}

	/**
	Make text bold based on current selection
	*/
	func makeTextBold() {
		beginEditing()
		let string = text as NSString

		if selectedRange.length > 0 {
			let selectedString = string.substringWithRange(selectedRange)
			let stringToInsert = NSAttributedString(string: "**\(selectedString)**")
			textProvider.replaceCharactersInRange(selectedRange, withAttributedString: stringToInsert)
			selectedRange.location += 2
		} else {
			let stringToInsert = NSAttributedString(string: "****")
			textProvider.insertAttributedString(stringToInsert, atIndex: selectedRange.location)
			selectedRange.location += 2
		}
		delegate?.richFormatTextViewShortcutHandlerHandlerDidModifyText(self)
		endEditing()
	}

	/**
	Make text bold based on current selection
	*/
	func makeTextItalic() {
		beginEditing()
		let string = text as NSString

		if selectedRange.length > 0 {
			let selectedString = string.substringWithRange(selectedRange)
			let stringToInsert = NSAttributedString(string: "*\(selectedString)*")
			textProvider.replaceCharactersInRange(selectedRange, withAttributedString: stringToInsert)
			selectedRange.location += 1
		} else {
			let stringToInsert = NSAttributedString(string: "**")
			textProvider.insertAttributedString(stringToInsert, atIndex: selectedRange.location)
			selectedRange.location += 1
		}
		delegate?.richFormatTextViewShortcutHandlerHandlerDidModifyText(self)
		endEditing()
	}

	/**
	Add or remove list symbol based on the content of line where cursor is
	*/
	func makeTextList() {
		beginEditing()
		let string = text as NSString

		let paragraphRange = string.paragraphRangeForRange(selectedRange)
		let paragraphString = string.substringWithRange(paragraphRange)
		if paragraphString.hasPrefix("- ") {
			textProvider.replaceCharactersInRange(NSMakeRange(paragraphRange.location, 2), withString: "")
			selectedRange.location -= 2
		} else {
			let stringToInsert = NSAttributedString(string: "- ")
			textProvider.insertAttributedString(stringToInsert, atIndex: paragraphRange.location)
			selectedRange.location += 2
		}
		delegate?.richFormatTextViewShortcutHandlerHandlerDidModifyText(self)
		endEditing()
	}

}

// MARK: Auto completion
extension RichFormatTextViewShortcutHandler {

	/**
	Provides auto completion for markdown list

	- parameter editedRange: editedRange
	- parameter text:        text

	- returns: return ture if this method has changed anyting
	*/
	func processListSymbolIfNeeded(editedRange: NSRange, replacementText text: String) -> Bool {

		// Puts an extra white space after `-` if
		if text == "-" && editedRange.length == 0 {
			let (_, paragraphRange) = textProvider.string.firstParagraphResult(editedRange)
			let prargraphStratLocation = textProvider.string.startIndex.distanceTo(paragraphRange.startIndex)
			if editedRange.location != prargraphStratLocation { return false }
			// insert a space
			textProvider.replaceCharactersInRange(NSMakeRange(editedRange.location, 0), withString: "- ")
			selectedRange = NSMakeRange(editedRange.location + 2, 0)
			return true
		}

		if text == "\n" {
			let (paragraphString, paragraphRange) = textProvider.string.firstParagraphResult(editedRange)

			let listPrefix = "- "
			// not a list
			if !paragraphString.hasPrefix(listPrefix) { return false }

			// skip if last paragraph has no content and also removes list symbol from last paragraph
			if paragraphString == listPrefix {
				let note = textProvider.string
				textProvider.replaceCharactersInRange(
					NSMakeRange(note.startIndex.distanceTo(paragraphRange.startIndex), 2), withString: "\n")
				selectedRange = NSMakeRange(note.startIndex.distanceTo(paragraphRange.startIndex) + 1, 0)
				return true
			}

			// Puts `- ` to the new line
			let stringToInsert = NSAttributedString(string: "\n- ")
			textProvider.insertAttributedString(stringToInsert, atIndex: editedRange.location)
			selectedRange.location += 3
			return true
		}

		return false
	}

}

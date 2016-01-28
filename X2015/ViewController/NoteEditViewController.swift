//
//  NoteEditViewController.swift
//  X2015
//
//  Created by Hang Zhang on 12/31/15.
//  Copyright © 2015 Zhang Hang. All rights reserved.
//

import UIKit
import CoreData

protocol NoteEditViewControllerDelegate: class {

	func noteEditViewController(
		controller: NoteEditViewController,
		didTapDeleteNoteShortCutWithNoteObjectID noteObjectID: NSManagedObjectID)

}

final class NoteEditViewController: ThemeAdaptableViewController {


	struct Storyboard {
		static let identifier = "NoteEditViewController"

		static let SegueIdentifierCreate = "CreateNoteSegueIdentifier"
		static let SegueIdentifierEdit = "EditNoteSegueIdentifier"
		static let SegueIdentifierEmpty = "EmptyNoteSegueIdentifier"
	}

	enum Mode {

		case Create(NSManagedObjectID, NSManagedObjectContext)
		case Edit(NSManagedObjectID, NSManagedObjectContext)
		case Empty

	}

	var noteActionMode: Mode = .Empty {

		didSet {
			switch noteActionMode {
			case let .Create(managedObjectID, managedObjectContext):
				noteUpdater = NoteUpdater(noteObjectID: managedObjectID,
					managedObjectContext: managedObjectContext)
				break
			case let .Edit(managedObjectID, managedObjectContext):
				noteUpdater = NoteUpdater(noteObjectID: managedObjectID,
					managedObjectContext: managedObjectContext)
				break
			case .Empty:
				break
			}
			if isViewLoaded() {
				configureInterface(noteActionMode)
			}
		}

	}

	private var noteUpdater: NoteUpdater?

	weak var delegate: NoteEditViewControllerDelegate?

	@IBOutlet private weak var textView: UITextView!

	private var emptyWelcomeView: EmptyNoteWelcomeView?

	private var keyboardNotificationObserver: KeyboardNotificationObserver!

	override func viewDidLoad() {
		super.viewDidLoad()

		keyboardNotificationObserver = KeyboardNotificationObserver(
			viewControllerView: view,
			keyboardOffsetChangeHandler: { [unowned self] (newKeyboardOffset) -> Void in
				var newContentInsect = self.textView.contentInset
				newContentInsect.bottom = newKeyboardOffset
				self.textView.contentInset = newContentInsect
			})

		configureInterface(noteActionMode)
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		keyboardNotificationObserver.startMonitor()

		switch noteActionMode {
		case .Create:
			textView.becomeFirstResponder()
		default:
			break
		}
	}

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		keyboardNotificationObserver.stopMonitor()
	}

	// Preview action items.
	lazy var previewActions: [UIPreviewActionItem] = {
		let deleteAction = UIPreviewAction(
			title: NSLocalizedString("Delete", comment: ""),
			style: .Destructive,
			handler: { [unowned self] (_, _) -> Void in
				self.delegate?.noteEditViewController(self,
					didTapDeleteNoteShortCutWithNoteObjectID: self.noteUpdater!.noteObjectID)
			})
		return [deleteAction]
	}()

	// MARK: Preview actions
	override func previewActionItems() -> [UIPreviewActionItem] {
		return previewActions
	}

	// MARK : Theme
	override func updateThemeInterface(theme: Theme) {
		super.updateThemeInterface(theme)
		textView.configureTheme(theme)
		emptyWelcomeView?.configureTheme(theme)
	}
}

extension NoteEditViewController {

	var noteContent: String {
		return textView.text
	}

	var noteTitle: String? {
		return noteContent.lineWithContent(0)
	}

}

extension NoteEditViewController: UITextViewDelegate {

	func updateViewControllerTitleIfNesscarry() {
		if noteTitle != title {
			title = noteTitle
		}
	}

	func textViewDidChange(textView: UITextView) {
		updateViewControllerTitleIfNesscarry()
		noteUpdater!.updateNote(textView.text)
	}

}

extension NoteEditViewController {

	private func configureInterface(mode: Mode) {
		switch noteActionMode {
		case .Empty:
			textView.hidden = true
			emptyWelcomeView = EmptyNoteWelcomeView.instantiateFromNib()
			guard let emptyView = emptyWelcomeView else {
				fatalError()
			}
			emptyView.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(emptyView)
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[welcomeView]-0-|",
				options: .DirectionLeadingToTrailing,
				metrics: nil,
				views: ["welcomeView": emptyView]))
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[welcomeView]-0-|",
				options: .DirectionLeadingToTrailing,
				metrics: nil,
				views: ["welcomeView": emptyView]))
			view.bringSubviewToFront(emptyView)
			break
		case .Edit(_, _):
			emptyWelcomeView?.removeFromSuperview()
			textView.hidden = false
			textView.text = noteUpdater!.noteContent
			break
		case .Create(_):
			emptyWelcomeView?.removeFromSuperview()
			textView.hidden = false
			textView.text = ""
			break
		}
		updateViewControllerTitleIfNesscarry()
	}

}

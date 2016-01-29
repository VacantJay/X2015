//
//  NoteUpdater.swift
//  X2015
//
//  Created by Hang Zhang on 1/26/16.
//  Copyright © 2016 Zhang Hang. All rights reserved.
//

import CoreData

class NoteUpdater {

	let noteObjectID: NSManagedObjectID
	let managedObjectContext: NSManagedObjectContext

	private var note: Note?

	init?(noteObjectID: NSManagedObjectID, managedObjectContext: NSManagedObjectContext) {
		self.noteObjectID = noteObjectID
		self.managedObjectContext = managedObjectContext

		guard let note = managedObjectContext.objectWithID(noteObjectID)
			as? Note else {
				return nil
		}
		self.note = note
	}

	deinit {
		managedObjectContext.saveOrRollback()
	}

}

extension NoteUpdater {

	var noteContent: String? {
		return note!.content
	}

}

extension NoteUpdater {

	func updateNote(content: String) {
		if note!.hasChange(content) {
			note!.update(content)
			// inform delegate
		}
	}

}
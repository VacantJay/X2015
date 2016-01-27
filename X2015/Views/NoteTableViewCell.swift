//
//  NoteTableViewCell.swift
//  X2015
//
//  Created by Hang Zhang on 1/21/16.
//  Copyright © 2016 Zhang Hang. All rights reserved.
//

import UIKit

final class NoteTableViewCell: UITableViewCell {

	static var nibName: String {
		return "NoteTableViewCell"
	}

	func configure(note: Note) {
		textLabel!.text = note.title
		detailTextLabel!.text = note.preview
	}

}

extension NoteTableViewCell: ReusableCell {}

extension NoteTableViewCell: ThemeAdaptable {

	func configureTheme(theme: Theme) {
		backgroundColor = UIColor.clearColor()
		switch theme {
		case .Bright:
			textLabel?.textColor = UIColor.bright_MainTextColor()
			detailTextLabel?.textColor = UIColor.bright_SubTextColor()
			selectionStyle = .Gray
			selectedBackgroundView = nil
		case .Dark:
			selectionStyle = .Default
			textLabel?.textColor = UIColor.dark_MainTextColor()
			detailTextLabel?.textColor = UIColor.dark_SubTextColor()
			selectedBackgroundView = UIView()
			selectedBackgroundView!.backgroundColor = UIColor.dark_tableViewCellBackgroundColor()
		}
	}

}

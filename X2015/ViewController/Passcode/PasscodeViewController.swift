//
//  PasscodeViewController.swift
//  X2015
//
//  Created by Hang Zhang on 1/21/16.
//  Copyright © 2016 Zhang Hang. All rights reserved.
//

import UIKit

final class PasscodeViewController: ThemeAdaptableViewController {

	var authSuccessHandler: ( () -> Void )?
	var authFailedHandler: ( () -> Void )?

	func performTouchIDAuth() {
		assert(TouchIDHelper.hasTouchID)
		TouchIDHelper.auth(
			NSLocalizedString("Use Touch ID to Unlock", comment: ""),
			successHandler: { [unowned self] () -> Void in
				self.authSuccessHandler?()
			}) { [unowned self] (errorMessage) -> Void in
				self.authFailedHandler?()
		}
	}

	override func updateThemeInterface(theme: Theme, animated: Bool) {
		switch theme {
		case .Default:
			view.backgroundColor = UIColor.x2015_BlueColor()
		case .Night:
			view.backgroundColor = UIColor.night_ViewControllerBackgroundColor()
		}
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}

}

extension PasscodeViewController: SotyboardCreatable {

	static var storyboardName: String {
		return "Main"
	}

	static var viewControllerIdentifier: String {
		return "PasscodeViewController"
	}

}

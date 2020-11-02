//
//  AppDelegate.swift
//  DSFToggleButton_Debugger
//
//  Created by Darren Ford on 3/3/20.
//  Copyright © 2020 Darren Ford. All rights reserved.
//

import Cocoa

import DSFToggleButton

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	@IBOutlet var window: NSWindow!
	@IBOutlet var bigButton: DSFToggleButton!
	@IBOutlet var bigButtonColorWell: NSColorWell!

	@IBOutlet var toggleAppearance: NSButton!

	var isDark: Bool {
		if #available(OSX 10.14, *) {
			return NSApp.appearance == NSAppearance(named: .darkAqua) ||
				NSApp.appearance == NSAppearance(named: .accessibilityHighContrastDarkAqua)
		} else {
			return false
		}
	}

	func applicationDidFinishLaunching(_: Notification) {
		// Insert code here to initialize your application
		bigButtonColorWell.color = self.bigButton.color

		if #available(OSX 10.14, *) {
			self.toggleAppearance.isEnabled = true
			let ap = NSApp.effectiveAppearance
			if ap.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
				toggleAppearance.state = .on
			}
		} else {
			self.toggleAppearance.isEnabled = false
		}

		self.bigButton.stateChangeBlock = { button in
			Swift.print("Toggled! State is now \(button.state)")
		}

		NSColorPanel.shared.showsAlpha = true
	}

	func applicationWillTerminate(_: Notification) {
		// Insert code here to tear down your application
	}

	@IBAction func primaryPress(_ sender: DSFToggleButton) {
		Swift.print("Primary Press! State is now \(sender.state)")
	}

	@IBAction func showLabelsToggle(_ sender: NSButton) {
		self.bigButton.showLabels = sender.state == .on
	}

	@IBAction func colorDidChange(_ sender: NSColorWell) {
		self.bigButton.color = sender.color
	}

	@IBAction func enableDisable(_ sender: NSButton) {
		self.bigButton.isEnabled = sender.state == .off
	}

	@IBAction func toggleAnimations(_ sender: NSButton) {
		self.bigButton.animated = sender.state == .on
	}

	@IBAction func toggleAppearance(_ sender: NSButton) {
		if #available(OSX 10.14, *) {
			NSApp.appearance =
				(sender.state == .on) ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
		}
	}

	@IBAction func toggleHideColorWhenInactive(_ sender: NSButton) {
		self.bigButton.removeColorWhenContainingWindowNotFocussed = (sender.state == .on)
	}

	@IBAction func toggleHighContrast(_ sender: NSButton) {
		self.bigButton.highContrast = sender.state == .on
	}

	@IBAction func toggleButton(_: Any) {
		self.bigButton.toggle()
	}
}

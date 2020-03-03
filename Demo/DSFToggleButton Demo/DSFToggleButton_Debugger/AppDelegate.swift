//
//  AppDelegate.swift
//  DSFToggleButton_Debugger
//
//  Created by Darren Ford on 3/3/20.
//  Copyright © 2020 Darren Ford. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var window: NSWindow!
	@IBOutlet weak var bigButton: DSFToggleButton!
	@IBOutlet weak var bigButtonColorWell: NSColorWell!

	var isDark: Bool {
		if #available(OSX 10.14, *) {
			return NSApp.appearance == NSAppearance(named: .darkAqua) ||
				NSApp.appearance == NSAppearance(named: .accessibilityHighContrastDarkAqua)
		} else {
			return false
		}
	}

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		bigButtonColorWell.color = self.bigButton.color

		self.bigButton.stateChangeBlock = { (button) in
			Swift.print("Toggled! State is now \(button.state)")
		}

		NSColorPanel.shared.showsAlpha = true
	}

	func applicationWillTerminate(_ aNotification: Notification) {
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
	@IBAction func toggleHighContrast(_ sender: NSButton) {
		self.bigButton.highContrast = sender.state == .on
	}

	@IBAction func toggleButton(_ sender: Any) {
		self.bigButton.toggle()
	}


}


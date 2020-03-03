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
		return NSApp.appearance == NSAppearance(named: .darkAqua) ||
			NSApp.appearance == NSAppearance(named: .accessibilityHighContrastDarkAqua)
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
		NSApp.appearance =
			(sender.state == .on) ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
	}
	@IBAction func toggleHighContrast(_ sender: NSButton) {
		self.bigButton.highContrast = sender.state == .on
	}

	@IBAction func toggleButton(_ sender: Any) {
		self.bigButton.toggle()
	}


}


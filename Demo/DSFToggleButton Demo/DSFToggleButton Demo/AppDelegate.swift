//
//  AppDelegate.swift
//  DSFToggleButton Demo
//
//  Created by Darren Ford on 17/2/20.
//  Copyright © 2020 Darren Ford. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var window: NSWindow!


	@IBOutlet weak var allButton: DSFToggleButton!
	@IBOutlet weak var redButton: DSFToggleButton!
	@IBOutlet weak var greenButton: DSFToggleButton!
	@IBOutlet weak var blueButton: DSFToggleButton!
	@IBOutlet weak var yellowButton: DSFToggleButton!

	@IBAction func toggle(_ sender: DSFToggleButton) {
		self.redButton.toggle()
		self.greenButton.toggle()
		self.blueButton.toggle()
		self.yellowButton.toggle()
	}

	@IBAction func allButtonChanged(_ sender: DSFToggleButton) {
		self.redButton.state = sender.state
		self.greenButton.state = sender.state
		self.blueButton.state = sender.state
		self.yellowButton.state = sender.state
	}


	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}


}


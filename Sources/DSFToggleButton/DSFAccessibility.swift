//
//  DSFAccessibility.swift
//
//  Created by Darren Ford on 17/2/20.
//  Copyright © 2020 Darren Ford. All rights reserved.
//
//	MIT License
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.

import Cocoa

@objc class DSFAccessibility: NSObject {

	/// Returns the shared DSFAccessibility instance using the default notification center
	public static var shared = DSFAccessibility()

	/// Listen to changes in display accessibility
	///
	/// You may listen for `DSFAccessibilityDidChange` to be notified when the user's accessibility display options change
	@objc(DSFAccessibilityDidChange) static let DidChange = Notification.Name("DSFAccessibilityDidChange")

	private let notificationCenter: NotificationCenter

	/// - Parameter notificationCenter: The notification center to receive change notifications through
	init(notificationCenter: NotificationCenter = NotificationCenter.default) {
		self.notificationCenter = notificationCenter
		super.init()
		self.setupObserver()
	}

	deinit {
		NSWorkspace.shared.notificationCenter.removeObserver(self)
	}
}

private extension DSFAccessibility {
	func setupObserver() {
		NSWorkspace.shared.notificationCenter.addObserver(
			self, selector: #selector(accessibilityDidChange(_:)),
			name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil)
	}

	@objc func accessibilityDidChange(_ notification: Notification) {
		self.notificationCenter.post(name: DSFAccessibility.DidChange, object: self)
	}
}

extension DSFAccessibility {

	/// Get the current accessibility display option for high-contrast UI.  If this is true, UI should be presented with high contrast such as utilizing a less subtle color palette or bolder lines.
	///
	/// You may listen for `DSFAccessibility.DidChange` to be notified when this changes.
	///
	/// See: `NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast`.
	var shouldIncreaseContrast: Bool {
		if #available(OSX 10.10, *) {
			return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
		}
		else {
			return false
		}
	}

	/// Get the current accessibility display option for differentiate without color. If this is true, UI should not convey information using color alone and instead should use shapes or glyphs to convey information.
	///
	/// You may listen for `DSFAccessibility.DidChange` to be notified when this changes.
	///
	/// See: `NSWorkspace.shared.accessibilityDisplayShouldDifferentiateWithoutColor`.
	var differentiateWithoutColor: Bool {
		if #available(OSX 10.10, *) {
			return NSWorkspace.shared.accessibilityDisplayShouldDifferentiateWithoutColor
		}
		else {
			return false
		}
	}

	/// Get the current accessibility display option for reduce motion. If this property's value is true, UI should avoid large animations, especially those that simulate the third dimension.
	///
	/// You may listen for `DSFAccessibility.DidChange` to be notified when this changes.
	///
	/// See: `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`.
	var reduceMotion: Bool {
		if #available(OSX 10.12, *) {
			return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
		} else {
			// Fallback on earlier versions
			return false
		}
	}

	/// Get the current accessibility display option for reduce transparency. If this property's value is true, UI (mainly window) backgrounds should not be semi-transparent; they should be opaque.
	///
	/// You may listen for `DSFAccessibility.DidChange` to be notified when this changes.
	///
	/// See: `NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency`
	var reduceTransparency: Bool {
		if #available(OSX 10.10, *) {
			return NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
		}
		else {
			return false
		}
	}


	/// Get the current accessibility display option for invert colors. If this property's value is true then the display will be inverted. In these cases it may be needed for UI drawing to be adjusted to in order to display optimally when inverted.
	///
	/// You may listen for `DSFAccessibility.DidChange` to be notified when this changes.
	///
	/// See: `NSWorkspace.shared.accessibilityDisplayShouldInvertColors`
	var shouldInvertColors: Bool {
		if #available(OSX 10.12, *) {
			return NSWorkspace.shared.accessibilityDisplayShouldInvertColors
		}
		else {
			return false
		}
	}
}

//
// DSFToggleButton+SwiftUI.swift
//
// Copyright © 2023 Darren Ford. All rights reserved.
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

// Only works for SwiftUI on macOS
#if canImport(SwiftUI) && os(macOS)

import SwiftUI

@available(macOS 11, *)
public extension DSFToggleButton {
	struct SwiftUI {
		let controlColor: CGColor

		/// The current state of the button
		let state: Binding<NSControl.StateValue>

		/// Enable or disable the control
		let isEnabled: Bool

		/// Called when the user interacts with the control
		let action: ((NSControl.StateValue) -> Void)?

		/// Called regardless of where the change came from (ie. programatically OR user-initiated)
		let stateChanged: ((NSControl.StateValue) -> Void)?

		/// Show the labels on the button
		let showLabels: Bool

		public static let DefaultColor: CGColor = NSColor.controlAccentColor.cgColor

		public func makeCoordinator() -> Coordinator {
			Coordinator(self)
		}

		public init(
			state: Binding<NSControl.StateValue>,
			isEnabled: Bool = true,
			controlColor: CGColor = Self.DefaultColor,
			showLabels: Bool = false,
			action: ((NSControl.StateValue) -> Void)? = nil,
			stateChanged: ((NSControl.StateValue) -> Void)? = nil
		) {
			self.state = state
			self.isEnabled = isEnabled
			self.controlColor = controlColor
			self.showLabels = showLabels
			self.action = action
			self.stateChanged = stateChanged
		}
	}
}

@available(macOS 11, *)
public extension DSFToggleButton.SwiftUI {
	class Coordinator: NSObject {
		let parent: DSFToggleButton.SwiftUI
		var observer: NSKeyValueObservation?
		var button: DSFToggleButton? {
			didSet {
				self.observer = self.button?.observe(\.state, options: [.new], changeHandler: { [weak self] obj, change in
					self?.parent.stateChanged?(change.newValue ?? .off)
				})
			}
		}

		init(_ toggle: DSFToggleButton.SwiftUI) {
			self.parent = toggle
		}

		deinit {
			self.observer = nil
			self.button?.target = nil
		}

		@objc func buttonPressed(_ sender: AnyObject) {
			let newVal = self.button?.state ?? .off

			// Update our internal state so that it's reflected up through the binding
			self.parent.state.wrappedValue = newVal

			// Notify any blocks that might be listening
			self.parent.action?(newVal)
			self.parent.stateChanged?(newVal)
		}
	}
}

@available(macOS 11, *)
extension DSFToggleButton.SwiftUI: NSViewRepresentable {
	public typealias NSViewType = DSFToggleButton

	public func makeNSView(context: Context) -> DSFToggleButton {
		let button = DSFToggleButton(frame: .zero)
		button.translatesAutoresizingMaskIntoConstraints = false

		button.target = context.coordinator
		button.action = #selector(Coordinator.buttonPressed(_:))

		button.showLabels = self.showLabels

		context.coordinator.button = button

		return button
	}

	public func updateNSView(_ nsView: DSFToggleButton, context: Context) {
		if nsView.state != self.state.wrappedValue {
			nsView.state = self.state.wrappedValue
		}
		if self.controlColor != nsView.color.cgColor {
			nsView.color = NSColor(cgColor: self.controlColor) ?? NSColor.controlAccentColor
		}

		if nsView.isEnabled != self.isEnabled {
			nsView.isEnabled = self.isEnabled
		}

		if nsView.showLabels != self.showLabels {
			nsView.showLabels = self.showLabels
		}
	}
}

#if DEBUG

@available(macOS 11, *)
struct ToggleButtonPreviews: PreviewProvider {
	static var previews: some View {
		VStack {
			HStack {
				DSFToggleButton.SwiftUI(
					state: .constant(.off),
					controlColor: NSColor.systemGreen.cgColor
				)
				DSFToggleButton.SwiftUI(
					state: .constant(.on),
					controlColor: NSColor.systemGreen.cgColor
				)
			}
			HStack {
				DSFToggleButton.SwiftUI(
					state: .constant(.off),
					isEnabled: false,
					controlColor: NSColor.systemGreen.cgColor
				)
				DSFToggleButton.SwiftUI(
					state: .constant(.on),
					isEnabled: false,
					controlColor: NSColor.systemGreen.cgColor
				)
			}
			HStack {
				DSFToggleButton.SwiftUI(
					state: .constant(.off),
					controlColor: NSColor.systemPurple.cgColor,
					showLabels: true
				)
				DSFToggleButton.SwiftUI(
					state: .constant(.on),
					controlColor: NSColor.systemRed.cgColor,
					showLabels: true
				)
			}
			HStack {
				DSFToggleButton.SwiftUI(
					state: .constant(.off),
					isEnabled: false,
					controlColor: NSColor.systemPurple.cgColor,
					showLabels: true
				)
				DSFToggleButton.SwiftUI(
					state: .constant(.on),
					isEnabled: false,
					controlColor: NSColor.systemRed.cgColor,
					showLabels: true
				)
			}
		}
	}
}
#endif


#endif

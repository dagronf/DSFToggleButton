//
//  DSFToggleButton+SwiftUI.swift
//  
//
//  Created by Darren Ford on 11/1/21.
//

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

		public static let DefaultColor: CGColor = {
			return NSColor.controlAccentColor.cgColor
		}()

		public func makeCoordinator() -> Coordinator {
			Coordinator(self)
		}

		public init(state: Binding<NSControl.StateValue>,
						isEnabled: Bool = true,
						controlColor: CGColor = Self.DefaultColor,
						action: ((NSControl.StateValue) -> Void)? = nil,
						stateChanged: ((NSControl.StateValue) -> Void)? = nil) {
			self.state = state
			self.isEnabled = isEnabled
			self.controlColor = controlColor
			self.action = action
			self.stateChanged = stateChanged
		}
	}

}

@available(macOS 11, *)
extension DSFToggleButton.SwiftUI {
	public class Coordinator: NSObject {
		let parent: DSFToggleButton.SwiftUI
		var observer: NSKeyValueObservation?
		var button: DSFToggleButton? {
			didSet {
				self.observer = button?.observe(\.state, options: [.new], changeHandler: { [weak self] obj, change in
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

	}



}

#endif

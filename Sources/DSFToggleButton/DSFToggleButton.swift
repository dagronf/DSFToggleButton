//
//  DSFToggleButton.swift
//
//  Created by Darren Ford on 16/2/20.
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

#if os(macOS)

import AppKit
import DSFAppearanceManager

@IBDesignable
public class DSFToggleButton: NSButton {
	// MARK: Public vars

	// All coordinates are designed in flipped coordinates
	override public var isFlipped: Bool {
		return false
	}

	/// Show labels (0 and 1) on the button to increase visual distinction between states
	@IBInspectable public dynamic var showLabels: Bool = false {
		didSet {
			self.needsDisplay = true
		}
	}

	/// The color of the button when the state is on
	@IBInspectable public dynamic var color: NSColor {
		didSet {
			self.needsDisplay = true
		}
	}

	/// Used in the interface builder to indicate whether the initial state of a button is on
	@IBInspectable public dynamic var isOn: Bool {
		didSet {
			self.state = self.isOn ? .on : .off
		}
	}

	/// Force high-contrast drawing
	@IBInspectable public dynamic var highContrast: Bool = false {
		didSet {
			self.needsDisplay = true
		}
	}

	/// Remove color when the control is not attached to the key window (standard checkbox behaviour)
	@IBInspectable public dynamic var removeColorWhenContainingWindowNotFocussed: Bool = true {
		didSet {
			self.needsDisplay = true
		}
	}

	/// Is the transition on/off animated?
	@IBInspectable public var animated: Bool = true

	/// A callback block for when the button changes state
	///
	/// Called regardless of whether the state change comes from the user (via the UI) or by code
	@objc public var stateChangeBlock: ((DSFToggleButton) -> Void)?

	// MARK: Private vars

	// Are we in the process of setting ourselves up?
	private var initialLoad = true

	// Default color for the control
	private static let defaultColor: NSColor = .underPageBackgroundColor
	private static let defaultInactiveColor: NSColor = .gridColor

	// Listen to frame changes
	private var frameChangeListener: NSObjectProtocol?

	// The layers used within the control
	private let borderLayer = CAShapeLayer()
	private let borderMaskLayer = CAShapeLayer()
	private let borderShadowLayer = CAShapeLayer()
	private let borderShadowMaskLayer = CAShapeLayer()
	private let borderBorderLayer = CAShapeLayer()
	private let toggleCircle = CAShapeLayer()
	private let onLayer = CAShapeLayer()
	private let offLayer = CAShapeLayer()

	// `didSet` is called when the user programatically changes the state
	@objc override public var state: NSControl.StateValue {
		didSet {
			self.configureForCurrentState(animated: true)
			self.stateChangeBlock?(self)
		}
	}

	// MARK: Action Tweaking

	// Make sure that the action is directed to us, so that we can update on press
	private func twiddleAction() {
		let actionChanged = super.action != #selector(self._action(_:))
		if actionChanged {
			self._action = super.action
			super.action = #selector(self._action(_:))
		}
	}

	@objc private var _action: Selector?
	@objc override public var action: Selector? {
		didSet {
			self.twiddleAction()
		}
	}

	// MARK: Target tweaking

	// Make sure that we remain our own target so we can update on press
	private func twiddleTarget() {
		let targetChanged = super.target !== self
		if targetChanged {
			self._target = super.target
			super.target = self
		}
	}

	@objc private var _target: AnyObject?
	@objc override public var target: AnyObject? {
		didSet {
			self.twiddleTarget()
		}
	}

	// All our drawing is going to be layer based
	override public var wantsUpdateLayer: Bool {
		return true
	}

	// Accessibility container
	let accessibility = DSFAppearanceManager.ChangeDetector()

	// MARK: Init and setup

	override init(frame frameRect: NSRect) {
		self.color = DSFToggleButton.defaultColor
		self.isOn = false

		super.init(frame: frameRect)
		self.setup()
	}

	required init?(coder: NSCoder) {
		self.color = DSFToggleButton.defaultColor
		self.isOn = false

		super.init(coder: coder)
		self.setup()
	}

	deinit {
		self.stateChangeBlock = nil
		self.cell?.unbind(.value)
	}

	@objc public func toggle() {
		self.state = (self.state == .on) ? .off : .on
	}

	override public func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()

		self.twiddleTargetAction()
	}

	// Update the action and target to ourselves, and set the user's action/target values
	// to our private variables
	private func twiddleTargetAction() {
		self.twiddleTarget()
		self.twiddleAction()
	}
}

extension DSFToggleButton {
	private func setup() {
		self.wantsLayer = true

		guard let layer = self.layer else { fatalError("Unable to create layer?") }

		layer.addSublayer(self.borderLayer)
		self.borderLayer.mask = self.borderMaskLayer

		layer.addSublayer(self.borderShadowLayer)
		self.borderShadowLayer.mask = self.borderShadowMaskLayer

		layer.addSublayer(self.borderBorderLayer)
		layer.addSublayer(self.toggleCircle)

		// The on and off layers are children of the border layer
		self.borderLayer.addSublayer(self.onLayer)
		self.borderLayer.addSublayer(self.offLayer)

		let cell = NSButtonCell()
		cell.isBordered = false
		cell.isTransparent = true
		cell.setButtonType(.toggle)
		cell.state = self.isOn ? .on : .off
		self.cell = cell

		self.accessibility.appearanceChangeCallback = { [weak self] _, _ in
			self?.configureForCurrentState(animated: false)
		}

		// Listen for frame changes so we can reconfigure ourselves
		self.postsFrameChangedNotifications = true
		self.frameChangeListener = NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
			guard let `self` = self else {
				return
			}
			CATransaction.setDisableActions(true)
			self.rebuildLayers()
			self.needsDisplay = true
		}
	}

	// Custom action to intercept changes to the button state via the UI
	@objc private func _action(_ button: NSButton) {
		self.configureForCurrentState(animated: true)
		self.stateChangeBlock?(self)
		if let t = _target, let a = _action {
			_ = t.perform(a, with: button)
		}
	}
}

// MARK: -  Interface builder and draw

public extension DSFToggleButton {
	override func prepareForInterfaceBuilder() {
		self.setup()
	}

	override func updateLayer() {
		super.updateLayer()
		self.rebuildLayers()
		self.configureForCurrentState(animated: false)
	}
}

extension DSFToggleButton {
	private func buttonOuterFrame(for cellFrame: NSRect) -> NSRect {
		let newFrame: NSRect!
		let tHeight = cellFrame.width * (26.0 / 42.0)
		if tHeight > cellFrame.height {
			let ratioSmaller = cellFrame.height / tHeight
			let newWidth = cellFrame.width * ratioSmaller
			newFrame = NSRect(x: (cellFrame.width - newWidth) / 2.0, y: 0, width: newWidth, height: cellFrame.height - 1)
		}
		else {
			newFrame = NSRect(x: 0, y: (cellFrame.height - tHeight) / 2.0, width: cellFrame.width, height: tHeight - 1)
		}
		return newFrame.insetBy(dx: 1, dy: 1)
	}

	#if TARGET_INTERFACE_BUILDER
	// Hack to show the layout within IB
	override public func layout() {
		super.layout()
		self.rebuildLayers()
		self.updateLayer()
	}
	#endif

	private func rebuildLayers() {
		// LAYERS:
		//  Lowest
		//    Rounded rect color
		//    Rounded rect inner shadow
		//    Rounded Rect border
		//    0 label
		//    1 label
		//    Toggle button
		//  Highest

		let rect = self.buttonOuterFrame(for: self.frame)
		let radius = rect.height / 2.0

		// Lowest color rounded rect

		with(self.borderLayer) { outer in
			outer.zPosition = 0
			outer.path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

			// Update the mask
			self.borderMaskLayer.path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
		}

		with(self.borderShadowLayer) { sh in
			// The inner shadow for the lowest rounded rect

			let pth = CGMutablePath()
			pth.addRect(rect.insetBy(dx: -10, dy: -10))
			pth.addRoundedRect(in: rect, cornerWidth: radius, cornerHeight: radius)
			pth.closeSubpath()

			sh.fillRule = .evenOdd
			sh.fillColor = .black

			sh.shadowOpacity = 0.8
			sh.shadowColor = .black
			sh.shadowOffset = CGSize(width: 1, height: -1)
			sh.shadowRadius = radius > 12 ? 1.5 : 0.5

			sh.path = pth
			sh.strokeColor = nil
			sh.zPosition = 10

			if let shm = sh.mask as? CAShapeLayer {
				shm.path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
			}
		}

		with(self.borderBorderLayer) { border in
			// Top level border for the rounded rect
			border.path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
			border.zPosition = 20
			border.fillColor = nil
		}

		let r: CGFloat = radius / 1.7

		// Labels

		let lineWidth: CGFloat = max(1, ((1.0 / 8.0) * radius).toNP5())

		with(self.onLayer) { onItem in

			// The 1 label

			let ll = rect.width * 0.23
			let leftpos: CGFloat = rect.minX + ll + ((radius < 30) ? 1.0 : 0.0)

			let ooo1 = NSRect(x: leftpos, y: rect.origin.y + (rect.height / 2.0) - (r / 2.0) - 0.5,
			                  width: lineWidth, height: r + 2).toNP5()

			onItem.path = CGPath(roundedRect: ooo1, cornerWidth: lineWidth / 2, cornerHeight: lineWidth / 2, transform: nil)
			onItem.strokeColor = nil
			onItem.zPosition = 30
		}

		with(self.offLayer) { offItem in
			// The 0 label
			let rr = rect.width * 0.69
			let rightpos: CGFloat = rect.minX + rr

			let ooo = NSRect(x: rightpos - 1, y: rect.origin.y + (rect.height / 2.0) - (r / 2.0), width: r + 1, height: r + 1).toNP5()
			offItem.path = CGPath(ellipseIn: ooo, transform: nil)
			offItem.fillColor = .clear
			offItem.lineWidth = lineWidth - 0.5
			offItem.zPosition = 30
		}

		with(self.toggleCircle) { toggleCircle in

			// The toggle circle head

			var circle = rect
			circle.size.width = rect.height

			// Inset the circle to make it look a bit nicer
			let inset = max(2.5, circle.width * 0.06)

			toggleCircle.path = CGPath(ellipseIn: circle.insetBy(dx: inset, dy: inset), transform: nil)
			toggleCircle.position.x = self.state == .on ? rect.width - rect.height : 0
			toggleCircle.zPosition = 50

			toggleCircle.shadowOpacity = 0.8
			toggleCircle.shadowColor = .black
			toggleCircle.shadowOffset = NSSize(width: 1, height: -1)
			toggleCircle.shadowRadius = radius > 12 ? 1.5 : 0.5
		}

		self.initialLoad = false
	}

	override public func drawFocusRingMask() {
		let rect = self.buttonOuterFrame(for: self.frame)
		let radius = rect.height / 2.0
		NSColor.black.setFill()
		let rectanglePath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
		rectanglePath.fill()
	}

	func configureForCurrentState(animated: Bool) {
		let rect = self.buttonOuterFrame(for: self.frame)
		let radius = rect.height / 2.0

		let highContrast = DSFAppearanceManager.IncreaseContrast || self.highContrast

		if !animated || DSFAppearanceManager.ReduceMotion || self.initialLoad || !self.animated {
			CATransaction.setDisableActions(true)
		}
		else {
			CATransaction.setAnimationDuration(0.15)
			CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
		}

		// 'Differentiate without color' always shows the labels
		let showLabels = (self.showLabels || DSFAppearanceManager.DifferentiateWithoutColor)

		let isOff = (self.state == .off || DSFAppearanceManager.DifferentiateWithoutColor)

		let bgcolor: NSColor

		#if TARGET_INTERFACE_BUILDER
		bgcolor = (self.state == .off || accessibility.differentiateWithoutColor) ? DSFToggleButton.defaultColor : self.color
		#else
		if let w = self.window, w.isKeyWindow {
			bgcolor = isOff ? DSFToggleButton.defaultColor : self.color
		}
		else {
			bgcolor = {
				if isOff {
					return DSFToggleButton.defaultColor
				}
				else if !self.removeColorWhenContainingWindowNotFocussed {
					return self.color
				}
				else {
					return DSFToggleButton.defaultInactiveColor.applyOnTopOf(NSColor.underPageBackgroundColor)
				}
			}()
		}
		#endif

		let fgcolor = bgcolor.flatContrastColor()

		self.borderShadowLayer.isHidden = highContrast
		self.borderShadowLayer.shadowRadius = radius > 12 ? 1.5 : 1

		self.onLayer.isHidden = !showLabels
		self.onLayer.fillColor = fgcolor.cgColor
		self.offLayer.isHidden = !showLabels
		self.offLayer.strokeColor = fgcolor.cgColor

		self.onLayer.fillColor = fgcolor.cgColor
		self.offLayer.strokeColor = fgcolor.cgColor

		self.borderLayer.fillColor = bgcolor.cgColor
		let borderColor = highContrast ? NSColor.textColor : NSColor.controlColor
		self.borderBorderLayer.strokeColor = borderColor.cgColor
		self.borderBorderLayer.lineWidth = 1.0
		self.borderBorderLayer.opacity = 1.0

		// Toggle color
		let toggleFront: CGColor = .white
		self.alphaValue = self.isEnabled ? 1.0 : 0.4

		self.toggleCircle.fillColor = toggleFront
		self.toggleCircle.strokeColor = highContrast ? .black : .clear
		self.toggleCircle.lineWidth = radius > 12 ? 1 : 0.5
		self.toggleCircle.shadowOpacity = highContrast ? 0.0 : 0.8
		self.toggleCircle.shadowRadius = radius > 12 ? 1.5 : 1

		if self.state == .on {
			self.toggleCircle.frame.origin = CGPoint(x: rect.width - rect.height, y: 0)
			let a = CGAffineTransform.identity
			self.onLayer.setAffineTransform(a)

			let b = CGAffineTransform(translationX: radius * 1.3, y: 0)
			self.offLayer.setAffineTransform(b)
		}
		else {
			self.toggleCircle.frame.origin = CGPoint(x: 0, y: 0)

			let a = CGAffineTransform(translationX: -radius * 1.3, y: 0)
			self.onLayer.setAffineTransform(a)

			self.offLayer.setAffineTransform(CGAffineTransform.identity)
		}

		CATransaction.commit()
	}
}

#endif

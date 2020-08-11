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

import AppKit

@IBDesignable
public class DSFToggleButton: NSButton {
	// MARK: Public vars

	// All coordinates are designed in flipped coordinates
	public override var isFlipped: Bool {
		return true
	}

	/// Show labels (0 and 1) on the button to increase visual distinction between states
	@IBInspectable dynamic var showLabels: Bool = false {
		didSet {
			self.needsDisplay = true
		}
	}

	/// The color of the button when the state is on
	@IBInspectable dynamic var color: NSColor {
		didSet {
			self.needsDisplay = true
		}
	}

	/// Used in the interface builder to indicate whether the initial state of a button is on
	@IBInspectable dynamic var isOn: Bool {
		didSet {
			self.state = self.isOn ? .on : .off
		}
	}

	/// Force high-contrast drawing
	@IBInspectable dynamic var highContrast: Bool = false {
		didSet {
			self.needsDisplay = true
		}
	}

	/// Is the transition on/off animated?
	@IBInspectable var animated: Bool = true

	/// A callback block for when the button changes state
	///
	/// Called regardless of whether the state change comes from the user (via the UI) or by code
	@objc public var stateChangeBlock: ((DSFToggleButton) -> Void)?

	// MARK: Private vars

	// Are we in the process of setting ourselves up?
	private var initialLoad = true

	// Default color for the control
	private static let defaultColor: NSColor = .underPageBackgroundColor

	// Listen to frame changes
	private var frameChangeListener: NSObjectProtocol?
	private var previousState: NSControl.StateValue?

	private var borderLayer: CAShapeLayer?
	private var borderShadowLayer: CAShapeLayer?
	private var borderBorderLayer: CAShapeLayer?
	private var toggleCircle: CAShapeLayer?
	private var onLayer: CAShapeLayer?
	private var offLayer: CAShapeLayer?

	// `didSet` is called when the user programatically changes the state
	@objc public override var state: NSControl.StateValue {
		didSet {
			self.configureForCurrentState()
			self.stateChangeBlock?(self)
		}
	}

	// MARK: Action Tweaking

	// Make sure that the action is directed to us, so that we can update on press
	private func twiddleAction() {
		let actionChanged = super.action != #selector(_action(_:))
		if actionChanged {
			self._action = super.action
			super.action = #selector(_action(_:))
		}
	}

	@objc private var _action: Selector?
	@objc public override var action: Selector? {
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
	@objc public override var target: AnyObject? {
		didSet {
			self.twiddleTarget()
		}
	}

	// All our drawing is going to be layer based
	public override var wantsUpdateLayer: Bool {
		return true
	}

	// Accessibility container
	let accessibility = DSFAccessibility.Observer()

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

	public override func viewDidMoveToWindow() {
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

		let cell = NSButtonCell()
		cell.isBordered = false
		cell.isTransparent = true
		cell.setButtonType(.toggle)
		cell.state = self.isOn ? .on : .off
		self.cell = cell

		self.accessibility.listen { [weak self] _ in
			self?.configureForCurrentState()
		}

		// Listen for frame changes so we can reconfigure ourselves
		self.postsFrameChangedNotifications = true
		self.frameChangeListener = NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
			guard let `self` = self else {
				return
			}

			self.rebuildLayers()
			self.needsDisplay = true
		}
	}

	// Custom action to intercept changes to the button state via the UI
	@objc private func _action(_ button: NSButton) {
		self.configureForCurrentState()
		self.stateChangeBlock?(self)
		if let t = _target, let a = _action {
			_ = t.perform(a, with: button)
		}
	}
}

// MARK: -  Interface builder and draw

extension DSFToggleButton {
	public override func prepareForInterfaceBuilder() {
		self.setup()
	}

	public override func updateLayer() {
		super.updateLayer()
		self.configureForCurrentState()
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
		} else {
			newFrame = NSRect(x: 0, y: (cellFrame.height - tHeight) / 2.0, width: cellFrame.width, height: tHeight - 1)
		}
		return newFrame.insetBy(dx: 1, dy: 1)
	}

	#if TARGET_INTERFACE_BUILDER
		// Hack to show the layout within IB
		public override func layout() {
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

		self.borderLayer?.removeFromSuperlayer()
		self.borderBorderLayer?.removeFromSuperlayer()
		self.borderShadowLayer?.removeFromSuperlayer()
		self.toggleCircle?.removeFromSuperlayer()
		self.onLayer?.removeFromSuperlayer()
		self.offLayer?.removeFromSuperlayer()

		let rect = self.buttonOuterFrame(for: self.frame)
		let radius = rect.height / 2.0

		// Lowest color rounded rect

		let outer = CAShapeLayer()
		outer.path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
		self.borderLayer = outer
		outer.zPosition = 0

		let shm33 = CAShapeLayer()
		shm33.path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
		outer.mask = shm33

		self.layer?.addSublayer(outer)

		// The inner shadow for the lowest rounded rect

		let pth = CGMutablePath()
		pth.addRect(rect.insetBy(dx: -10, dy: -10))
		pth.addRoundedRect(in: rect, cornerWidth: radius, cornerHeight: radius)
		pth.closeSubpath()

		let sh = CAShapeLayer()
		sh.fillRule = .evenOdd
		sh.fillColor = .black

		sh.shadowOpacity = 0.8
		sh.shadowColor = .black
		#if !TARGET_INTERFACE_BUILDER
		sh.shadowOffset = CGSize(width: 1, height: 1)
		#else
		sh.shadowOffset = CGSize(width: 1, height: -1)
		#endif
		sh.shadowRadius = radius > 12 ? 1.5 : 0.5
		sh.path = pth
		sh.strokeColor = nil
		sh.zPosition = 10

		let shm = CAShapeLayer()
		shm.path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
		sh.mask = shm

		self.borderShadowLayer = sh
		self.layer?.addSublayer(sh)

		// Top level border for the rounded rect

		let border = CAShapeLayer()
		border.path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
		border.zPosition = 20
		border.fillColor = nil
		self.borderBorderLayer = border
		self.layer?.addSublayer(border)

		let r: CGFloat = radius / 1.7

		// Labels

		let lineWidth: CGFloat = max(1, ((1.0 / 8.0) * radius).toNP5())

		// The 1 label

		let onItem = CAShapeLayer()

		let ll = rect.width * 0.23
		let leftpos: CGFloat = rect.minX + ll + ((radius < 30) ? 1.0 : 0.0)

		let ooo1 = NSRect(x: leftpos, y: rect.origin.y + (rect.height / 2.0) - (r / 2.0) - 0.5,
						  width: lineWidth, height: r + 2).toNP5()

		onItem.path = CGPath(roundedRect: ooo1, cornerWidth: lineWidth / 2, cornerHeight: lineWidth / 2, transform: nil)
		onItem.strokeColor = nil
		onItem.zPosition = 30

		self.onLayer = onItem
		outer.addSublayer(onItem)

		// The 0 label
		let rr = rect.width * 0.69
		let rightpos: CGFloat = rect.minX + rr

		let offItem = CAShapeLayer()
		let ooo = NSRect(x: rightpos - 1, y: rect.origin.y + (rect.height / 2.0) - (r / 2.0), width: r + 1, height: r + 1).toNP5()
		offItem.path = CGPath(ellipseIn: ooo, transform: nil)
		offItem.fillColor = .clear
		offItem.lineWidth = lineWidth - 0.5
		offItem.zPosition = 30
		self.offLayer = offItem
		outer.addSublayer(offItem)

		// The toggle circle head

		let toggleCircle = CAShapeLayer()
		var circle = rect
		circle.size.width = rect.height

		// Inset the circle to make it look a bit nicer
		let inset = max(2.5, circle.width * 0.08)

		toggleCircle.path = CGPath(ellipseIn: circle.insetBy(dx: inset, dy: inset), transform: nil)
		toggleCircle.position.x = self.state == .on ? rect.width - rect.height : 0
		self.toggleCircle = toggleCircle
		toggleCircle.zPosition = 50
		self.layer?.addSublayer(toggleCircle)

		toggleCircle.shadowOpacity = 0.8
		toggleCircle.shadowColor = .black
		#if !TARGET_INTERFACE_BUILDER
		toggleCircle.shadowOffset = NSSize(width: 1, height: 1)
		#else
		toggleCircle.shadowOffset = NSSize(width: 1, height: -1)
		#endif
		toggleCircle.shadowRadius = radius > 12 ? 1.5 : 0.5

		self.initialLoad = false
	}

	public override func drawFocusRingMask() {
		let rect = self.buttonOuterFrame(for: self.frame)
		let radius = rect.height / 2.0
		NSColor.black.setFill()
		let rectanglePath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
		rectanglePath.fill()
	}

	func configureForCurrentState() {
		let rect = self.buttonOuterFrame(for: self.frame)
		let radius = rect.height / 2.0

		let accessibility = DSFAccessibility.shared.display
		let highContrast = accessibility.shouldIncreaseContrast || self.highContrast

		if accessibility.reduceMotion || self.initialLoad || !self.animated {
			CATransaction.setDisableActions(true)
		} else {
			CATransaction.setAnimationDuration(0.15)
			CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
		}

		let showLabels = (self.showLabels || accessibility.differentiateWithoutColor)

		let bgcolor = (self.state == .off || accessibility.differentiateWithoutColor) ? DSFToggleButton.defaultColor : self.color
		let fgcolor = bgcolor.contrastingTextColor()

		self.borderShadowLayer?.isHidden = highContrast
		self.borderShadowLayer?.shadowRadius = radius > 12 ? 1.5 : 1

		self.onLayer?.isHidden = !showLabels
		self.onLayer?.fillColor = self.color.contrastingTextColor().cgColor
		self.offLayer?.isHidden = !showLabels
		self.offLayer?.strokeColor = self.color.contrastingTextColor().cgColor

		self.onLayer?.fillColor = fgcolor.cgColor
		self.offLayer?.strokeColor = fgcolor.cgColor

		self.borderLayer?.fillColor = bgcolor.cgColor
		let borderColor = highContrast ? NSColor.textColor : NSColor.controlColor
		self.borderBorderLayer?.strokeColor = borderColor.cgColor
		self.borderBorderLayer?.lineWidth = 1.0
		self.borderBorderLayer?.opacity = 1.0

		// Toggle color
		let toggleFront: CGColor = .white
		self.alphaValue = self.isEnabled ? 1.0 : 0.4

		self.toggleCircle?.fillColor = toggleFront
		self.toggleCircle?.strokeColor = highContrast ? .black : CGColor(gray: 0.8, alpha: 1.0)
		self.toggleCircle?.lineWidth = radius > 12 ? 1 : 0.5
		self.toggleCircle?.shadowOpacity = highContrast ? 0.0 : 0.8
		self.toggleCircle?.shadowRadius = radius > 12 ? 1.5 : 1

		if self.previousState != self.state {
			self.previousState = self.state
			if self.state == .on {
				self.toggleCircle?.frame.origin = CGPoint(x: rect.width - rect.height, y: 0)
				let a = CGAffineTransform.identity
				self.onLayer?.setAffineTransform(a)

				let b = CGAffineTransform(translationX: radius * 1.3, y: 0)
				self.offLayer?.setAffineTransform(b)

			} else {
				self.toggleCircle?.frame.origin = CGPoint(x: 0, y: 0)

				let a = CGAffineTransform(translationX: -radius * 1.3, y: 0)
				self.onLayer?.setAffineTransform(a)

				self.offLayer?.setAffineTransform(CGAffineTransform.identity)
			}
		}

		CATransaction.commit()
	}
}

private extension BinaryFloatingPoint {
	func toNP5() -> Self {
		var result = self.rounded(.towardZero)
		let diff = self - result
		if diff > 0.5 {
			result += self > 0 ? 0.5 : -0.5
		}
		return result
	}
}

private extension NSRect {
	/// Return a tweaked rect where all edges sit on a multiple of 0.5
	func toNP5() -> CGRect {
		return CGRect(x: self.origin.x.toNP5(),
					  y: self.origin.y.toNP5(),
					  width: self.size.width.toNP5(),
					  height: self.size.height.toNP5())
	}
}

// MARK: - NSColor extension

private extension NSColor {
	private struct ColorComponents {
		var r: CGFloat = 0.0
		var g: CGFloat = 0.0
		var b: CGFloat = 0.0
		var a: CGFloat = 0.0
	}

	private func components() -> ColorComponents {
		var result = ColorComponents()
		self.getRed(&result.r, green: &result.g, blue: &result.b, alpha: &result.a)
		return result
	}

	func contrastingTextColor() -> NSColor {
		if self == NSColor.clear {
			return .black
		}

		guard let c1 = self.usingColorSpace(.deviceRGB) else {
			return .black
		}

		let rgbColor = c1.components()

		// Counting the perceptive luminance - human eye favors green color...
		let avgGray: CGFloat = 1 - (0.299 * rgbColor.r + 0.587 * rgbColor.g + 0.114 * rgbColor.b)
		return avgGray > 0.5 ? .white : .black
	}

	/// Returns an inverted version this color, optionally preserving the colorspace from the original color if possible
	func inverted(preserveColorSpace: Bool = false) -> NSColor {
		guard let c1 = self.usingColorSpace(.deviceRGB) else {
			return self
		}
		let rgbColor = c1.components()
		let inverted = NSColor(calibratedRed: 1.0 - rgbColor.r,
							   green: 1.0 - rgbColor.g,
							   blue: 1.0 - rgbColor.b,
							   alpha: c1.alphaComponent)
		if preserveColorSpace, let c2 = inverted.usingColorSpace(self.colorSpace) {
			return c2
		}
		return inverted
	}
}

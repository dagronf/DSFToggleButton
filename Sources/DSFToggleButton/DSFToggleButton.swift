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

	/// Called regardless of whether the state change comes from the user (via the UI) or by code
	@objc public var stateChangeBlock: ((DSFToggleButton) -> Void)?

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

	/// Is the transition on/off animated?
	@IBInspectable var animated: Bool = true

	// MARK: Private vars

	private var initialLoad = true
	private let defaultColor: NSColor = .underPageBackgroundColor
	private var accessibilityListener: NSObjectProtocol?
	private var previousState: NSControl.StateValue = .off

	private var borderLayer: CAShapeLayer?
	private var borderShadowLayer: CAShapeLayer?
	private var borderBorderLayer: CAShapeLayer?
	private var toggleCircle: CAShapeLayer?
	private var onLayer: CAShapeLayer?
	private var offLayer: CAShapeLayer?

	// MARK: Bindings to help make the toggle more accurate

	private var lastButtonState: NSButton.StateValue = .off
	@objc private var internalButtonState: NSButton.StateValue = .off {
		didSet {
			self.lastButtonState = self.internalButtonState

			// Notify the state change delegate of the change
			self.stateChangeBlock?(self)
		}
	}

	// MARK: Init and setup

	override init(frame frameRect: NSRect) {
		self.color = self.defaultColor
		self.isOn = false

		super.init(frame: frameRect)
		self.setup()
	}

	required init?(coder: NSCoder) {
		self.color = self.defaultColor
		self.isOn = false

		super.init(coder: coder)
		self.setup()
	}

	deinit {
		self.stateChangeBlock = nil
		self.accessibilityListener = nil
		self.cell?.unbind(.value)

		DSFAccessibility.shared.display.unlisten(self)
	}

	// MARK: State capture/handling

	@objc public func toggle() {
		self.state = (self.state == .on) ? .off : .on
	}

	@objc public override var state: NSControl.StateValue {
		didSet {
			self.willChangeValue(for: \.internalButtonState)
			self.internalButtonState = self.state
			self.didChangeValue(for: \.internalButtonState)
		}
	}
}

extension DSFToggleButton {
	public override var intrinsicContentSize: NSSize {
		return self.frame.size
	}

	private func setup() {
		self.wantsLayer = true

		let cell = DSFToggleButtonCell()
		cell.setButtonType(.toggle)
		cell.bind(.value, to: self, withKeyPath: "internalButtonState", options: nil)
		self.cell = cell

		self.setContentHuggingPriority(.required, for: .horizontal)
		self.setContentHuggingPriority(.required, for: .vertical)

		self.setContentCompressionResistancePriority(.required, for: .horizontal)
		self.setContentCompressionResistancePriority(.required, for: .vertical)

		self.accessibilityListener = DSFAccessibility.shared.display.listen(queue: OperationQueue.main) { [weak self] _ in
			// Notifications should come in on the main queue for UI updates
			// self?.needsDisplay = true
			self?.configureForCurrentState()
		}

		self.postsFrameChangedNotifications = true
		NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
			guard let `self` = self else {
				return
			}

			self.rebuildLayers()
			self.configureForCurrentState()
			self.needsDisplay = true
		}
	}
}

extension DSFToggleButton {
	// Interface builder and draw

	private var customCell: DSFToggleButtonCell? {
		return self.cell as? DSFToggleButtonCell
	}

	public override func prepareForInterfaceBuilder() {
		self.setup()
	}

	public override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		configureForCurrentState()
		// Drawing code here.
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
		sh.shadowOffset = CGSize(width: 1, height: 1)
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

		// The 1 label

		let onItem = CAShapeLayer()

		let leftpos: CGFloat = (rect.maxX - rect.minX) / 4.0 + 1.5
		let rightpos: CGFloat = (rect.maxX - rect.minX) * (3.0 / 4.0) + 1.5

		let w: CGFloat = radius > 12 ? 2 : 1
		let ooo1 = NSRect(x: leftpos - (w / 2.0), y: rect.origin.y + (rect.height / 2.0) - (r / 2.0) - 0.5,
						  width: w, height: r + 1).toNP5()
		onItem.path = CGPath(rect: ooo1, transform: nil)
		onItem.strokeColor = nil
		onItem.zPosition = 30
		self.onLayer = onItem
		self.layer?.addSublayer(onItem)

		// The 0 label

		let offItem = CAShapeLayer()
		let ooo = NSRect(x: rightpos - (r / 2), y: rect.origin.y + (rect.height / 2.0) - (r / 2.0), width: r, height: r).toNP5()
		offItem.path = CGPath(ellipseIn: ooo, transform: nil)
		offItem.fillColor = .clear
		offItem.lineWidth = radius > 12 ? 1.5 : 0.75
		offItem.zPosition = 30
		self.offLayer = offItem
		self.layer?.addSublayer(offItem)

		// The toggle

		let toggleCircle = CAShapeLayer()
		var circle = rect
		circle.size.width = rect.height
		toggleCircle.path = CGPath(ellipseIn: circle.insetBy(dx: 2.5, dy: 2.5), transform: nil)
		toggleCircle.position.x = self.state == .on ? rect.width - rect.height : 0
		self.toggleCircle = toggleCircle
		toggleCircle.zPosition = 50
		self.layer?.addSublayer(toggleCircle)

		toggleCircle.shadowOpacity = 0.8
		toggleCircle.shadowColor = .black
		toggleCircle.shadowOffset = NSSize(width: 1, height:1)
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
		let highContrast = accessibility.shouldIncreaseContrast

		if accessibility.reduceMotion || self.initialLoad || !self.animated {
			CATransaction.setDisableActions(true)
		} else {
			CATransaction.setAnimationDuration(0.15)
			CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
		}

		let showLabels = ((self.showLabels || accessibility.differentiateWithoutColor) && self.isEnabled)

		let bgcolor = (self.state == .off || accessibility.differentiateWithoutColor) ? self.defaultColor : self.color
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
		self.borderBorderLayer?.strokeColor = borderColor.cgColor // borderColor.withAlphaComponent(1).cgColor
		self.borderBorderLayer?.lineWidth = 1.0
		self.borderBorderLayer?.opacity = 1.0

		// Toggle color
		let toggleFront: CGColor!
		if self.isEnabled {
			toggleFront = .white
		} else {
			toggleFront = NSColor.white.withAlphaComponent(highContrast ? 0.6 : 0.4).cgColor
		}
		self.toggleCircle?.fillColor = toggleFront
		self.toggleCircle?.strokeColor = highContrast ? .black : nil
		self.toggleCircle?.lineWidth = 1
		self.toggleCircle?.shadowOpacity = highContrast ? 0.0 : 0.8
		self.toggleCircle?.shadowRadius = radius > 12 ? 1.5 : 1

		if self.previousState != self.state {
			let rect = self.buttonOuterFrame(for: self.frame)
			if self.state == .on {
				self.toggleCircle?.frame.origin = CGPoint(x: rect.width - rect.height, y: 0)
			} else {
				self.toggleCircle?.frame.origin = CGPoint(x: 0, y: 0)
			}
		}
		self.previousState = self.state
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

// MARK: - DSFToggleButton custom cell

private class DSFToggleButtonCell: NSButtonCell {
	// MARK: Drawing methods

	override func drawBezel(withFrame _: NSRect, in _: NSView) {
		// Override to ignore the default drawing
	}

	override func drawInterior(withFrame cellFrame: NSRect, in _: NSView) {
		// Override to ignore the default drawing
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

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
	public var stateChangeDelegate: ((DSFToggleButton) -> Void)?

	/// Show labels (0 and 1) on the button to increase visual distinction between states
	@IBInspectable dynamic var showLabels: Bool = false {
		didSet {
			self.customCell?.showLabels = self.showLabels
			self.needsDisplay = true
		}
	}

	/// The color of the button when the state is on
	@IBInspectable dynamic var color: NSColor {
		didSet {
			self.customCell?.color = self.color
			self.needsDisplay = true
		}
	}

	/// Used in the interface builder to indicate whether the initial state of a button is on
	@IBInspectable dynamic var isOn: Bool {
		didSet {
			self.state = self.isOn ? .on : .off
		}
	}

	// MARK: Private vars

	private var initialLoad = true
	private let defaultColor: NSColor = .underPageBackgroundColor
	private var animLayer: ArbitraryAnimationLayer?
	private var accessibilityListener: NSObjectProtocol?

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

	public override var intrinsicContentSize: NSSize {
		return self.frame.size
	}

	public override func awakeFromNib() {
		super.awakeFromNib()
		self.initialLoad = false
	}

	deinit {
		self.stateChangeDelegate = nil
		self.accessibilityListener = nil
		self.cell?.unbind(.value)

		DSFAccessibility.shared.unlisten(self)
	}

	@objc public func toggle() {
		self.state = (self.state == .on) ? .off : .on
	}

	// MARK: State capture/handling

	@objc public override var state: NSControl.StateValue {
		didSet {
			self.willChangeValue(for: \.internalButtonState)
			self.internalButtonState = self.state
			self.didChangeValue(for: \.internalButtonState)
		}
	}

	private var lastButtonState: NSButton.StateValue = .off
	@objc private var internalButtonState: NSButton.StateValue = .off {
		didSet {
			if self.lastButtonState == .off, self.internalButtonState != .off {
				self.animate(on: true)
			} else if self.lastButtonState != .off, self.internalButtonState == .off {
				self.animate(on: false)
			}
			self.lastButtonState = self.internalButtonState

			// Notify the state change delegate of the change
			self.stateChangeDelegate?(self)
		}
	}

	// Interface builder and draw

	private var customCell: DSFToggleButtonCell? {
		return self.cell as? DSFToggleButtonCell
	}

	public override func prepareForInterfaceBuilder() {
		self.setup()

		self.customCell?.showLabels = self.showLabels
		self.customCell?.color = self.color
	}

	public override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		// Drawing code here.
	}
}

private extension DSFToggleButton {
	func setup() {
		self.wantsLayer = true

		let cell = DSFToggleButtonCell()
		cell.color = self.color
		cell.setButtonType(.toggle)
		cell.bind(.value, to: self, withKeyPath: "internalButtonState", options: nil)
		self.cell = cell

		self.setContentHuggingPriority(.required, for: .horizontal)
		self.setContentHuggingPriority(.required, for: .vertical)

		self.setContentCompressionResistancePriority(.required, for: .horizontal)
		self.setContentCompressionResistancePriority(.required, for: .vertical)

		self.accessibilityListener = DSFAccessibility.shared.listen(queue: OperationQueue.main) { [weak self] _ in
			// Notifications should come in on the main queue for UI updates
			self?.needsDisplay = true
		}
	}
}

private extension DSFToggleButton {
	func animate(on: Bool) {
		let startEndPos = DSFToggleButtonCell.toggleStartEndPos(for: self.frame)

		if DSFAccessibility.shared.reduceMotion || self.initialLoad {
			self.customCell?.xanimPos = on ? startEndPos.right : startEndPos.left
			return
		}

		let alayer = ArbitraryAnimationLayer()
		alayer.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
		self.animLayer = alayer
		self.layer?.addSublayer(alayer)
		let anim = CABasicAnimation(keyPath: ArbitraryAnimationLayer.KeyPath)
		anim.fromValue = on ? startEndPos.left : startEndPos.right
		anim.toValue = on ? startEndPos.right : startEndPos.left
		anim.duration = 0.1
		anim.fillMode = CAMediaTimingFillMode.forwards
		anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
		anim.isRemovedOnCompletion = true

		alayer.progressCallback = { [weak self] progress in
			self?.customCell?.xanimPos = progress
			self?.needsDisplay = true
		}
		alayer.add(anim, forKey: "change")
	}
}

// MARK: - DSFToggleButton custom cell

private class DSFToggleButtonCell: NSButtonCell {
	fileprivate var showLabels: Bool = false
	fileprivate var color: NSColor = .green
	fileprivate var xanimPos: CGFloat?

	static func buttonDrawFrame(for cellFrame: NSRect) -> NSRect {
		let newFrame: NSRect!
		let tHeight = cellFrame.width * (26.0 / 42.0)
		if tHeight > cellFrame.height {
			let ratioSmaller = cellFrame.height / tHeight
			let newWidth = cellFrame.width * ratioSmaller
			newFrame = NSRect(x: (cellFrame.width - newWidth) / 2.0, y: 0, width: newWidth, height: cellFrame.height - 1)
		} else {
			newFrame = NSRect(x: 0, y: (cellFrame.height - tHeight) / 2.0, width: cellFrame.width, height: tHeight - 1)
		}
		return newFrame
	}

	static func toggleStartEndPos(for cellFrame: NSRect) -> (left: CGFloat, right: CGFloat) {
		let newFrame = DSFToggleButtonCell.buttonDrawFrame(for: cellFrame)
		return (newFrame.origin.x + 3.0, newFrame.origin.x + newFrame.width - newFrame.height + 2)
	}

	// MARK: Drawing methods

	override func drawFocusRingMask(withFrame cellFrame: NSRect, in _: NSView) {
		var newFrame = DSFToggleButtonCell.buttonDrawFrame(for: cellFrame)
		NSColor.black.setFill()
		newFrame.size.width -= 1
		newFrame = newFrame.insetBy(dx: -0.5, dy: -0.5)
		let radius = newFrame.height / 2.0
		let rectanglePath = NSBezierPath(roundedRect: newFrame, xRadius: radius, yRadius: radius)
		rectanglePath.fill()
	}

	override func drawBezel(withFrame _: NSRect, in _: NSView) {
		// Override to ignore the default drawing
	}

	override func drawInterior(withFrame cellFrame: NSRect, in _: NSView) {
		//// General Declarations
		let context = NSGraphicsContext.current!.cgContext

		let accessibility = DSFAccessibility.shared

		let highContrast = accessibility.shouldIncreaseContrast
		let differentiateWithoutColor = accessibility.differentiateWithoutColor

		// Work out how we best fit

		let newFrame = DSFToggleButtonCell.buttonDrawFrame(for: cellFrame)

		//// Shadow Declarations
		let shadow = NSShadow()
		shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
		shadow.shadowOffset = NSSize(width: 1, height: -1)
		shadow.shadowBlurRadius = 4

		let backColor: NSColor!
		if differentiateWithoutColor {
			// If differentiateWithoutColor is on, just ignore the color
			backColor = .underPageBackgroundColor
		} else {
			let bgcolor = accessibility.shouldInvertColors ? self.color.inverted() : self.color
			backColor = (self.state == .on) ? bgcolor : .underPageBackgroundColor
		}

		let borderColor = highContrast ? NSColor.textColor : NSColor.controlColor

		let width = newFrame.width - 2
		let height = newFrame.height - 1
		let radius = height / 2.0

		//// Rectangle Drawing
		let rectanglePath = NSBezierPath(roundedRect: NSRect(x: newFrame.minX + 0.5, y: newFrame.minY + 0.5, width: width, height: height), xRadius: radius, yRadius: radius)
		backColor.setFill()
		rectanglePath.fill()

		////// Rectangle Inner Shadow

		if !highContrast {
			NSGraphicsContext.saveGraphicsState()
			rectanglePath.bounds.clip()
			context.setShadow(offset: NSSize.zero, blur: 0, color: nil)

			context.setAlpha(shadow.shadowColor!.alphaComponent)
			context.beginTransparencyLayer(auxiliaryInfo: nil)
			let rectangleOpaqueShadow = NSShadow()
			rectangleOpaqueShadow.shadowColor = shadow.shadowColor!.withAlphaComponent(1)
			rectangleOpaqueShadow.shadowOffset = shadow.shadowOffset
			rectangleOpaqueShadow.shadowBlurRadius = shadow.shadowBlurRadius
			rectangleOpaqueShadow.set()

			context.setBlendMode(.sourceOut)
			context.beginTransparencyLayer(auxiliaryInfo: nil)

			rectangleOpaqueShadow.shadowColor!.setFill()
			rectanglePath.fill()

			context.endTransparencyLayer()
			context.endTransparencyLayer()
			NSGraphicsContext.restoreGraphicsState()
		}

		borderColor.setStroke()
		rectanglePath.lineWidth = 1
		rectanglePath.stroke()

		if showLabels || differentiateWithoutColor {
			/// Accessibility

			var c = backColor.contrastingTextColor()
			if !highContrast {
				c = c.withAlphaComponent(0.7)
			}
			c.setStroke()
			c.setFill()

			/// Draw the '1' label

			let xc = newFrame.origin.x + (newFrame.width / 5.0) + 1
			let yc = height / 2.0 + newFrame.minY - 1
			let sz = height / 7

			let linepath = NSBezierPath(rect: NSRect(x: xc + 1, y: yc - sz + 1, width: 1.5, height: sz * 2 + 1))
			linepath.fill()

			/// Draw the '0' label

			let xc2 = newFrame.origin.x + (newFrame.width / 4.0 * 3)
			let yc2 = height / 2.0 + newFrame.minY - 0.5

			let sz2 = height / 8

			let ovalPath = NSBezierPath(ovalIn: NSRect(x: xc2 - 3, y: yc2 - sz2 + 1, width: sz2 * 2, height: sz2 * 2))
			ovalPath.lineWidth = height < 20 ? 1.0 : 1.5
			ovalPath.stroke()
		}

		let startEnd = DSFToggleButtonCell.toggleStartEndPos(for: cellFrame)

		let xpos: CGFloat = xanimPos ?? ((self.state == .on) ? startEnd.right : startEnd.left)

		//// Oval Drawing
		let ovalPath = NSBezierPath(ovalIn: NSRect(x: xpos - 0.5, y: newFrame.minY + 2.5, width: height - 4, height: height - 4))
		NSGraphicsContext.saveGraphicsState()
		if !highContrast {
			shadow.set()
		}
		NSColor.white.setFill()
		ovalPath.fill()

		if highContrast {
			NSColor.labelColor.setStroke()
			ovalPath.stroke()
		}

		NSGraphicsContext.restoreGraphicsState()
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

// MARK: - Arbitrary animation layer

public class ArbitraryAnimationLayer: CALayer {
	static let KeyPath: String = "progress"

	override init() {
		super.init()
	}

	var progressCallback: ((CGFloat) -> Void)?

	override init(layer: Any) {
		super.init(layer: layer)
		guard let newL = layer as? ArbitraryAnimationLayer else {
			fatalError()
		}
		self.progress = newL.progress
		self.progressCallback = newL.progressCallback
	}

	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@objc dynamic var progress: CGFloat = 0 {
		didSet {
			progressCallback?(progress)
		}
	}

	public override static func needsDisplay(forKey key: String) -> Bool {
		if key == ArbitraryAnimationLayer.KeyPath {
			return true
		}
		return super.needsDisplay(forKey: key)
	}
}

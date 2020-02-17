//
//  DSFToggleButton.swift
//  DSFToggleButton
//
//  Created by Darren Ford on 16/2/20.
//  Copyright © 2020 Darren Ford. All rights reserved.
//

import Cocoa

final class WeakBox<A: AnyObject> {
    weak var unbox: A?
    init(_ value: A) {
        unbox = value
    }
}

struct WeakArray<Element: AnyObject> {
    private var items: [WeakBox<Element>] = []

    init(_ elements: [Element]) {
        items = elements.map { WeakBox($0) }
    }
}


extension WeakArray: Collection {
    var startIndex: Int { return items.startIndex }
    var endIndex: Int { return items.endIndex }

    subscript(_ index: Int) -> Element? {
        return items[index].unbox
    }

    func index(after idx: Int) -> Int {
        return items.index(after: idx)
    }

	mutating func add(_ element: Element) {
		items.append( WeakBox(element) )
	}

	mutating func remove(_ element: Element) {
		items = items.filter {
			guard let unboxed = $0.unbox else {
				return false
			}
			return unboxed !== element
		}
	}
}




@objc public protocol AccessibilityListener: class {
	@objc func accessibilityDisplayOptionsDidChange()
}

@objc public class Accessibility: NSObject {

	static var shared = Accessibility()

	var listeners = WeakArray<AccessibilityListener>([])

	func listen(_ listener: AccessibilityListener) {
		listeners.add(listener)
	}

	func unlisten( _ listener: AccessibilityListener) {
		listeners.remove(listener)
	}

	override init() {
		super.init()
		self.setup()
	}

	var isHighContrast: Bool {
		return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
	}

	var differentiateWithoutColor: Bool {
		return NSWorkspace.shared.accessibilityDisplayShouldDifferentiateWithoutColor
	}

	var reduceMotion: Bool {
		if #available(OSX 10.12, *) {
			return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
		} else {
			// Fallback on earlier versions
			return false
		}
	}

	func setup() {
		NSWorkspace.shared.notificationCenter.addObserver(
			self, selector: #selector(accessibilityDidChange(_:)),
			name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil)
	}

	@objc func accessibilityDidChange(_ notification: Notification) {
		self.listeners.forEach { listener in
			listener?.accessibilityDisplayOptionsDidChange()
		}
	}
}



class DSFToggleButtonCell: NSButtonCell {
	fileprivate var showLabels: Bool = false
	fileprivate var color: NSColor = .green
	fileprivate var xanimPos: CGFloat?

	override func drawFocusRingMask(withFrame cellFrame: NSRect, in controlView: NSView) {
		let newFrame = DSFToggleButtonCell.buttonDrawFrame(for: cellFrame)
		NSColor.controlColor.setFill()

		let radius = newFrame.height / 2.0
		let rectanglePath = NSBezierPath(roundedRect: newFrame, xRadius: radius, yRadius: radius)
		rectanglePath.fill()
	}

	override func drawBezel(withFrame _: NSRect, in _: NSView) {
		// Override to ignore the default drawing
	}

	static func buttonDrawFrame(for cellFrame: NSRect) -> NSRect {
		let newFrame: NSRect!
		let tHeight = cellFrame.width * (28.0 / 42.0)
		if tHeight > cellFrame.height {
			let ratioSmaller = cellFrame.height / tHeight
			newFrame = NSRect(x: 0, y: 0, width: cellFrame.width * ratioSmaller, height: cellFrame.height - 1)
		}
		else {
			newFrame = NSRect(x: 0, y: 0, width: cellFrame.width, height: tHeight - 1)
		}
		return newFrame
	}

	static func toggleStartEndPos(for cellFrame: NSRect) -> (left: CGFloat, right: CGFloat) {
		let newFrame = DSFToggleButtonCell.buttonDrawFrame(for: cellFrame)
		return (3.0, newFrame.width - newFrame.height + 2)
	}

	override func drawInterior(withFrame cellFrame: NSRect, in _: NSView) {
		//// General Declarations
		let context = NSGraphicsContext.current!.cgContext

		let highContrast = Accessibility.shared.isHighContrast
		let differentiateWithoutColor = Accessibility.shared.differentiateWithoutColor

		// Work out how we best fit

		let newFrame = DSFToggleButtonCell.buttonDrawFrame(for: cellFrame)

		//// Shadow Declarations
		let shadow = NSShadow()
		shadow.shadowColor = NSColor.black.withAlphaComponent(0.34)
		shadow.shadowOffset = NSSize(width: 1, height: -1)
		shadow.shadowBlurRadius = 4

		let backColor: NSColor = (self.state == .on) ? self.color : .underPageBackgroundColor
		let borderColor = Accessibility.shared.isHighContrast ? NSColor.textColor : NSColor.controlColor

		let width = newFrame.width - 2
		let height = newFrame.height - 1
		let radius = height / 2.0

		//// Rectangle Drawing
		let rectanglePath = NSBezierPath(roundedRect: NSRect(x: 1, y: 1, width: width, height: height), xRadius: radius, yRadius: radius)
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

			if self.state == .on {
				let xc = newFrame.width / 5.0 + 1
				let yc = height / 2.0
				let sz = height / 7

				let linepath = NSBezierPath(rect: NSRect(x: xc, y: yc - sz + 1, width: rectanglePath.lineWidth, height: sz * 2 + 1))
				linepath.fill()
			} else {
				let xc = newFrame.width / 4.0 * 3
				let yc = height / 2.0

				let sz = height / 8

				let ovalPath = NSBezierPath(ovalIn: NSRect(x: xc - 3, y: yc - sz + 1, width: sz * 2, height: sz * 2))
				ovalPath.lineWidth = 1.5
				ovalPath.stroke()
			}
		}

		let xpos: CGFloat = xanimPos ?? ((self.state == .on) ? width - height + 3.0 : 3.0)

		//// Oval Drawing
		let ovalPath = NSBezierPath(ovalIn: NSRect(x: xpos, y: 3.0, width: height - 4, height: height - 4))
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

@IBDesignable
public class DSFToggleButton: NSButton {

	private let defaultColor = NSColor(calibratedRed: 24.0 / 255.0, green: 218.0 / 255.0, blue: 99.0 / 255.0, alpha: 1.0)
	private var animLayer: ArbitraryAnimationLayer?

	@IBInspectable dynamic var showLabels: Bool = false {
		didSet {
			self.customCell?.showLabels = self.showLabels
			self.needsDisplay = true
		}
	}

	@IBInspectable dynamic var color: NSColor {
		didSet {
			self.customCell?.color = self.color
			self.needsDisplay = true
		}
	}

	override init(frame frameRect: NSRect) {
		self.color = self.defaultColor

		super.init(frame: frameRect)
		self.setup()
	}

	required init?(coder: NSCoder) {
		self.color = self.defaultColor

		super.init(coder: coder)
		self.setup()
	}

	override public var intrinsicContentSize: NSSize {
		return self.frame.size
	}

	deinit {
		Accessibility.shared.unlisten(self)
		self.cell?.unbind(.value)
	}

	func toggle() {
		self.state = (self.state == .on) ? .off : .on
	}

	// State capture/handling

	@objc override public var state: NSControl.StateValue {
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
		}
	}

	// Interface builder and draw

	private var customCell: DSFToggleButtonCell? {
		return self.cell as? DSFToggleButtonCell
	}

	override public func prepareForInterfaceBuilder() {
		super.prepareForInterfaceBuilder()

		self.setup()
	}

	override public func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		// Drawing code here.
	}
}

extension DSFToggleButton: AccessibilityListener {
	public func accessibilityDisplayOptionsDidChange() {
		self.needsDisplay = true
	}
}

private extension DSFToggleButton {
	func setup() {
		self.wantsLayer = true

		let cell = DSFToggleButtonCell()
		cell.color = self.color
		self.cell = cell
		self.setButtonType(.toggle)

		self.setContentHuggingPriority(.required, for: .horizontal)
		self.setContentHuggingPriority(.required, for: .vertical)

		self.setContentCompressionResistancePriority(.required, for: .horizontal)
		self.setContentCompressionResistancePriority(.required, for: .vertical)

		// Listen to bindings changes (via the UI)
		cell.bind(.value, to: self, withKeyPath: "internalButtonState", options: nil)

		Accessibility.shared.listen(self)
	}
}

private extension DSFToggleButton {
	func animate(on: Bool) {

		let startEndPos = DSFToggleButtonCell.toggleStartEndPos(for: self.frame)

		if Accessibility.shared.reduceMotion {
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
		anim.duration = 0.2
		anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
		anim.isRemovedOnCompletion = true

		alayer.progressCallback = { [weak self] progress in
			self?.customCell?.xanimPos = progress
			self?.needsDisplay = true
		}
		alayer.add(anim, forKey: "change")
	}
}

/// A simple layer class to expose an animation progress for a CAAnimation.
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
}

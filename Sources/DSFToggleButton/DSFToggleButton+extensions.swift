//
//  DSFToggleButton+extensions.swift
//
//  Internal class extensions needed for DSFToggleButton
//  Created by Darren Ford on 11/8/20.
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

internal extension BinaryFloatingPoint {
	/// Round a floating point value to the nearest 0.5
	func toNP5() -> Self {
		var result = self.rounded(.towardZero)
		let diff = self - result
		if diff > 0.5 {
			result += self > 0 ? 0.5 : -0.5
		}
		return result
	}
}

internal extension NSRect {
	/// Return a tweaked rect where all edges sit on a multiple of 0.5
	func toNP5() -> CGRect {
		return CGRect(
			x: self.origin.x.toNP5(),
			y: self.origin.y.toNP5(),
			width: self.size.width.toNP5(),
			height: self.size.height.toNP5()
		)
	}
}

// MARK: - NSColor extension

internal extension NSColor {
	/// Returns a black or white contrasting color for this color
	/// - Parameter defaultColor: If the color cannot be converted to the genericRGB colorspace, or the input color is .clear, the fallback color
	/// - Returns: black or white depending on which provides the greatest contrast to this color
	func flatContrastColor(defaultColor: NSColor = .textColor) -> NSColor {
		guard self != .clear, let rgba = RGBAColor(self) else {
			return defaultColor
		}

		// Counting the perceptive luminance - human eye favors green color...
		let avgGray: CGFloat = 1 - (0.299 * rgba.R + 0.587 * rgba.G + 0.114 * rgba.B)
		return avgGray > 0.45 ? .white : .black
	}

	/// A simple struct to help with conversions of colors to RGBA colorspace
	private struct RGBAColor {
		let R: CGFloat
		let G: CGFloat
		let B: CGFloat
		let A: CGFloat
		let rgbaColor: NSColor

		init?(_ color: NSColor) {
			guard let c = color.usingColorSpace(.deviceRGB) else { return nil }
			self.R = c.redComponent
			self.G = c.greenComponent
			self.B = c.blueComponent
			self.A = c.alphaComponent
			self.rgbaColor = c
		}
	}

	/// Returns a color that is the result of THIS color applied on top of `backgroundColor`
	/// taking into account transparencies
	///
	/// [Wikipedia Entry defining the algorithm](https://en.wikipedia.org/wiki/Alpha_compositing)
	///   (Refer to the section "Analytical derivation of the over operator" for derivation of these formulas)
	///
	/// [Stack Overflow implementation here](https://stackoverflow.com/questions/726549/algorithm-for-additive-color-mixing-for-rgb-values)
	func applyOnTopOf(_ backgroundColor: NSColor) -> NSColor {
		guard let fg = RGBAColor(self), let bg = RGBAColor(backgroundColor) else {
			return self
		}

		let rA: CGFloat = 1 - (1 - fg.A) * (1 - bg.A)
		if rA < 1.0e-6 {
			return .clear // Fully transparent -- R,G,B not important
		}

		let rR: CGFloat = fg.R * fg.A / rA + bg.R * bg.A * (1 - fg.A) / rA
		let rG: CGFloat = fg.G * fg.A / rA + bg.G * bg.A * (1 - fg.A) / rA
		let rB: CGFloat = fg.B * fg.A / rA + bg.B * bg.A * (1 - fg.A) / rA

		return NSColor(calibratedRed: rR, green: rG, blue: rB, alpha: rA)
	}

	/// Returns an inverted version this color, optionally preserving the colorspace from the original color if possible
	func inverted(preserveColorSpace: Bool = false) -> NSColor {
		guard let rgbColor = RGBAColor(self) else {
			return self
		}
		let inverted = NSColor(
			calibratedRed: 1.0 - rgbColor.R,
			green: 1.0 - rgbColor.G,
			blue: 1.0 - rgbColor.B,
			alpha: rgbColor.A
		)
		if preserveColorSpace, let c2 = inverted.usingColorSpace(self.colorSpace) {
			return c2
		}
		return inverted
	}
}

/// Perform an immediate `transform` of a given `subject`. The `transform`
/// function may just mutate the given `subject`, or replace it entirely.
///
/// ```
/// let oneAndTwo = mutate([1]) {
///     $0.append(2)
/// }
/// ```
///
/// - Parameters:
///     - subject: The subject to transform.
///     - transform: The transformation to perform.
///
/// - Throws: Any error that was thrown inside `transform`.
///
/// - Returns: A transformed `subject`.
@discardableResult
@inlinable internal func with<T>(_ subject: T, _ transform: (_ subject: inout T) throws -> Void) rethrows -> T {
	var subject = subject
	try transform(&subject)
	return subject
}

#endif

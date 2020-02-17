# DSFToggleButton

![](https://github.com/dagronf/dagronf.github.io/raw/master/art/projects/DSFToggleButton/primary.png)

A macOS toggle button that mimics the toggle button of iOS. Inherits from `NSButton`.  Configurable via code and Interface Builder.

![](https://img.shields.io/github/v/tag/dagronf/DSFToggleButton) ![](https://img.shields.io/badge/macOS-10.11+-red) ![](https://img.shields.io/badge/Swift-5.0-orange.svg)
![](https://img.shields.io/badge/License-MIT-lightgrey) [![](https://img.shields.io/badge/pod-compatible-informational)](https://cocoapods.org) [![](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)

# Usage

Since `DSFToggleButton` inherits from `NSButton`, its behaviour is the same as for a regular checkbox. You can programatically set the state as you would for an `NSButton` for example.

## Direct

Copy `DSFToggleButton.swift` and `DSFAccessibility.swift` into your project.

## Cocoapods

Add 

`pod 'DSFToggleButton', :git => 'https://github.com/dagronf/DSFToggleButton'`

to your podfile.

## Interface builder

* Drop in a new custom view into your canvas and set its class to `DSFToggleButton`

# Configuration

| Variable  | Type    | Description                                                                       |
|-----------|---------|-----------------------------------------------------------------------------------|
| `showLabel` | `Bool`    | Show labels (0 and 1) on the button to increase visual distinction between states |
| `color`     | `NSColor` | The color of the button when the state is on, defaults to the off background color |

# Screenshots

### Dark mode, green (no labels)

![](https://github.com/dagronf/dagronf.github.io/raw/master/art/projects/DSFToggleButton/green_toggle.gif)

### Dark mode, blue with labels

![](https://github.com/dagronf/dagronf.github.io/raw/master/art/projects/DSFToggleButton/blue_toggle_labels.gif)

### Light mode with labels, high contrast

![](https://github.com/dagronf/dagronf.github.io/raw/master/art/projects/DSFToggleButton/gray_toggle_high_contrast.gif)


# License

```
MIT License

Copyright (c) 2020 Darren Ford

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
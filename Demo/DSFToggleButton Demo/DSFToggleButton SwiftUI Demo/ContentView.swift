//
//  ContentView.swift
//  DSFToggleButton SwiftUI Demo
//
//  Created by Darren Ford on 11/1/21.
//  Copyright © 2021 Darren Ford. All rights reserved.
//

import SwiftUI

import DSFToggleButton

struct ContentView: View {

	@State var state: NSControl.StateValue = .on

	@State var isEnabled: NSControl.StateValue = .on

    var body: some View {
		VStack {
			DSFToggleButton.SwiftUI(
				state: $state,
				isEnabled: self.isEnabled == .on,
				controlColor: NSColor.systemIndigo.cgColor,
				action: { state in
					// Called in response to the user changing the value
					Swift.print("ACTION: \(state)")
				},
				stateChanged: { state in
					// This gets called for EVERY change, regardless of whether its user or program initiated
					Swift.print("STATECHANGE: \(state)")
				})
				.frame(height: 40, alignment: .center)
				.padding()

			DSFToggleButton.SwiftUI(
				state: $isEnabled,
				controlColor: NSColor.systemGreen.cgColor
			)
			.frame(height: 80, alignment: .center)
			.padding()

			DSFToggleButton.SwiftUI(
				state: $isEnabled,
				controlColor: NSColor.systemYellow.cgColor,
				showLabels: false
			)
			.frame(height: 80, alignment: .center)
			.padding()

			Text("Hello, world!")
				.padding()

			Button("Toggle", action: {
				self.state = (self.state == .on) ? .off : .on
			})

			Button("info") {
				Swift.print("self.state = \(self.state)")
			}

			Spacer()
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

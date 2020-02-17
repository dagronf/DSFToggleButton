//
//  AppDelegate.m
//  DSFToggleButton Demo Objc
//
//  Created by Darren Ford on 18/2/20.
//  Copyright © 2020 Darren Ford. All rights reserved.
//

#import "AppDelegate.h"

#import "DSFToggleButton_Demo_Objc-Swift.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@property (weak) IBOutlet DSFToggleButton *red;
@property (weak) IBOutlet DSFToggleButton *green;
@property (weak) IBOutlet DSFToggleButton *blue;


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

- (IBAction)clickedAll:(DSFToggleButton *)sender {
	[_red setState:[sender state]];
	[_green setState:[sender state]];
	[_blue setState:[sender state]];
}

- (IBAction)toggle:(id)sender {
	[_red toggle];
	[_green toggle];
	[_blue toggle];

}
@end

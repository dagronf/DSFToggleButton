//
//  AppDelegate.m
//  DSFToggleButton Demo Objc
//
//  Created by Darren Ford on 18/2/20.
//  Copyright © 2020 Darren Ford. All rights reserved.
//

#import "AppDelegate.h"

@import DSFToggleButton;

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@property (weak) IBOutlet DSFToggleButton *red;
@property (weak) IBOutlet DSFToggleButton *green;
@property (weak) IBOutlet DSFToggleButton *blue;
@property (weak) IBOutlet DSFToggleButton *all;

@end

BOOL isAllChanging = NO;

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self configureListeners];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
	[_red setStateChangeBlock:nil];
	[_green setStateChangeBlock:nil];
	[_blue setStateChangeBlock:nil];
	[_all setStateChangeBlock:nil];
}

- (void)configureListeners {
	[_red setStateChangeBlock:^(DSFToggleButton * _Nonnull button) {
		NSLog(@"Red did change to state %ld", [button state]);
		[self updateAllButton];
	}];
	[_green setStateChangeBlock:^(DSFToggleButton * _Nonnull button) {
		NSLog(@"Green did change to state %ld", [button state]);
		[self updateAllButton];
	}];
	[_blue setStateChangeBlock:^(DSFToggleButton * _Nonnull button) {
		NSLog(@"Blue did change to state %ld", [button state]);
		[self updateAllButton];
	}];
	[_all setStateChangeBlock:^(DSFToggleButton * _Nonnull button) {
		NSLog(@"All did change to state %ld", [button state]);
	}];
}

- (void)updateAllButton {
	if ([_red state] == NSControlStateValueOn &&
		[_green state] == NSControlStateValueOn &&
		[_blue state] == NSControlStateValueOn) {
		[_all setState:NSControlStateValueOn];
	}
	else if ([_red state] == NSControlStateValueOff &&
		[_green state] == NSControlStateValueOff &&
		[_blue state] == NSControlStateValueOff) {
		[_all setState:NSControlStateValueOff];
	}
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

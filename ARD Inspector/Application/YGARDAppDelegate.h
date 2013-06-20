//
//  YGARDAppDelegate.h
//  ARD Inspector
//
//  Created by Yoann Gini on 19/06/13.
//  Copyright (c) 2013 Yoann Gini. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface YGARDAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *loginWindow;
@property (assign) IBOutlet NSSecureTextField *masterPassword;

@property (retain) NSDictionary *ardPreferences;
@property (retain) NSArray *internalObjectList;
@property (retain) IBOutlet NSArray *bindablePreferences;

@property (assign) IBOutlet NSOutlineView *outlineView;
@property (assign) IBOutlet NSTableView *tableView;

- (IBAction)loginWindowCancel:(id)sender;
- (IBAction)loginWindowOK:(id)sender;

@end

//
//  YGARDAppDelegate.m
//  ARD Inspector
//
//  Created by Yoann Gini on 19/06/13.
//  Copyright (c) 2013 Yoann Gini. All rights reserved.
//

#import "YGARDAppDelegate.h"

#import "YGARDPreferencesDecoder.h"

@interface YGARDAppDelegate () <NSWindowDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTableViewDelegate>
{
	BOOL _dontShowLoginWindow;
	NSMutableDictionary *_internalComputerDatabase;
	NSMutableDictionary *_internalListDatabase;
}

- (void)showLoginWindow;
- (void)loadARDPreferencesFromFile:(NSString*)filePath;
- (void)preparePreferencesForBinding;

- (void)reloadUI;

@end

@implementation YGARDAppDelegate

- (void)dealloc
{
	self.ardPreferences = nil;
	self.internalObjectList = nil;
	self.bindablePreferences = nil;
	[_internalComputerDatabase release];
	[_internalListDatabase release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	_internalComputerDatabase = [NSMutableDictionary new];
	_internalListDatabase = [NSMutableDictionary new];
	
	self.bindablePreferences = nil;
	[self showLoginWindow];
}

-(void)windowWillClose:(NSNotification *)notification
{
	_dontShowLoginWindow = YES;
	
}

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    [self.window makeKeyAndOrderFront:self];
	if (!_dontShowLoginWindow) {
		[self showLoginWindow];
	}
    return NO;
}

#pragma mark - ARD Hack

- (void)loadARDPreferencesFromFile:(NSString*)filePath
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
	
	self.ardPreferences = [YGARDPreferencesDecoder decodePreferences:dict
												  withMasterPassword:self.masterPassword.stringValue
															   error:NULL];
	
	if (self.ardPreferences)
	{
		[self preparePreferencesForBinding];
	}
	else
	{
		[self showLoginWindow];
	}
}

- (void)preparePreferencesForBinding
{
	[_internalComputerDatabase removeAllObjects];
	[_internalListDatabase removeAllObjects];
	
	NSMutableArray *finalObjectList = [NSMutableArray new];
	
	NSString *uuid = nil;
	NSDictionary *computerSecrets = nil;
	NSMutableDictionary *internalItem = nil;
	NSMutableDictionary *internalNeastedItem = nil;
	NSString *value = nil;
	
	NSMutableArray *internalItems = nil;
	
	
	
	NSArray *computerProperties = @[
								 @"OSVersion",
		 @"hardwareAddress",
		 @"machineSerialNumber",
		 @"networkAddress",
		 @"name",
		 @"hostname"];
	
	
	
	NSArray *secretProperties = @[
							   @"login",
		  @"password"];
	
	for (NSDictionary *ardComputer in [self.ardPreferences objectForKey:@"ComputerDatabase"]) {
		internalItem = [NSMutableDictionary new];
		uuid = [ardComputer objectForKey:@"uuid"];
		[internalItem setObject:uuid forKey:@"uuid"];
		[internalItem setObject:@"computer" forKey:@"internalType"];
		
		computerSecrets = [[self.ardPreferences objectForKey:@"accessCredentials"] objectForKey:uuid];
		
		for (NSString *property in computerProperties) {
			value = [ardComputer objectForKey:property];
			if (value) {
				[internalItem setObject:value forKey:property];
			}
		}
		
		for (NSString *property in secretProperties) {
			value = [computerSecrets objectForKey:property];
			if (value) {
				[internalItem setObject:value forKey:property];
			}
		}
		
		[_internalComputerDatabase setObject:internalItem forKey:uuid];
		[internalItem release];
	}
	
	
	
	
	internalItems = nil;
	
	for (NSDictionary *ardList in [self.ardPreferences objectForKey:@"ListDatabase"]) {
		internalItem = [NSMutableDictionary new];
		[internalItem setObject:@"list" forKey:@"internalType"];
		
		[internalItem setObject:[ardList objectForKey:@"listName"]
						 forKey:@"name"];
		
		[internalItem setObject:[ardList objectForKey:@"uuid"]
						 forKey:@"uuid"];
		
		internalItems = [NSMutableArray new];
		for (uuid in [ardList objectForKey:@"items"]) {
			[internalItems addObject:[_internalComputerDatabase objectForKey:uuid]];
		}
		
		[internalItem setObject:internalItems
						 forKey:@"items"];
		[internalItems release];
		
		[_internalListDatabase setObject:internalItem forKey:[ardList objectForKey:@"uuid"]];
		[internalItem release];
	}
	
	
	NSMutableDictionary *specialList = [NSMutableDictionary new];
	
	[specialList setObject:@"smartList"
					forKey:@"internalType"];
	
	[specialList setObject:NSLocalizedString(@"All computers", @"")
					forKey:@"name"];
	
	[specialList setObject:[[_internalComputerDatabase allValues] sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
		return [[obj1 objectForKey:@"name"] compare:[obj2 objectForKey:@"name"]];
	}]
					forKey:@"items"];
	
	[finalObjectList addObject:specialList];
	
	[specialList release];
	
	
	NSMutableDictionary *workingListDatabase = [_internalListDatabase mutableCopy];
	for (id ardObject in [self.ardPreferences objectForKey:@"ObjectList"]) {
		if ([ardObject isKindOfClass:[NSDictionary class]])
		{
			internalItem = [NSMutableDictionary new];
			
			[internalItem setObject:@"folder" forKey:@"internalType"];
			
			[internalItem setObject:[ardObject objectForKey:@"name"]
							 forKey:@"name"];
			
			[internalItem setObject:[ardObject objectForKey:@"state"]
							 forKey:@"state"];
			
			internalItems = [NSMutableArray new];
			for (uuid in [ardObject objectForKey:@"members"]) {
				internalNeastedItem = [workingListDatabase objectForKey:uuid];
				if (internalNeastedItem)
				{
					[internalItems addObject:internalNeastedItem];
					[workingListDatabase removeObjectForKey:uuid];
				}
				else
				{
					NSLog(@"Unable to find %@", ardObject);
				}
			}
			
			[internalItem setObject:internalItems forKey:@"members"];
			
			[internalItems release];
			
			[finalObjectList addObject:internalItem];
			[internalItem release];
		}
	}
	
	
	for (internalItem in [workingListDatabase allValues]) {
		[finalObjectList addObject:internalItem];
	}
	
	[workingListDatabase release];
	
	self.internalObjectList = finalObjectList;
	
	[finalObjectList release];
	
	[self reloadUI];
}

#pragma mark - Internal

- (void)showLoginWindow
{
	if (!self.loginWindow.isVisible) {
		[NSApp beginSheet:self.loginWindow
		   modalForWindow:self.window
			modalDelegate:self
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:NULL];
	}
	
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:self];
	
	if (NSOKButton == returnCode) {
		[self loadARDPreferencesFromFile:[@"~/Library/Preferences/com.apple.RemoteDesktop.plist" stringByExpandingTildeInPath]];
	}
	else
	{
		[self.window close];
	}
}

- (void)reloadUI
{
	[self.outlineView reloadData];
	[self.outlineView expandItem:nil expandChildren:YES];
}

#pragma mark - Actions

- (IBAction)loginWindowCancel:(id)sender {
	[NSApp endSheet:self.loginWindow returnCode:NSCancelButton];
}

- (IBAction)loginWindowOK:(id)sender {
	[NSApp endSheet:self.loginWindow returnCode:NSOKButton];
}

#pragma mark - NSOutlineView

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (!item) {
		return [self.internalObjectList count];
	}
	else
	{
		return [[item objectForKey:@"members"] count];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [[item objectForKey:@"internalType"] isEqualToString:@"folder"];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (!item) {
		return [self.internalObjectList objectAtIndex:index];
	}
	return [[item objectForKey:@"members"] objectAtIndex:index];
}

- (NSView*)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([[item objectForKey:@"internalType"] isEqualToString:@"folder"])
	{
		NSTableCellView *cell = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
        [cell.textField setStringValue:[item objectForKey:@"name"]];
        return cell;
	}
	else
	{
		NSTableCellView *cell = [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
        [cell.textField setStringValue:[item objectForKey:@"name"]];
		cell.imageView.image = [NSImage imageNamed:@"list-32.png"];
        return cell;
	}
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSIndexSet *indexSet = [self.outlineView selectedRowIndexes];
		
	[indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		NSDictionary *item = [self.outlineView itemAtRow:idx];
		NSMutableArray *items = [NSMutableArray new];
		if ([[item objectForKey:@"internalType"] isEqualToString:@"folder"]) {
			for (NSDictionary *list in [item objectForKey:@"members"]) {
				[items addObjectsFromArray:[list objectForKey:@"items"]];
			}
		}
		else
		{
			[items addObjectsFromArray:[item objectForKey:@"items"]];
		}
		
		self.bindablePreferences = items;
		[self.tableView reloadData];
		[items release];
	}];
}

@end

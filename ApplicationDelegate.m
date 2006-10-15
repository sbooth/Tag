/*
 *  $Id$
 *
 *  Copyright (C) 2005, 2006 Stephen F. Booth <me@sbooth.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "ApplicationDelegate.h"
#import "PreferencesController.h"
#import "AcknowledgmentsController.h"
#import "UppercaseStringValueTransformer.h"
#import "TagEditor.h"
#import "UpdateChecker.h"
#import "ServicesProvider.h"

@implementation ApplicationDelegate

+ (void)initialize
{
	NSValueTransformer			*transformer;
    	
	transformer = [[[UppercaseStringValueTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"UppercaseStringValueTransformer"];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"startupVersionCheck"]];
}

- (void) applicationWillFinishLaunching:(NSNotification *)aNotification
{
	[[TagEditor sharedEditor] showWindow:self];
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"startupVersionCheck"]) {
		[[UpdateChecker sharedController] checkForUpdate:NO];
	}
	
	// Register services
	[[NSApplication sharedApplication] setServicesProvider:[[ServicesProvider alloc] init]];
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *) sender
{
	return ([[TagEditor sharedEditor] applicationShouldTerminate] ? NSTerminateNow : NSTerminateCancel);
}

- (void) application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	TagEditor			*editor				= [TagEditor sharedEditor];
	NSEnumerator		*enumerator;
	NSString			*filename;
	BOOL				success				= YES;
	
	enumerator = [filenames objectEnumerator];
	while((filename = [enumerator nextObject])) {
		success &= [editor addFile:[filename stringByExpandingTildeInPath]];
	}

	[editor openFilesDrawerIfNeeded];
	
	[[NSApplication sharedApplication] replyToOpenOrPrint:(success ? NSApplicationDelegateReplySuccess : NSApplicationDelegateReplyFailure)];
}

- (BOOL) application:(NSApplication *)sender delegateHandlesKey:(NSString *)key
{	
	return [key isEqualToString:@"files"];
}

- (IBAction) showPreferences:(id)sender
{
	[[PreferencesController sharedPreferences] showWindow:self];
}

- (IBAction) showAcknowledgments:(id)sender
{
	[[AcknowledgmentsController sharedController] showWindow:self];
}

- (IBAction) performVersionCheck:(id)sender
{
	[[UpdateChecker sharedController] checkForUpdate:YES];	
}

- (unsigned)						countOfFiles							{ return [[TagEditor sharedEditor] countOfFiles]; }
- (KeyValueTaggedFile *)			objectInFilesAtIndex:(unsigned)idx		{ return [[TagEditor sharedEditor] objectInFilesAtIndex:idx]; }

@end

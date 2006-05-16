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

#import "RenameFilesSheet.h"

enum {
	kTitleButtonTag			= 0,
	kArtistButtonTag		= 1,
	kAlbumButtonTag			= 2,
	kYearButtonTag			= 3,
	kGenreButtonTag			= 4,
	kComposerButtonTag		= 5,
	kMCNButtonTag			= 6,
	kISRCButtonTag			= 7,
	kEncoderButtonTag		= 8,
	kCommentButtonTag		= 9,
	kCustomButtonTag		= 10,
	kTrackNumberButtonTag	= 11,
	kTrackTotalButtonTag	= 12,
	kDiscNumberButtonTag	= 13,
	kDiscTotalButtonTag		= 14,
	kCompilationButtonTag	= 15
};

@implementation RenameFilesSheet

- (id) init;
{
	if((self = [super init])) {
		if(NO == [NSBundle loadNibNamed:@"RenameFilesSheet" owner:self])  {
			@throw [NSException exceptionWithName:@"MissingResourceException" reason:NSLocalizedStringFromTable(@"Unable to find the resource \"RenameFilesSheet.nib\".", @"Errors", @"") userInfo:nil];
		}
		
		return self;
	}
	return nil;
}

- (void)										setDelegate:(id <RenameFilesSheetDelegateMethods>)delegate		{ _delegate = delegate; }
- (id <RenameFilesSheetDelegateMethods>)		delegate														{ return _delegate; }

- (void) showSheet
{
    [[NSApplication sharedApplication] beginSheet:_sheet modalForWindow:[_delegate windowForSheet] modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction) cancel:(id)sender
{
    [[NSApplication sharedApplication] endSheet:_sheet];
}

- (IBAction) rename:(id)sender
{
	NSString		*pattern	= [_pattern stringValue];
	NSMutableArray	*patterns	= nil;
	
	patterns = [[[[NSUserDefaults standardUserDefaults] arrayForKey:@"renameFilesPatterns"] mutableCopy] autorelease];
	if(NO == [patterns containsObject:pattern]) {
		[patterns insertObject:pattern atIndex:0];
		
		while(10 < [patterns count]) {
			[patterns removeLastObject];
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:patterns forKey:@"renameFilesPatterns"];
	}
	
	[_delegate renameFilesUsingPattern:pattern];
    [[NSApplication sharedApplication] endSheet:_sheet];
}

- (void) didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
	[self release];
}

- (IBAction) patternTokenButtonClicked:(id)sender
{
	NSString	*string			= nil;
	NSText		*fieldEditor;
	
	switch([(NSButton *)sender tag]) {
		case kTitleButtonTag:				string = @"{title}";			break;
		case kArtistButtonTag:				string = @"{artist}";			break;
		case kAlbumButtonTag:				string = @"{album}";			break;
		case kYearButtonTag:				string = @"{year}";				break;
		case kGenreButtonTag:				string = @"{genre}";			break;
		case kComposerButtonTag:			string = @"{composer}";			break;
		case kMCNButtonTag:					string = @"{MCN}";				break;
		case kISRCButtonTag:				string = @"{ISRC}";				break;
		case kEncoderButtonTag:				string = @"{encoder}";			break;
		case kCommentButtonTag:				string = @"{comment}";			break;
		case kCustomButtonTag:				string = @"{custom}";			break;
		case kTrackNumberButtonTag:			string = @"{trackNumber}";		break;
		case kTrackTotalButtonTag:			string = @"{trackTotal}";		break;
		case kDiscNumberButtonTag:			string = @"{discNumber}";		break;
		case kDiscTotalButtonTag:			string = @"{discTotal}";		break;
		case kCompilationButtonTag:			string = @"{compilation}";		break;
	}
	
	fieldEditor = [_pattern currentEditor];
	if(nil == fieldEditor) {
		[_pattern setStringValue:string];
	}
	else {
		if([_pattern textShouldBeginEditing:fieldEditor]) {
			[fieldEditor replaceCharactersInRange:[fieldEditor selectedRange] withString:string];
			[_pattern textShouldEndEditing:fieldEditor];
		}
	}
	
	[_renameButton setEnabled:YES];
}

- (void) controlTextDidChange:(NSNotification *)aNotification
{
	NSString *pattern = [_pattern stringValue];
	[_renameButton setEnabled:(nil != pattern && 0 != [pattern length])];
}

- (void) comboBoxSelectionDidChange:(NSNotification *)aNotification
{
	NSString	*pattern;
	
	[_pattern setObjectValue:[_pattern objectValueOfSelectedItem]];
	pattern = [_pattern stringValue];
	[_renameButton setEnabled:(nil != pattern && 0 != [pattern length])];
}

@end

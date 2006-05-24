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

#import "FileSelectionSheet.h"

@implementation FileSelectionSheet

- (id) init;
{
	if((self = [super init])) {
		if(NO == [NSBundle loadNibNamed:@"FileSelectionSheet" owner:self])  {
			@throw [NSException exceptionWithName:@"MissingResourceException" reason:NSLocalizedStringFromTable(@"Unable to find the resource \"FileSelectionSheet.nib\".", @"Errors", @"") userInfo:nil];
		}
	
		_files = nil;
		
		return self;
	}
	return nil;
}

- (void)									setDelegate:(id <FileSelectionSheetDelegateMethods>)delegate	{ _delegate = delegate; }
- (id <FileSelectionSheetDelegateMethods>)	delegate														{ return _delegate; }

- (void) showSheet
{
    [[NSApplication sharedApplication] beginSheet:_sheet modalForWindow:[_delegate windowForSheet] modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction) cancel:(id)sender
{
    [[NSApplication sharedApplication] endSheet:_sheet];
}

- (IBAction) ok:(id)sender
{	
	[_delegate copySelectedTagsToFiles:[_filesController selectedObjects]];	
    [[NSApplication sharedApplication] endSheet:_sheet];
}

- (void) didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

@end

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

#import "TagArrayController.h"

@implementation TagArrayController

- (void)										setDelegate:(id <TagArrayControllerDelegateMethods>)delegate	{ _delegate = delegate; }
- (id <TagArrayControllerDelegateMethods>)		delegate														{ return _delegate; }

- (void) objectDidBeginEditing:(id)editor
{
	NSDictionary	*dictionary;
	
	if(nil != _delegate) {
		dictionary		= [[self arrangedObjects] objectAtIndex:[self selectionIndex]];
		_previousTag	= [[[dictionary valueForKey:@"key"] uppercaseString] retain];
		_previousValue	= [[dictionary valueForKey:@"value"] retain];
	}

	[super objectDidBeginEditing:editor];
}

- (void) objectDidEndEditing:(id)editor
{
	NSDictionary	*dictionary;
	NSString		*tag, *value;
	
	if(nil != _delegate) {
		dictionary	= [[self arrangedObjects] objectAtIndex:[self selectionIndex]];
		tag			= [[dictionary valueForKey:@"key"] uppercaseString];
		value		= [dictionary valueForKey:@"value"];

		if([_previousTag isEqualToString:tag]) {
			[_delegate updateTag:tag withValue:_previousValue toValue:value];
		}
		else {
			[_delegate renameTag:_previousTag withValue:_previousValue toTag:tag];
		}

		[_previousTag release];
		[_previousValue release];
	}
	
	[super objectDidEndEditing:editor];
}

#pragma mark Drag and Drop

- (BOOL) tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	[pboard declareTypes:[NSArray arrayWithObject:@"org.sbooth.Tag.TagItem"] owner:self];
	[pboard setPropertyList:[[self arrangedObjects] objectsAtIndexes:rowIndexes] forType:@"org.sbooth.Tag.TagItem"];
	
	return YES;
}

@end

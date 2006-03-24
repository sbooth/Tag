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

#import "EditorWindow.h"
#import "TagEditor.h"

@implementation EditorWindow

- (IBAction)		performClose:(id)sender						{ [[TagEditor sharedEditor] performClose:sender]; }

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	switch([menuItem tag]) {
		case kCloseMenuItemTag:
			return (0 != [[TagEditor sharedEditor] countOfSelectedFiles]);
			break;
			
		default:
			return [super validateMenuItem:menuItem];
			break;
	}
}

- (void) awakeFromNib
{
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender 
{
    NSPasteboard		*pasteboard		= [sender draggingPasteboard];
	
    if([[pasteboard types] containsObject:NSFilenamesPboardType]) {
		return NSDragOperationCopy;
    }
	
    return NSDragOperationNone;
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender 
{
    NSPasteboard		*pasteboard		= [sender draggingPasteboard];
	TagEditor			*editor			= [TagEditor sharedEditor];
	BOOL				success			= YES;
	
	if([[pasteboard types] containsObject:NSFilenamesPboardType]) {
		NSEnumerator		*enumerator;
		NSString			*current;
		
		enumerator = [[pasteboard propertyListForType:NSFilenamesPboardType] objectEnumerator];
		while((current = [enumerator nextObject])) {
			success &= [editor addFile:current];
		}
	}
	else {
		success = NO;
	}
	
	[editor openFilesDrawerIfNeeded];
	
	return success;
}

@end

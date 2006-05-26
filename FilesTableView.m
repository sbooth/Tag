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

#import "FilesTableView.h"
#import "TagEditor.h"

@implementation FilesTableView

- (unsigned) draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return (isLocal ? NSDragOperationMove : NSDragOperationCopy);
}

- (IBAction) paste:(id)sender
{
	[[TagEditor sharedEditor] pasteTagsFromPasteboard];	
}

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	if(@selector(paste:) == [anItem action]) {
		return (0 < [self numberOfSelectedRows] && [[[NSPasteboard generalPasteboard] types] containsObject:@"org.sbooth.Tag.TagItem"]);
	}
	else {
		return [super validateUserInterfaceItem:anItem];
	}
}

@end

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

#import "TagTableView.h"
#import "TagEditor.h"

@implementation TagTableView

- (IBAction) cut:(id)sender
{
	[[TagEditor sharedEditor] cutSelectedTagsToPasteboard];	
}

- (IBAction) copy:(id)sender
{
	[[TagEditor sharedEditor] copySelectedTagsToPasteboard];	
}

- (IBAction) paste:(id)sender
{
	[[TagEditor sharedEditor] pasteTagsFromPasteboard];	
}

- (IBAction) delete:(id)sender
{
	[[TagEditor sharedEditor] deleteTag:sender];	
}

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	if(@selector(cut:) == [anItem action]) {
		return 0 < [self numberOfSelectedRows];
	}
	else if(@selector(copy:) == [anItem action]) {
		return 0 < [self numberOfSelectedRows];
	}
	else if(@selector(paste:) == [anItem action]) {
		return [[[NSPasteboard generalPasteboard] types] containsObject:@"org.sbooth.Tag.TagItem"];
	}
	else if(@selector(delete:) == [anItem action]) {
		return 0 < [self numberOfSelectedRows];
	}
	else {
		return [super validateUserInterfaceItem:anItem];
	}
}

@end

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

#import "CompilationButton.h"
#import "CompilationButtonCell.h"
#import "TagEditor.h"

@implementation CompilationButton

+ (Class) cellClass
{
	return [CompilationButtonCell class];
}

/*- (id) initWithCoder:(NSCoder *)decoder
{
	if((self = [super initWithCoder:decoder])) {
		[self setCell:[[[CompilationButtonCell alloc] initTextCell:[self title]] autorelease]];
		return self;
	}
	return nil;
}*/

- (void) awakeFromNib
{
	[self setButtonType:NSSwitchButton];
	[self setTitle:NSLocalizedStringFromTable(@"Part of a compilation", @"General", @"")];
	[self setFont:[NSFont fontWithName:@"LucidaGrande" size:13]];
	[self setAllowsMixedState:YES];
	[self bind:@"enabled" toObject:[TagEditor sharedEditor] withKeyPath:@"filesController.selectedObjects.@count" options:nil];
	[self bind:@"value" toObject:[TagEditor sharedEditor] withKeyPath:@"compilation" options:nil];
}

@end

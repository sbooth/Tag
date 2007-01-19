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

#import "FLACHelperFunctions.h"

void
truncateVorbisComments(FLAC__StreamMetadata *block)
{
	if(NO == FLAC__metadata_object_vorbiscomment_resize_comments(block, 0)) {
		@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Errors", @"") userInfo:nil];
	}
}

void
addVorbisComment(FLAC__StreamMetadata		*block,
				 NSString					*key,
				 NSString					*value)
{
	FLAC__StreamMetadata_VorbisComment_Entry	entry;
	FLAC__bool									result;
	
	result			= FLAC__metadata_object_vorbiscomment_entry_from_name_value_pair(&entry, [key cStringUsingEncoding:NSASCIIStringEncoding], [value UTF8String]);
	NSCAssert1(YES == result, NSLocalizedStringFromTable(@"The call to %@ failed.", @"Exceptions", @""), @"FLAC__metadata_object_vorbiscomment_entry_from_name_value_pair");	
	
	result = FLAC__metadata_object_vorbiscomment_append_comment(block, entry, NO);
	NSCAssert1(YES == result, NSLocalizedStringFromTable(@"The call to %@ failed.", @"Exceptions", @""), @"FLAC__metadata_object_vorbiscomment_append_comment");	
}

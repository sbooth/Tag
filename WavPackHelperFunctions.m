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

#import "WavPackHelperFunctions.h"

void
truncateAPEComments(WavpackContext *wpc)
{
	char							*tagName				= NULL;
	int								len, i;
		
	if(WavpackGetMode(wpc) & MODE_VALID_TAG) {
		for(i = 0; i < WavpackGetNumTagItems(wpc); ++i) {
			
			// Get the tag's name
			len			= WavpackGetTagItemIndexed(wpc, i, NULL, 0);
			tagName		= (char *)calloc(len + 1, sizeof(char));
			if(NULL == tagName) {
				@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Exceptions", @"") 
											 userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:errno], [NSString stringWithCString:strerror(errno) encoding:NSASCIIStringEncoding], nil] forKeys:[NSArray arrayWithObjects:@"errorCode", @"errorString", nil]]];
			}
			len			= WavpackGetTagItemIndexed(wpc, i, tagName, len + 1);
			
			if(0 == WavpackDeleteTagItem(wpc, tagName)) {
				free(tagName);
				@throw [NSException exceptionWithName:@"WavPackException" reason:NSLocalizedStringFromTable(@"Unable to delete WavPack tag.", @"Exceptions", @"") userInfo:nil];
			}

			--i;
						
			free(tagName);
		}
	}
}

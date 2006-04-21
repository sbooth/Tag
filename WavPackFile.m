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

#import "WavPackFile.h"
#import "WavPackHelperFunctions.h"

#include <WavPack/wputils.h>

@interface WavPackFile (Private)
- (void) parseFile;
@end

@implementation WavPackFile

/*+ (void) initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:8192] forKey:@"FLACPadding"]];
}*/

- (id) initWithFile:(NSString *)filename
{
	if((self = [super initWithFile:filename])) {
		[self parseFile];
		return self;
	}
	return nil;
}

- (void) parseFile
{
	char							error [80];
	char							*tagName				= NULL;
	char							*tagValue				= NULL;
    WavpackContext					*wpc					= NULL;
	NSString						*key, *value;
	int								len, i;
	NSMutableArray					*tagsArray;
	
	@try {
		if(NO == [[NSFileManager defaultManager] fileExistsAtPath:_filename]) {
			@throw [NSException exceptionWithName:@"IOException" reason:NSLocalizedStringFromTable(@"The file was not found.", @"Errors", @"") userInfo:nil];
		}

		wpc = WavpackOpenFileInput([_filename fileSystemRepresentation], error, OPEN_TAGS, 0);
		if(NULL == wpc) {
			@throw [NSException exceptionWithName:@"InvalidFileFormatException" reason:NSLocalizedStringFromTable(@"The file does not appear to be a valid WavPack file.", @"Errors", @"")
										 userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSString stringWithCString:error encoding:NSASCIIStringEncoding]] forKeys:[NSArray arrayWithObject:@"errorString"]]];
		}
	
		if(WavpackGetMode(wpc) & MODE_VALID_TAG) {
			
			tagsArray = [self mutableArrayValueForKey:@"tags"];
			
			for(i = 0; i < WavpackGetNumTagItems(wpc); ++i) {
				
				// Get the tag's name
				len			= WavpackGetTagItemIndexed(wpc, i, NULL, 0);
				tagName		= (char *)calloc(len + 1, sizeof(char));
				if(NULL == tagName) {
					@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Exceptions", @"") 
												 userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:errno], [NSString stringWithCString:strerror(errno) encoding:NSASCIIStringEncoding], nil] forKeys:[NSArray arrayWithObjects:@"errorCode", @"errorString", nil]]];
				}			
				len			= WavpackGetTagItemIndexed(wpc, i, tagName, len + 1);
				
				// Get the tag's value
				len			= WavpackGetTagItem(wpc, tagName, NULL, 0);
				tagValue	= (char *)calloc(len + 1, sizeof(char));
				if(NULL == tagValue) {
					free(tagName);
					@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Exceptions", @"") 
												 userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:errno], [NSString stringWithCString:strerror(errno) encoding:NSASCIIStringEncoding], nil] forKeys:[NSArray arrayWithObjects:@"errorCode", @"errorString", nil]]];
				}
				len			= WavpackGetTagItem(wpc, tagName, tagValue, len + 1);
				
				key			= [NSString stringWithCString:tagName encoding:NSASCIIStringEncoding];
				value		= [NSString stringWithUTF8String:tagValue];
				
				[tagsArray addObject:[NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:key, value, nil] forKeys:[NSArray arrayWithObjects:@"key", @"value", nil]]];
				
				free(tagName);
				free(tagValue);
			}
		}
	}

	@finally {
		WavpackCloseFile(wpc);
	}
}

- (void) save
{
	NSEnumerator						*enumerator			= nil;
	NSDictionary						*currentTag			= nil;
    WavpackContext						*wpc				= NULL;
	char								error [80];
	
	@try  {
		if(NO == [[NSFileManager defaultManager] fileExistsAtPath:_filename]) {
			@throw [NSException exceptionWithName:@"IOException" reason:NSLocalizedStringFromTable(@"The file was not found.", @"Errors", @"") userInfo:nil];
		}
		
		wpc = WavpackOpenFileInput([_filename fileSystemRepresentation], error, OPEN_EDIT_TAGS, 0);
		if(NULL == wpc) {
			@throw [NSException exceptionWithName:@"IOException" reason:NSLocalizedStringFromTable(@"Unable to open the file for writing.", @"Errors", @"") 
										 userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:[NSString stringWithCString:error encoding:NSASCIIStringEncoding]] forKeys:[NSArray arrayWithObject:@"errorString"]]];
		}
		
		// Delete existing comments
		truncateAPEComments(wpc);

		// Iterate through metadata
		enumerator = [_tags objectEnumerator];
		while((currentTag = [enumerator nextObject])) {
			WavpackAppendTagItem(wpc, [[currentTag valueForKey:@"key"] cStringUsingEncoding:NSASCIIStringEncoding], [[currentTag valueForKey:@"value"] UTF8String], strlen([[currentTag valueForKey:@"value"] UTF8String]));
		}
			
		if(0 == WavpackWriteTag(wpc)) {
			@throw [NSException exceptionWithName:@"IOException" reason:NSLocalizedStringFromTable(@"Unable to write to the output file.", @"Errors", @"") 
										 userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:[NSString stringWithCString:error encoding:NSASCIIStringEncoding]] forKeys:[NSArray arrayWithObject:@"errorString"]]];
		}
		
		[self updateChangeCount:NSChangeCleared];
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged:_filename];
	}
		
	@finally {
		// Ignore errors on close
		WavpackCloseFile(wpc);
	}
}

- (void) revert
{
	if(YES == [self dirty]) {
		[[self mutableArrayValueForKey:@"tags"] removeAllObjects];
		[self parseFile];
		[self updateChangeCount:NSChangeCleared];
	}
}

- (NSString *) customizeTag:(NSString *)tag
{
	NSString *customTag;
	
	customTag = [[NSUserDefaults standardUserDefaults] stringForKey:[NSString stringWithFormat:@"WavPackTag_%@", tag]];
	return (nil == customTag ? tag : customTag);
}

- (NSDictionary *) tagMapping
{
	NSArray *objects, *keys;
	
	objects = [NSArray arrayWithObjects:@"title", @"artist", @"album", @"year", @"genre", @"composer", @"MCN", @"ISRC", @"encoder", @"comment", @"trackNumber", @"trackTotal", @"discNumber", @"discTotal", @"compilation", @"custom", nil];
	keys	= [NSArray arrayWithObjects:[self customizeTag:@"TITLE"], [self customizeTag:@"ARTIST"], [self customizeTag:@"ALBUM"], [self customizeTag:@"YEAR"], [self customizeTag:@"GENRE"], [self customizeTag:@"COMPOSER"], [self customizeTag:@"MCN"], [self customizeTag:@"ISRC"], [self customizeTag:@"TOOL NAME"], [self customizeTag:@"COMMENT"], [self customizeTag:@"TRACK"], [self customizeTag:@"TRACKTOTAL"], [self customizeTag:@"DISCNUMBER"], [self customizeTag:@"DISCTOTAL"], [self customizeTag:@"COMPILATION"], [self customizeTag:@"_CUSTOM"], nil];
	
	return [[[NSDictionary dictionaryWithObjects:objects forKeys:keys] retain] autorelease];
}

- (NSString *) encoder								{ return [self valueForTag:[self customizeTag:@"TOOL NAME"]]; }
- (NSNumber *) trackNumber							{ return [NSNumber numberWithInt:[[self valueForTag:[self customizeTag:@"TRACK"]] intValue]]; }

- (void) setEncoder:(NSString *)value				{ [self setValue:value forTag:[self customizeTag:@"TOOL NAME"]]; }
- (void) setTrackNumber:(NSNumber *)value			{ [self setValue:[value stringValue] forTag:[self customizeTag:@"TRACK"]]; }

@end

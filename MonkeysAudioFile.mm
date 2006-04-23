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

#import "MonkeysAudioFile.h"
#import "FLACHelperFunctions.h"

#include <MAC/All.h>
#include <MAC/MACLib.h>
#include <MAC/APETag.h>
#include <MAC/CharacterHelper.h>

@interface MonkeysAudioFile (Private)
- (void) parseFile;
@end

@implementation MonkeysAudioFile

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
	str_utf16						*utf16chars				= NULL;
	str_utf8						*utf8chars				= NULL;
	CAPETag							*f						= NULL;
	CAPETagField					*tag					= NULL;	
	int								i						= 0;
	NSString						*key, *value;
	NSMutableArray					*tagsArray;
	
	
	if(NO == [[NSFileManager defaultManager] fileExistsAtPath:_filename]) {
		@throw [NSException exceptionWithName:@"IOException" reason:NSLocalizedStringFromTable(@"The file was not found.", @"Errors", @"") userInfo:nil];
	}

	@try {
		utf16chars = GetUTF16FromANSI([_filename fileSystemRepresentation]);
		if(NULL == utf16chars) {
			@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Errors", @"") userInfo:nil];
		}
		f = new CAPETag(utf16chars);
		if(NULL == f) {
			@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Errors", @"") userInfo:nil];
		}
		
		tagsArray	= [self mutableArrayValueForKey:@"tags"];

		for(;;) {
			tag = f->GetTagField(i);

			if(NULL == tag) {
				break;
			}
			
			if(tag->GetIsUTF8Text()) {
				
				utf8chars	= GetUTF8FromUTF16(tag->GetFieldName());
				if(NULL == utf8chars) {
					@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Errors", @"") userInfo:nil];
				}
				
				key			= [[NSString stringWithUTF8String:(const char *)utf8chars] uppercaseString];
				value		= [NSString stringWithUTF8String:tag->GetFieldValue()];
				
				[tagsArray addObject:[NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:key, value, nil] forKeys:[NSArray arrayWithObjects:@"key", @"value", nil]]];

				free(utf8chars);
			}
			
			++i;
		}

	}
	
	@finally {
		delete f;
		free(utf16chars);
	}	
}

- (void) save
{
	str_utf16						*utf16chars				= NULL;
	str_utf16						*fieldName				= NULL;
	CAPETag							*f						= NULL;
	int								result					= ERROR_SUCCESS;
	NSEnumerator					*enumerator				= nil;
	NSDictionary					*currentTag				= nil;
	
	
	@try {
		if(NO == [[NSFileManager defaultManager] fileExistsAtPath:_filename]) {
			@throw [NSException exceptionWithName:@"IOException" reason:NSLocalizedStringFromTable(@"The file was not found.", @"Errors", @"") userInfo:nil];
		}
		
		utf16chars = GetUTF16FromANSI([_filename fileSystemRepresentation]);
		if(NULL == utf16chars) {
			@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Errors", @"") userInfo:nil];
		}
		f = new CAPETag(utf16chars);
		if(NULL == f) {
			@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Errors", @"") userInfo:nil];
		}
		
		// Delete existing comments
		result = f->ClearFields();
		if(ERROR_SUCCESS != result) {
			@throw [NSException exceptionWithName:@"MACException" reason:NSLocalizedStringFromTable(@"MAC error (APETag::ClearFields)", @"Errors", @"") userInfo:nil];
		}
		
		// Iterate through metadata
		enumerator = [_tags objectEnumerator];
		while((currentTag = [enumerator nextObject])) {
			
			fieldName = GetUTF16FromUTF8((const str_utf8 *)[[currentTag valueForKey:@"key"] UTF8String]);
			if(NULL == fieldName) {
				@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Errors", @"") userInfo:nil];
			}
			
			result = f->SetFieldString(fieldName, [[currentTag valueForKey:@"value"] UTF8String], TRUE);			
			free(fieldName);
			if(ERROR_SUCCESS != result) {
				@throw [NSException exceptionWithName:@"MACException" reason:NSLocalizedStringFromTable(@"MAC error (APETag::SetFieldString)", @"Errors", @"") userInfo:nil];
			}			
		}
		
		// Write the new metadata to the file
		result = f->Save();
		if(ERROR_SUCCESS != result) {
			@throw [NSException exceptionWithName:@"MACException" reason:NSLocalizedStringFromTable(@"MAC error (APETag::Save)", @"Errors", @"") userInfo:nil];
		}
		
		[self updateChangeCount:NSChangeCleared];
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged:_filename];
	}

	@finally {
		delete f;
		free(utf16chars);
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
	
	customTag = [[NSUserDefaults standardUserDefaults] stringForKey:[NSString stringWithFormat:@"APETag_%@", tag]];
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

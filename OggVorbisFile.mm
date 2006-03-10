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

#import "OggVorbisFile.h"

#include <TagLib/vorbisfile.h>				// TagLib::Ogg::Vorbis::File
#include <TagLib/xiphcomment.h>				// TagLib::Ogg::XiphComment
#include <TagLib/tlist.h>					// TagLib::List

@interface OggVorbisFile (Private)
- (void) parseFile;
@end

@implementation OggVorbisFile

- (id) initWithFile:(NSString *)filename;
{
    if((self = [super initWithFile:filename])) {
		[self parseFile];
		return self;
    }
	
    return nil;
}

- (void) parseFile
{
	TagLib::Ogg::Vorbis::File				vorbisFile				([_filename fileSystemRepresentation]);
	TagLib::String							s;
	TagLib::Ogg::XiphComment				*xiphComment;
	NSMutableArray							*tagsArray;
	
	if(NO == [[NSFileManager defaultManager] fileExistsAtPath:_filename]) {
		@throw [NSException exceptionWithName:@"IOException" reason:NSLocalizedStringFromTable(@"The file was not found.", @"Errors", @"") userInfo:nil];
	}

	if(vorbisFile.isValid()) {
		tagsArray		= [self mutableArrayValueForKey:@"tags"];
		xiphComment		= vorbisFile.tag();
		
		if(NULL != xiphComment) {
			NSString									*key, *value;
			TagLib::Ogg::FieldListMap					fieldList	= xiphComment->fieldListMap();
			TagLib::Ogg::FieldListMap::ConstIterator	iterator;
			TagLib::StringList							values;
			TagLib::StringList::ConstIterator			valuesIterator;
			
			for(iterator = fieldList.begin(); iterator != fieldList.end(); ++iterator) {
				key			= [NSString stringWithUTF8String:(*iterator).first.toCString(true)];
				values		= (*iterator).second;
				
				for(valuesIterator = values.begin(); valuesIterator != values.end(); ++valuesIterator) {
					value = [NSString stringWithUTF8String:(*valuesIterator).toCString(true)];
					[tagsArray addObject:[NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:key, value, nil] forKeys:[NSArray arrayWithObjects:@"key", @"value", nil]]];
				}
			}
		}
	}
	else {
		@throw [NSException exceptionWithName:@"InvalidFileFormatException" reason:NSLocalizedStringFromTable(@"The file does not appear to be a valid Ogg Vorbis file.", @"Errors", @"") userInfo:nil];
	}
}

- (void) save
{
	TagLib::Ogg::Vorbis::File				vorbisFile				([_filename fileSystemRepresentation]);
	TagLib::String							s;
	TagLib::Ogg::XiphComment				*xiphComment			= NULL;
	NSEnumerator							*enumerator				= nil;
	NSDictionary							*currentTag				= nil;
	id										value					= nil;
	NSString								*stringValue			= nil;
	
	if(NO == [[NSFileManager defaultManager] fileExistsAtPath:_filename]) {
		@throw [NSException exceptionWithName:@"IOException" reason:NSLocalizedStringFromTable(@"The file was not found.", @"Errors", @"") userInfo:nil];
	}
		
	if(vorbisFile.isValid()) {
		
		xiphComment	= vorbisFile.tag();
		
		if(NULL != xiphComment) {
			TagLib::Ogg::FieldListMap					fieldList	= xiphComment->fieldListMap();
			TagLib::Ogg::FieldListMap::ConstIterator	iterator;
			
			// Delete existing comments
			for(iterator = fieldList.begin(); iterator != fieldList.end(); ++iterator) {
				xiphComment->removeField((*iterator).first);
			}
			
			// Iterate through metadata
			enumerator = [_tags objectEnumerator];
			while((currentTag = [enumerator nextObject])) {
				value			= [currentTag valueForKey:@"value"];
				stringValue		= ([value isKindOfClass:[NSString class]] ? (NSString *)value : ([value respondsToSelector:@selector(stringValue)] ? [value stringValue] : @""));
				
				xiphComment->addField(TagLib::String([[currentTag valueForKey:@"key"] UTF8String], TagLib::String::UTF8), TagLib::String([stringValue UTF8String], TagLib::String::UTF8), false);
			}
		}
		
		if(NO == vorbisFile.save()) {
			@throw [NSException exceptionWithName:@"OggVorbisException" reason:NSLocalizedStringFromTable(@"Ogg Vorbis error (vorbisFile.save())", @"Errors", @"") userInfo:nil];
		}

		[self updateChangeCount:NSChangeCleared];
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged:_filename];
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
	
	customTag = [[NSUserDefaults standardUserDefaults] stringForKey:[NSString stringWithFormat:@"OggVorbisTag_%@", tag]];
	return (nil == customTag ? tag : customTag);
}

- (NSDictionary *) tagMapping
{
	NSArray *objects, *keys;
	
	objects = [NSArray arrayWithObjects:@"title", @"artist", @"album", @"year", @"genre", @"composer", @"MCN", @"ISRC", @"encoder", @"comment", @"trackNumber", @"trackTotal", @"discNumber", @"discTotal", @"compilation", @"custom", nil];
	keys	= [NSArray arrayWithObjects:[self customizeTag:@"TITLE"], [self customizeTag:@"ARTIST"], [self customizeTag:@"ALBUM"], [self customizeTag:@"YEAR"], [self customizeTag:@"GENRE"], [self customizeTag:@"COMPOSER"], [self customizeTag:@"MCN"], [self customizeTag:@"ISRC"], [self customizeTag:@"ENCODER"], [self customizeTag:@"DESCRIPTION"], [self customizeTag:@"TRACKNUMBER"], [self customizeTag:@"TRACKTOTAL"], [self customizeTag:@"DISCNUMBER"], [self customizeTag:@"DISCTOTAL"], [self customizeTag:@"COMPILATION"], [self customizeTag:@"_CUSTOM"], nil];
	
	return [[[NSDictionary dictionaryWithObjects:objects forKeys:keys] retain] autorelease];
}

@end

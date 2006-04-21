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

#import "FLACFile.h"
#import "FLACHelperFunctions.h"

#include <FLAC/metadata.h>

@interface FLACFile (Private)
- (void) parseFile;
@end

@implementation FLACFile

+ (void) initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:8192] forKey:@"FLACPadding"]];
}

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
	FLAC__Metadata_Chain			*chain				= NULL;
	FLAC__Metadata_Iterator			*iterator			= NULL;
	FLAC__StreamMetadata			*block				= NULL;
	unsigned						i;
	NSString						*commentString, *key, *value;
	NSRange							range;
	NSMutableArray					*tagsArray;
	
	@try {
		if(NO == [[NSFileManager defaultManager] fileExistsAtPath:_filename]) {
			@throw [NSException exceptionWithName:@"IOException" reason:NSLocalizedStringFromTable(@"The file was not found.", @"Errors", @"") userInfo:nil];
		}

		chain = FLAC__metadata_chain_new();
		if(NULL == chain) {
			@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Errors", @"") userInfo:nil];
		}
		
		if(NO == FLAC__metadata_chain_read(chain, [_filename fileSystemRepresentation])) {
			switch(FLAC__metadata_chain_status(chain)) {
				case FLAC__METADATA_CHAIN_STATUS_NOT_A_FLAC_FILE:
					@throw [NSException exceptionWithName:@"InvalidFileFormatException" reason:NSLocalizedStringFromTable(@"The file does not appear to be a valid FLAC file.", @"Errors", @"") userInfo:nil];
					break;

				case FLAC__METADATA_CHAIN_STATUS_READ_ERROR:
				case FLAC__METADATA_CHAIN_STATUS_SEEK_ERROR:
				case FLAC__METADATA_CHAIN_STATUS_BAD_METADATA:
				case FLAC__METADATA_CHAIN_STATUS_ERROR_OPENING_FILE:
				default:
					@throw [NSException exceptionWithName:@"IOException" reason:NSLocalizedStringFromTable(@"An unknown error occurred.", @"Errors", @"") userInfo:nil];
					break;
			}
		}
		
		iterator = FLAC__metadata_iterator_new();
		if(NULL == iterator) {
			@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Errors", @"") userInfo:nil];
		}
		
		FLAC__metadata_iterator_init(iterator, chain);
	
		do {
			block = FLAC__metadata_iterator_get_block(iterator);
			if(NULL == block) {
				break;
			}
			
			switch(block->type) {					
				case FLAC__METADATA_TYPE_VORBIS_COMMENT:
					tagsArray	= [self mutableArrayValueForKey:@"tags"];

					for(i = 0; i < block->data.vorbis_comment.num_comments; ++i) {
						
						// Split the comment at '='
						commentString	= [NSString stringWithUTF8String:(const char *)block->data.vorbis_comment.comments[i].entry];
						range			= [commentString rangeOfString:@"=" options:NSLiteralSearch];
						
						// Sanity check (comments should be well-formed)
						if(NSNotFound != range.location && 0 != range.length) {
							key				= [commentString substringToIndex:range.location];
							value			= [commentString substringFromIndex:range.location + 1];

							[tagsArray addObject:[NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:key, value, nil] forKeys:[NSArray arrayWithObjects:@"key", @"value", nil]]];
						}							
					}					
					break;
					
				case FLAC__METADATA_TYPE_STREAMINFO:					break;
				case FLAC__METADATA_TYPE_PADDING:						break;
				case FLAC__METADATA_TYPE_APPLICATION:					break;
				case FLAC__METADATA_TYPE_SEEKTABLE:						break;
				case FLAC__METADATA_TYPE_CUESHEET:						break;
				case FLAC__METADATA_TYPE_UNDEFINED:						break;
			}
		} while(FLAC__metadata_iterator_next(iterator));
	}
	
	@finally {
		FLAC__metadata_iterator_delete(iterator);
		FLAC__metadata_chain_delete(chain);
	}
}

- (void) save
{
	FLAC__Metadata_Chain				*chain				= NULL;
	FLAC__Metadata_Iterator				*iterator			= NULL;
	FLAC__StreamMetadata				*block				= NULL;
	NSEnumerator						*enumerator			= nil;
	NSDictionary						*currentTag			= nil;
	int									paddingSize			= [[NSUserDefaults standardUserDefaults] integerForKey:@"FLACPadding"];
	FLAC__StreamMetadata				*paddingMetadata	= NULL;
		
	@try  {
		if(NO == [[NSFileManager defaultManager] fileExistsAtPath:_filename]) {
			@throw [NSException exceptionWithName:@"IOException" reason:NSLocalizedStringFromTable(@"The file was not found.", @"Errors", @"") userInfo:nil];
		}

		chain = FLAC__metadata_chain_new();
		if(NULL == chain) {
			@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Errors", @"") userInfo:nil];
		}
		
		if(NO == FLAC__metadata_chain_read(chain, [_filename fileSystemRepresentation])) {
			@throw [NSException exceptionWithName:@"IOException" reason:NSLocalizedStringFromTable(@"Unable to open the file for writing.", @"Errors", @"") userInfo:nil];
		}
		
		FLAC__metadata_chain_sort_padding(chain);

		iterator = FLAC__metadata_iterator_new();
		if(NULL == iterator) {
			@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Errors", @"") userInfo:nil];
		}
		
		FLAC__metadata_iterator_init(iterator, chain);
		
		// FLAC padding
		if(0 < paddingSize) {
			
			// Seek to the padding block if it exists (if it does it will be the last one)
			while(FLAC__METADATA_TYPE_PADDING != FLAC__metadata_iterator_get_block_type(iterator) && FLAC__metadata_iterator_next(iterator)) {
				; // Do nothing
			}

			// If there is already a padding block don't do anything
			// Ensuring it meets our minimum size would mean it would be re-written every save (by us) if the data size increases
			if(FLAC__METADATA_TYPE_PADDING != FLAC__metadata_iterator_get_block_type(iterator)) {
				
				paddingMetadata = FLAC__metadata_object_new(FLAC__METADATA_TYPE_PADDING);
				if(NULL == paddingMetadata) {
					@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Errors", @"") userInfo:nil];
				}
				
				paddingMetadata->length = paddingSize;
				
				if(NO == FLAC__metadata_iterator_insert_block_after(iterator, paddingMetadata)) {
					FLAC__metadata_object_delete(paddingMetadata);
					@throw [NSException exceptionWithName:@"FLACException" reason:NSLocalizedStringFromTable(@"FLAC error (FLAC__metadata_iterator_insert_block_after)", @"Errors", @"") userInfo:nil];
				}	
			}

			// Reset iterator
			FLAC__metadata_iterator_init(iterator, chain);
		}
		
		// Seek to the vorbis comment block if it exists
		while(FLAC__METADATA_TYPE_VORBIS_COMMENT != FLAC__metadata_iterator_get_block_type(iterator) && FLAC__metadata_iterator_next(iterator)) {
			; // Do nothing
		}
		
		// If there isn't a vorbis comment block add one
		if(FLAC__METADATA_TYPE_VORBIS_COMMENT != FLAC__metadata_iterator_get_block_type(iterator)) {

			// The padding block will be the last block if it exists; add the comment block before it
			if(FLAC__METADATA_TYPE_PADDING == FLAC__metadata_iterator_get_block_type(iterator)) {
				FLAC__metadata_iterator_prev(iterator);
			}
			
			block = FLAC__metadata_object_new(FLAC__METADATA_TYPE_VORBIS_COMMENT);
			if(NULL == block) {
				@throw [NSException exceptionWithName:@"MallocException" reason:NSLocalizedStringFromTable(@"Unable to allocate memory.", @"Errors", @"") userInfo:nil];
			}
			
			// Add our metadata
			if(NO == FLAC__metadata_iterator_insert_block_after(iterator, block)) {
				FLAC__metadata_object_delete(block);
				@throw [NSException exceptionWithName:@"FLACException" reason:NSLocalizedStringFromTable(@"FLAC error (FLAC__metadata_iterator_insert_block_after)", @"Errors", @"") userInfo:nil];
			}
		}
		else {
			block = FLAC__metadata_iterator_get_block(iterator);
		}
		
		// Delete existing comments
		truncateVorbisComments(block);
		
		// Iterate through metadata
		enumerator = [_tags objectEnumerator];
		while((currentTag = [enumerator nextObject])) {
			addVorbisComment(block, [currentTag valueForKey:@"key"], [currentTag valueForKey:@"value"]);
		}
		
		// Write the new metadata to the file
		if(NO == FLAC__metadata_chain_write(chain, YES, NO)) {
			@throw [NSException exceptionWithName:@"FLACException" reason:NSLocalizedStringFromTable(@"FLAC error (FLAC__metadata_chain_write)", @"Errors", @"") userInfo:nil];
		}

		[self updateChangeCount:NSChangeCleared];
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged:_filename];
	}

	@finally {
		FLAC__metadata_chain_delete(chain);
		FLAC__metadata_iterator_delete(iterator);
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
	
	customTag = [[NSUserDefaults standardUserDefaults] stringForKey:[NSString stringWithFormat:@"FLACTag_%@", tag]];
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

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

#import <Cocoa/Cocoa.h>

@interface KeyValueTaggedFile : NSObject
{
	NSMutableArray		*_tags;
	NSString			*_filename;
	NSString			*_displayName;
	int					_changeCount;
}

+ (KeyValueTaggedFile *) parseFile:(NSString *)filename;

- (id)				initWithFile:(NSString *)filename;

- (NSString *)		filename;
- (NSURL *)			fileURL;
- (NSString *)		displayName;

- (void)			save;
- (void)			revert;

- (BOOL)			dirty;
- (int)				changeCount;
- (void)			updateChangeCount:(NSDocumentChangeType)changeType;

- (NSString *)		valueForTag:(NSString *)tag;

- (void)			willChangeValueForTag:(NSString *)tag;
- (void)			didChangeValueForTag:(NSString *)tag;

- (void)			setValue:(NSString *)value forTag:(NSString *)tag;
- (void)			addValue:(NSString *)value forTag:(NSString *)tag;
- (void)			updateTag:(NSString *)tag withValue:(NSString *)currentValue toValue:(NSString *)newValue;
- (void)			renameTag:(NSString *)currentTag withValue:(NSString *)currentValue toTag:(NSString *)newTag;

- (void)			guessTagsUsingPattern:(NSString *)pattern;

- (NSString *)		customizeTag:(NSString *)tag;

- (NSDictionary *)	tagMapping;
- (NSString *)		tagForKey:(NSString *)key;

	// Accessors
- (NSString *) title;
- (NSString *) artist;
- (NSString *) album;
- (NSNumber *) year;
- (NSString *) genre;
- (NSString *) composer;
- (NSString *) MCN;
- (NSString *) ISRC;
- (NSString *) encoder;
- (NSString *) comment;
- (NSNumber *) trackNumber;
- (NSNumber *) trackTotal;
- (NSNumber *) discNumber;
- (NSNumber *) discTotal;
- (NSNumber *) compilation;
- (NSString *) custom;

	// Mutators
- (void) setArtist:(NSString *)value;
- (void) setTitle:(NSString *)value;
- (void) setAlbum:(NSString *)value;
- (void) setYear:(NSNumber *)value;
- (void) setGenre:(NSString *)value;
- (void) setComposer:(NSString *)value;
- (void) setMCN:(NSString *)value;
- (void) setISRC:(NSString *)value;
- (void) setEncoder:(NSString *)value;
- (void) setComment:(NSString *)value;
- (void) setTrackNumber:(NSNumber *)value;
- (void) setTrackTotal:(NSNumber *)value;
- (void) setDiscNumber:(NSNumber *)value;
- (void) setDiscTotal:(NSNumber *)value;
- (void) setCompilation:(NSNumber *)value;
- (void) setCustom:(NSString *)value;

@end

@interface KeyValueTaggedFile (ScriptingAdditions)

- (id) handleCloseScriptCommand:(NSCloseCommand *)command;
- (id) handleSaveScriptCommand:(NSScriptCommand *)command;

@end

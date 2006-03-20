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

#import "KeyValueTaggedFile.h"
#import "OggVorbisFile.h"
#import "FLACFile.h"
#import "MonkeysAudioFile.h"
#import "TagEditor.h"

@implementation KeyValueTaggedFile

+ (KeyValueTaggedFile *) parseFile:(NSString *)filename
{
	KeyValueTaggedFile		*result			= nil;
	NSString				*extension		= [filename pathExtension];
	
	if([extension isEqualToString:@"ogg"]) {
		result = [[OggVorbisFile alloc] initWithFile:filename];
	}
	else if([extension isEqualToString:@"flac"]) {
		result = [[FLACFile alloc] initWithFile:filename];
	}
	else if([extension isEqualToString:@"ape"] || [extension isEqualToString:@"apl"] || [extension isEqualToString:@"mac"]) {
		result = [[MonkeysAudioFile alloc] initWithFile:filename];
	}
	else {
		@throw [NSException exceptionWithName:@"FileFormatNotSupportedException" reason:NSLocalizedStringFromTable(@"The document does not appear to be a valid FLAC, Ogg Vorbis or Monkey's Audio file.", @"Errors", @"") userInfo:nil];
	}
	
	return [result autorelease];
}

- (id) initWithFile:(NSString *)filename;
{
    if((self = [super init])) {
		_tags			= [[NSMutableArray arrayWithCapacity:10] retain];
		_filename		= [filename retain];
		_displayName	= [[_filename lastPathComponent] retain];

		[self updateChangeCount:NSChangeCleared];
		
		return self;
    }
    return nil;
}

- (void) dealloc
{
	[[[TagEditor sharedEditor] undoManager] removeAllActionsWithTarget:self];

	[_tags release];
	[_filename release];
	[_displayName release];
	
	[super dealloc];
}

- (NSString *) valueForTag:(NSString *)tag
{
	NSEnumerator	*enumerator;
	NSDictionary	*current;
	
	enumerator = [_tags objectEnumerator];
	while((current = [enumerator nextObject])) {
		if(NSOrderedSame == [[current valueForKey:@"key"] caseInsensitiveCompare:tag]) {
			return [current valueForKey:@"value"];
		}
	}
	
	return nil;
}

- (void) willChangeValueForTag:(NSString *)tag
{
	TagEditor	*editor		= [TagEditor sharedEditor];
	NSString	*key		= [[self tagMapping] valueForKey:tag];
	
	[editor willChangeValueForKey:@"tags"];

	if(nil != key) {
		[editor willChangeValueForKey:key];
		[self willChangeValueForKey:key];
	}
}

- (void) didChangeValueForTag:(NSString *)tag
{
	TagEditor	*editor		= [TagEditor sharedEditor];
	NSString	*key		= [[self tagMapping] valueForKey:tag];

	if(nil != key) {
		[self didChangeValueForKey:key];
		[editor didChangeValueForKey:key];
	}

	[editor didChangeValueForKey:@"tags"];
}

- (void) setValue:(NSString *)value forTag:(NSString *)tag
{
	TagEditor				*editor;
	NSUndoManager			*undoManager;
	NSEnumerator			*enumerator;
	NSDictionary			*current;

	editor			= [TagEditor sharedEditor];
	undoManager		= [editor undoManager];
	tag				= [tag uppercaseString];
	enumerator		= [_tags objectEnumerator];	
	
	if([tag isEqualToString:@"_CUSTOM"]) {
		return;
	}
	
	while((current = [enumerator nextObject])) {
		if([[current valueForKey:@"key"] isEqualToString:tag]) {

			if([value isEqualToString:[current valueForKey:@"value"]]) {
				return;
			}
			
			[self willChangeValueForTag:tag];

			if(nil == value) {
				[[undoManager prepareWithInvocationTarget:self] addValue:[current valueForKey:@"value"] forTag:tag];
				[undoManager setActionName:NSLocalizedStringFromTable(([undoManager isUndoing] ? @"New Tag" : @"Delete Tag"), @"Actions", @"")];
				[_tags removeObject:current];
			}
			else {
				[[undoManager prepareWithInvocationTarget:self] updateTag:tag withValue:value toValue:[current valueForKey:@"value"]];
				[undoManager setActionName:NSLocalizedStringFromTable(@"Edit Tag", @"Actions", @"")];
				[current setValue:value forKey:@"value"];
			}
			
			[self didChangeValueForTag:tag];
			[self updateChangeCount:([undoManager isUndoing] ? NSChangeUndone : NSChangeDone)];

			return;
		}
	}
	
	// Tag not found, add it
	[self willChangeValueForTag:tag];
	[[undoManager prepareWithInvocationTarget:self] updateTag:tag withValue:value toValue:nil];
	[undoManager setActionName:NSLocalizedStringFromTable(([undoManager isUndoing] ? @"Delete Tag" : @"New Tag"), @"Actions", @"")];
	[_tags addObject:[NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:tag, value, nil] forKeys:[NSArray arrayWithObjects:@"key", @"value", nil]]];
	[self didChangeValueForTag:tag];
	
	[self updateChangeCount:([undoManager isUndoing] ? NSChangeUndone : NSChangeDone)];
}

- (void) addValue:(NSString *)value forTag:(NSString *)tag
{
	TagEditor				*editor;
	NSUndoManager			*undoManager;

	editor			= [TagEditor sharedEditor];
	undoManager		= [editor undoManager];
	tag				= [tag uppercaseString];

	[self willChangeValueForTag:tag];
	[[undoManager prepareWithInvocationTarget:self] updateTag:tag withValue:value toValue:nil];
	[undoManager setActionName:NSLocalizedStringFromTable(([undoManager isUndoing] ? @"Delete Tag" : @"New Tag"), @"Actions", @"")];
	[_tags addObject:[NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:tag, value, nil] forKeys:[NSArray arrayWithObjects:@"key", @"value", nil]]];
	[self didChangeValueForTag:tag];

	[self updateChangeCount:([undoManager isUndoing] ? NSChangeUndone : NSChangeDone)];
}

- (void) updateTag:(NSString *)tag withValue:(NSString *)currentValue toValue:(NSString *)newValue
{
	TagEditor				*editor;
	NSUndoManager			*undoManager;
	NSEnumerator			*enumerator;
	NSMutableDictionary		*current;
	
	editor			= [TagEditor sharedEditor];
	undoManager		= [editor undoManager];
	tag				= [tag uppercaseString];
	enumerator		= [_tags objectEnumerator];	

	if([newValue isEqualToString:currentValue]) {
		return;
	}
	
	while((current = [enumerator nextObject])) {
		if([[current valueForKey:@"key"] isEqualToString:tag] && [[current valueForKey:@"value"] isEqualToString:currentValue]) {

			[self willChangeValueForTag:tag];
			
			if(nil == newValue) {
				[[undoManager prepareWithInvocationTarget:self] addValue:currentValue forTag:tag];
				[undoManager setActionName:NSLocalizedStringFromTable(([undoManager isUndoing] ? @"New Tag" : @"Delete Tag"), @"Actions", @"")];
				[_tags removeObject:current];
			}
			else {
				[[undoManager prepareWithInvocationTarget:self] updateTag:tag withValue:newValue toValue:currentValue];
				[undoManager setActionName:NSLocalizedStringFromTable(@"Edit Tag", @"Actions", @"")];
				[current setValue:newValue forKey:@"value"];
			}
			
			[self didChangeValueForTag:tag];			
			[self updateChangeCount:([undoManager isUndoing] ? NSChangeUndone : NSChangeDone)];

			return;
		}
	}
}

- (void) renameTag:(NSString *)currentTag withValue:(NSString *)currentValue toTag:(NSString *)newTag
{
	TagEditor				*editor;
	NSUndoManager			*undoManager;
	NSEnumerator			*enumerator;
	NSMutableDictionary		*current;
	
	editor			= [TagEditor sharedEditor];
	undoManager		= [editor undoManager];
	currentTag		= [currentTag uppercaseString];
	newTag			= [newTag uppercaseString];
	enumerator		= [_tags objectEnumerator];	

	if([newTag isEqualToString:currentTag] || [newTag isEqualToString:@"_CUSTOM"]) {
		return;
	}
	
	[[undoManager prepareWithInvocationTarget:self] renameTag:newTag withValue:currentValue toTag:currentTag];
	[undoManager setActionName:NSLocalizedStringFromTable(@"Rename Tag", @"Actions", @"")];

	// First remove the existing tag
	while((current = [enumerator nextObject])) {
		if([[current valueForKey:@"key"] isEqualToString:currentTag] && [[current valueForKey:@"value"] isEqualToString:currentValue]) {
			
			[self willChangeValueForTag:currentTag];
			[_tags removeObject:current];
			[self didChangeValueForTag:currentTag];
			
			break;
		}
	}
	
	// And then add the new one
	[self willChangeValueForTag:newTag];
	[_tags addObject:[NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newTag, currentValue, nil] forKeys:[NSArray arrayWithObjects:@"key", @"value", nil]]];
	[self didChangeValueForTag:newTag];
	
	[self updateChangeCount:([undoManager isUndoing] ? NSChangeUndone : NSChangeDone)];
}

- (void) updateChangeCount:(NSDocumentChangeType)changeType
{
	[self willChangeValueForKey:@"dirty"];
	switch(changeType) {
		case NSChangeDone:			_changeCount += 1;			break;
		case NSChangeUndone:		_changeCount -= 1;			break;
		case NSChangeCleared:		_changeCount = 0;			break;
		default:					;							break;
	}
	[self didChangeValueForKey:@"dirty"];
}

- (void) guessTagsUsingPattern:(NSString *)pattern
{
	NSArray					*patternPaths;
	NSString				*filename, *tagName;
	NSArray					*filenamePaths;
	NSScanner				*filenameScanner, *patternScanner;
	
	NSEnumerator			*filenameEnumerator;
	NSEnumerator			*patternEnumerator;
	
	NSString				*currentFilenameComponent;
	NSString				*currentPatternComponent;
	NSString				*patternToken, *patternTokenPrefix, *patternTokenSuffix;
	NSString				*filenameToken, *filenameTokenPrefix, *filenameTokenSuffix;
	
	NSCharacterSet			*emptyCharacterSet;
	
	BOOL					scanResult;
	
	
	filename				= [_filename stringByDeletingPathExtension];
	filenamePaths			= [filename pathComponents];
	filenameEnumerator		= [filenamePaths reverseObjectEnumerator];
	patternPaths			= [pattern pathComponents];
	patternEnumerator		= [patternPaths reverseObjectEnumerator];
	emptyCharacterSet		= [NSCharacterSet characterSetWithCharactersInString:@""];
	
	while((currentFilenameComponent = [filenameEnumerator nextObject]) && (currentPatternComponent = [patternEnumerator nextObject])) {
		
		filenameScanner = [NSScanner scannerWithString:currentFilenameComponent];
		patternScanner	= [NSScanner scannerWithString:currentPatternComponent];
		
		[patternScanner setCharactersToBeSkipped:emptyCharacterSet];
		
		// Attempt to match one single pattern token- consumes input matching ".*%{.*}.*"
		for(;;) {
			
			patternTokenPrefix	= nil;
			patternToken		= nil;
			patternTokenSuffix	= nil;
			
			// Get the token prefix, if present
			scanResult = [patternScanner scanUpToString:@"{" intoString:&patternTokenPrefix];
			
			// Consume token opener
			scanResult = [patternScanner scanString:@"{" intoString:nil];
			if(NO == scanResult) {
				// No token found
				break;
			}
			
			// Extract token name
			scanResult = [patternScanner scanUpToString:@"}" intoString:&patternToken];
			if(NO == scanResult) {
				// Empty token
				break;
			}
			
			// Consume token closer
			scanResult = [patternScanner scanString:@"}" intoString:nil];
			if(NO == scanResult) {
				// Missing token terminator
				break;
			}
			
			// Get the token suffix, if present
			scanResult = [patternScanner scanUpToString:@"{" intoString:&patternTokenSuffix];
			
			
			filenameTokenPrefix	= nil;
			filenameToken		= nil;
			filenameTokenSuffix	= nil;
			
			// If there is a prefix attempt to match it
			[filenameScanner setCharactersToBeSkipped:emptyCharacterSet];
			if(nil != patternTokenPrefix) {
				scanResult = [filenameScanner scanString:patternTokenPrefix intoString:&filenameTokenPrefix];
				if(NO == scanResult) {
					// Input doesn't match pattern
				}
			}
			
			// Extract the value
			[filenameScanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
			if(nil != patternTokenSuffix) {
				scanResult = [filenameScanner scanUpToString:patternTokenSuffix intoString:&filenameToken];
				if(NO == scanResult) {
					// No match found
				}
				
				// Consume suffix
				[filenameScanner setCharactersToBeSkipped:emptyCharacterSet];
				scanResult = [filenameScanner scanString:patternTokenSuffix intoString:nil];
				if(NO == scanResult) {
					// Suffix doesn't match
					break;
				}
				[filenameScanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
			}
			else {
				filenameToken = [[filenameScanner string] substringFromIndex:[filenameScanner scanLocation]];
			}
			
			tagName = [self tagForKey:patternToken];
			if(nil != tagName) {
				[self setValue:filenameToken forTag:tagName];
			}
			
			if([patternScanner isAtEnd] || [filenameScanner isAtEnd]) {
				break;
			}
		}
	}
}


- (NSString *) tagForKey:(NSString *)key
{
	NSArray *reverseMappedKeys = [[self tagMapping] allKeysForObject:key];
	
	if(0 < [reverseMappedKeys count]) {
		return [reverseMappedKeys objectAtIndex:0];
	}
	
	return nil;
}

- (void)			save								{}
- (void)			revert								{}
- (BOOL)			dirty								{ return (0 != _changeCount); }
- (int)				changeCount							{ return _changeCount; }
- (NSDictionary *)	tagMapping							{ return nil; }
- (NSString *)		customizeTag:(NSString *)tag		{ return tag; }

- (NSString *) title								{ return [self valueForTag:[self customizeTag:@"TITLE"]]; }
- (NSString *) artist								{ return [self valueForTag:[self customizeTag:@"ARTIST"]]; }
- (NSString *) album								{ return [self valueForTag:[self customizeTag:@"ALBUM"]]; }
- (NSNumber *) year									{ return [NSNumber numberWithInt:[[self valueForTag:[self customizeTag:@"YEAR"]] intValue]]; }
- (NSString *) genre								{ return [self valueForTag:[self customizeTag:@"GENRE"]]; }
- (NSString *) composer								{ return [self valueForTag:[self customizeTag:@"COMPOSER"]]; }
- (NSString *) MCN									{ return [self valueForTag:[self customizeTag:@"MCN"]]; }
- (NSString *) ISRC									{ return [self valueForTag:[self customizeTag:@"ISRC"]]; }
- (NSString *) encoder								{ return [self valueForTag:[self customizeTag:@"ENCODER"]]; }
- (NSString *) comment								{ return [self valueForTag:[self customizeTag:@"DESCRIPTION"]]; }
- (NSNumber *) trackNumber							{ return [NSNumber numberWithInt:[[self valueForTag:[self customizeTag:@"TRACKNUMBER"]] intValue]]; }
- (NSNumber *) trackTotal							{ return [NSNumber numberWithInt:[[self valueForTag:[self customizeTag:@"TRACKTOTAL"]] intValue]]; }
- (NSNumber *) discNumber							{ return [NSNumber numberWithInt:[[self valueForTag:[self customizeTag:@"DISCNUMBER"]] intValue]]; }
- (NSNumber *) discTotal							{ return [NSNumber numberWithInt:[[self valueForTag:[self customizeTag:@"DISCTOTAL"]] intValue]]; }
- (NSNumber *) compilation							{ return [NSNumber numberWithInt:[[self valueForTag:[self customizeTag:@"COMPILATION"]] intValue]]; }
- (NSString *) custom								{ return [self valueForTag:[self customizeTag:@"_CUSTOM"]]; }

- (void) setArtist:(NSString *)value				{ [self setValue:value forTag:[self customizeTag:@"ARTIST"]]; }
- (void) setTitle:(NSString *)value					{ [self setValue:value forTag:[self customizeTag:@"TITLE"]]; }
- (void) setAlbum:(NSString *)value					{ [self setValue:value forTag:[self customizeTag:@"ALBUM"]]; }
- (void) setYear:(NSNumber *)value					{ [self setValue:[value stringValue] forTag:[self customizeTag:@"YEAR"]]; }
- (void) setGenre:(NSString *)value					{ [self setValue:value forTag:[self customizeTag:@"GENRE"]]; }
- (void) setComposer:(NSString *)value				{ [self setValue:value forTag:[self customizeTag:@"COMPOSER"]]; }
- (void) setMCN:(NSString *)value					{ [self setValue:value forTag:[self customizeTag:@"MCN"]]; }
- (void) setISRC:(NSString *)value					{ [self setValue:value forTag:[self customizeTag:@"ISRC"]]; }
- (void) setEncoder:(NSString *)value				{ [self setValue:value forTag:[self customizeTag:@"ENCODER"]]; }
- (void) setComment:(NSString *)value				{ [self setValue:value forTag:[self customizeTag:@"DESCRIPTION"]]; }
- (void) setTrackNumber:(NSNumber *)value			{ [self setValue:[value stringValue] forTag:[self customizeTag:@"TRACKNUMBER"]]; }
- (void) setTrackTotal:(NSNumber *)value			{ [self setValue:[value stringValue] forTag:[self customizeTag:@"TRACKTOTAL"]]; }
- (void) setDiscNumber:(NSNumber *)value			{ [self setValue:[value stringValue] forTag:[self customizeTag:@"DISCNUMBER"]]; }
- (void) setDiscTotal:(NSNumber *)value				{ [self setValue:[value stringValue] forTag:[self customizeTag:@"DISCTOTAL"]]; }
- (void) setCompilation:(NSNumber *)value			{ [self setValue:[value stringValue] forTag:[self customizeTag:@"COMPILATION"]]; }
- (void) setCustom:(NSString *)value				{ [self setValue:value forTag:[self customizeTag:@"_CUSTOM"]]; }

- (NSString *) description							{ return [NSString stringWithFormat:@"%@:%@", _displayName, _tags]; }

@end

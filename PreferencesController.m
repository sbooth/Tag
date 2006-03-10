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

#import "PreferencesController.h"

static PreferencesController	*sharedPreferences					= nil;

@implementation PreferencesController

+ (void) initialize
{
	NSMutableDictionary		*initialValuesDictionary	= [NSMutableDictionary dictionaryWithCapacity:40];
	NSColor					*defaultColor				= [NSColor colorWithCalibratedRed:1.0 green:(250.0/255.0) blue:(178.0/255.0) alpha:1.0];
	
	
	[initialValuesDictionary setObject:[NSNumber numberWithBool:YES] forKey:@"startupVersionCheck"];
	[initialValuesDictionary setObject:[NSNumber numberWithInt:8192] forKey:@"FLACPadding"];
	[initialValuesDictionary setObject:[NSArchiver archivedDataWithRootObject:defaultColor] forKey:@"multipleValuesMarkerColor"];
	[initialValuesDictionary setObject:NSLocalizedStringFromTable(@"<Multiple Values>", @"General", @"") forKey:@"multipleValuesDescription"];
	
/*	[initialValuesDictionary setObject:nil forKey:@"FLACTag_TITLE"];
	[initialValuesDictionary setObject:nil forKey:@"FLACTag_ARTIST"];
	[initialValuesDictionary setObject:nil forKey:@"FLACTag_ALBUM"];
	[initialValuesDictionary setObject:nil forKey:@"FLACTag_YEAR"];
	[initialValuesDictionary setObject:nil forKey:@"FLACTag_GENRE"];
	[initialValuesDictionary setObject:nil forKey:@"FLACTag_COMPOSER"];
	[initialValuesDictionary setObject:nil forKey:@"FLACTag_MCN"];
	[initialValuesDictionary setObject:nil forKey:@"FLACTag_ISRC"];
	[initialValuesDictionary setObject:nil forKey:@"FLACTag_ENCODER"];
	[initialValuesDictionary setObject:nil forKey:@"FLACTag_DESCRIPTION"];
	[initialValuesDictionary setObject:nil forKey:@"FLACTag_TRACKNUMBER"];
	[initialValuesDictionary setObject:nil forKey:@"FLACTag_TRACKTOTAL"];
	[initialValuesDictionary setObject:nil forKey:@"FLACTag_DISCNUMBER"];
	[initialValuesDictionary setObject:nil forKey:@"FLACTag_DISCTOTAL"];
	[initialValuesDictionary setObject:nil forKey:@"FLACTag_COMPILATION"];
	[initialValuesDictionary setObject:nil forKey:@"FLACTag__CUSTOM"];

	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag_TITLE"];
	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag_ARTIST"];
	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag_ALBUM"];
	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag_YEAR"];
	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag_GENRE"];
	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag_COMPOSER"];
	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag_MCN"];
	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag_ISRC"];
	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag_ENCODER"];
	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag_DESCRIPTION"];
	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag_TRACKNUMBER"];
	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag_TRACKTOTAL"];
	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag_DISCNUMBER"];
	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag_DISCTOTAL"];
	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag_COMPILATION"];
	[initialValuesDictionary setObject:nil forKey:@"OggVorbisTag__CUSTOM"];*/
	
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDictionary];
}

+ (PreferencesController *) sharedPreferences
{
	@synchronized(self) {
		if(nil == sharedPreferences) {
			sharedPreferences = [[self alloc] init];
		}
	}
	return sharedPreferences;
}

+ (id) allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if(nil == sharedPreferences) {
            return [super allocWithZone:zone];
        }
    }
    return sharedPreferences;
}

- (id) init
{
	if((self = [super initWithWindowNibName:@"Preferences"])) {
		return self;
	}
	return nil;
}

- (id)				copyWithZone:(NSZone *)zone					{ return self; }
- (id)				retain										{ return self; }
- (unsigned)		retainCount									{ return UINT_MAX;  /* denotes an object that cannot be released */ }
- (void)			release										{ /* do nothing */ }
- (id)				autorelease									{ return self; }

- (void) windowDidLoad
{
	[self setShouldCascadeWindows:NO];
	[[self window] center];
}

- (IBAction) revertToInitialValues:(id)sender
{
	[[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:self];
}
@end

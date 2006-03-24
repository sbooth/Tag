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
#import "TagArrayControllerDelegateMethods.h"
#import "AddTagSheetDelegateMethods.h"
#import "GuessTagsSheetDelegateMethods.h"
#import "FileArrayController.h"
#import "TagArrayController.h"

enum {
	kSaveMenuItemTag				= 1,
	kRevertMenuItemTag				= 2,
	kOpenMenuItemTag				= 3,
	kToggleDrawerMenuItemTag		= 4,
	kSelectNextMenuItemTag			= 5,
	kSelectPreviousMenuItemTag		= 6,
	kCloseMenuItemTag				= 7,
	kSelectAllFilesMenuItemTag		= 8,
	kBasicTabMenuItemTag			= 9,
	kAdvancedTabMenuItemTag			= 10,
	kTabularTabMenuItemTag			= 11,
	kNewTagMenuItemTag				= 12,
	kDeleteTagMenuItemTag			= 13,
	kGuessTagsMenuItemTag			= 14,
	
	kSortByFilenameMenuItemTag		= 15,
	kSortByTitleMenuItemTag			= 16,
	kSortByArtistMenuItemTag		= 17,
	kSortByAlbumMenuItemTag			= 18,
	kSortByYearMenuItemTag			= 19,
	kSortByGenreMenuItemTag			= 20,
	kSortByComposerMenuItemTag		= 21,
	kSortByTrackNumberMenuItemTag	= 22,
	kSortByDiscNumberMenuItemTag	= 23
};

enum {
	kBasicTabViewItemIndex			= 0,
	kAdvancedTabViewItemIndex		= 1,
	kTabularTabViewItemIndex		= 2
};

@interface TagEditor : NSWindowController <TagArrayControllerDelegateMethods, AddTagSheetDelegateMethods, GuessTagsSheetDelegateMethods>
{
	NSArray							*_validKeys;
	NSMutableArray					*_files;
	
	IBOutlet FileArrayController	*_filesController;
	IBOutlet TagArrayController		*_tagsController;
	IBOutlet NSArrayController		*_selectedFilesController;

	IBOutlet NSDrawer				*_filesDrawer;
	IBOutlet NSTableView			*_tagsTable;
	IBOutlet NSTableView			*_tabularTagsTable;
	IBOutlet NSTabView				*_tabView;
	
	IBOutlet NSTextField			*_titleTextField;
	IBOutlet NSTextField			*_artistTextField;
	IBOutlet NSTextField			*_albumTextField;
	IBOutlet NSTextField			*_yearTextField;
	IBOutlet NSTextField			*_genreTextField;
	IBOutlet NSTextField			*_composerTextField;
	IBOutlet NSTextField			*_MCNTextField;
	IBOutlet NSTextField			*_ISRCTextField;
	IBOutlet NSTextField			*_encoderTextField;
	IBOutlet NSTextField			*_commentTextField;
	IBOutlet NSTextField			*_customTextField;
	IBOutlet NSTextField			*_trackNumberTextField;
	IBOutlet NSTextField			*_trackTotalTextField;
	IBOutlet NSTextField			*_discNumberTextField;
	IBOutlet NSTextField			*_discTotalTextField;
}

+ (TagEditor *)				sharedEditor;

- (IBAction)				selectBasicTab:(id)sender;
- (IBAction)				selectAdvancedTab:(id)sender;
- (IBAction)				selectTabularTab:(id)sender;

- (IBAction)				toggleFilesDrawer:(id)sender;
- (IBAction)				openFilesDrawer:(id)sender;
- (IBAction)				closeFilesDrawer:(id)sender;

- (IBAction)				openDocument:(id)sender;
- (IBAction)				saveDocument:(id)sender;
- (IBAction)				revertDocumentToSaved:(id)sender;
- (IBAction)				performClose:(id)sender;

- (IBAction)				selectNextFile:(id)sender;
- (IBAction)				selectPreviousFile:(id)sender;
- (IBAction)				selectAllFiles:(id)sender;
- (IBAction)				sortFiles:(id)sender;

- (unsigned)				countOfFiles;
- (unsigned)				countOfSelectedFiles;
- (KeyValueTaggedFile *)	objectInFilesAtIndex:(unsigned)index;

- (BOOL)					addFile:(NSString *)filename;
- (BOOL)					addFile:(NSString *)filename atIndex:(unsigned)index;

- (void)					openFilesDrawerIfNeeded;

- (IBAction)				newTag:(id)sender;
- (IBAction)				deleteTag:(id)sender;
- (IBAction)				guessTags:(id)sender;

- (void)					setValue:(NSString *)value forTag:(NSString *)tag;
- (void)					addValue:(NSString *)value forTag:(NSString *)tag;
- (void)					updateTag:(NSString *)tag withValue:(NSString *)currentValue toValue:(NSString *)newValue;
- (void)					renameTag:(NSString *)currentTag withValue:(NSString *)currentValue toTag:(NSString *)newTag;

- (void)					guessTagsUsingPattern:(NSString *)pattern;

- (BOOL)					applicationShouldTerminate;

- (BOOL)					dirty;
- (BOOL)					selectionDirty;

- (NSArray *)				genres;

@end

@interface TagEditor (ScriptingAdditions)

- (void)					saveFile:(KeyValueTaggedFile *)file;
- (void)					closeFile:(KeyValueTaggedFile *)file saveOptions:(NSSaveOptions)saveOptions;

@end

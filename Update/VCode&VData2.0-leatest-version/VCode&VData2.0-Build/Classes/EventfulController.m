//
//  EventfulController.m
//  VCode
//
//  Created by Joey Hagedorn on 9/16/07.
//  Updated and modified by Joshua Hailpern & Zhongnan Du on 12/7/2011
//  Copyright 2008 University of Illinois & Joey Hagedorn. All rights reserved.
//	This software is licensed under a BSD license. Please refer to the included
//  license file for more details.

#import "EventfulController.h"

#import "ColorCell.h"
#import "TimelineEventTrackView.h"
#import "TimelineView.h"
#import "TrackListView.h"

#import "CodingDocument.h"


@implementation EventfulController



//Color Stuff
- (void) awakeFromNib {
	NSTableColumn* column;
	ColorCell* colorCell;
	
	column = [[indexTable tableColumns] objectAtIndex: 2];
	colorCell = [[[ColorCell alloc] init] autorelease];
    [colorCell setEditable: YES];
	[colorCell setTarget: self];
	[colorCell setAction: @selector (colorClick:)];
	[column setDataCell: colorCell];
	
	//drag & drop
	[indexTable registerForDraggedTypes:[NSArray arrayWithObject:@"PrivateTrackIndexItemDataType"]];
}

#pragma mark Color Well Code

- (void) colorClick: (id) sender {    // sender is the table view
	NSColorPanel* panel;
	
	colorRow = [sender clickedRow];
    //geting the correct eventtrack
    item=[indexTable itemAtRow:colorRow];
    if ([item isKindOfClass:[EventTrack class]]) {
        //id parent=[indexTable parentForItem:item];
        //int realRow=colorRow-[indexTable rowForItem: parent];
        
        panel = [NSColorPanel sharedColorPanel];
        [panel setTarget: self];
        [panel setAction: @selector (colorChanged:)];
        [panel setColor: [(EventTrack*)item trackColor]];
        [panel makeKeyAndOrderFront: self];
    }
    
    
	
}

- (void) colorChanged: (id) sender {    // sender is the NSColorPanel
	[item setTrackColor:[sender color]];
	[indexTable reloadData];
	[indexCustomView setNeedsDisplay:YES];
	[timelineController updateTimeline];
}

//end color stuff

#pragma mark Add/Delete/Edit Events


- (IBAction) addEventNow:(id)sender{
    printf(@"what is the sender tag %d\n",[sender tag]);
	EventTrack *activeTrack;
	activeTrack = [[doc eventTracks] objectAtIndex:([sender tag]-1)];
	[self addEventToTrack:activeTrack];
	
	[indexCustomView setNeedsDisplay:YES];
	[timelineController updateTimeline];
}

- (IBAction) addEventNowWithComment:(id)sender{
	int trackArrayIndex;
	//verify it is a valid track
	//
	//Display dialog for adding comment, pause movie, etc
	
	[commentField setStringValue:@""];
	[NSApp beginSheet:commentSheet modalForWindow:docWindow
        modalDelegate:self didEndSelector:NULL contextInfo:nil];
	
	//save the button click info somewhere special, perhaps an instance variable. Also save "playing state".
	
	trackArrayIndex = (0-[sender tag])-1; //negative because tag was inverted


	//Save data to instance vars that needs to be saved across sheet instantiation.
	if([(QTMovie *)[doc movie] rate] > 0){
		wasPlaying = YES;
		[(QTMovie *)[doc movie] stop];
	}else{
		wasPlaying = NO;
	};
	trackIndex = trackArrayIndex;
	
	return;
}

//check if the sender was OK or Cancel
//if it was OK, do all the event stuff, if not just don't do anything
//if movie was playing; re-play it afterwards
- (IBAction) doneCommenting:(id)sender{
	EventTrack *activeTrack;
	//Hide the sheet
    [commentSheet orderOut:nil];
    [NSApp endSheet:commentSheet];	

	if(editingEvent == nil){
		if([sender tag]==NSOKButton){
			Event *newEvent;
			activeTrack = [[doc eventTracks] objectAtIndex:trackIndex];
			newEvent = [self addEventToTrack: activeTrack];
			
			if([commentField stringValue] != @""){
				if(newEvent != nil){
					[newEvent setComment:[commentField stringValue]];
				}
			}
			//disable comment button, change text to in/out
		}
	}else{//just editing an existing eventevent
		if([sender tag]==NSOKButton){
			if(editingEvent != nil){
				[editingEvent setComment:[commentField stringValue]];
			}
			//disable comment button, change text to in/out
		}
		editingEvent = nil;
	}
	
	
	if(wasPlaying){
		[(QTMovie *)[doc movie] play];
	}
	[indexCustomView setNeedsDisplay:YES];
	[timelineController updateTimeline];
	return;
}
- (IBAction) insertSpecialChar:(id)sender{
	NSText *textEditor = [commentField currentEditor];
	[textEditor replaceCharactersInRange:[textEditor selectedRange] 
							  withString:[[sender selectedCell] title]];
}

- (void) editEventComment:(Event *)evt{
	editingEvent = evt;
	//verify it is a valid track
	//
	//Display dialog for adding comment, pause movie, etc
	if([evt comment] != nil){
		[commentField setStringValue:[evt comment]];
	}else{
		[commentField setStringValue:@""];
	}

	[NSApp beginSheet:commentSheet modalForWindow:docWindow
        modalDelegate:self didEndSelector:NULL contextInfo:nil];

	//Save data to instance vars that needs to be saved across sheet instantiation.
	if([(QTMovie *)[doc movie] rate] > 0){
		wasPlaying = YES;
		[(QTMovie *)[doc movie] stop];
	}else{
		wasPlaying = NO;
	};
	return;
}



//returns event if it was added; otherwise returns nil.
- (Event *) addEventToTrack:(EventTrack *)activeTrack{
	NSArray * recordingEvents;
	Event *newEvent = Nil;
	unsigned long long now;
	now = [doc playheadTime];
	
	if([activeTrack eventAtTime:now] == nil){
	
		//Check if there is an event in activeTrack
		
		if(![activeTrack instantaneousMode]){  //IS a ranged track
			recordingEvents = [doc recordingEvents];
			if(![self array:recordingEvents containsEventOnTrack:activeTrack]){//This should check if there is no recording event on this track...
				//create new event and start recording
				newEvent = [[Event alloc] initInstantEventAtTime:now];
				[doc addRecordingEvent:newEvent];
				[activeTrack addEvent:newEvent];
			}else{
				for(int i=0; i<[recordingEvents count]; i++){
					if( [[activeTrack eventList] containsObject:[recordingEvents objectAtIndex:i]]){
						[doc removeRecordingEvent:[recordingEvents objectAtIndex:i]];//Stop recording
						break;
					}
				}
			}
		}else{//instantaneous event
			newEvent = [[Event alloc] initInstantEventAtTime:now];
			[activeTrack addEvent:newEvent];
		}
		[doc updateChangeCount:NSChangeDone];
	}else{
	//display alert sheet indicating an event couldn't be added	
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Mark could not be added."];
		[alert setInformativeText:@"An identical mark already exists."];
		[alert setAlertStyle:NSWarningAlertStyle];

		[alert runModal];
		[alert release];
		return nil;
	}
	return newEvent;
}

-(BOOL) array:(NSArray *)array containsEventOnTrack:(EventTrack *)aTrack{
	for(id evt in array){
		if ([[aTrack eventList] containsObject:evt]){
			return YES;
		}
	}
	return NO;
}

- (void) destroyEvent:(Event *)evt{
	
	
	[doc removeRecordingEvent:evt];
	
	for(int i=0; i<[[doc eventTracks] count]; i++){
		if([[[[doc eventTracks] objectAtIndex:i] eventList] containsObject:evt]){
			[[[doc eventTracks] objectAtIndex:i] removeEvent:evt];
		}
	}
	
	[timelineController updateTimeline];

}




#pragma mark Admin Window Table Glue Code 

 - (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
     NSArray *children =item==nil ? [doc eventTrackGroups] : [item Childrens];
     return [children count];
 
 }
 - (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
     if([item isKindOfClass:[EventTrackGroups class]]) {
         return YES;
     }
     else {
         return NO;
     }
 }
 
 - (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
     NSArray *children =item==nil ? [doc eventTrackGroups] : [item Childrens];
     return [children objectAtIndex:index];

 /*    if ([item isKindOfClass:[EventTrackGroups class]]) {
         return [[(EventTrackGroups *)item Childrens] objectAtIndex:index];
     }
     else return nil;
  */
 }
 
 
 - (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
     id result=nil;
     if([item isKindOfClass:[EventTrackGroups class]]) {
         if(tableColumn==nil || [[tableColumn identifier] isEqualToString:@"name"]) {
             result=[item folderName];
         }
         else if (tableColumn==nil || [[tableColumn identifier] isEqualToString:@"color"]) {
             result=[NSColor grayColor];
         }
         else if(tableColumn ==nil || [[tableColumn identifier] isEqualToString:@"range"]) {
             result=nil;
         }
         
     }
     else if ([item isKindOfClass:[EventTrack class]]) {
         if (tableColumn == nil || [[tableColumn identifier] isEqualToString:@"name"]) {
             result=[(EventTrack *)item name];
         }
         else if(tableColumn ==nil || [[tableColumn identifier] isEqualToString:@"key"]) {
             result=[(EventTrack *)item key];
         }
         else if(tableColumn ==nil || [[tableColumn identifier] isEqualToString:@"color"]) {
             result=[item trackColor];
         }
         else if(tableColumn ==nil || [[tableColumn identifier] isEqualToString:@"range"]) {
             if ([item instantaneousMode]) {
                 result= [NSNumber numberWithInt:NSOffState];
             }
             else result= [NSNumber numberWithInt:NSOnState];
         }
     }
     return result;
 }


- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if([item isKindOfClass:[EventTrackGroups class]]) {
        if([[tableColumn identifier] isEqualToString:@"name"]) {
            [item setfolderName:object]; 
        }
    }
    else if([item isKindOfClass:[EventTrack class]]) {
        if([[tableColumn identifier] isEqualToString:@"name"]) {
            [(EventTrack *)item setName:object];
        }
    }
    [indexCustomView setNeedsDisplay:YES];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return [item isKindOfClass:[EventTrackGroups class]];
}
// just returns the item for the right row
/*- (id)     tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex{  
	//log or something to figure out which table column?	
	if([[aTableColumn identifier] compare: @"name"]==NSOrderedSame){
		return [[[doc eventTracks]objectAtIndex:rowIndex] name];  
	}else if([[aTableColumn identifier] compare: @"key"]==NSOrderedSame){
		return [[[doc eventTracks]objectAtIndex:rowIndex] key];  
	}else if([[aTableColumn identifier] compare: @"color"]==NSOrderedSame){
		return [[[doc eventTracks] objectAtIndex:rowIndex] trackColor];
    }else if([[aTableColumn identifier] compare: @"range"]==NSOrderedSame){
		if([[[doc eventTracks] objectAtIndex:rowIndex] instantaneousMode]){
			return [NSNumber numberWithInt:NSOffState];
		}else{
			return [NSNumber numberWithInt:NSOnState];
		}
	}
	return nil;

}

// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView{
	return [[doc eventTracks] count];  
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	if([[aTableColumn identifier] compare: @"name"]==NSOrderedSame){
		[(EventTrack *)[[doc eventTracks]objectAtIndex:rowIndex] setName:anObject];
	}else if([[aTableColumn identifier] compare: @"key"]==NSOrderedSame){
		[[[doc eventTracks]objectAtIndex:rowIndex] setKey:anObject];
	}

	[indexCustomView setNeedsDisplay:YES];

}

//Drag and drop support for the table

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    // Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:@"PrivateTrackIndexItemDataType"] owner:self];
    [pboard setData:data forType:@"PrivateTrackIndexItemDataType"];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
	if(op== NSTableViewDropAbove){
		//Check to validate index, to see if we're moving to a valid row
		return NSDragOperationMove;
	}
	
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:@"PrivateTrackIndexItemDataType"];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    int dragRow = [rowIndexes firstIndex];

	if (row>dragRow){
		[doc moveEventTrackFromIndex:dragRow toIndex:row-1];
	}else{
		[doc moveEventTrackFromIndex:dragRow toIndex:row];

	}

	[indexCustomView setNeedsDisplay:YES];
	[timelineController updateTimeline];
	[indexTable reloadData];

	
	
	
    // Move the specified row to its new location...
	return YES;
}

*/


@end

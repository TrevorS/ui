// 13 may 2014

#include "objc_darwin.h"
#import <Foundation/NSDictionary.h>
#import <AppKit/NSArrayController.h>
#import <AppKit/NSTableColumn.h>

// see delegateuitask_darwin.m
// in this case, NSTableView.h includes NSApplication.h
#import <Foundation/NSIndexSet.h>

#ifdef MAC_OS_X_VERSION_10_7
#undef MAC_OS_X_VERSION_MIN_REQUIRED
#undef MAC_OS_X_VERSION_MAX_ALLOWED
#define MAC_OS_X_VERSION_MIN_REQUIRED MAC_OS_X_VERSION_10_7
#define MAC_OS_X_VERSION_MAX_ALLOWED MAC_OS_X_VERSION_10_7
#endif
#import <AppKit/NSApplication.h>
#undef MAC_OS_X_VERSION_MIN_REQUIRED
#undef MAC_OS_X_VERSION_MAX_ALLOWED
#define MAC_OS_X_VERSION_MIN_REQUIRED MAC_OS_X_VERSION_10_6
#define MAC_OS_X_VERSION_MAX_ALLOWED MAC_OS_X_VERSION_10_6

#import <AppKit/NSTableView.h>
#import <Foundation/NSIndexSet.h>

#define to(T, x) ((T *) (x))
#define toNSMutableDictionary(x) to(NSMutableDictionary, (x))
#define toNSArrayController(x) to(NSArrayController, (x))
#define toNSTableColumn(x) to(NSTableColumn, (x))
#define toNSTableView(x) to(NSTableView, (x))
#define toNSIndexSet(x) to(NSIndexSet, (x))

#define toNSInteger(x) ((NSInteger) (x))
#define fromNSInteger(x) ((intptr_t) (x))
#define toNSUInteger(x) ((NSUInteger) (x))
#define fromNSUInteger(x) ((uintptr_t) (x))

extern NSRect dummyRect;

id toListboxItem(id key, id value)
{
	return [NSMutableDictionary dictionaryWithObject:value forKey:key];
}

id fromListboxItem(id item, id key)
{
	return [toNSMutableDictionary(item) objectForKey:key];
}

id makeListboxArray(void)
{
	NSArrayController *ac;

	ac = [NSArrayController new];
	[ac setAutomaticallyRearrangesObjects:NO];
	// we don't want Cocoa to change the selection when items are inserted
	// found via http://stackoverflow.com/a/5765318/3408572; not sure how I missed it the first time
	[ac setSelectsInsertedObjects:NO];		// for insertions
	[ac setAvoidsEmptySelection:NO];		// for deletions
	return ac;
}

void listboxArrayAppend(id ac, id item)
{
	[toNSArrayController(ac) addObject:item];
}

void listboxArrayInsertBefore(id ac, id item, uintptr_t before)
{
	[toNSArrayController(ac) insertObject:item atArrangedObjectIndex:toNSUInteger(before)];
}

void listboxArrayDelete(id ac, uintptr_t index)
{
	[toNSArrayController(ac) removeObjectAtArrangedObjectIndex:toNSUInteger(index)];
}

id listboxArrayItemAt(id ac, uintptr_t index)
{
	NSArrayController *array;

	array = toNSArrayController(ac);
	return [[array arrangedObjects] objectAtIndex:toNSUInteger(index)];
}

void bindListboxArray(id tableColumn, id bindwhat, id ac, id keyPath)
{
	[toNSTableColumn(tableColumn) bind:bindwhat
		toObject:ac
		withKeyPath:keyPath
		options:nil];		// no options
}

id boundListboxArray(id tableColumn, id boundwhat)
{
	return [[toNSTableColumn(tableColumn) infoForBinding:boundwhat]
		objectForKey:NSObservedObjectKey];
}

id makeListboxTableColumn(id identifier)
{
	NSTableColumn *column;
	NSCell *dataCell;

	column = [[NSTableColumn alloc] initWithIdentifier:identifier];
	[column setEditable:NO];
	// to set the font for each item, we set the font of the "data cell", which is more aptly called the "cell template"
	dataCell = [column dataCell];
	// technically not a NSControl, but still accepts the selector, so we can call it anyway
	applyStandardControlFont(dataCell);
	[column setDataCell:dataCell];
	// TODO other properties?
	return column;
}

id listboxTableColumn(id listbox, id identifier)
{
	return [toNSTableView(listbox) tableColumnWithIdentifier:identifier];
}

id makeListbox(id tableColumn, BOOL multisel)
{
	NSTableView *listbox;

	listbox = [[NSTableView alloc]
		initWithFrame:dummyRect];
	[listbox addTableColumn:tableColumn];
	[listbox setAllowsMultipleSelection:multisel];
	[listbox setAllowsEmptySelection:YES];
	[listbox setHeaderView:nil];
	// TODO other prperties?
	return listbox;
}

id listboxSelectedRowIndexes(id listbox)
{
	return [toNSTableView(listbox) selectedRowIndexes];
}

uintptr_t listboxIndexesCount(id indexes)
{
	return fromNSUInteger([toNSIndexSet(indexes) count]);
}

uintptr_t listboxIndexesFirst(id indexes)
{
	return fromNSUInteger([toNSIndexSet(indexes) firstIndex]);
}

uintptr_t listboxIndexesNext(id indexes, uintptr_t prev)
{
	return fromNSUInteger([toNSIndexSet(indexes) indexGreaterThanIndex:toNSUInteger(prev)]);
}

intptr_t listboxLen(id listbox)
{
	return fromNSInteger([toNSTableView(listbox) numberOfRows]);
}

//
//  JEFAppController.m
//  Jeff
//
//  Created by Brandon Evans on 2014-10-08.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFPopoverContentViewController.h"
#import "INPopoverController.h"
#import "JEFAppController.h"

NSString *const JEFOpenPopoverNotification = @"JEFOpenPopoverNotification";
NSString *const JEFClosePopoverNotification = @"JEFClosePopoverNotification";
NSString *const JEFSetStatusViewNotRecordingNotification = @"JEFSetStatusViewNotRecordingNotification";
NSString *const JEFSetStatusViewRecordingNotification = @"JEFSetStatusViewRecordingNotification";
NSString *const JEFStopRecordingNotification = @"JEFStopRecordingNotification";
CGFloat const JEFPopoverVerticalOffset = -3.0;

@interface JEFAppController ()

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) INPopoverController *popover;
@property (strong, nonatomic) id popoverTransiencyMonitor;
@end

@implementation JEFAppController

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    [self setupStatusItem];
    [self setupPopover];

    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:JEFOpenPopoverNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
        [weakSelf showPopover:weakSelf.statusItem.button];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:JEFClosePopoverNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf closePopover:nil];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:JEFSetStatusViewNotRecordingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf setStatusItemActionRecord:NO];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:JEFSetStatusViewRecordingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf setStatusItemActionRecord:YES];
    }];
    return self;
}

- (void)setupStatusItem {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.button.image = [NSImage imageNamed:@"StatusItemTemplate"];
    self.statusItem.button.target = self;
    [self setStatusItemActionRecord:YES];
}

- (void)setupPopover {
    self.popover = [[INPopoverController alloc] init];
    JEFPopoverContentViewController *popoverController = [[NSStoryboard storyboardWithName:@"JEFPopoverStoryboard" bundle:nil] instantiateInitialController];
    self.popover.contentViewController = popoverController;
    self.popover.animates = NO;
    self.popover.closesWhenApplicationBecomesInactive = YES;
}

- (void)showPopover:(NSStatusBarButton *)sender {
    if (self.popover.popoverIsVisible) {
        [self closePopover:nil];
        return;
    }

    [self.popover presentPopoverFromRect:NSOffsetRect(sender.frame, 0, JEFPopoverVerticalOffset) inView:sender preferredArrowDirection:INPopoverArrowDirectionUp anchorsToPositionView:YES];

    if (!self.popoverTransiencyMonitor) {
        __weak __typeof(self) weakSelf = self;
        self.popoverTransiencyMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask|NSRightMouseDownMask handler:^(NSEvent* event) {
            [weakSelf closePopover:sender];
        }];
    }

    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)closePopover:(id)sender {
    if (self.popoverTransiencyMonitor) {
        [NSEvent removeMonitor:self.popoverTransiencyMonitor];
        self.popoverTransiencyMonitor = nil;
        [self.popover closePopover:nil];
    }
}

- (void)stopRecording:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFStopRecordingNotification object:nil];
}

- (void)setStatusItemActionRecord:(BOOL)record {
    if (record) {
        self.statusItem.button.image = [NSImage imageNamed:@"StatusItemTemplate"];
        self.statusItem.button.action = @selector(showPopover:);
    }
    else {
        self.statusItem.button.image = [NSImage imageNamed:NSImageNameStopProgressTemplate];
        self.statusItem.button.action = @selector(stopRecording:);
    }
}
@end
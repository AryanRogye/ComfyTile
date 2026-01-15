//
//  UserWindow.m
//  TestingAX_SkyLight
//
//  Created by Aryan Rogye on 1/13/26.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "UserWindow.h"


@implementation UserWindow

- (void) focusApp {
    NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:self.pid];
    [app activateWithOptions:NSApplicationActivateAllWindows];
}

@end

//
//  WindowFetcher.m
//  TestingAX_SkyLight
//
//  Created by Aryan Rogye on 1/12/26.
//

#import "WindowFetcher.h"
#import "WindowServerBridge.h"

@implementation WindowFetcher

+ (SCWindows _Nullable) getSCWindows {
    __block NSArray<SCWindow *> *windows = nil;
    __block NSError *err = nil;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    /// Set Windows Based off ScreenshotKit
    [SCShareableContent getShareableContentExcludingDesktopWindows:true onScreenWindowsOnly:false completionHandler:^(SCShareableContent *content, NSError *error) {
        
        /// Assign Values
        err = error;
        windows = content.windows;
        
        dispatch_semaphore_signal(sema);
    }];
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return windows;
}

static void RequireAccessibility(void) {
    NSDictionary *opts = @{ (__bridge NSString *)kAXTrustedCheckOptionPrompt : @YES };
    Boolean trusted = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)opts);
    if (!trusted) {
        NSLog(@"Need Accessibility permission. Enable it in System Settings > Privacy & Security > Accessibility, then re-run.");
        exit(1);
    }
}

+ (NSArray<UserWindow *> * _Nullable)getWindowsWithBridge:(WindowServerBridge *)bridge {
    
    if (!CGPreflightScreenCaptureAccess()) {
        BOOL ok = CGRequestScreenCaptureAccess();
        
        if (!ok) {
            NSLog(@"Please Accept Screen Recording Permissions");
            exit(1);
        }
    }
    
    RequireAccessibility();
    
    NSLog(@"Getting Windows");
    SCWindows windows = [WindowFetcher getSCWindows];
    
    if (windows == nil) {
        return nil;
    }
    
    NSLog(@"Got %lu Windows", windows.count);
    
    NSMutableArray<UserWindow *> *results = [NSMutableArray array];
    for (int i = 0; i < windows.count; i++) {
        
        /// Get SCWindow
        SCWindow *window = [windows objectAtIndexedSubscript:i];
        if (!window)
            continue;
        
        /// Get Running Application
        SCRunningApplication* app = window.owningApplication;
        
        if (!app ||
            window.windowLayer != 0 ||
            window.frame.size.width < 100)
            continue;
        
        /// Get Window
        NSArray<NSDictionary *> *windowInfo = (__bridge_transfer NSArray *)
        CGWindowListCopyWindowInfo(
                                   kCGWindowListOptionIncludingWindow,
                                   window.windowID);
        
        NSDictionary *firstWindow = windowInfo.firstObject;
        NSString* windowTitle = firstWindow[(id)kCGWindowName];
        NSNumber* pidNum = firstWindow[(id)kCGWindowOwnerPID];
        NSDictionary *boundsDict = firstWindow[(id)kCGWindowBounds];
        NSNumber *x = boundsDict[@"X"];
        NSNumber *y = boundsDict[@"Y"];
        NSNumber *width  = boundsDict[@"Width"];
        NSNumber *height = boundsDict[@"Height"];
        
        if (!windowTitle ||
            !pidNum ||
            !boundsDict ||
            !x ||
            !y ||
            !width ||
            !height
            ) {
            continue;
        }
        
        pid_t pid = (pid_t)pidNum.intValue;

        AXUIElementRef element = [bridge findMatchingAXWindowWithPid:pid targetWindowID:window.windowID];
        
        if (element) {
            NSLog(@"\e[1;32mFound Element For Window: %u, %@\e[0m", window.windowID, app);
        }
        
        UserWindow *uw = [UserWindow alloc];
        
        uw.title = windowTitle;
        uw.element = element;
        uw.window = window;
        uw.pid = pid;
        uw.bundleIdentifier = app.bundleIdentifier;
        
        [results addObject:uw];
    }
    
    return results;
}

@end

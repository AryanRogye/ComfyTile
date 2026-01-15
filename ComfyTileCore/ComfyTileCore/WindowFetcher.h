//
//  WindowFetcher.h
//  TestingAX_SkyLight
//
//  Created by Aryan Rogye on 1/12/26.
//

#ifndef WINDOW_FETCHER_H
#define WINDOW_FETCHER_H

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>
#import <ComfyTileCore/WindowServerBridge.h>
#import <ComfyTileCore/UserWindow.h>

# pragma mark SCWindows
typedef NSArray<SCWindow *> * SCWindows;


# pragma mark WindowFetcher
@interface WindowFetcher : NSObject

+ (NSArray<UserWindow *> * _Nullable)getWindowsWithBridge:(WindowServerBridge * _Nullable)bridge;

@end

#endif

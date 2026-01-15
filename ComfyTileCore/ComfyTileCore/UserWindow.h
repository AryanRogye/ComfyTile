//
//  UserWindow.h
//  TestingAX_SkyLight
//
//  Created by Aryan Rogye on 1/13/26.
//

#ifndef USER_WINDOW_H
#define USER_WINDOW_H

#import <ScreenCaptureKit/ScreenCaptureKit.h>

# pragma mark UserWindow
@interface UserWindow: NSObject
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *bundleIdentifier;
@property (nonatomic) pid_t pid;
@property (nonatomic, strong, nullable) SCWindow *window;
@property (nonatomic, assign, nullable) AXUIElementRef element; // just a raw ref

- (void)focusApp;
@end

#endif

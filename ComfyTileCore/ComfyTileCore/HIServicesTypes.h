//
//  HIServicesTypes.h
//  ComfyTileCore
//
//  Created by Aryan Rogye on 1/14/26.
//

#ifndef HI_SERVICES_TYPES_H
#define HI_SERVICES_TYPES_H

#import <CoreGraphics/CoreGraphics.h>

static const char *hiServicesPath = "/System/Library/Frameworks/ApplicationServices.framework/Frameworks/HIServices.framework/HIServices";


typedef OSStatus (*GetProcessForPIDFn)(
                                       pid_t,
                                       ProcessSerialNumber *
                                       );

typedef AXError (*AXUIElementGetWindowFn)(
                                          AXUIElementRef,
                                          CGWindowID *
                                          );

typedef AXUIElementRef (*AXUIElementCreateWithRemoteTokenFn)(
                                                             CFDataRef
                                                             );

#endif

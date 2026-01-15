//
//  SLPSTypes.h
//  TestingAX_SkyLight
//
//  Created by Aryan Rogye on 1/12/26.
//

#ifndef SLPSTypes_H
#define SLPSTypes_H

#import <CoreGraphics/CoreGraphics.h>

static const char *skylightPath = "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight";

typedef CGError (*SLPSSetFrontProcessWithOptionsFn)(
                                                    ProcessSerialNumber *,
                                                    CGWindowID,
                                                    uint32_t
                                                    );

typedef CGError (*SLPSPostEventRecordToFn)(
                                           ProcessSerialNumber *,
                                           UInt8 *bytes
                                           );

/// TODO: Move below to a seperate File

#endif

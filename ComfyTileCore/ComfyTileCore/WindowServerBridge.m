//
//  WindowServerBridge.m
//  TestingAX_SkyLight
//
//  Created by Aryan Rogye on 1/13/26.
//

#import <ApplicationServices/ApplicationServices.h>
#import <dlfcn.h>

#import <ComfyTileCore/WindowServerBridge.h>
#import <ComfyTileCore/HIServicesTypes.h>
#import <ComfyTileCore/SLPSTypes.h>

@interface WindowServerBridge()
@property (nonatomic, nullable) void* skylightHandle;
@property (nonatomic, nullable) void* hiServicesHandle;
@property (nonatomic, nullable) SLPSSetFrontProcessWithOptionsFn setFrontProcessWithOptions;
@property (nonatomic, nullable) SLPSPostEventRecordToFn postEventRecordTo;
@property (nonatomic, nullable) GetProcessForPIDFn GetProcessForPID;
@property (nonatomic, nullable) AXUIElementGetWindowFn AXUIElementGetWindow;
@property (nonatomic, nullable) AXUIElementCreateWithRemoteTokenFn AXUIElementCreateWithRemoteToken;
@end

@implementation WindowServerBridge

- (void) focusAppForUserWindow:(UserWindow*)userWindow {
    UInt32 windowID = (UInt32)userWindow.window.windowID;
    pid_t pid = userWindow.pid;
    
    ProcessSerialNumber psn = {0, 0};
    OSStatus status = self.GetProcessForPID(pid, &psn);
    if (status != noErr) {
        NSLog(@"\e[1;31mCould Not Get Process For PID\e[0m");
        /// Dont Return this could just be a weird bug in the moment
        return;
    }
    
    /// 0x200 is - userGenerated
    self.setFrontProcessWithOptions(&psn, windowID, 0x200);
    NSLog(@"\e[1;32mSet Front Process With Options\e[0m");
    
    [self makeKeyWindowForWindowID:windowID psn:&psn];
    NSLog(@"\e[1;32mMade Key Window For WindowID\e[0m");
    //    self.makeKeyWindow(&psn, windowID)
    
    if (userWindow.element != NULL) {
        NSLog(@"\e[1;32mAXElement Exists, Attempting To Raise\e[0m");
        AXUIElementPerformAction(userWindow.element, kAXRaiseAction);
        NSLog(@"\e[1;32mRaising Done\e[0m");
    } else {
        for (int attempt = 0; attempt < 3; attempt++) {
            AXUIElementRef element = [self findAXUIElementForWindowID:windowID pid:pid];
            if (element) {
                NSLog(@"\e[1;32mAXElement Found, Rasing\e[0m");
                AXUIElementPerformAction(element, kAXRaiseAction);
            } else {
                NSLog(@"\e[1;31mAXElement Not Found On Try: %d\e[0m", attempt);
            }
            
            if (element) CFRelease(element);
            if (element) break;
        }
    }
}

- (nullable AXUIElementRef) findMatchingAXWindowWithPid:(pid_t)pid targetWindowID:(CGWindowID)targetWindowID {
    
    AXUIElementRef appAX = AXUIElementCreateApplication(pid);
    if (!appAX) return NULL;
    
    CFTypeRef windowsValue = NULL;
    AXError err = AXUIElementCopyAttributeValue(appAX, kAXWindowsAttribute, &windowsValue);
    CFRelease(appAX);
    
    if (err != kAXErrorSuccess || !windowsValue) {
        if (windowsValue) CFRelease(windowsValue);
        return NULL;
    }
    
    if (CFGetTypeID(windowsValue) != CFArrayGetTypeID()) {
        CFRelease(windowsValue);
        return NULL;
    }
    
    CFArrayRef windows = (CFArrayRef)windowsValue;
    
    for (CFIndex i = 0; i < CFArrayGetCount(windows); i++) {
        AXUIElementRef winAX = (AXUIElementRef)CFArrayGetValueAtIndex(windows, i);
        if (!winAX) continue;
        
        CGWindowID wid = 0;
        if (_AXUIElementGetWindow(winAX, &wid) == kAXErrorSuccess && wid == targetWindowID) {
            CFRetain(winAX);          // IMPORTANT: returning it, so retain it
            CFRelease(windowsValue);  // release the array container
            return winAX;
        }
    }
    
    CFRelease(windowsValue);
    return NULL;
}

// MARK: - Private API's
- (void) makeKeyWindowForWindowID:(UInt32)windowID psn:(ProcessSerialNumber *)psn {
    UInt8 bytes[0xf8] = {0};
    
    bytes[0x04] = 0xf8;
    bytes[0x08] = 0x01;
    bytes[0x3a] = 0x10;
    
    bytes[0x3c] = (windowID & 0xFF);
    bytes[0x3d] = ((windowID >> 8) & 0xFF);
    bytes[0x3e] = ((windowID >> 16) & 0xFF);
    bytes[0x3f] = ((windowID >> 24) & 0xFF);
    
    UInt64 psnLow = psn->lowLongOfPSN;
    UInt64 psnHigh = psn->highLongOfPSN;
    UInt64 psnValue = psnLow | (psnHigh << 32);
    for (int i = 0; i < 8; i++) {
        bytes[0x20 + i] = (UInt8)((psnValue >> (i * 8)) & 0xFF);
    }
    
    self.postEventRecordTo(psn, bytes);
}

- (AXUIElementRef) findAXUIElementForWindowID:(UInt32)windowID pid:(pid_t)pid {
    // Probe token structures until we find the right one
    for (UInt32 tokenValue = 0; tokenValue < 65536; tokenValue++) {
        UInt8 token[20] = {0};
        
        // Encode potential token structure
        token[0] = 0x00;
        token[1] = 0x62;
        token[2] = 0x00;
        token[3] = 0x00;
        
        // Window ID at offset 4
        token[4] = (UInt8)(windowID & 0xFF);
        token[5] = (UInt8)((windowID >> 8) & 0xFF);
        token[6] = (UInt8)((windowID >> 16) & 0xFF);
        token[7] = (UInt8)((windowID >> 24) & 0xFF);
        
        // Token value at offset 8 (little-endian 16-bit inside 32-bit loop)
        token[8]  = (UInt8)(tokenValue & 0xFF);
        token[9]  = (UInt8)((tokenValue >> 8) & 0xFF);
        token[10] = 0x00;
        token[11] = 0x00;
        
        // More header bytes
        token[12] = 0x00;
        token[13] = 0x00;
        token[14] = 0x01;
        token[15] = 0x00;
        
        CFDataRef tokenData = CFDataCreate(kCFAllocatorDefault, token, 20);
        
        AXUIElementRef element = self.AXUIElementCreateWithRemoteToken(tokenData);
        CFRelease(tokenData);
        if (element) {
            UInt32 foundID = 0;
            AXError axErr = self.AXUIElementGetWindow(element, &foundID);
            if (axErr == kAXErrorSuccess && foundID == windowID) {
                return element;
            }
            CFRelease(element);
        }
    }
    return NULL;
}

- (void)dealloc
{
    if (self.skylightHandle) {
        dlclose(self.skylightHandle);
    }
    if (self.hiServicesHandle) {
        dlclose(self.hiServicesHandle);
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.skylightHandle = NULL;
        self.hiServicesHandle = NULL;
        self.setFrontProcessWithOptions = NULL;
        self.postEventRecordTo = NULL;
        self.GetProcessForPID = NULL;
        
        /// Get Handle And Assign Pointers to Functions
        [self openHandle];
        [self setGetProcessForPID];
        [self setSLPSPostEventRecordTo];
        [self setSLPSSetFrontProcessWithOptions];
        [self setAXUIElementGetWindow];
        [self setAXUIElementCreateWithRemoteToken];
    }
    return self;
}

- (void) openHandle {
    self.skylightHandle = dlopen(skylightPath, RTLD_LAZY | RTLD_GLOBAL);
    if (!self.skylightHandle) {
        NSLog(@"\e[1;31mSkyLight Handle is Null\e[0m");
        exit(1);
    }
    
    self.hiServicesHandle = dlopen(hiServicesPath, RTLD_LAZY | RTLD_GLOBAL);
    if (!self.hiServicesHandle) {
        NSLog(@"\e[1;31mHIServices Handle is Null\e[0m");
        exit(1);
    }
    
    NSLog(@"✅ Handles are Ready");
}

- (void) setAXUIElementCreateWithRemoteToken {
    NSLog(@"Attempting AXUIElementCreateWithRemoteToken");
    void* sym = dlsym(self.hiServicesHandle, "AXUIElementCreateWithRemoteToken");
    if (!sym) {
        NSLog(@"Attempting _AXUIElementGetWindow");
        sym = dlsym(self.hiServicesHandle, "_AXUIElementCreateWithRemoteToken");
        if (!sym) {
            NSLog(@"\e[1;31mdlsym Cant be Found: %s\e[0m", dlerror());
            exit(1);
        } else {
            NSLog(@"✅ _AXUIElementCreateWithRemoteToken Success");
        }
    } else {
        NSLog(@"✅ AXUIElementCreateWithRemoteToken Success");
    }
    
    self.AXUIElementCreateWithRemoteToken = sym;
}

- (void) setAXUIElementGetWindow {
    NSLog(@"Attempting AXUIElementGetWindow");
    void* sym = dlsym(self.hiServicesHandle, "AXUIElementGetWindow");
    if (!sym) {
        NSLog(@"Attempting _AXUIElementGetWindow");
        sym = dlsym(self.hiServicesHandle, "_AXUIElementGetWindow");
        if (!sym) {
            NSLog(@"\e[1;31mdlsym Cant be Found: %s\e[0m", dlerror());
            exit(1);
        } else {
            NSLog(@"✅ _AXUIElementGetWindow Success");
        }
    } else {
        NSLog(@"✅ AXUIElementGetWindow Success");
    }
    
    self.AXUIElementGetWindow = sym;
}

- (void) setGetProcessForPID {
    NSLog(@"Attempting GetProcessForPID");
    void* sym = dlsym(self.hiServicesHandle, "GetProcessForPID");
    if (!sym) {
        NSLog(@"Attempting _GetProcessForPID");
        sym = dlsym(self.hiServicesHandle, "_GetProcessForPID");
        if (!sym) {
            NSLog(@"\e[1;31mdlsym Cant be Found: %s\e[0m", dlerror());
            exit(1);
        } else {
            NSLog(@"✅ _GetProcessForPID Success");
        }
    } else {
        NSLog(@"✅ GetProcessForPID Success");
    }
    
    self.GetProcessForPID = sym;
}

- (void) setSLPSSetFrontProcessWithOptions {
    NSLog(@"Attempting SLPSSetFrontProcessWithOptions");
    void* sym = dlsym(self.skylightHandle, "SLPSSetFrontProcessWithOptions");
    if (!sym) {
        NSLog(@"Attempting _SLPSSetFrontProcessWithOptions");
        sym = dlsym(self.skylightHandle, "_SLPSSetFrontProcessWithOptions");
        if (!sym) {
            NSLog(@"\e[1;31mdlsym Cant be Found: %s\e[0m", dlerror());
            exit(1);
        } else {
            NSLog(@"✅ _SLPSSetFrontProcessWithOptions Success");
        }
    } else {
        NSLog(@"✅ SLPSSetFrontProcessWithOptions Success");
    }
    
    self.setFrontProcessWithOptions = sym;
}

- (void) setSLPSPostEventRecordTo {
    NSLog(@"Attempting SLPSPostEventRecordTo");
    void *sym = dlsym(self.skylightHandle, "SLPSPostEventRecordTo");
    if (!sym) {
        NSLog(@"Attempting _SLPSPostEventRecordTo");
        sym = dlsym(self.skylightHandle, "_SLPSPostEventRecordTo");
        if (!sym) {
            NSLog(@"\e[1;31mdlsym Cant be Found: %s\e[0m", dlerror());
            exit(1);
        } else {
            NSLog(@"✅ _SLPSPostEventRecordTo Success");
        }
    } else {
        NSLog(@"✅ SLPSPostEventRecordTo Success");
    }
    
    self.postEventRecordTo = sym;
}

@end

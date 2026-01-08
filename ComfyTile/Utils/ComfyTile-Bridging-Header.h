//
//  ComfyTile-Bridging-Header.h
//  ComfyTile
//  Copyright (C) 2025 Aryan Rogye
//  SPDX-License-Identifier: GPL-3.0-or-later
//  Derived from DockDoor (GPL-3.0) and/or alt-tab-macos (GPL); modified by Aryan Rogye.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

#import <AppKit/AppKit.h>

// MARK: - AX Private APIs

// Returns the CGWindowID of the provided AXUIElement
// macOS 10.10+
AXError _AXUIElementGetWindow(AXUIElementRef element, CGWindowID *outWindowID);

// MARK: - CoreGraphics Private APIs

// Core Graphics types
typedef uint32_t CGSConnectionID;
typedef uint32_t CGSWindowCount;
typedef uint64_t CGSSpaceID;
typedef uint64_t CGSSpaceMask;

// Get main connection ID
CGSConnectionID CGSMainConnectionID(void);

// Capture window screenshots
CFArrayRef CGSHWCaptureWindowList(
                                  CGSConnectionID cid,
                                  const uint32_t *windowList,
                                  CGSWindowCount count,
                                  uint32_t options
                                  );

// Get window level (layer)
int32_t CGSGetWindowLevel(
                          CGSConnectionID cid,
                          uint32_t wid,
                          int32_t *outLevel
                          );

// Copy window property (e.g., title)
int32_t CGSCopyWindowProperty(
                              CGSConnectionID cid,
                              uint32_t wid,
                              CFStringRef key,
                              CFTypeRef *outValue
                              );

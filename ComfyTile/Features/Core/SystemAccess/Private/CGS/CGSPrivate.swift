//
//  CGSPrivate.swift
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


import CoreGraphics

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> CGSConnectionID

@_silgen_name("CGSHWCaptureWindowList")
func CGSHWCaptureWindowList(
    _ cid: CGSConnectionID,
    _ windowList: UnsafePointer<UInt32>?,
    _ count: CGSWindowCount,
    _ options: UInt32
) -> Unmanaged<CFArray>?

@_silgen_name("CGSGetWindowLevel")
func CGSGetWindowLevel(
    _ cid: CGSConnectionID,
    _ wid: UInt32,
    _ outLevel: UnsafeMutablePointer<Int32>?
) -> Int32

@_silgen_name("CGSCopyWindowProperty")
func CGSCopyWindowProperty(
    _ cid: CGSConnectionID,
    _ wid: UInt32,
    _ key: CFString,
    _ outValue: UnsafeMutablePointer<CFTypeRef?>?
) -> Int32

@_silgen_name("CGSCopySpacesForWindows")
func CGSCopySpacesForWindows(
    _ cid: CGSConnectionID,
    _ mask: CGSSpaceMask,
    _ windowIDs: CFArray
) -> Unmanaged<CFArray>?

struct CGSWindowCaptureOptions: OptionSet {
    let rawValue: UInt32
    
    static let ignoreGlobalClipShape = CGSWindowCaptureOptions(rawValue: 1 << 11)
    static let nominalResolution     = CGSWindowCaptureOptions(rawValue: 1 << 9)
    static let bestResolution        = CGSWindowCaptureOptions(rawValue: 1 << 8)
    static let fullSize              = CGSWindowCaptureOptions(rawValue: 1 << 19)
}

let kCGSAllSpacesMask: CGSSpaceMask = CGSSpaceMask.max

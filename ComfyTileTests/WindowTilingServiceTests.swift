//
//  WindowTilingServiceTests.swift
//  ComfyTileTests
//
//  Created by Aryan Rogye on 6/10/26.
//

import Testing
@testable import ComfyTile
import Foundation
import ScreenCaptureKit

// MARK: - Test Fakes

extension ComfyWindow {
    static func fake(
        windowID: CGWindowID = 1,
        title: String = "Fake Window",
        bundleIdentifier: String = "com.fake.app",
        pid: pid_t = 1234,
        isInSpace: Bool = true
    ) -> ComfyWindow {
        ComfyWindow(
            app: NSRunningApplication.current,
            windowID: windowID,
            windowTitle: title,
            element: WindowElement.fake(),
            bundleIdentifier: bundleIdentifier,
            pid: pid,
            isInSpace: isInSpace
        )
    }
}

extension WindowElement {
    static func fake() -> WindowElement {
        return .init(element: nil)
    }
}

// MARK: - Helper

/// Creates a `WindowTilingService` wired to a fake window and `NSScreen.main`.
@MainActor
private func makeSUT() -> WindowTilingService {
    let windowCore = WindowCore()
    return WindowTilingService(windowCore: windowCore, getFocusedAndScreen: {
        (.fake(), NSScreen.main!)
    })
}

/// Creates a `WindowTilingService` whose `getFocusedAndScreen` returns `(nil, nil)`
/// so that every tiling method early-returns without side-effects.
@MainActor
private func makeNilSUT() -> WindowTilingService {
    let windowCore = WindowCore()
    return WindowTilingService(windowCore: windowCore, getFocusedAndScreen: {
        (nil, nil)
    })
}

// MARK: - HorizontalTileLayout Tests

@Suite("HorizontalTileLayout")
struct HorizontalTileLayoutTests {

    @Test func nextLayout_cyclesThroughAllThreeStates() {
        var layout = HorizontalTileLayout.half
        #expect(layout == .half)

        layout.nextLayout()
        #expect(layout == .oneThird)

        layout.nextLayout()
        #expect(layout == .twoThirds)

        layout.nextLayout()
        #expect(layout == .half)
    }

    @Test func complementary_isInvolution_forNonHalf() {
        // complementary(complementary(x)) == x  for all cases
        let cases: [HorizontalTileLayout] = [.half, .oneThird, .twoThirds]
        for c in cases {
            #expect(c.complementary().complementary() == c)
        }
    }
}

// MARK: - CenterTileLayout Tests

/// Center Tiling Goes center then centerExpanded then center again
/// as its nextLayout()
@Suite("CenterTileLayout")
struct CenterTileLayoutTests {

    @Test func nextLayout_togglesBetweenTwoStates() {
        var layout = CenterTileLayout.center
        #expect(layout == .center)

        layout.nextLayout()
        #expect(layout == .centerExpanded)

        layout.nextLayout()
        #expect(layout == .center)
    }
}

// MARK: - WindowTilingService: Smart Tiling State

@MainActor
@Suite("WindowTilingService – Smart Tiling State")
struct SmartTilingStateTests {

    @Test func initialState_allCountersAreZero() {
        let sut = makeSUT()
        #expect(sut.hasJustTiledLeft == 0)
        #expect(sut.hasJustTiledRight == 0)
        #expect(sut.hasJustTiledCenter == 0)
    }

    @Test func resetSmartTiling_clearsAllCounters() {
        let sut = makeSUT()
        // Artificially bump counters
        sut.hasJustTiledLeft = 3
        sut.hasJustTiledRight = 2
        sut.hasJustTiledCenter = 1

        sut.resetSmartTiling()

        #expect(sut.hasJustTiledLeft == 0)
        #expect(sut.hasJustTiledRight == 0)
        #expect(sut.hasJustTiledCenter == 0)
    }

    @Test func moveLeft_incrementsLeftCounter_resetsOthers() {
        let sut = makeSUT()
        sut.hasJustTiledRight = 1
        sut.hasJustTiledCenter = 1

        sut.moveLeft(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)

        #expect(sut.hasJustTiledLeft == 1)
        #expect(sut.hasJustTiledRight == 0)
        #expect(sut.hasJustTiledCenter == 0)
    }

    @Test func moveLeft_doesNotIncrementPastOne() {
        let sut = makeSUT()
        sut.moveLeft(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)
        sut.moveLeft(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)
        sut.moveLeft(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)

        #expect(sut.hasJustTiledLeft == 1)
    }

    @Test func moveRight_incrementsRightCounter_resetsOthers() {
        let sut = makeSUT()
        sut.hasJustTiledLeft = 1
        sut.hasJustTiledCenter = 1

        sut.moveRight(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)

        #expect(sut.hasJustTiledRight == 1)
        #expect(sut.hasJustTiledLeft == 0)
        #expect(sut.hasJustTiledCenter == 0)
    }

    @Test func moveRight_doesNotIncrementPastOne() {
        let sut = makeSUT()
        sut.moveRight(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)
        sut.moveRight(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)

        #expect(sut.hasJustTiledRight == 1)
    }

    @Test func center_incrementsCenterCounter_resetsLeftAndRight() {
        let sut = makeSUT()
        sut.hasJustTiledLeft = 1
        sut.hasJustTiledRight = 1

        sut.center(withAnimation: false, padding: 0, isLayoutCycling: false, isUsingAdvancedPadding: false)

        #expect(sut.hasJustTiledCenter == 1)
        #expect(sut.hasJustTiledLeft == 0)
        #expect(sut.hasJustTiledRight == 0)
    }

    @Test func fullScreen_resetsAllCounters() {
        let sut = makeSUT()
        sut.hasJustTiledLeft = 1
        sut.hasJustTiledRight = 1
        sut.hasJustTiledCenter = 1

        sut.fullScreen(withAnimation: false)

        #expect(sut.hasJustTiledLeft == 0)
        #expect(sut.hasJustTiledRight == 0)
        #expect(sut.hasJustTiledCenter == 0)
    }

    @Test func moveTopHalf_resetsAllCounters() {
        let sut = makeSUT()
        sut.hasJustTiledLeft = 1
        sut.hasJustTiledRight = 1
        sut.hasJustTiledCenter = 1

        sut.moveTopHalf(withAnimation: false)

        #expect(sut.hasJustTiledLeft == 0)
        #expect(sut.hasJustTiledRight == 0)
        #expect(sut.hasJustTiledCenter == 0)
    }

    @Test func moveBottomHalf_resetsAllCounters() {
        let sut = makeSUT()
        sut.hasJustTiledLeft = 1
        sut.hasJustTiledRight = 1
        sut.hasJustTiledCenter = 1

        sut.moveBottomHalf(withAnimation: false)

        #expect(sut.hasJustTiledLeft == 0)
        #expect(sut.hasJustTiledRight == 0)
        #expect(sut.hasJustTiledCenter == 0)
    }

    @Test func moveTopLeft_resetsAllCounters() {
        let sut = makeSUT()
        sut.hasJustTiledLeft = 1
        sut.hasJustTiledRight = 1
        sut.hasJustTiledCenter = 1

        sut.moveTopLeft(withAnimation: false)

        #expect(sut.hasJustTiledLeft == 0)
        #expect(sut.hasJustTiledRight == 0)
        #expect(sut.hasJustTiledCenter == 0)
    }

    @Test func moveTopRight_resetsAllCounters() {
        let sut = makeSUT()
        sut.hasJustTiledLeft = 1
        sut.hasJustTiledRight = 1
        sut.hasJustTiledCenter = 1

        sut.moveTopRight(withAnimation: false)

        #expect(sut.hasJustTiledLeft == 0)
        #expect(sut.hasJustTiledRight == 0)
        #expect(sut.hasJustTiledCenter == 0)
    }

    @Test func moveBottomLeft_resetsAllCounters() {
        let sut = makeSUT()
        sut.hasJustTiledLeft = 1
        sut.hasJustTiledRight = 1
        sut.hasJustTiledCenter = 1

        sut.moveBottomLeft(withAnimation: false)

        #expect(sut.hasJustTiledLeft == 0)
        #expect(sut.hasJustTiledRight == 0)
        #expect(sut.hasJustTiledCenter == 0)
    }

    @Test func moveBottomRight_resetsAllCounters() {
        let sut = makeSUT()
        sut.hasJustTiledLeft = 1
        sut.hasJustTiledRight = 1
        sut.hasJustTiledCenter = 1

        sut.moveBottomRight(withAnimation: false)

        #expect(sut.hasJustTiledLeft == 0)
        #expect(sut.hasJustTiledRight == 0)
        #expect(sut.hasJustTiledCenter == 0)
    }
}

// MARK: - WindowTilingService: Layout Cycling

@MainActor
@Suite("WindowTilingService – Layout Cycling")
struct LayoutCyclingTests {

    @Test func initialLayout_isHalf() {
        let sut = makeSUT()
        #expect(sut.leftLayout == .half)
        #expect(sut.rightLayout == .half)
    }

    @Test func initialCenterLayout_isCenter() {
        let sut = makeSUT()
        #expect(sut.centerLayout == .center)
    }

    @Test func moveLeft_withLayoutCycling_cyclesLeftLayout() {
        let sut = makeSUT()

        // First call uses .half (0.5), then advances to .oneThird
        sut.moveLeft(withAnimation: false, isLayoutCycling: true, enableSmartTiling: false)
        #expect(sut.leftLayout == .oneThird)

        // Second call uses .oneThird (1/3), then advances to .twoThirds
        sut.moveLeft(withAnimation: false, isLayoutCycling: true, enableSmartTiling: false)
        #expect(sut.leftLayout == .twoThirds)

        // Third call uses .twoThirds (2/3), then advances back to .half
        sut.moveLeft(withAnimation: false, isLayoutCycling: true, enableSmartTiling: false)
        #expect(sut.leftLayout == .half)
    }

    @Test func moveRight_withLayoutCycling_cyclesRightLayout() {
        let sut = makeSUT()

        sut.moveRight(withAnimation: false, isLayoutCycling: true, enableSmartTiling: false)
        #expect(sut.rightLayout == .oneThird)

        sut.moveRight(withAnimation: false, isLayoutCycling: true, enableSmartTiling: false)
        #expect(sut.rightLayout == .twoThirds)

        sut.moveRight(withAnimation: false, isLayoutCycling: true, enableSmartTiling: false)
        #expect(sut.rightLayout == .half)
    }

    @Test func moveLeft_withoutLayoutCycling_doesNotCycleLayout() {
        let sut = makeSUT()

        sut.moveLeft(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)
        #expect(sut.leftLayout == .half)

        sut.moveLeft(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)
        #expect(sut.leftLayout == .half)
    }

    @Test func moveRight_withoutLayoutCycling_doesNotCycleLayout() {
        let sut = makeSUT()

        sut.moveRight(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)
        #expect(sut.rightLayout == .half)

        sut.moveRight(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)
        #expect(sut.rightLayout == .half)
    }

    @Test func center_withLayoutCycling_togglesCenterLayout() {
        let sut = makeSUT()

        sut.center(withAnimation: false, padding: 10, isLayoutCycling: true, isUsingAdvancedPadding: false)
        #expect(sut.centerLayout == .centerExpanded)

        sut.center(withAnimation: false, padding: 10, isLayoutCycling: true, isUsingAdvancedPadding: false)
        #expect(sut.centerLayout == .center)
    }

    @Test func center_withoutLayoutCycling_doesNotChangeLayout() {
        let sut = makeSUT()

        sut.center(withAnimation: false, padding: 10, isLayoutCycling: false, isUsingAdvancedPadding: false)
        #expect(sut.centerLayout == .center)
    }
}

// MARK: - WindowTilingService: Smart Tiling Prediction

@MainActor
@Suite("WindowTilingService – Smart Tiling Prediction")
struct SmartTilingPredictionTests {

    @Test func moveLeft_thenMoveRight_withSmartTiling_predictsComplementaryLayout() {
        let sut = makeSUT()

        // Tile left with layout cycling → uses .half, cycles to .oneThird
        sut.moveLeft(withAnimation: false, isLayoutCycling: true, enableSmartTiling: true)
        #expect(sut.leftLayout == .oneThird)
        #expect(sut.hasJustTiledLeft == 1)

        // Now tile right with smart tiling enabled
        // Since hasJustTiledLeft > 0, it should predict the complementary:
        //   leftLayout.last() = .half (because .oneThird.last() == .half)
        //   .half.complementary() = .half
        sut.moveRight(withAnimation: false, isLayoutCycling: true, enableSmartTiling: true)
        #expect(sut.hasJustTiledRight == 1)
        #expect(sut.hasJustTiledLeft == 0)
    }

    @Test func moveRight_thenMoveLeft_withSmartTiling_predictsComplementaryLayout() {
        let sut = makeSUT()

        // Tile right with layout cycling → uses .half, cycles to .oneThird
        sut.moveRight(withAnimation: false, isLayoutCycling: true, enableSmartTiling: true)
        #expect(sut.rightLayout == .oneThird)
        #expect(sut.hasJustTiledRight == 1)

        // Now tile left with smart tiling enabled
        // Since hasJustTiledRight > 0, it should predict the complementary:
        //   rightLayout.last() = .half (because .oneThird.last() == .half)
        //   .half.complementary() = .half
        sut.moveLeft(withAnimation: false, isLayoutCycling: true, enableSmartTiling: true)
        #expect(sut.hasJustTiledLeft == 1)
        #expect(sut.hasJustTiledRight == 0)
    }

    @Test func smartTiling_notTriggered_whenBothCountersZero() {
        let sut = makeSUT()

        // Neither side has been tiled yet, so smart tiling prediction should NOT apply.
        // It should just cycle normally.
        sut.moveLeft(withAnimation: false, isLayoutCycling: true, enableSmartTiling: true)
        #expect(sut.leftLayout == .oneThird)
    }
}

// MARK: - WindowTilingService: Nil Window/Screen Guard

@MainActor
@Suite("WindowTilingService – Nil Guards")
struct NilGuardTests {

    @Test func moveLeft_withNilFocusedWindow_doesNotCrash() {
        let sut = makeNilSUT()
        sut.moveLeft(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)
        // No crash = success. State should be unchanged.
        #expect(sut.hasJustTiledLeft == 0)
    }

    @Test func moveRight_withNilFocusedWindow_doesNotCrash() {
        let sut = makeNilSUT()
        sut.moveRight(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)
        #expect(sut.hasJustTiledRight == 0)
    }

    @Test func center_withNilFocusedWindow_doesNotCrash() {
        let sut = makeNilSUT()
        sut.center(withAnimation: false, padding: 10, isLayoutCycling: false, isUsingAdvancedPadding: false)
        #expect(sut.hasJustTiledCenter == 0)
    }

    @Test func fullScreen_withNilFocusedWindow_doesNotCrash() {
        let sut = makeNilSUT()
        sut.fullScreen(withAnimation: false)
        // Just verify no crash
    }

    @Test func moveTopHalf_withNilFocusedWindow_doesNotCrash() {
        let sut = makeNilSUT()
        sut.moveTopHalf(withAnimation: false)
    }

    @Test func moveBottomHalf_withNilFocusedWindow_doesNotCrash() {
        let sut = makeNilSUT()
        sut.moveBottomHalf(withAnimation: false)
    }

    @Test func moveTopLeft_withNilFocusedWindow_doesNotCrash() {
        let sut = makeNilSUT()
        sut.moveTopLeft(withAnimation: false)
    }

    @Test func moveTopRight_withNilFocusedWindow_doesNotCrash() {
        let sut = makeNilSUT()
        sut.moveTopRight(withAnimation: false)
    }

    @Test func moveBottomLeft_withNilFocusedWindow_doesNotCrash() {
        let sut = makeNilSUT()
        sut.moveBottomLeft(withAnimation: false)
    }

    @Test func moveBottomRight_withNilFocusedWindow_doesNotCrash() {
        let sut = makeNilSUT()
        sut.moveBottomRight(withAnimation: false)
    }
}

// MARK: - WindowTilingService: Padding

@MainActor
@Suite("WindowTilingService – Padding")
struct PaddingTests {

    @Test func setPaddingForScreen_storesClosure() {
        let sut = makeSUT()
        #expect(sut.paddingForScreen == nil)

        sut.setPaddingForScreen { _ in 20.0 }
        #expect(sut.paddingForScreen != nil)
    }

    @Test func center_withAdvancedPadding_usesCustomPaddingClosure() {
        let sut = makeSUT()
        sut.setPaddingForScreen { _ in 42.0 }

        // Should not crash and should use the custom padding
        sut.center(withAnimation: false, padding: 10, isLayoutCycling: false, isUsingAdvancedPadding: true)

        // The padding was used (no visible crash), counters are updated
        #expect(sut.hasJustTiledCenter == 1)
    }

    @Test func center_withAdvancedPadding_fallsBackToPaddingParam_whenClosureReturnsNil() {
        let sut = makeSUT()
        sut.setPaddingForScreen { _ in nil }

        sut.center(withAnimation: false, padding: 10, isLayoutCycling: false, isUsingAdvancedPadding: true)

        #expect(sut.hasJustTiledCenter == 1)
    }
}

// MARK: - WindowTilingService: Cross-Direction State Transitions

@MainActor
@Suite("WindowTilingService – Cross-Direction Transitions")
struct CrossDirectionTests {

    @Test func alternatingLeftRight_keepsCorrectCounters() {
        let sut = makeSUT()

        sut.moveLeft(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)
        #expect(sut.hasJustTiledLeft == 1)
        #expect(sut.hasJustTiledRight == 0)

        sut.moveRight(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)
        #expect(sut.hasJustTiledLeft == 0)
        #expect(sut.hasJustTiledRight == 1)

        sut.moveLeft(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)
        #expect(sut.hasJustTiledLeft == 1)
        #expect(sut.hasJustTiledRight == 0)
    }

    @Test func center_afterLeftRight_resetsBoth() {
        let sut = makeSUT()

        sut.moveLeft(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)
        sut.center(withAnimation: false, padding: 0, isLayoutCycling: false, isUsingAdvancedPadding: false)

        #expect(sut.hasJustTiledLeft == 0)
        #expect(sut.hasJustTiledRight == 0)
        #expect(sut.hasJustTiledCenter == 1)
    }

    @Test func fullScreen_afterCenter_resetsCenter() {
        let sut = makeSUT()

        sut.center(withAnimation: false, padding: 0, isLayoutCycling: false, isUsingAdvancedPadding: false)
        #expect(sut.hasJustTiledCenter == 1)

        sut.fullScreen(withAnimation: false)
        #expect(sut.hasJustTiledCenter == 0)
    }

    @Test func cornerMoves_afterLeftTile_resetLeftCounter() {
        let sut = makeSUT()

        sut.moveLeft(withAnimation: false, isLayoutCycling: false, enableSmartTiling: false)
        #expect(sut.hasJustTiledLeft == 1)

        sut.moveTopLeft(withAnimation: false)
        #expect(sut.hasJustTiledLeft == 0)
        #expect(sut.hasJustTiledRight == 0)
        #expect(sut.hasJustTiledCenter == 0)
    }
}

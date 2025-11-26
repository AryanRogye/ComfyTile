//
//  AXUtils.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 11/2/25.
//


@MainActor
struct AXUtils {
    public static func findMatchingAXWindow(
        pid: pid_t,
        targetCGSWindowID: CGWindowID,
        targetCGSFrame: CGRect,
        targetCGSTitle: String?
    ) -> AXUIElement? {
        
        let appAX = AXUIElementCreateApplication(pid)
        
        var windowsRef: AnyObject?
        guard AXUIElementCopyAttributeValue(appAX, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let axWindowsAll = windowsRef as? [AXUIElement]
        else { return nil }
        
        let axTargetRect = AXUtils().cgToAXRect(targetCGSFrame)
        let tol: CGFloat = 12.0 // be generous; titles/shadows/scale can skew a bit
        
        for ax in AXUIElement.windowsByBruteForce(pid) {
            if let axRect = getAXWindowRect(ax),
               axRect.width >= 5, axRect.height >= 5,
               AXUtils().rectRoughMatch(axRect, axTargetRect, tol: tol) {
                return ax
            }
        }
        
        return nil
    }
    
    private func cgToAXRect(_ cg: CGRect) -> CGRect {
        // Pick the screen that contains the CG rect
        let screen = NSScreen.screens.first { $0.frame.intersects(cg) } ?? NSScreen.main!
        // Flip Y: CG uses a different origin than AX
        let flippedY = screen.frame.maxY - (cg.origin.y + cg.size.height)
        return CGRect(x: cg.origin.x, y: flippedY, width: cg.size.width, height: cg.size.height)
    }
    
    private func nearlyEqual(_ a: CGFloat, _ b: CGFloat, tol: CGFloat) -> Bool {
        abs(a - b) <= tol
    }
    
    private func rectRoughMatch(_ a: CGRect, _ b: CGRect, tol: CGFloat) -> Bool {
        nearlyEqual(a.origin.x, b.origin.x, tol: tol)
        && nearlyEqual(a.origin.y, b.origin.y, tol: tol)
        && nearlyEqual(a.size.width, b.size.width, tol: tol)
        && nearlyEqual(a.size.height, b.size.height, tol: tol)
    }

    
    private static func isValidAXWindowCandidate(_ axWindow: AXUIElement) -> Bool {
        var roleRef: AnyObject?
        guard AXUIElementCopyAttributeValue(axWindow, kAXRoleAttribute as CFString, &roleRef) == .success,
              let role = roleRef as? String, role == kAXWindowRole as String else {
            return false
        }
        
        var subroleRef: AnyObject?
        if AXUIElementCopyAttributeValue(axWindow, kAXSubroleAttribute as CFString, &subroleRef) == .success {
            if let subrole = subroleRef as? String,
               ![kAXStandardWindowSubrole as String, kAXDialogSubrole as String].contains(subrole) {
                return false
            }
        }
        
        guard let rect = getAXWindowRect(axWindow),
              rect.width >= 100, rect.height >= 100,
              rect.origin.x.isFinite, rect.origin.y.isFinite
        else {
            return false
        }
        
        return true
    }
    
    private static func getAXWindowRect(_ axWindow: AXUIElement) -> CGRect? {
        var positionRef: AnyObject?
        var sizeRef: AnyObject?
        guard AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &positionRef) == .success,
              AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &sizeRef) == .success
        else { return nil }
        
        var cgPoint: CGPoint = .zero
        var cgSize: CGSize = .zero
        AXValueGetValue(positionRef as! AXValue, .cgPoint, &cgPoint)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &cgSize)
        
        guard cgSize.width > 50 && cgSize.height > 50 else { return nil }
        return CGRect(origin: cgPoint, size: cgSize)
    }
}



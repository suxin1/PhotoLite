import SwiftUI
import AppKit
import CoreGraphics

extension CGKeyCode
{
    // Define whatever key codes you want to detect here
//    static let kVK_UpArrow: CGKeyCode = 0x7E
    static let kVK_Command                   : CGKeyCode = 0x37
    static let kVK_Shift                     : CGKeyCode = 0x38
    static let kVK_Space                     : CGKeyCode = 0x31
    var isPressed: Bool {
        CGEventSource.keyState(.combinedSessionState, key: self)
    }
}

enum RenderType {
    case metal
    case swiftUI
}

class PhotoViewEnvet {
    var active = false // active when mouse hover
    var continuousPhase: HoverPhase = .ended
    var continuousCursorPoint: CGPoint = .zero
    var anchorPhase: HoverPhase = .ended
    
    var shiftKeyPressed = false
    var commandKeyPressed = false
    var spaceKeyPressed = false
    var leftMousePressed = false
    
    var arrowCursor = NSCursor(image: NSImage(systemSymbolName: "arrow.left.and.right", accessibilityDescription: nil)!, hotSpot: .zero)
    
    var keyStates: [CGKeyCode: Bool] =
    [
        .kVK_Shift: false,
        .kVK_Command: false,
        .kVK_Space: false,
        // populate with other key codes you're interested in
    ]
    
    static let shared = PhotoViewEnvet()
    
    init() {
        pollKeyStates()
        listenForScroll()
    }
    
    func handleHover(phase: HoverPhase) {
        switch phase {
            case .active(let point):
                active = true
                continuousCursorPoint = point
                MetalViewModel.shared.setAnchor(p: point)
            case .ended:
                active = false
            
        }
    }
    
    func handleGesture(gesture: DragGesture.Value) {
//        if (commandKeyPressed) {
            
//            MetalViewModel.shared.setOffsetByOrigin(x: gesture.translation.width, y: gesture.translation.height)
            MetalViewModel.shared.move(current: gesture.location)
//        }
    }
    
    
    func onSpaceKeyPress() {
        spaceKeyPressed = true
        NSCursor.openHand.push()
        MetalViewModel.shared.setDragStart(pt: self.continuousCursorPoint)
    }
    
    func onSpaceKeyRelease() {
        spaceKeyPressed = false
        anchorPhase = .ended
    }
    
    func listenForScroll() {
        NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { event in
            if (event.scrollingDeltaY != 0) {
//                MetalViewModel.shared.setAnchor(p: self.continuousCursorPoint)
//                MetalViewModel.shared.accumulateScale(event.scrollingDeltaY * 0.04)
                if (self.spaceKeyPressed) {
                    print(event)
                    MetalViewModel.shared.moveByDelta(dx: event.scrollingDeltaX, dy: event.scrollingDeltaY)
                } else {
                    MetalViewModel.shared.zoom(steps: event.scrollingDeltaY * 0.1)
                }
               
            }
            
            return event
        }
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { event in
            MetalViewModel.shared.setDragStart(pt: self.continuousCursorPoint)
            return event
        }
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]) { event in
            return event
        }
    }
    
    func pollKeyStates()
    {
        for (code, wasPressed) in keyStates
        {
            if code.isPressed
            {
                if !wasPressed
                {
                    dispatchKeyDown(code)
                    keyStates[code] = true
                }
            }
            else if wasPressed
            {
                dispatchKeyUp(code)
                keyStates[code] = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50))
        {
            // The infinite loop from previous code is replaced by
            // infinite chaining.
            self.pollKeyStates()
        }
    }
    
    func dispatchKeyDown(_ code: CGKeyCode) {
        if (active) {
            if (code == .kVK_Space) {
                onSpaceKeyPress()
            }
//            if (code == .kVK_Shift) {
//                onShiftKeyPress()
//            }
//            if (code == .kVK_Command) {
//                onCommandKeyPress()
//            }
        }
    }
    
    func dispatchKeyUp(_ code: CGKeyCode) {
//        if (code == .kVK_Space) {
////            shiftKeyPressed = false
//            onCommandKeyRelease()
//        }
        if (code == .kVK_Space) {
            onSpaceKeyRelease()
        }
        NSCursor.pop()
    }
}

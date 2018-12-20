//
//  GameInputController.swift
//  StNesEmu
//
//  Created by paraches on 2018/12/16.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation
import Cocoa

extension Int {
    static let keyboardA = 0
    static let keyboardS = 1
    static let keyboardX = 6
    static let keyboardZ = 7
    static let keyboardLeft = 123
    static let keyboardRight = 124
    static let keyboardDown = 125
    static let keyboardUp = 126
}

class GameInputController: NSObject, KeyPadSetProtocol {
    struct PadValue {
        var hVal: UInt8 = 64
        var vVal: UInt8 = 64
        var button: UInt8 = 0
        
        init(data: Data) {
            if data.count == 3 {
                hVal = data[0]
                vVal = data[1]
                button = data[2]
            }
        }
        
        static func ==(lhs: PadValue, rhs: PadValue) -> Bool {
            return (lhs.hVal == rhs.hVal) && (lhs.vVal == rhs.vVal) && (lhs.button == rhs.button)
        }
        
        static func !=(lhs: PadValue, rhs: PadValue) -> Bool {
            return (lhs.hVal != rhs.hVal) || (lhs.vVal != rhs.vVal) || (lhs.button != rhs.button)
        }
        
    }

    var lastPadValue: PadValue = PadValue(data: Data())

    static let gamePadKeyCodeTable: Dictionary<Int, Int?> = [0: .aKey, 1: .bKey, 2: nil, 3: .selectKey, 4: .startKey, 5:nil, 6: nil, 7: nil]
    
    static let keyboardKeyCodeTable: Dictionary<Int, Int> = [.keyboardZ: .aKey, .keyboardX: .bKey, .keyboardA: .selectKey, .keyboardS: .startKey, .keyboardUp: .upKey, .keyboardDown: .downKey, .keyboardLeft: .leftKey, .keyboardRight: .rightKey]
    
    var keyPad: KeyPadProtocol?
    
    func setKeyPad(_ keyPad: KeyPadProtocol) {
        self.keyPad = keyPad
        setupKeyInput()
        setupHidInput()
    }
    
    func setupKeyInput() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            guard let keyPad = self.keyPad, let keyPadCode = GameInputController.keyboardKeyCodeTable[Int($0.keyCode)] else { return $0 }
            keyPad.onKeyDown(keyPadCode)
            return nil
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) {
            guard let keyPad = self.keyPad, let keyPadCode = GameInputController.keyboardKeyCodeTable[Int($0.keyCode)] else { return $0 }
            keyPad.onKeyUp(keyPadCode)
            return nil
        }
    }
    
    func setupHidInput() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.hidReadData), name: .HIDDeviceDataReceived, object: nil)
    }
    
    @objc func hidReadData(notification: Notification) {
        if let dic = notification.object as? NSDictionary, let data = dic["data"] as? Data {
            if data.count == 3 {
                sendHidKey(PadValue(data: data))
            }
        }
    }
    
    func sendHidKey(_ val: PadValue) {
        guard let keyPad = keyPad, lastPadValue != val else {
            return
        }

        //  check left, right button
        if val.hVal != lastPadValue.hVal {
            if val.hVal == 0 {
                if lastPadValue.hVal == 127 {
                    keyPad.onKeyUp(.rightKey)
                }
                keyPad.onKeyDown(.leftKey)
            }
            else if val.hVal == 127 {
                if lastPadValue.hVal == 0 {
                    keyPad.onKeyUp(.leftKey)
                }
                keyPad.onKeyDown(.rightKey)
            }
            else {
                if lastPadValue.hVal == 0 {
                    keyPad.onKeyUp(.leftKey)
                }
                else {
                    keyPad.onKeyUp(.rightKey)
                }
            }
        }
        
        //  check up, down button
        if val.vVal != lastPadValue.vVal {
            if val.vVal == 0 {
                if lastPadValue.vVal == 127 {
                    keyPad.onKeyUp(.downKey)
                }
                keyPad.onKeyDown(.upKey)
            }
            else if val.vVal == 127 {
                if lastPadValue.vVal == 0 {
                    keyPad.onKeyUp(.upKey)
                }
                keyPad.onKeyDown(.downKey)
            }
            else {
                if lastPadValue.vVal == 0 {
                    keyPad.onKeyUp(.upKey)
                }
                else {
                    keyPad.onKeyUp(.downKey)
                }
            }
        }
        
        //  check buttons
        let vXor = val.button ^ lastPadValue.button
        for bit in 0..<8 {
            if vXor[bit] {
                if let tableValue = GameInputController.gamePadKeyCodeTable[bit], let keyCode = tableValue {
                    if val.button[bit] {
                        keyPad.onKeyDown(keyCode)
                    }
                    else {
                        keyPad.onKeyUp(keyCode)
                    }
                }
            }
        }
        
        self.lastPadValue = val
    }
}

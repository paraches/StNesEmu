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
    static let keyboardKeyCodeTable: Dictionary<Int, Int> = [.keyboardZ: .aKey, .keyboardX: .bKey, .keyboardA: .selectKey, .keyboardS: .startKey, .keyboardUp: .upKey, .keyboardDown: .downKey, .keyboardLeft: .leftKey, .keyboardRight: .rightKey]
    
    var keyPad: KeyPadProtocol?
    
    func setKeyPad(keyPad: KeyPadProtocol) {
        self.keyPad = keyPad
        setupKeyInput()
    }
    
    func setupKeyInput() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            guard let keyPad = self.keyPad, let keyPadCode = GameInputController.keyboardKeyCodeTable[Int($0.keyCode)] else { return $0 }
            keyPad.onKeyDown(index: keyPadCode)
            return nil
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) {
            guard let keyPad = self.keyPad, let keyPadCode = GameInputController.keyboardKeyCodeTable[Int($0.keyCode)] else { return $0 }
            keyPad.onKeyUp(index: keyPadCode)
            return nil
        }
    }
}

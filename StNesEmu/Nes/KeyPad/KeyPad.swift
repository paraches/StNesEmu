//
//  KeyPad.swift
//  StNesEmu
//
//  Created by paraches on 2018/12/16.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

extension Int {
    static let aKey = 0
    static let bKey = 1
    static let selectKey = 2
    static let startKey = 3
    static let upKey = 4
    static let downKey = 5
    static let leftKey = 6
    static let rightKey = 7
}

class KeyPad: NSObject, KeyPadProtocol {
    var isSet: Bool = false
    var index = 0
    var keyRegisters: [Bool]
    var keyBuffer: [Bool]
    
    override init() {
        keyRegisters = [Bool](repeating: false, count: 8)
        keyBuffer = [Bool](repeating: false, count: 8)
        
        super.init()
    }
    
    func onKeyDown(index: Int) {
        if index < keyBuffer.count {
            keyBuffer[index] = true
        }
    }
    
    func onKeyUp(index: Int) {
        if index < keyBuffer.count {
            keyBuffer[index] = false
        }
    }
    
    func write(_ data: Byte) {
        if (data & 0x01) != 0 {
            isSet = true
        }
        else if isSet && !((data & 0x01) != 0) {
            isSet = false
            index = 0
            for (i, value) in keyBuffer.enumerated() {
                keyRegisters[i] = value
            }
        }
    }
    
    func read() -> Bool {
        guard keyRegisters.count > index else { return false }
        let readIndex = index
        index += 1
        return keyRegisters[readIndex]
    }
}


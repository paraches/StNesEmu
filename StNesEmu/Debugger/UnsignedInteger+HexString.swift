//
//  UnsignedInteger+HexString.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/19.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

extension UInt8 {
    func hexString() -> String {
        return String(format: "%02X", self)
    }
}

extension UInt16 {
    func hexString() -> String {
        return String(format: "%04X", self)
    }
}

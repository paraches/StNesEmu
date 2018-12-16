//
//  KeyPadProtocols.swift
//  StNesEmu
//
//  Created by paraches on 2018/12/16.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

protocol KeyPadProtocol {
    func onKeyDown(index: Int)
    func onKeyUp(index: Int)
}

protocol KeyPadSetProtocol {
    func setKeyPad(keyPad: KeyPadProtocol)
}

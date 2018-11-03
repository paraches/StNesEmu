//
//  Interrupts.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/03.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

class Interrupts: NSObject {
    var nmi = false
    var irq = false
    
    func isNMIAssert() -> Bool {
        return nmi
    }
    
    func isIRQAssert() -> Bool {
        return irq
    }
    
    func assertNMI() {
        nmi = true
    }
    
    func deassertNMI() {
        nmi = false
    }
    
    func assertIRQ() {
        irq = true
    }
    
    func deassertIRQ() {
        irq = false
    }
}

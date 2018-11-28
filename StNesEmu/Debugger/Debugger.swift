//
//  Debugger.swift
//  StNesEmu
//
//  Created by paraches on 2018/11/20.
//  Copyright © 2018年 paraches lifestyle lab. All rights reserved.
//

import Foundation

class Debugger: NSObject {
    private static var stepLogs = [CPU.StepInfo]()
    
    static func addStep(_ step: CPU.StepInfo) {
        stepLogs.append(step)
    }
    
    static func lastStep() -> CPU.StepInfo? {
        return stepLogs.last
    }
    
    static func dumpMemory(memory: [UInt8], address: Word = 0, count: Word = 256) -> Void {
        print("     00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F")
        for i in stride(from: address, to: address+count-1, by: 16) {
            let hexAddress = String(format: "%04X", i)
            var bytes = ""
            for j in i..<i+16 {
                bytes = bytes + " " + String(format: "%02X", memory[Int(j)])
            }
            print("\(hexAddress)\(bytes)")
        }
    }

}
